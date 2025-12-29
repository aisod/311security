import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:security_311_admin/providers/admin/admin_provider.dart';
import 'package:security_311_admin/models/user_profile.dart';
import 'package:intl/intl.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  String _searchQuery = '';
  String? _selectedRole;
  bool? _verifiedFilter;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadAllUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adminProvider = context.watch<AdminProvider>();
    final users = _filterUsers(adminProvider.allUsers);

    return Scaffold(
      body: Column(
        children: [
          // Search and Filters
          _buildSearchAndFilters(context),
          
          // Users Stats
          _buildUsersStats(context, adminProvider.allUsers),
          
          // Users list
          Expanded(
            child: adminProvider.isLoadingUsers
                ? const Center(child: CircularProgressIndicator())
                : users.isEmpty
                    ? _buildEmptyState(theme)
                    : RefreshIndicator(
                        onRefresh: () => adminProvider.loadAllUsers(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            return _UserCard(
                              user: users[index],
                              isSuperAdmin: adminProvider.isSuperAdmin,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 12),
          
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Role filter
                _FilterChip(
                  label: _selectedRole ?? 'All Roles',
                  isSelected: _selectedRole != null,
                  onTap: () => _showRoleFilter(context),
                ),
                const SizedBox(width: 8),
                // Verified filter
                _FilterChip(
                  label: _verifiedFilter == null
                      ? 'All Status'
                      : _verifiedFilter!
                          ? 'Verified'
                          : 'Unverified',
                  isSelected: _verifiedFilter != null,
                  onTap: () => _showVerifiedFilter(context),
                ),
                const SizedBox(width: 8),
                // Clear filters
                if (_selectedRole != null || _verifiedFilter != null || _searchQuery.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _selectedRole = null;
                        _verifiedFilter = null;
                      });
                    },
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('Clear'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersStats(BuildContext context, List<Map<String, dynamic>> users) {
    final theme = Theme.of(context);
    final totalUsers = users.length;
    final verifiedUsers = users.where((u) => u['is_verified'] == true).length;
    final adminUsers = users.where((u) => u['role'] == 'admin' || u['role'] == 'super_admin').length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', totalUsers.toString(), Icons.people),
          _buildStatDivider(),
          _buildStatItem('Verified', verifiedUsers.toString(), Icons.verified_user),
          _buildStatDivider(),
          _buildStatItem('Admins', adminUsers.toString(), Icons.admin_panel_settings),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 50,
      color: Colors.white.withOpacity(0.3),
    );
  }

  List<Map<String, dynamic>> _filterUsers(List<Map<String, dynamic>> users) {
    return users.where((user) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final name = (user['full_name'] ?? '').toString().toLowerCase();
        final email = (user['email'] ?? '').toString().toLowerCase();
        final phone = (user['phone_number'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        
        if (!name.contains(query) && !email.contains(query) && !phone.contains(query)) {
          return false;
        }
      }
      
      // Role filter
      if (_selectedRole != null && user['role'] != _selectedRole) {
        return false;
      }
      
      // Verified filter
      if (_verifiedFilter != null && user['is_verified'] != _verifiedFilter) {
        return false;
      }
      
      return true;
    }).toList();
  }

  void _showRoleFilter(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Filter by Role'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              setState(() => _selectedRole = null);
              Navigator.pop(context);
            },
            child: const Text('All Roles'),
          ),
          for (final role in ['user', 'admin', 'super_admin'])
            SimpleDialogOption(
              onPressed: () {
                setState(() => _selectedRole = role);
                Navigator.pop(context);
              },
              child: Row(
                children: [
                  Icon(
                    _getRoleIcon(role),
                    size: 20,
                    color: _getRoleColor(role),
                  ),
                  const SizedBox(width: 8),
                  Text(_formatRole(role)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showVerifiedFilter(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Filter by Status'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              setState(() => _verifiedFilter = null);
              Navigator.pop(context);
            },
            child: const Text('All Status'),
          ),
          SimpleDialogOption(
            onPressed: () {
              setState(() => _verifiedFilter = true);
              Navigator.pop(context);
            },
            child: const Row(
              children: [
                Icon(Icons.verified, size: 20, color: Colors.green),
                SizedBox(width: 8),
                Text('Verified'),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              setState(() => _verifiedFilter = false);
              Navigator.pop(context);
            },
            child: const Row(
              children: [
                Icon(Icons.pending, size: 20, color: Colors.orange),
                SizedBox(width: 8),
                Text('Unverified'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No Users Found',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Users matching your criteria will appear here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'super_admin':
        return Icons.shield;
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'super_admin':
        return Colors.purple;
      case 'admin':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatRole(String role) {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'admin':
        return 'Admin';
      default:
        return 'User';
    }
  }
}

// User Card
class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isSuperAdmin;

  const _UserCard({
    required this.user,
    required this.isSuperAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = user['role'] as String? ?? 'user';
    final isVerified = user['is_verified'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _showUserDetails(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Avatar
                  if ((user['avatar_url'] != null && user['avatar_url'].toString().isNotEmpty) ||
                      (user['profile_image_url'] != null && user['profile_image_url'].toString().isNotEmpty))
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: NetworkImage(
                          (user['avatar_url'] != null && user['avatar_url'].toString().isNotEmpty)
                              ? user['avatar_url']
                              : user['profile_image_url']),
                      backgroundColor: _getRoleColor(role).withOpacity(0.1),
                    )
                  else
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: _getRoleColor(role).withOpacity(0.1),
                      child: Text(
                        _getInitials(user['full_name'] ?? user['email'] ?? 'U'),
                        style: TextStyle(
                          color: _getRoleColor(role),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                user['full_name'] ?? 'Unknown',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isVerified)
                              const Icon(
                                Icons.verified,
                                size: 18,
                                color: Colors.green,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user['email'] ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _buildRoleBadge(role),
                ],
              ),
              const SizedBox(height: 12),
              
              // Contact & Region & ID
              Row(
                children: [
                  if (user['phone_number'] != null && user['phone_number'].toString().isNotEmpty) ...[
                    Icon(
                      Icons.phone,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user['phone_number'],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (user['id_number'] != null && user['id_number'].toString().isNotEmpty) ...[
                    Icon(
                      Icons.badge,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user['id_number'],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (user['region'] != null && user['region'].toString().isNotEmpty) ...[
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user['region'],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              
              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Joined ${_formatDate(user['created_at'])}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  if (isSuperAdmin && role != 'super_admin')
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => _showChangeRoleDialog(context),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Role'),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getRoleColor(role).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getRoleColor(role).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getRoleIcon(role),
            size: 14,
            color: _getRoleColor(role),
          ),
          const SizedBox(width: 4),
          Text(
            _formatRole(role),
            style: TextStyle(
              color: _getRoleColor(role),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _UserDetailsSheet(user: user, isSuperAdmin: isSuperAdmin),
    );
  }

  void _showChangeRoleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ChangeRoleDialog(user: user),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'super_admin':
        return Icons.shield;
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'super_admin':
        return Colors.purple;
      case 'admin':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatRole(String role) {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'admin':
        return 'Admin';
      default:
        return 'User';
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    try {
      final dateTime = DateTime.parse(date.toString());
      return DateFormat('MMM d, yyyy').format(dateTime);
    } catch (e) {
      return 'Unknown';
    }
  }
}

// User Details Sheet
class _UserDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> user;
  final bool isSuperAdmin;

  const _UserDetailsSheet({
    required this.user,
    required this.isSuperAdmin,
  });

  @override
  State<_UserDetailsSheet> createState() => _UserDetailsSheetState();
}

class _UserDetailsSheetState extends State<_UserDetailsSheet> {
  List<Map<String, dynamic>> _emergencyContacts = [];
  bool _isLoadingContacts = false;

  @override
  void initState() {
    super.initState();
    _loadEmergencyContacts();
  }

  Future<void> _loadEmergencyContacts() async {
    setState(() => _isLoadingContacts = true);
    try {
      final contacts = await context
          .read<AdminProvider>()
          .getUserEmergencyContacts(widget.user['id']);
      if (mounted) {
        setState(() => _emergencyContacts = contacts);
      }
    } catch (e) {
      // Handle error silently or log it
    } finally {
      if (mounted) {
        setState(() => _isLoadingContacts = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = widget.user['role'] as String? ?? 'user';
    final isVerified = widget.user['is_verified'] == true;

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Avatar & Name
              Center(
                child: Column(
                  children: [
                    if ((widget.user['avatar_url'] != null &&
                            widget.user['avatar_url'].toString().isNotEmpty) ||
                        (widget.user['profile_image_url'] != null &&
                            widget.user['profile_image_url'].toString().isNotEmpty))
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(
                            (widget.user['avatar_url'] != null &&
                                    widget.user['avatar_url'].toString().isNotEmpty)
                                ? widget.user['avatar_url']
                                : widget.user['profile_image_url']),
                        backgroundColor: _getRoleColor(role).withOpacity(0.1),
                      )
                    else
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: _getRoleColor(role).withOpacity(0.1),
                        child: Text(
                          _getInitials(
                              widget.user['full_name'] ?? widget.user['email'] ?? 'U'),
                          style: TextStyle(
                            color: _getRoleColor(role),
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.user['full_name'] ?? 'Unknown',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.verified,
                              color: Colors.green, size: 24),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildRoleBadge(role),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // User Info
              _buildSection(context, 'Email', Icons.email,
                  widget.user['email'] ?? 'Not provided'),
              const SizedBox(height: 16),
              _buildSection(context, 'Phone', Icons.phone,
                  widget.user['phone_number'] ?? 'Not provided'),
              const SizedBox(height: 16),
              _buildSection(context, 'Region', Icons.location_on,
                  widget.user['region'] ?? 'Not provided'),

              if (widget.user['id_type'] != null ||
                  widget.user['id_number'] != null) ...[
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  'ID Information',
                  Icons.badge,
                  '${widget.user['id_type'] ?? 'Unknown Type'}: ${widget.user['id_number'] ?? 'Not provided'}',
                ),
              ],

              const SizedBox(height: 16),
              _buildSection(
                context,
                'Account Created',
                Icons.calendar_today,
                _formatDate(widget.user['created_at']),
              ),

              // Emergency Contacts
              const SizedBox(height: 24),
              Text(
                'Emergency Contacts',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (_isLoadingContacts)
                const Center(child: CircularProgressIndicator())
              else if (_emergencyContacts.isEmpty)
                Text(
                  'No emergency contacts found',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                ..._emergencyContacts.map((contact) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              theme.colorScheme.primary.withOpacity(0.1),
                          child: Icon(Icons.contact_phone,
                              color: theme.colorScheme.primary),
                        ),
                        title: Text(contact['name'] ?? 'Unknown'),
                        subtitle: Text(
                            '${contact['relationship'] ?? 'Contact'} • ${contact['phone_number'] ?? ''}'),
                      ),
                    )),

              // Actions
              if (widget.isSuperAdmin && role != 'super_admin') ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          showDialog(
                            context: context,
                            builder: (context) =>
                                _ChangeRoleDialog(user: widget.user),
                          );
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Change Role'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmDeleteUser(context),
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete User'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(
      BuildContext context, String title, IconData icon, String content) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            content,
            style: theme.textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleBadge(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getRoleColor(role).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getRoleIcon(role),
            size: 18,
            color: _getRoleColor(role),
          ),
          const SizedBox(width: 8),
          Text(
            _formatRole(role),
            style: TextStyle(
              color: _getRoleColor(role),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUser(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
            'Are you sure you want to delete ${widget.user['full_name']}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              Navigator.pop(context);

              final adminProvider = context.read<AdminProvider>();
              final success = await adminProvider.deleteUser(widget.user['id']);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'User deleted successfully'
                        : 'Failed to delete user'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'super_admin':
        return Icons.shield;
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'super_admin':
        return Colors.purple;
      case 'admin':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatRole(String role) {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'admin':
        return 'Admin';
      default:
        return 'User';
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    try {
      final dateTime = DateTime.parse(date.toString());
      return DateFormat('EEEE, MMMM d, yyyy').format(dateTime);
    } catch (e) {
      return 'Unknown';
    }
  }
}

// Change Role Dialog
class _ChangeRoleDialog extends StatefulWidget {
  final Map<String, dynamic> user;

  const _ChangeRoleDialog({required this.user});

  @override
  State<_ChangeRoleDialog> createState() => _ChangeRoleDialogState();
}

class _ChangeRoleDialogState extends State<_ChangeRoleDialog> {
  late String _selectedRole;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.user['role'] ?? 'user';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change User Role'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User: ${widget.user['full_name'] ?? widget.user['email']}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 16),
          const Text('Select new role:'),
          const SizedBox(height: 8),
          ...['user', 'admin'].map((role) => RadioListTile<String>(
                title: Row(
                  children: [
                    Icon(_getRoleIcon(role), color: _getRoleColor(role), size: 20),
                    const SizedBox(width: 8),
                    Text(_formatRole(role)),
                  ],
                ),
                value: role,
                groupValue: _selectedRole,
                onChanged: (value) => setState(() => _selectedRole = value!),
                contentPadding: EdgeInsets.zero,
              )),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading || _selectedRole == widget.user['role']
              ? null
              : _changeRole,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _changeRole() async {
    setState(() => _isLoading = true);

    try {
      final adminProvider = context.read<AdminProvider>();
      final newRole = _selectedRole == 'admin' ? UserRole.admin : UserRole.user;
      
      final success = await adminProvider.updateUserRole(
        widget.user['id'],
        newRole,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Role updated successfully' : 'Failed to update role'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'super_admin':
        return Icons.shield;
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'super_admin':
        return Colors.purple;
      case 'admin':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatRole(String role) {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'admin':
        return 'Admin';
      default:
        return 'User';
    }
  }
}

// Filter Chip Widget
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.1)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 20,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}


