import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_indicator.dart';

final _usersProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, ({String? search, String? role})>((ref, params) async {
  final queryParams = <String, String>{};
  if (params.search != null && params.search!.isNotEmpty) queryParams['search'] = params.search!;
  if (params.role != null && params.role!.isNotEmpty) queryParams['role'] = params.role!;
  queryParams['limit'] = '50';
  final resp = await apiClient.dio.get('/admin/users', queryParameters: queryParams);
  return resp.data['data'] as Map<String, dynamic>;
});

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _searchCtrl = TextEditingController();
  String? _roleFilter;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleActive(String userId, bool currentActive) async {
    try {
      await apiClient.dio.patch('/admin/users/$userId', data: {'isActive': !currentActive});
      ref.invalidate(_usersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(currentActive ? 'User deactivated' : 'User activated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _toggleVerified(String userId, bool currentVerified) async {
    try {
      await apiClient.dio.patch('/admin/users/$userId', data: {'isVerified': !currentVerified});
      ref.invalidate(_usersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(currentVerified ? 'Verification removed' : 'User verified')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final params = (search: _searchCtrl.text, role: _roleFilter);
    final async = ref.watch(_usersProvider(params));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Manage Users')),
      body: Column(
        children: [
          // Search + filter row
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search by name or email...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    ),
                    onSubmitted: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String?>(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.filter_list_rounded, color: _roleFilter != null ? AppColors.primary : AppColors.textSecondary),
                  ),
                  onSelected: (v) => setState(() => _roleFilter = v),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: null, child: Text('All Roles')),
                    const PopupMenuItem(value: 'PARENT', child: Text('Parents')),
                    const PopupMenuItem(value: 'NANNY', child: Text('Nannies')),
                    const PopupMenuItem(value: 'ADMIN', child: Text('Admins')),
                  ],
                ),
              ],
            ),
          ),

          // User list
          Expanded(
            child: async.when(
              loading: () => const Center(child: LoadingIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (data) {
                final users = (data['users'] as List?) ?? [];
                if (users.isEmpty) {
                  return const Center(child: Text('No users found'));
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(_usersProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: users.length,
                    itemBuilder: (_, i) {
                      final u = users[i] as Map<String, dynamic>;
                      final isActive = u['isActive'] as bool? ?? true;
                      final isVerified = u['isVerified'] as bool? ?? false;
                      final role = u['role'] as String? ?? 'PARENT';
                      final counts = u['_count'] as Map<String, dynamic>? ?? {};

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isActive ? AppColors.divider : AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: role == 'ADMIN'
                                ? AppColors.primary
                                : role == 'NANNY'
                                    ? AppColors.success
                                    : AppColors.accent,
                            child: Text(
                              (u['fullName'] as String? ?? '?')[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  u['fullName'] as String? ?? '',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    decoration: isActive ? null : TextDecoration.lineThrough,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (isVerified) const Icon(Icons.verified, color: AppColors.success, size: 16),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: role == 'ADMIN' ? AppColors.primaryLight : role == 'NANNY' ? AppColors.successLight : AppColors.accentLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(role, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(u['email'] as String? ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              const SizedBox(height: 2),
                              Text(
                                'Bookings: ${counts['parentBookings'] ?? 0} as parent, ${counts['nannyBookings'] ?? 0} as nanny',
                                style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            iconSize: 20,
                            onSelected: (action) {
                              if (action == 'toggle_active') _toggleActive(u['id'] as String, isActive);
                              if (action == 'toggle_verified') _toggleVerified(u['id'] as String, isVerified);
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'toggle_active',
                                child: Row(
                                  children: [
                                    Icon(isActive ? Icons.block : Icons.check_circle, size: 18, color: isActive ? AppColors.error : AppColors.success),
                                    const SizedBox(width: 8),
                                    Text(isActive ? 'Deactivate' : 'Activate'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'toggle_verified',
                                child: Row(
                                  children: [
                                    Icon(isVerified ? Icons.remove_circle : Icons.verified, size: 18, color: isVerified ? AppColors.warning : AppColors.success),
                                    const SizedBox(width: 8),
                                    Text(isVerified ? 'Remove Verification' : 'Verify'),
                                  ],
                                ),
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
          ),
        ],
      ),
    );
  }
}
