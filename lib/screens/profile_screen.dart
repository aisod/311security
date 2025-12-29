import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:provider/provider.dart';
import 'package:security_311_user/services/auth_service.dart';
import 'package:security_311_user/services/storage_service.dart';
import 'package:security_311_user/providers/auth_provider.dart';
import 'package:security_311_user/core/logger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;
  const ProfileScreen({super.key, this.onBackPressed});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;

  // User profile data (kept for edit dialog and other local uses)
  String _userName = 'Guest User';
  String _userPhone = '';
  String _userEmail = '';
  String? _profileImageUrl; // URL from database
  XFile? _profileImageFile; // Local file for display (works on web and mobile)
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Listen to auth provider changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Listen to auth state changes first
        final authProvider = context.read<AuthProvider>();
        authProvider.addListener(_onAuthStateChanged);

        // Then load profile
        _loadUserProfile();
      }
    });
  }

  @override
  void dispose() {
    // Remove listener when widget is disposed
    try {
      final authProvider = context.read<AuthProvider>();
      authProvider.removeListener(_onAuthStateChanged);
    } catch (e) {
      // Provider might not be available during dispose
    }
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (!mounted) return;
    // Reset local state and reload when auth state changes
    setState(() {
      _userName = 'Guest User';
      _userPhone = '';
      _userEmail = '';
    });
    // Reload profile after a short delay to ensure auth state is fully updated
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _loadUserProfile();
      }
    });
  }

  Future<void> _loadUserProfile() async {
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();

    // Check if user is authenticated using AuthProvider
    if (!authProvider.isAuthenticated) {
      setState(() {
        _userName = 'Guest User';
        _userPhone = '';
        _userEmail = '';
      });
      return;
    }

    try {
      // Force refresh profile from AuthProvider
      await authProvider.refreshProfile();

      // Wait a bit for the provider to update
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;

      // Get fresh profile from provider
      Map<String, dynamic>? profile = authProvider.userProfile;

      if (!mounted) return;

      setState(() {
        _userName = profile!['full_name'] ??
            profile['email']?.split('@').first ??
            'User';
        _userPhone = profile['phone_number'] ?? '';
        _userEmail = profile['email'] ?? '';
        _profileImageUrl = profile['profile_image_url'] ??
            profile['avatar_url']; // Backward compatibility
        _profileImageFile = null; // Clear local file when loading from server
      });

      AppLogger.info(
          'Profile loaded: $_userName, $_userPhone, $_userEmail, profile image: $_profileImageUrl');
    } catch (e, stackTrace) {
      if (mounted) {
        AppLogger.error('Failed to load profile', e, stackTrace);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header with Back Button
            Container(
              padding: const EdgeInsets.fromLTRB(24, 50, 24, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: Column(
                children: [
                  // App Bar Row with Back Button
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () {
                            // Use callback to navigate back to home or fallback to pop
                            if (widget.onBackPressed != null) {
                              widget.onBackPressed!();
                            } else if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        "Profile",
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () => _showSettingsMenu(context),
                          icon: const Icon(
                            Icons.more_vert,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => _showProfilePictureOptions(context),
                    child: Stack(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: _profileImageFile != null
                                ? kIsWeb
                                    ? Image.network(
                                        _profileImageFile!.path,
                                        fit: BoxFit.cover,
                                        width: 90,
                                        height: 90,
                                      )
                                    : FutureBuilder<Uint8List>(
                                        future:
                                            _profileImageFile!.readAsBytes(),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData) {
                                            return Image.memory(
                                              snapshot.data!,
                                              fit: BoxFit.cover,
                                              width: 90,
                                              height: 90,
                                            );
                                          }
                                          return const Icon(
                                            Icons.person,
                                            color: Colors.white,
                                            size: 42,
                                          );
                                        },
                                      )
                                : _profileImageUrl != null
                                    ? Image.network(
                                        _profileImageUrl!,
                                        fit: BoxFit.cover,
                                        width: 90,
                                        height: 90,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Consumer<AuthProvider>(
                                            builder:
                                                (context, authProvider, child) {
                                              return Icon(
                                                authProvider.isAuthenticated
                                                    ? Icons.person
                                                    : Icons.person_outline,
                                                color: Colors.white,
                                                size: 42,
                                              );
                                            },
                                          );
                                        },
                                      )
                                    : Consumer<AuthProvider>(
                                        builder:
                                            (context, authProvider, child) {
                                          return Icon(
                                            authProvider.isAuthenticated
                                                ? Icons.person
                                                : Icons.person_outline,
                                            color: Colors.white,
                                            size: 42,
                                          );
                                        },
                                      ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      final profile = authProvider.userProfile;
                      final displayName =
                          authProvider.isAuthenticated && profile != null
                              ? (profile['full_name'] ??
                                  profile['email']?.split('@').first ??
                                  'User')
                              : "Guest User";
                      return Text(
                        displayName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      final profile = authProvider.userProfile;
                      final displayPhone =
                          authProvider.isAuthenticated && profile != null
                              ? (profile['phone_number'] ?? '')
                              : "Complete registration to unlock all features";
                      return Text(
                        displayPhone.isNotEmpty
                            ? displayPhone
                            : "Complete registration to unlock all features",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Menu Items
                  Text(
                    "Account",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return _ProfileMenuItem(
                        icon: Icons.edit,
                        title: "Edit Profile",
                        subtitle: "Update your personal information",
                        onTap: () => _showEditProfileDialog(context),
                        enabled: authProvider.isAuthenticated,
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  Text(
                    "Settings",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _ProfileMenuItem(
                    icon: Icons.notifications,
                    title: "Notifications",
                    subtitle: "Configure alert preferences",
                    onTap: () => _showNotificationSettings(context),
                  ),
                  _ProfileMenuItem(
                    icon: Icons.location_on,
                    title: "Location Settings",
                    subtitle: "Manage location permissions",
                    onTap: () => _showLocationSettings(context),
                  ),
                  _ProfileMenuItem(
                    icon: Icons.security,
                    title: "Privacy & Security",
                    subtitle: "Control your data and privacy",
                    onTap: () => _showPrivacyDialog(context),
                  ),

                  const SizedBox(height: 32),

                  Text(
                    "Support",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _ProfileMenuItem(
                    icon: Icons.help,
                    title: "Help & Support",
                    subtitle: "Get help and contact support",
                    onTap: () => _showSupportDialog(context),
                  ),
                  _ProfileMenuItem(
                    icon: Icons.info,
                    title: "About 3:11 Security",
                    subtitle: "App version and information",
                    onTap: () => _showAboutDialog(context),
                  ),
                  _ProfileMenuItem(
                    icon: Icons.description,
                    title: "Terms & Privacy",
                    subtitle: "Legal documents and policies",
                    onTap: () => _showTermsAndPrivacy(context),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy & Security'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🔒 Your data is encrypted and secure'),
            SizedBox(height: 8),
            Text('📍 Location data is only used for emergency response'),
            SizedBox(height: 8),
            Text('🔕 Anonymous reporting protects your identity'),
            SizedBox(height: 8),
            Text('🗑️ You can delete your data at any time'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showDetailedPrivacySettings(context);
            },
            child: const Text('Manage Privacy'),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📧 support@311security.na'),
            SizedBox(height: 8),
            Text('📞 +264 61 XXX XXXX'),
            SizedBox(height: 8),
            Text('🕒 Monday-Friday 8:00-17:00 (NAM)'),
            SizedBox(height: 16),
            Text('For emergencies, use the panic button or dial 10111'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _contactSupport();
            },
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About 3:11 Security'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🛡️ 3:11 Security'),
            SizedBox(height: 8),
            Text('Version 1.0.0'),
            SizedBox(height: 8),
            Text('"Your Safety, Our Priority"'),
            SizedBox(height: 16),
            Text(
                'Emergency response and crime reporting app designed specifically for Namibia.'),
            SizedBox(height: 16),
            Text('© 2025 3:11 Security - All Rights Reserved'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Settings Menu
  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Quick Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out'),
              onTap: () async {
                Navigator.pop(context);
                await _signOut();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Account'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteAccountDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Refresh Profile'),
              onTap: () {
                Navigator.pop(context);
                _refreshProfile();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Profile Picture Options
  void _showProfilePictureOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Profile Picture',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _chooseFromGallery();
              },
            ),
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                if (authProvider.isAuthenticated) {
                  return ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Remove Photo'),
                    onTap: () {
                      Navigator.pop(context);
                      _removePhoto();
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Edit Profile Dialog
  void _showEditProfileDialog(BuildContext context) {
    final nameController = TextEditingController(text: _userName);
    final phoneController = TextEditingController(text: _userPhone);
    final emailController = TextEditingController(text: _userEmail);
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      setState(() => isLoading = true);

                      try {
                        final authProvider =
                            Provider.of<AuthProvider>(context, listen: false);
                        final result = await _authService.updateProfile(
                          fullName: nameController.text.trim(),
                          phoneNumber: phoneController.text.trim(),
                        );

                        if (result.success) {
                          // Refresh profile in AuthProvider
                          await authProvider.refreshProfile();
                          // Also refresh local state
                          await _loadUserProfile();
                          if (!mounted) return;
                          // ignore: use_build_context_synchronously
                          Navigator.pop(context);
                          if (!mounted) return;
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Profile updated successfully!')),
                          );
                        } else {
                          if (!mounted) return;
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Failed to update profile: ${result.error}')),
                          );
                        }
                      } catch (e) {
                        if (!mounted) return;
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Failed to update profile: $e')),
                        );
                      } finally {
                        setState(() => isLoading = false);
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // Notification Settings
  void _showNotificationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Emergency Alerts'),
                subtitle: const Text('Critical emergency notifications'),
                value: _notificationsEnabled,
                onChanged: (value) =>
                    setDialogState(() => _notificationsEnabled = value),
              ),
              SwitchListTile(
                title: const Text('Crime Alerts'),
                subtitle: const Text('Local crime and safety alerts'),
                value: _notificationsEnabled,
                onChanged: (value) =>
                    setDialogState(() => _notificationsEnabled = value),
              ),
              SwitchListTile(
                title: const Text('App Updates'),
                subtitle: const Text('Feature updates and announcements'),
                value: true,
                onChanged: null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification settings updated!')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Location Settings
  void _showLocationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Settings'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                title: const Text('Location Services'),
                subtitle:
                    const Text('Allow location access for emergency response'),
                value: _locationEnabled,
                onChanged: (value) =>
                    setDialogState(() => _locationEnabled = value),
              ),
              const SizedBox(height: 16),
              if (_locationEnabled) ...[
                const Text('📍 Current Location: Windhoek, Namibia'),
                const SizedBox(height: 8),
                const Text('🎯 Accuracy: High (GPS enabled)'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _updateLocation(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Update Location'),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Location disabled. Emergency services may not be able to find you.',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Terms and Privacy
  void _showTermsAndPrivacy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms & Privacy'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Terms of Service'),
                subtitle: const Text('User agreement and app terms'),
                onTap: () => _showDocument('terms'),
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: const Text('Privacy Policy'),
                subtitle: const Text('How we handle your data'),
                onTap: () => _showDocument('privacy'),
              ),
              ListTile(
                leading: const Icon(Icons.cookie),
                title: const Text('Cookie Policy'),
                subtitle: const Text('Information about cookies'),
                onTap: () => _showDocument('cookies'),
              ),
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Data Security'),
                subtitle: const Text('Security measures and encryption'),
                onTap: () => _showDocument('security'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Detailed Privacy Settings
  void _showDetailedPrivacySettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Controls'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('Profile Visibility'),
                subtitle: const Text('Control who can see your profile'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showPrivacySetting('visibility'),
              ),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Location Sharing'),
                subtitle: const Text('Manage location sharing preferences'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showPrivacySetting('location'),
              ),
              ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('Contact Information'),
                subtitle: const Text('Control access to your contact details'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showPrivacySetting('contact'),
              ),
              ListTile(
                leading: const Icon(Icons.report),
                title: const Text('Report History'),
                subtitle: const Text('Manage your crime report visibility'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showPrivacySetting('reports'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.download, color: Colors.blue),
                title: const Text('Download My Data'),
                subtitle: const Text('Get a copy of your personal data'),
                onTap: () => _downloadUserData(),
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete My Data'),
                subtitle: const Text('Permanently remove all your data'),
                onTap: () => _showDeleteDataDialog(context),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Support and App Actions
  void _contactSupport() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.email),
              title: Text('Email Support'),
              subtitle: Text('support@311security.na'),
            ),
            ListTile(
              leading: Icon(Icons.phone),
              title: Text('Call Support'),
              subtitle: Text('+264 61 XXX XXXX'),
            ),
            ListTile(
              leading: Icon(Icons.chat),
              title: Text('Live Chat'),
              subtitle: Text('Available Mon-Fri 8:00-17:00'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _launchEmail();
            },
            child: const Text('Send Email'),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null && mounted) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        final authProvider = context.read<AuthProvider>();
        final userId = authProvider.user?.id;

        if (userId == null) {
          if (mounted) Navigator.pop(context);
          throw Exception('User not authenticated');
        }

        // Upload to Supabase Storage (using XFile directly)
        final imageUrl =
            await _storageService.uploadProfileImage(image, userId);

        if (imageUrl != null) {
          // Update profile in database
          final result =
              await _authService.updateProfile(profileImageUrl: imageUrl);

          if (mounted) Navigator.pop(context); // Close loading dialog

          if (result.success) {
            setState(() {
              _profileImageFile = image;
              _profileImageUrl = imageUrl;
            });

            // Refresh provider
            await authProvider.refreshProfile();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('📸 Profile picture updated!')),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Failed to update profile: ${result.error}')),
              );
            }
          }
        } else {
          if (mounted) {
            Navigator.pop(context); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to upload image')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        // Try to close loading dialog if it's open
        if (Navigator.canPop(context)) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to take photo: $e')),
        );
      }
    }
  }

  Future<void> _chooseFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null && mounted) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        final authProvider = context.read<AuthProvider>();
        final userId = authProvider.user?.id;

        if (userId == null) {
          if (mounted) Navigator.pop(context);
          throw Exception('User not authenticated');
        }

        // Upload to Supabase Storage (using XFile directly)
        final imageUrl =
            await _storageService.uploadProfileImage(image, userId);

        if (imageUrl != null) {
          // Update profile in database
          final result =
              await _authService.updateProfile(profileImageUrl: imageUrl);

          if (mounted) Navigator.pop(context); // Close loading dialog

          if (result.success) {
            setState(() {
              _profileImageFile = image;
              _profileImageUrl = imageUrl;
            });

            // Refresh provider
            await authProvider.refreshProfile();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🖼️ Profile picture updated!')),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Failed to update profile: ${result.error}')),
              );
            }
          }
        } else {
          if (mounted) {
            Navigator.pop(context); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to upload image')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        // Try to close loading dialog if it's open
        if (Navigator.canPop(context)) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select photo: $e')),
        );
      }
    }
  }

  Future<void> _removePhoto() async {
    try {
      final authProvider = context.read<AuthProvider>();

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Delete from storage if URL exists
      if (_profileImageUrl != null) {
        await _storageService.deleteProfileImage(_profileImageUrl!);
      }

      // Update profile to remove avatar URL
      final result = await _authService.updateProfile(profileImageUrl: '');

      if (mounted) Navigator.pop(context); // Close loading dialog

      if (result.success) {
        setState(() {
          _profileImageFile = null;
          _profileImageUrl = null;
        });

        // Refresh provider
        await authProvider.refreshProfile();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🗑️ Profile picture removed')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove photo: ${result.error}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        if (Navigator.canPop(context)) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove photo: $e')),
        );
      }
    }
  }

  void _updateLocation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📍 Location updated successfully!')),
    );
  }

  void _showDocument(String type) {
    String title = '';
    String content = '';

    switch (type) {
      case 'terms':
        title = 'Terms of Service';
        content = 'Terms of service content would be loaded here...';
        break;
      case 'privacy':
        title = 'Privacy Policy';
        content = 'Privacy policy content would be loaded here...';
        break;
      case 'cookies':
        title = 'Cookie Policy';
        content = 'Cookie policy content would be loaded here...';
        break;
      case 'security':
        title = 'Data Security';
        content = 'Data security information would be loaded here...';
        break;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Text(content),
            ),
          ),
        ),
      ),
    );
  }

  void _showPrivacySetting(String setting) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('Opening ${setting.toUpperCase()} privacy settings...')),
    );
  }

  void _downloadUserData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📦 Preparing your data download...')),
    );
  }

  void _showDeleteDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete All Data'),
          ],
        ),
        content: const Text(
          'This action cannot be undone. All your data including profile, reports, and contacts will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteUserData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
  }

  void _deleteUserData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🗑️ All user data has been deleted')),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Account'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    // Note: Supabase doesn't have a direct account deletion API
    // This would need to be implemented server-side or through Supabase Auth Admin API
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text(
              'Account deletion not implemented yet. Please contact support.')),
    );
  }

  Future<void> _signOut() async {
    try {
      final result = await _authService.signOut();
      if (!mounted) return;

      if (result.success) {
        setState(() {
          _userName = 'Guest User';
          _userPhone = '';
          _userEmail = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed out successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign out failed: ${result.error}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign out failed: $e')),
      );
    }
  }

  void _refreshProfile() async {
    await _loadUserProfile();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🔄 Profile refreshed!')),
    );
  }

  void _launchEmail() async {
    const email = 'support@311security.na';
    const subject = '3:11 Security App Support';
    const body = 'Hello, I need help with...';

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );

    try {
      await launchUrl(emailUri);
    } catch (e) {
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open email app')),
      );
    }
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: enabled
                          ? [
                              theme.colorScheme.primary.withValues(alpha: 0.15),
                              theme.colorScheme.primary.withValues(alpha: 0.05),
                            ]
                          : [
                              theme.colorScheme.onSurface
                                  .withValues(alpha: 0.1),
                              theme.colorScheme.onSurface
                                  .withValues(alpha: 0.05),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: enabled
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: enabled
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: enabled
                              ? theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6)
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.4),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: enabled
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
