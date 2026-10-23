import 'package:trash/features/auth/data/providers/auth_providers.dart';
import 'package:trash/services/cloudinary_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:trash/core/constants/app_constants.dart';
import 'package:trash/core/theme/app_theme.dart';
import 'package:trash/features/profile/data/profile_module.dart';
import 'package:trash/features/profile/domain/entities/user_profile.dart';
import 'package:trash/features/profile/presentation/controllers/profile_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user   = ref.watch(authStateProvider).valueOrNull;
    final userId = user?.uid ?? '';

    final profileAsync = ref.watch(userProfileProvider(userId));
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: profileAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.accentGreen)),
          ),
          error: (_, __) => const Center(child: Text('Failed to load profile')),
          data: (profile) => _ProfileBody(
              profile: profile, userId: userId),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile Body
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileBody extends ConsumerWidget {
  final UserProfile profile;
  final String userId;

  const _ProfileBody({required this.profile, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Hero header ───────────────────────────────────────────────
        SliverToBoxAdapter(child: _ProfileHero(profile: profile, userId: userId)),

        // ── Stats grid ────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          sliver: SliverToBoxAdapter(child: _StatsGrid(profile: profile)),
        ),

        // ── Level progress ────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverToBoxAdapter(
              child: _LevelCard(profile: profile)),
        ),

        // ── Badges ────────────────────────────────────────────────────
        if (profile.badges.isNotEmpty) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Text('Badges', style: AppTextStyles.headlineMedium),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: _BadgesGrid(badges: profile.badges),
            ),
          ),
        ],

        // ── Category breakdown ────────────────────────────────────────
        if (profile.claimsByCategory.isNotEmpty) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Text('Claimed by type',
                  style: AppTextStyles.headlineMedium),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: _CategoryBreakdown(
                  claimsByCategory: profile.claimsByCategory),
            ),
          ),
        ],

        // ── Account settings ──────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _AccountSection(profile: profile, userId: userId),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Header
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileHero extends ConsumerWidget {
  final UserProfile profile;
  final String userId;

  const _ProfileHero({required this.profile, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.deepGreen.withOpacity(0.9),
            AppColors.background,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            children: [
              // Top bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Profile', style: AppTextStyles.headlineLarge),
                  // Edit button
                  GestureDetector(
                    onTap: () =>
                        _showEditSheet(context, ref, profile, userId),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: const Icon(Icons.edit_rounded,
                          color: AppColors.textSecondary, size: 18),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Avatar + name
              Row(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.glowGradient,
                          border: Border.all(
                            color: AppColors.accentGreen.withOpacity(0.5),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentGreen.withOpacity(0.3),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: profile.photoUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  profile.photoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _Initial(profile: profile),
                                ),
                              )
                            : _Initial(profile: profile),
                      ),
                      // Verified badge
                      if (profile.isEmailVerified)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: AppColors.accentGreen,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.background, width: 2),
                            ),
                            child: const Icon(Icons.verified_rounded,
                                size: 12, color: Colors.white),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.fullName,
                          style: AppTextStyles.headlineLarge,
                        ),
                        Text(
                          '@${profile.username}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.accentGreen,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _LevelPill(level: profile.level,
                                title: profile.levelTitle),
                            const SizedBox(width: 8),
                            if (profile.globalRank > 0)
                              _PillChip(
                                  label: '#${profile.globalRank}',
                                  color: const Color(0xFFFFD700)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Join date
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 12, color: AppColors.textHint),
                  const SizedBox(width: 5),
                  Text(
                    'Joined ${_monthYear(profile.joinedAt)}',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(width: 12),
                  if (profile.streak > 0) ...[
                    const Text('🔥',
                        style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 3),
                    Text(
                      '${profile.streak} day streak',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _monthYear(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  void _showEditSheet(BuildContext context, WidgetRef ref,
      UserProfile profile, String userId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: _EditProfileSheet(profile: profile, userId: userId),
      ),
    );
  }
}

class _Initial extends StatelessWidget {
  final UserProfile profile;
  const _Initial({required this.profile});

  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          profile.firstName.isNotEmpty
              ? profile.firstName[0].toUpperCase()
              : '?',
          style: AppTextStyles.displayMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats Grid
// ─────────────────────────────────────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  final UserProfile profile;
  const _StatsGrid({required this.profile});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _StatTile(emoji: '📸', value: '${profile.totalClaims}',
            label: 'Total Claims', color: AppColors.accentGreen),
        _StatTile(emoji: '🪙', value: _fmt(profile.coins),
            label: 'Coins', color: const Color(0xFFFFD700)),
        _StatTile(emoji: '⭐', value: '${profile.stars}',
            label: 'Stars', color: const Color(0xFF7C6CFF)),
        _StatTile(emoji: '⚡', value: _fmt(profile.score),
            label: 'Score', color: AppColors.orange),
      ],
    );
  }

  String _fmt(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}

