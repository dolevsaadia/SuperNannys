import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/async_value_ui.dart';

// ── Providers ──

final _usersProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, ({String? search, String? role})>((ref, params) async {
  final queryParams = <String, String>{};
  if (params.search != null && params.search!.isNotEmpty) queryParams['search'] = params.search!;
  if (params.role != null && params.role!.isNotEmpty) queryParams['role'] = params.role!;
  queryParams['limit'] = '50';
  final resp = await apiClient.dio.get('/admin/users', queryParameters: queryParams);
  return resp.data['data'] as Map<String, dynamic>;
});

final _deletedUsersProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, ({String? search})>((ref, params) async {
  final queryParams = <String, String>{'limit': '50'};
  if (params.search != null && params.search!.isNotEmpty) queryParams['search'] = params.search!;
  final resp = await apiClient.dio.get('/admin/users/deleted', queryParameters: queryParams);
  return resp.data['data'] as Map<String, dynamic>;
});

// ── Screen ──

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  String? _roleFilter;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabController.dispose();
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

  Future<void> _deleteUser(String userId, String userName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dc) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Delete User', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to delete "$userName"?\n\n'
          'This will anonymize all personal data, cancel future bookings, and deactivate the account. This action cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dc, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(dc, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await apiClient.dio.delete('/admin/users/$userId');
      ref.invalidate(_usersProvider);
      ref.invalidate(_deletedUsersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully')),
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
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Manage Users'),
        leading: BackButton(onPressed: () => context.pop()),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Active Users'),
            Tab(text: 'Deleted Users'),
          ],
        ),
      ),
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

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ActiveUsersList(
                  searchCtrl: _searchCtrl,
                  roleFilter: _roleFilter,
                  onToggleActive: _toggleActive,
                  onToggleVerified: _toggleVerified,
                  onDelete: _deleteUser,
                ),
                _DeletedUsersList(searchCtrl: _searchCtrl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// ACTIVE USERS TAB
// ══════════════════════════════════════════════════════════
class _ActiveUsersList extends ConsumerWidget {
  final TextEditingController searchCtrl;
  final String? roleFilter;
  final Future<void> Function(String, bool) onToggleActive;
  final Future<void> Function(String, bool) onToggleVerified;
  final Future<void> Function(String, String) onDelete;

  const _ActiveUsersList({
    required this.searchCtrl,
    required this.roleFilter,
    required this.onToggleActive,
    required this.onToggleVerified,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = (search: searchCtrl.text, role: roleFilter);
    final async = ref.watch(_usersProvider(params));

    return async.authAwareWhen(
      ref,
      errorTitle: 'Could not load users',
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
                      if (action == 'toggle_active') onToggleActive(u['id'] as String, isActive);
                      if (action == 'toggle_verified') onToggleVerified(u['id'] as String, isVerified);
                      if (action == 'delete') onDelete(u['id'] as String, u['fullName'] as String? ?? '');
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
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_forever_rounded, size: 18, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('Delete User', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
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
    );
  }
}

// ══════════════════════════════════════════════════════════
// DELETED USERS TAB
// ══════════════════════════════════════════════════════════
class _DeletedUsersList extends ConsumerWidget {
  final TextEditingController searchCtrl;
  const _DeletedUsersList({required this.searchCtrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = (search: searchCtrl.text);
    final async = ref.watch(_deletedUsersProvider(params));

    return async.authAwareWhen(
      ref,
      errorTitle: 'Could not load deleted users',
      data: (data) {
        final users = (data['users'] as List?) ?? [];
        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete_outline_rounded, size: 48, color: AppColors.textHint.withValues(alpha: 0.4)),
                const SizedBox(height: 12),
                const Text('No deleted users', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textHint)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(_deletedUsersProvider),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: users.length,
            itemBuilder: (_, i) {
              final u = users[i] as Map<String, dynamic>;
              final originalName = u['preDeleteName'] as String? ?? 'Unknown';
              final originalEmail = u['preDeleteEmail'] as String? ?? 'Unknown';
              final role = u['role'] as String? ?? 'PARENT';
              final deletedAt = DateTime.tryParse(u['deletedAt'] as String? ?? '');
              final deletedByAdmin = u['deletedByAdminId'] as String?;
              final counts = u['_count'] as Map<String, dynamic>? ?? {};

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.error.withValues(alpha: 0.15),
                    child: const Icon(Icons.person_off_rounded, size: 20, color: AppColors.error),
                  ),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          originalName,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          deletedByAdmin != null ? 'Admin deleted' : 'Self deleted',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.error.withValues(alpha: 0.8)),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: role == 'NANNY' ? AppColors.successLight : AppColors.accentLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(role, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(originalEmail, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (deletedAt != null)
                            Text(
                              'Deleted: ${DateFormat('dd/MM/yyyy HH:mm').format(deletedAt.toLocal())}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                            ),
                          const SizedBox(width: 8),
                          Text(
                            'Bookings: ${(counts['parentBookings'] ?? 0) + (counts['nannyBookings'] ?? 0)}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                          ),
                        ],
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
