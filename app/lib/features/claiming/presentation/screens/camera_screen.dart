import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:trash/core/constants/app_constants.dart';
import 'package:trash/core/theme/app_theme.dart';
import 'package:trash/features/auth/data/providers/auth_providers.dart';
import 'package:trash/features/claiming/presentation/controllers/claiming_controller.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestPermissionsAndInit();
  }

  Future<void> _requestPermissionsAndInit() async {
    final cameraStatus = await Permission.camera.request();
    final locationStatus = await Permission.locationWhenInUse.request();

    if (!mounted) return;

    if (cameraStatus.isDenied) {
      context.pop();
      return;
    }

    ref.read(cameraNotifierProvider.notifier).initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraState = ref.read(cameraNotifierProvider);
    if (cameraState.controller == null) return;

    if (state == AppLifecycleState.inactive) {
      cameraState.controller!.dispose();
    } else if (state == AppLifecycleState.resumed) {
      ref.read(cameraNotifierProvider.notifier).initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ref.read(cameraNotifierProvider.notifier).disposeCamera();
    super.dispose();
  }

  Future<void> _onSnap() async {
    final user   = ref.read(authStateProvider).valueOrNull;
    final userId = user?.uid ?? '';

    if (userId.isEmpty) {
      // Not logged in — shouldn't happen but safety check
      return;
    }
    HapticFeedback.mediumImpact();
    final path =
        await ref.read(cameraNotifierProvider.notifier).capturePhoto();
    if (path == null || !mounted) return;

    // Navigate to processing / trigger classification
    await ref.read(claimingNotifierProvider.notifier).classifyAndClaim(
      imagePath: path,
      userId: userId,              // ← real user ID
      isFirstClaimToday: true,     // improve later
      currentStreak: 3,            // Replace with real streak
        );

    if (!mounted) return;
    context.push(AppConstants.routeResult, extra: path);
  }

  @override
  Widget build(BuildContext context) {
    final cameraState = ref.watch(cameraNotifierProvider);

    // Full-screen camera experience
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: switch (cameraState.phase) {
          CameraPhase.initializing => const _CameraLoading(),
          CameraPhase.error => _CameraError(message: cameraState.errorMessage),
          _ => _CameraLiveView(
              controller: cameraState.controller!,
              phase: cameraState.phase,
              liveConfidence: cameraState.liveConfidence,
              onSnap: _onSnap,
              onClose: () => context.pop(),
            ),
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Live Camera View
// ─────────────────────────────────────────────────────────────────────────────

class _CameraLiveView extends StatelessWidget {
  final CameraController controller;
  final CameraPhase phase;
  final double? liveConfidence;
  final VoidCallback onSnap;
  final VoidCallback onClose;

  const _CameraLiveView({
    required this.controller,
    required this.phase,
    required this.liveConfidence,
    required this.onSnap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isProcessing = phase == CameraPhase.processing ||
        phase == CameraPhase.capturing;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Camera preview (fills screen) ──────────────────────────────────
        _FullScreenCameraPreview(controller: controller),

        // ── Vignette overlay ───────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.55),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withOpacity(0.75),
              ],
              stops: const [0.0, 0.25, 0.65, 1.0],
            ),
          ),
        ),

        // ── Targeting reticle ──────────────────────────────────────────────
        Center(
          child: _TargetReticle(confidence: liveConfidence),
        ),

        // ── Top bar ────────────────────────────────────────────────────────
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                _CircleButton(
                  icon: Icons.close_rounded,
                  onTap: onClose,
                ),
                const Spacer(),
                const _ScanningBadge(),
              ],
            ),
          ),
        ),

        // ── Bottom controls ────────────────────────────────────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Confidence indicator
                  if (liveConfidence != null)
                    _ConfidenceBar(confidence: liveConfidence!),

                  const SizedBox(height: 20),

                  // Guidance text
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      isProcessing
                          ? 'Analysing...'
                          : 'Centre one piece of trash clearly',
                      key: ValueKey(isProcessing),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Snap button row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Gallery button (future)
                      const SizedBox(width: 64),
                      const Spacer(),
                      _SnapButton(
                        isProcessing: isProcessing,
                        onTap: isProcessing ? null : onSnap,
                      ),
                      const Spacer(),
                      // Flash toggle (future)
                      const SizedBox(width: 64),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Processing overlay ─────────────────────────────────────────────
        if (isProcessing)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor:
                          AlwaysStoppedAnimation(AppColors.accentGreen),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Identifying trash...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full Screen Camera Preview (aspect-ratio-correct)
// ─────────────────────────────────────────────────────────────────────────────