class _StatTile extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color color;

  const _StatTile(
      {required this.emoji, required this.value,
       required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(emoji,
                style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: AppTextStyles.headlineMedium.copyWith(
                  color: color, fontWeight: FontWeight.w800, fontSize: 20)),
                Text(label, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Level Card
// ─────────────────────────────────────────────────────────────────────────────
class _LevelCard extends StatelessWidget {
  final UserProfile profile;
  const _LevelCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Level ${profile.level}',
                  style: AppTextStyles.headlineMedium),
              const SizedBox(width: 8),
              Text('· ${profile.levelTitle}',
                  style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.accentGreen)),
              const Spacer(),
              Text('Level ${profile.level + 1}',
                  style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 10),
          Stack(
            children: [
              Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(5))),
              FractionallySizedBox(
                widthFactor: profile.levelProgress,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.accentGreen, AppColors.forestGreen]),
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [BoxShadow(
                        color: AppColors.accentGreen.withOpacity(0.4),
                        blurRadius: 6)],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${profile.stars} / ${profile.starsForNextLevel} ⭐ to next level',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badges Grid
// ─────────────────────────────────────────────────────────────────────────────
class _BadgesGrid extends StatelessWidget {
  final List<TrashBadge > badges;
  const _BadgesGrid({required this.badges});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: badges.map((b) => _BadgeTile(badge: b)).toList(),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final TrashBadge  badge;
  const _BadgeTile({required this.badge});

  @override
  Widget build(BuildContext context) {
    final color = Color(badge.rarity.colorValue);
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text('${badge.emoji} ${badge.name}',
              style: AppTextStyles.headlineMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(badge.description, style: AppTextStyles.bodyMedium),
              const SizedBox(height: 8),
              _PillChip(label: badge.rarity.label, color: color),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close')),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(badge.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(badge.name,
                style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600, color: color),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category Breakdown
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryBreakdown extends StatelessWidget {
  final Map<String, int> claimsByCategory;
  const _CategoryBreakdown({required this.claimsByCategory});

  @override
  Widget build(BuildContext context) {
    final total = claimsByCategory.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    final sorted = claimsByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: sorted.take(5).map((e) {
          final pct = e.value / total;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                    width: 100,
                    child: Text(e.key,
                        style: AppTextStyles.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 10),
                Expanded(
                  child: Stack(children: [
                    Container(height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(4))),
                    FractionallySizedBox(
                      widthFactor: pct,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen,
                          borderRadius: BorderRadius.circular(4))),
                    ),
                  ]),
                ),
                const SizedBox(width: 8),
                Text('${e.value}', style: AppTextStyles.caption
                    .copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Account Section
// ─────────────────────────────────────────────────────────────────────────────
class _AccountSection extends ConsumerWidget {
  final UserProfile profile;
  final String userId;

  const _AccountSection({required this.profile, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Account', style: AppTextStyles.headlineMedium),
        const SizedBox(height: 12),

        _SettingsTile(
          icon: Icons.email_outlined,
          label: 'Email',
          value: profile.email,
          trailing: profile.isEmailVerified
              ? const Icon(Icons.verified_rounded,
                  size: 16, color: AppColors.accentGreen)
              : null,
        ),
        _SettingsTile(
          icon: Icons.info_outline_rounded,
          label: 'App version',
          value: 'v1.0.0',
        ),
        _SettingsTile(
          icon: Icons.privacy_tip_outlined,
          label: 'Privacy Policy',
          onTap: () {},
        ),
        _SettingsTile(
          icon: Icons.help_outline_rounded,
          label: 'Help & Support',
          onTap: () {},
        ),

        const SizedBox(height: 16),

        // Sign out
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () async {
              // Show confirmation dialog
              final confirm = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: Text('Sign Out', style: AppTextStyles.headlineMedium),
                  content: Text(
                      'Are you sure you want to sign out?',
                      style: AppTextStyles.bodyMedium),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: Text('Sign Out',
                          style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              );

              // IMPORTANT: check mounted before using context after await
              if (confirm == true) {
                // Sign out first
                await ref.read(profileControllerProvider.notifier).signOut();
                // Use go_router's router directly — not context.go() which may be stale
                if (context.mounted) {
                  context.go(AppConstants.routeLogin);
                }
              }
            },
            icon: const Icon(Icons.logout_rounded, size: 18,
                color: AppColors.error),
            label: Text('Sign Out',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.error)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.error.withOpacity(0.5)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Text(label, style: AppTextStyles.bodyLarge
                .copyWith(fontWeight: FontWeight.w500)),
            const Spacer(),
            if (value != null)
              Text(value!, style: AppTextStyles.bodyMedium,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            if (trailing != null) trailing!,
            if (onTap != null) ...[
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded,
                  size: 16, color: AppColors.textHint),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit Profile Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _EditProfileSheet extends ConsumerStatefulWidget {
  final UserProfile profile;
  final String userId;

  const _EditProfileSheet({required this.profile, required this.userId});

  @override
  ConsumerState<_EditProfileSheet> createState() =>
      _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _firstCtrl;
  late final TextEditingController _lastCtrl;
  late final TextEditingController _usernameCtrl;
  String? _newPhotoPath;

  @override
  void initState() {
    super.initState();
    _firstCtrl =
        TextEditingController(text: widget.profile.firstName);
    _lastCtrl =
        TextEditingController(text: widget.profile.lastName);
    _usernameCtrl =
        TextEditingController(text: widget.profile.username);
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  // AFTER:
  Future<void> _pickPhoto() async {
    final f = await ImagePicker()
        .pickImage(source: ImageSource.gallery, maxWidth: 512, imageQuality: 80);
    if (f == null) return;
    setState(() => _newPhotoPath = f.path); // Show local preview immediately
  }

  // AFTER:
  Future<void> _save() async {
    // If user picked a new photo, upload to Cloudinary first
    String? uploadedPhotoUrl;
    if (_newPhotoPath != null) {
      uploadedPhotoUrl = await CloudinaryService.uploadAvatar(
        localFilePath: _newPhotoPath!,
        userId: widget.userId,
      );
      // If upload failed, uploadedPhotoUrl is null
      // Profile saves normally — existing photo stays unchanged
    }

    ref.read(profileControllerProvider.notifier).saveProfile(
      userId: widget.userId,
      data: ProfileEditData(
        firstName: _firstCtrl.text,
        lastName: _lastCtrl.text,
        username: _usernameCtrl.text,
        photoUrl: uploadedPhotoUrl, // null if no new photo or upload failed
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);

    ref.listen<ProfileEditState>(profileControllerProvider, (_, next) {
      if (next.isSuccess) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!')),
        );
        ref.read(profileControllerProvider.notifier).resetSuccess();
      }
    });

    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 28),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 20),
          Text('Edit Profile', style: AppTextStyles.headlineLarge),
          const SizedBox(height: 20),

          // Avatar picker
          GestureDetector(
            onTap: _pickPhoto,
            child: Stack(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    border: Border.all(
                        color: AppColors.accentGreen.withOpacity(0.5),
                        width: 2),
                  ),
                  child: widget.profile.photoUrl != null
                      ? ClipOval(child: Image.network(
                          widget.profile.photoUrl!, fit: BoxFit.cover))
                      : Center(
                          child: Text(
                            widget.profile.firstName.isNotEmpty
                                ? widget.profile.firstName[0].toUpperCase()
                                : '?',
                            style: AppTextStyles.displayMedium.copyWith(
                                color: Colors.white, fontSize: 28),
                          ),
                        ),
                ),
                Positioned(
                  right: 0, bottom: 0,
                  child: Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.surface, width: 2)),
                    child: const Icon(Icons.camera_alt_rounded,
                        size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(child: _Field(ctrl: _firstCtrl, label: 'First name')),
              const SizedBox(width: 12),
              Expanded(child: _Field(ctrl: _lastCtrl, label: 'Last name')),
            ],
          ),
          const SizedBox(height: 12),
          _Field(ctrl: _usernameCtrl, label: 'Username',
              prefix: const Icon(Icons.alternate_email_rounded, size: 18)),

          if (state.errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(state.errorMessage!,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.error)),
          ],

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: state.isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: state.isLoading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : Text('Save Changes',
                      style: AppTextStyles.labelLarge),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final Widget? prefix;

  const _Field({required this.ctrl, required this.label, this.prefix});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      style: AppTextStyles.bodyLarge,
      decoration: InputDecoration(labelText: label, prefixIcon: prefix),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────
class _LevelPill extends StatelessWidget {
  final int level;
  final String title;
  const _LevelPill({required this.level, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: AppColors.glowGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('✦ Lv.$level · $title',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600)),
    );
  }
}

class _PillChip extends StatelessWidget {
  final String label;
  final Color color;
  const _PillChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(label,
            style: TextStyle(color: color, fontSize: 11,
                fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
      );
}
