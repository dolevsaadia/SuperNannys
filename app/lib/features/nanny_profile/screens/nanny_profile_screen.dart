import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/models/nanny_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
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
    return CustomScrollView(
      slivers: [
        // Hero image / app bar
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: AppColors.primary,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                profile.user?.avatarUrl != null
                    ? CachedNetworkImage(imageUrl: profile.user!.avatarUrl!, fit: BoxFit.cover)
                    : Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                            begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          ),
                        ),
                        child: const Center(child: Icon(Icons.person, size: 100, color: Colors.white30)),
                      ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // Name + rating overlay
                Positioned(
                  bottom: 16, left: 16, right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.user?.fullName ?? '',
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Row(children: [
                        RatingDisplay(rating: profile.rating, count: profile.reviewsCount),
                        const SizedBox(width: 12),
                        const Icon(Icons.location_on_rounded, size: 14, color: Colors.white70),
                        Text(profile.city, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined, color: Colors.white),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.favorite_border_rounded, color: Colors.white),
              onPressed: () {},
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats row
                Row(
                  children: [
                    _StatBox(value: '₪${profile.hourlyRateNis}', label: 'per hour'),
                    const SizedBox(width: 12),
                    _StatBox(value: '${profile.yearsExperience}', label: 'years exp'),
                    const SizedBox(width: 12),
                    _StatBox(value: '${profile.completedJobs}', label: 'jobs done'),
                  ],
                ),
                const SizedBox(height: 20),

                // Headline
                if (profile.headline.isNotEmpty) ...[
                  Text(profile.headline, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                ],

                // Bio
                if (profile.bio.isNotEmpty) ...[
                  const Text('About', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(profile.bio, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6)),
                  const SizedBox(height: 20),
                ],

                // Badges
                if (profile.badges.isNotEmpty) ...[
                  const Text('Certifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: profile.badges.map((b) => BadgeChip(badge: b)).toList()),
                  const SizedBox(height: 20),
                ],

                // Languages
                if (profile.languages.isNotEmpty) ...[
                  const Text('Languages', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: profile.languages.map((l) => Chip(
                      label: Text(l),
                      avatar: const Icon(Icons.language_rounded, size: 14),
                    )).toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // Skills
                if (profile.skills.isNotEmpty) ...[
                  const Text('Skills', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: profile.skills.map((s) => Chip(
                      label: Text(s, style: const TextStyle(fontSize: 12)),
                      backgroundColor: AppColors.bg,
                    )).toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // Availability
                if (profile.availability.isNotEmpty) ...[
                  const Text('Availability', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  _AvailabilityGrid(slots: profile.availability),
                  const SizedBox(height: 20),
                ],

                // Reviews
                if (reviews.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Reviews (${profile.reviewsCount})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      RatingDisplay(rating: profile.rating, count: profile.reviewsCount),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...reviews.take(5).map((r) => _ReviewCard(review: r as Map<String, dynamic>)),
                  const SizedBox(height: 20),
                ],

                // Book CTA
                AppButton(
                  label: 'Book ${profile.user?.fullName.split(' ').first ?? 'Now'}',
                  prefixIcon: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 20),
                  onTap: profile.isAvailable ? () => context.go('/home/nanny/$nannyId/book') : null,
                ),
                if (!profile.isAvailable)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Center(
                      child: Text('Currently unavailable', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
                    ),
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
}

class _AvailabilityGrid extends StatelessWidget {
  final List<AvailabilitySlot> slots;
  const _AvailabilityGrid({required this.slots});

  @override
  Widget build(BuildContext context) => Row(
        children: slots.map((slot) => Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: slot.isAvailable ? AppColors.successLight : AppColors.bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  slot.dayName,
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: slot.isAvailable ? AppColors.success : AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  slot.isAvailable ? Icons.check_rounded : Icons.close_rounded,
                  size: 14,
                  color: slot.isAvailable ? AppColors.success : AppColors.textHint,
                ),
              ],
            ),
          ),
        )).toList(),
      );
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final reviewer = review['reviewer'] as Map<String, dynamic>?;
    final rating = review['rating'] as int? ?? 5;
    final comment = review['comment'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  (reviewer?['fullName'] as String? ?? '?')[0].toUpperCase(),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(reviewer?['fullName'] as String? ?? 'Anonymous', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
              Row(children: List.generate(5, (i) => Icon(Icons.star_rounded, size: 14, color: i < rating ? AppColors.star : AppColors.divider))),
            ],
          ),
          if (comment != null && comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(comment, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
          ],
        ],
      ),
    );
  }
}
