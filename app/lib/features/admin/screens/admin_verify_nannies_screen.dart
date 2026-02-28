import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_indicator.dart';

final _pendingNanniesProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final resp = await apiClient.dio.get('/admin/nannies/pending-verification');
  return resp.data['data'] as Map<String, dynamic>;
});

class AdminVerifyNanniesScreen extends ConsumerWidget {
  const AdminVerifyNanniesScreen({super.key});

  Future<void> _verifyNanny(BuildContext context, WidgetRef ref, String userId) async {
    try {
      await apiClient.dio.patch('/admin/users/$userId', data: {'isVerified': true});
      ref.invalidate(_pendingNanniesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nanny verified successfully!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _rejectNanny(BuildContext context, WidgetRef ref, String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate Nanny?'),
        content: const Text('This will deactivate the nanny account. They can be re-activated later.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await apiClient.dio.patch('/admin/users/$userId', data: {'isActive': false});
      ref.invalidate(_pendingNanniesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nanny deactivated'), backgroundColor: AppColors.warning),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_pendingNanniesProvider);
    final df = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Verify Nannies'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(_pendingNanniesProvider),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          final nannies = (data['nannies'] as List?) ?? [];

          if (nannies.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_rounded, size: 64, color: AppColors.success.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  const Text('All nannies are verified!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  const Text('No pending verifications', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_pendingNanniesProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: nannies.length,
              itemBuilder: (_, i) {
                final n = nannies[i] as Map<String, dynamic>;
                final profile = n['nannyProfile'] as Map<String, dynamic>?;
                final joined = DateTime.tryParse(n['createdAt'] as String? ?? '') ?? DateTime.now();

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.primaryLight,
                              backgroundImage: n['avatarUrl'] != null ? NetworkImage(n['avatarUrl'] as String) : null,
                              child: n['avatarUrl'] == null
                                  ? Text(
                                      (n['fullName'] as String? ?? '?')[0].toUpperCase(),
                                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    n['fullName'] as String? ?? '',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(n['email'] as String? ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.warningLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('PENDING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.warning)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (profile != null) ...[
                          // Profile details
                          if (profile['headline'] != null)
                            Text(profile['headline'] as String, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
                          const SizedBox(height: 8),

                          // Info chips
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              if (profile['city'] != null)
                                _InfoChip(Icons.location_on_rounded, profile['city'] as String),
                              if (profile['hourlyRateNis'] != null)
                                _InfoChip(Icons.payments_rounded, '₪${profile['hourlyRateNis']}/hr'),
                              if (profile['yearsExperience'] != null && (profile['yearsExperience'] as num) > 0)
                                _InfoChip(Icons.work_rounded, '${profile['yearsExperience']} yrs exp'),
                              _InfoChip(Icons.star_rounded, '${profile['rating'] ?? 0} (${profile['reviewsCount'] ?? 0})'),
                              _InfoChip(Icons.check_circle_rounded, '${profile['completedJobs'] ?? 0} jobs'),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Languages & skills
                          if (profile['languages'] is List && (profile['languages'] as List).isNotEmpty) ...[
                            Text('Languages: ${(profile['languages'] as List).join(', ')}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                          ],
                          if (profile['skills'] is List && (profile['skills'] as List).isNotEmpty) ...[
                            Text('Skills: ${(profile['skills'] as List).join(', ')}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                          ],
                        ],

                        const SizedBox(height: 4),
                        Text('Joined: ${df.format(joined.toLocal())}', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                        const SizedBox(height: 12),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _rejectNanny(context, ref, n['id'] as String),
                                icon: const Icon(Icons.close_rounded, size: 18),
                                label: const Text('Reject'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: const BorderSide(color: AppColors.error),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _verifyNanny(context, ref, n['id'] as String),
                                icon: const Icon(Icons.verified_rounded, size: 18),
                                label: const Text('Verify'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      );
}
