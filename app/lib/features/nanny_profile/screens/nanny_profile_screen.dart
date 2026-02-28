import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/models/nanny_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/widgets/badge_chip.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/rating_bar_widget.dart';
import '../../../core/widgets/app_button.dart';

final _nannyDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) async {
  final resp = await apiClient.dio.get('/nannies/$id');
  return resp.data['data'] as Map<String, dynamic>;
});

class NannyProfileScreen extends ConsumerWidget {
  final String nannyId;
  const NannyProfileScreen({super.key, required this.nannyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_nannyDetailProvider(nannyId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: async.when(
        loading: () => const FullScreenLoader(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          final profile = NannyModel.fromJson(data['profile'] as Map<String, dynamic>);
          final reviews = data['reviews'] as List<dynamic>? ?? [];
          return _ProfileBody(profile: profile, reviews: reviews, nannyId: nannyId);
        },
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final NannyModel profile;
  final List<dynamic> reviews;
  final String nannyId;

  const _ProfileBody({required this.profile, required this.reviews, required this.nannyId});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // ── Parallax Hero ──────────────────────
            SliverAppBar(
              expandedHeight: 320,
              pinned: true,
              backgroundColor: AppColors.primary,
              leading: _CircleBackButton(),
              actions: [
                _HeroActionButton(Icons.share_outlined, () {}),
                _HeroActionButton(Icons.favorite_border_rounded, () {}),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    profile.user?.avatarUrl != null
                        ? CachedNetworkImage(
                            imageUrl: profile.user!.avatarUrl!,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: AppColors.gradientPrimary,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                (profile.user?.fullName ?? '?')[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 80,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                            ),
                          ),
                    // Premium gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.2),
                            Colors.black.withValues(alpha: 0.7),
                          ],
                          stops: const [0.3, 0.6, 1.0],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    // Name + rating overlay
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  profile.user?.fullName ?? '',
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
                                ),
                              ),
                              if (profile.isVerified) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                                  child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              RatingDisplay(rating: profile.rating, count: profile.reviewsCount),
                              const SizedBox(width: 12),
                              const Icon(Icons.location_on_rounded, size: 14, color: Colors.white70),
                              const SizedBox(width: 2),
                              Text(profile.city, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Floating Stats Card ──────────────────
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppShadows.lg,
                    ),
                    child: Row(
                      children: [
                        _FloatingStatItem(
                          value: '\u20AA${profile.hourlyRateNis}',
                          label: 'per hour',
                          icon: Icons.attach_money_rounded,
                          color: AppColors.success,
                        ),
                        _statDivider(),
                        _FloatingStatItem(
                          value: '${profile.yearsExperience}',
                          label: 'years exp',
                          icon: Icons.workspace_premium_rounded,
                          color: AppColors.primary,
                        ),
                        _statDivider(),
                        _FloatingStatItem(
                          value: '${profile.completedJobs}',
                          label: 'jobs done',
                          icon: Icons.work_outline_rounded,
                          color: AppColors.accent,
                        ),
                        _statDivider(),
                        _FloatingStatItem(
                          value: '${profile.rating}',
                          label: 'rating',
                          icon: Icons.star_rounded,
                          color: AppColors.star,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Content ──────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Headline
                    if (profile.headline.isNotEmpty) ...[
                      Text(
                        profile.headline,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // About section
                    if (profile.bio.isNotEmpty) ...[
                      _SectionTitle('About'),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppShadows.sm,
                        ),
                        child: Text(
                          profile.bio,
                          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.7),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Badges / Certifications
                    if (profile.badges.isNotEmpty) ...[
                      _SectionTitle('Certifications'),
                      const SizedBox(height: 10),
                      Wrap(spacing: 8, runSpacing: 8, children: profile.badges.map((b) => BadgeChip(badge: b)).toList()),
                      const SizedBox(height: 24),
                    ],

                    // Skills as colorful pills
                    if (profile.skills.isNotEmpty) ...[
                      _SectionTitle('Skills'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: profile.skills.asMap().entries.map((e) {
                          final colors = [
                            AppColors.primary,
                            AppColors.accent,
                            AppColors.success,
                            AppColors.warning,
                            const Color(0xFFEC4899),
                            const Color(0xFF8B5CF6),
                          ];
                          final c = colors[e.key % colors.length];
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: c.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: c.withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              e.value,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Languages
                    if (profile.languages.isNotEmpty) ...[
                      _SectionTitle('Languages'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: profile.languages.map((l) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: AppShadows.sm,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.language_rounded, size: 16, color: AppColors.accent),
                              const SizedBox(width: 6),
                              Text(l, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            ],
                          ),
                        )).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Availability grid
                    if (profile.availability.isNotEmpty) ...[
                      _SectionTitle('Availability'),
                      const SizedBox(height: 12),
                      _AvailabilityGrid(slots: profile.availability),
                      const SizedBox(height: 24),
                    ],

                    // Reviews
                    if (reviews.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _SectionTitle('Reviews (${profile.reviewsCount})'),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.star.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, size: 16, color: AppColors.star),
                                const SizedBox(width: 4),
                                Text(
                                  '${profile.rating}',
                                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.star, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...reviews.take(5).map((r) => _ReviewCard(review: r as Map<String, dynamic>)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),

        // ── Sticky Book Now Bar ──────────────────
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: AppShadows.top,
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '\u20AA${profile.hourlyRateNis}/hr',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    if (!profile.isAvailable)
                      const Text('Currently unavailable', style: TextStyle(fontSize: 12, color: AppColors.error)),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppButton(
                    label: 'Book Now',
                    variant: AppButtonVariant.gradient,
                    prefixIcon: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 20),
                    onTap: profile.isAvailable ? () => context.go('/home/nanny/$nannyId/book') : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statDivider() => Container(
        width: 1,
        height: 36,
        color: AppColors.divider,
      );
}

// ── Section title widget ──────────────────
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      );
}

// ── Hero action button ──────────────────
class _HeroActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeroActionButton(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 4),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      );
}

// ── Circle back button ──────────────────
class _CircleBackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 8),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
          ),
        ),
      );
}

// ── Floating stat item ──────────────────
class _FloatingStatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _FloatingStatItem({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
          ],
        ),
      );
}

// ── Availability grid ──────────────────
class _AvailabilityGrid extends StatelessWidget {
  final List<AvailabilitySlot> slots;
  const _AvailabilityGrid({required this.slots});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: slots.map((slot) => Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: slot.isAvailable ? AppColors.success.withValues(alpha: 0.1) : AppColors.bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    slot.dayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: slot.isAvailable ? AppColors.success : AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: slot.isAvailable ? AppColors.success : Colors.transparent,
                      shape: BoxShape.circle,
                      border: slot.isAvailable ? null : Border.all(color: AppColors.divider, width: 1.5),
                    ),
                    child: Icon(
                      slot.isAvailable ? Icons.check_rounded : Icons.close_rounded,
                      size: 14,
                      color: slot.isAvailable ? Colors.white : AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          )).toList(),
        ),
      );
}

// ── Review card ──────────────────
class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final reviewer = review['reviewer'] as Map<String, dynamic>?;
    final rating = review['rating'] as int? ?? 5;
    final comment = review['comment'] as String?;
    final initial = (reviewer?['fullName'] as String? ?? '?')[0].toUpperCase();

    final gradientColors = [
      [const Color(0xFF7C3AED), const Color(0xFF9D5CF8)],
      [const Color(0xFF06B6D4), const Color(0xFF0EA5E9)],
      [const Color(0xFF10B981), const Color(0xFF059669)],
      [const Color(0xFFF59E0B), const Color(0xFFEF4444)],
      [const Color(0xFFEC4899), const Color(0xFF8B5CF6)],
    ];
    final grad = gradientColors[initial.codeUnitAt(0) % gradientColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: grad),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  reviewer?['fullName'] as String? ?? 'Anonymous',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              ...List.generate(5, (i) => Padding(
                padding: const EdgeInsets.only(left: 1),
                child: Icon(
                  Icons.star_rounded,
                  size: 16,
                  color: i < rating ? AppColors.star : AppColors.divider,
                ),
              )),
            ],
          ),
          if (comment != null && comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(comment, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.6)),
          ],
        ],
      ),
    );
  }
}