class _FullScreenCameraPreview extends StatelessWidget {
  final CameraController controller;
  const _FullScreenCameraPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) return const SizedBox.shrink();

    return LayoutBuilder(builder: (context, constraints) {
      final screenSize = Size(constraints.maxWidth, constraints.maxHeight);
      final previewSize = controller.value.previewSize!;
      final previewAspect = previewSize.height / previewSize.width;
      final screenAspect = screenSize.height / screenSize.width;

      double scale;
      if (previewAspect > screenAspect) {
        scale = screenSize.width / (previewSize.height / previewAspect);
      } else {
        scale = screenSize.height / (previewSize.height);
      }
      scale = scale.clamp(1.0, 3.0);

      return Transform.scale(
        scale: scale,
        child: Center(child: CameraPreview(controller)),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Target Reticle
// ─────────────────────────────────────────────────────────────────────────────

class _TargetReticle extends StatefulWidget {
  final double? confidence;
  const _TargetReticle({this.confidence});

  @override
  State<_TargetReticle> createState() => _TargetReticleState();
}

class _TargetReticleState extends State<_TargetReticle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conf = widget.confidence ?? 0.0;
    final isHigh = conf >= 0.65;
    final color = isHigh ? AppColors.accentGreen : Colors.white60;

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnim.value,
          child: SizedBox(
            width: 240,
            height: 240,
            child: CustomPaint(
              painter: _ReticlePainter(color: color),
            ),
          ),
        );
      },
    );
  }
}

class _ReticlePainter extends CustomPainter {
  final Color color;
  const _ReticlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const corner = 32.0;
    const gap = 16.0;

    // Top-left
    canvas.drawLine(Offset(gap, gap), Offset(gap + corner, gap), paint);
    canvas.drawLine(Offset(gap, gap), Offset(gap, gap + corner), paint);

    // Top-right
    canvas.drawLine(
        Offset(size.width - gap, gap), Offset(size.width - gap - corner, gap), paint);
    canvas.drawLine(
        Offset(size.width - gap, gap), Offset(size.width - gap, gap + corner), paint);

    // Bottom-left
    canvas.drawLine(
        Offset(gap, size.height - gap), Offset(gap + corner, size.height - gap), paint);
    canvas.drawLine(
        Offset(gap, size.height - gap), Offset(gap, size.height - gap - corner), paint);

    // Bottom-right
    canvas.drawLine(Offset(size.width - gap, size.height - gap),
        Offset(size.width - gap - corner, size.height - gap), paint);
    canvas.drawLine(Offset(size.width - gap, size.height - gap),
        Offset(size.width - gap, size.height - gap - corner), paint);
  }

  @override
  bool shouldRepaint(covariant _ReticlePainter old) => old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Confidence Bar
// ─────────────────────────────────────────────────────────────────────────────

class _ConfidenceBar extends StatelessWidget {
  final double confidence;
  const _ConfidenceBar({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final isGood = confidence >= 0.65;
    final color = isGood ? AppColors.accentGreen : Colors.orange;
    final label = isGood ? 'Good shot!' : 'Move closer or improve lighting';

    return Column(
      children: [
        Row(
          children: [
            Icon(
              isGood ? Icons.check_circle_rounded : Icons.center_focus_strong,
              color: color,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontFamily: 'Poppins',
              ),
            ),
            const Spacer(),
            Text(
              '${(confidence * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: confidence,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Snap Button
// ─────────────────────────────────────────────────────────────────────────────

class _SnapButton extends StatefulWidget {
  final bool isProcessing;
  final VoidCallback? onTap;

  const _SnapButton({required this.isProcessing, this.onTap});

  @override
  State<_SnapButton> createState() => _SnapButtonState();
}

class _SnapButtonState extends State<_SnapButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.9).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: AppColors.accentGreen.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
          ),
          child: widget.isProcessing
              ? const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor:
                          AlwaysStoppedAnimation(AppColors.forestGreen),
                    ),
                  ),
                )
              : const Icon(
                  Icons.camera_alt_rounded,
                  color: AppColors.forestGreen,
                  size: 32,
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Supporting widgets
// ─────────────────────────────────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black38,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _ScanningBadge extends StatelessWidget {
  const _ScanningBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accentGreen.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentGreen,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'AI Scanning',
            style: TextStyle(
              color: AppColors.accentGreen,
              fontSize: 12,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading / Error states
// ─────────────────────────────────────────────────────────────────────────────

class _CameraLoading extends StatelessWidget {
  const _CameraLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.accentGreen),
          ),
          SizedBox(height: 16),
          Text(
            'Starting camera...',
            style: TextStyle(
              color: Colors.white60,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  final String? message;
  const _CameraError({this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined,
                color: Colors.white38, size: 64),
            const SizedBox(height: 16),
            Text(
              message ?? 'Camera not available',
              style: const TextStyle(color: Colors.white60, fontFamily: 'Poppins'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white30)),
              child: const Text('Go back'),
            ),
          ],
        ),
      ),
    );
  }
}
