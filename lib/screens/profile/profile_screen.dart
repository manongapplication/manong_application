import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/auth_service.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/models/app_user.dart';
import 'package:manong_application/providers/bottom_nav_provider.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/url_utils.dart';
import 'package:manong_application/widgets/error_state_widget.dart';
import 'package:manong_application/widgets/incomplete_profile_card.dart';
import 'package:manong_application/widgets/my_app_bar.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

final Logger logger = Logger('profile_screen');

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService authService = AuthService();
  bool isLoading = true;
  AppUser? profile;
  String? errorMessage;
  bool _isLoggedIn = false;
  bool _permissionsExpanded = false; // For dropdown state

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      // Try to get profile - if successful, user is logged in
      final response = await authService.getMyProfile();

      if (mounted) {
        setState(() {
          profile = response;
          _isLoggedIn = true;
          isLoading = false;
        });
      }
    } catch (e) {
      // If error, user is not logged in
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          profile = null;
          isLoading = false;
        });
      }
      logger.info('User not logged in: $e');
    }
  }

  Future<void> _getProfile() async {
    if (!_isLoggedIn) return;

    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final response = await authService.getMyProfile();

      if (mounted) {
        setState(() {
          profile = response;
          _isLoggedIn = true;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to load profile. Please try again.';
          _isLoggedIn = false;
        });
      }
      logger.severe('Error loading profile: $e');
    }
  }

  // ============ LOGGED IN UI ============
  Widget _buildLoggedInUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildProfileHeader(),
        if (profile!.firstName == null || profile!.email == null)
          IncompleteProfileCard(
            onTap: () async {
              final result = await Navigator.pushNamed(
                context,
                '/complete-profile',
              );

              if (result != null && result is Map) {
                if (result['update'] == true) {
                  _getProfile();
                }
              }
            },
          ),
        _buildProfileActions(),
      ],
    );
  }

  // ============ NOT LOGGED IN UI ============
  Widget _buildNotLoggedInUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Welcome Card for non-logged in users
        Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                Icons.person_outline,
                size: 60,
                color: AppColorScheme.primaryColor.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome to Manong',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to access your profile, bookings, and preferences',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColorScheme.primaryColor,
                        side: BorderSide(
                          color: AppColorScheme.primaryColor,
                          width: 1.5,
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColorScheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        shadowColor: AppColorScheme.primaryColor.withOpacity(
                          0.3,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/register',
                          arguments: {'isLoginFlow': true},
                        );
                      },
                      child: Text(
                        'Log In',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Essential Settings for non-logged in users
        Text(
          'App Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),

        // Permissions Section (combined)
        _buildPermissionsSection(),

        const SizedBox(height: 12),

        // App Tutorial
        _buildActionTile(
          icon: Icons.school,
          title: 'App Tutorial',
          subtitle: 'Learn how to use Manong step-by-step',
          onTap: () {
            Navigator.pushNamed(context, '/gallery-tutorial');
          },
        ),

        const SizedBox(height: 12),

        // Help & Support
        _buildActionTile(
          icon: Icons.help,
          title: 'Help & Support',
          subtitle: 'Get help and contact support',
          onTap: () {
            Navigator.pushNamed(context, '/help-and-support');
          },
        ),

        const SizedBox(height: 12),

        // Privacy Policy
        _buildActionTile(
          icon: Icons.privacy_tip,
          title: 'Privacy Policy',
          subtitle: 'View how we collect and use your data',
          onTap: () async {
            await launchUrlScreen(
              navigatorKey.currentContext!,
              'https://manongapp.com/index.php/privacy-policy/',
            );
          },
        ),
      ],
    );
  }

  // ============ SHARED COMPONENTS ============
  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColorScheme.primaryColor,
            AppColorScheme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Icon(Icons.person, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 16),

          // Welcome Text
          Text(
            'Welcome,',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w300,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 4),

          // Phone Number
          Text(
            profile!.phone,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          // Name and Email if available
          if (profile!.firstName != null) ...[
            const SizedBox(height: 8),
            Text(
              profile!.firstName!,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],

          if (profile!.email != null) ...[
            const SizedBox(height: 4),
            Text(
              profile!.email!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileActions() {
    return Column(
      children: [
        if (!(profile!.firstName == null || profile!.email == null)) ...[
          _buildActionTile(
            icon: Icons.edit,
            title: 'Edit Profile',
            subtitle: 'Edit your profile or permanently delete your account',
            onTap: () {
              Navigator.pushNamed(context, '/edit-profile').then((_) {
                _getProfile();
              });
            },
          ),
          const SizedBox(height: 12),
        ],

        // Permissions Section (combined)
        _buildPermissionsSection(),

        const SizedBox(height: 12),
        _buildActionTile(
          icon: Icons.help,
          title: 'Help & Support',
          subtitle: 'Get help and contact support',
          onTap: () {
            Navigator.pushNamed(context, '/help-and-support');
          },
        ),

        const SizedBox(height: 12),
        _buildActionTile(
          icon: Icons.school,
          title: 'App Tutorial',
          subtitle: 'Learn how to use Manong step-by-step',
          onTap: () {
            Navigator.pushNamed(context, '/gallery-tutorial');
          },
        ),

        const SizedBox(height: 12),
        _buildActionTile(
          icon: Icons.privacy_tip,
          title: 'Privacy Policy',
          subtitle: 'View how we collect and use your data',
          onTap: () async {
            await launchUrlScreen(
              navigatorKey.currentContext!,
              'https://manongapp.com/index.php/privacy-policy/',
            );
          },
        ),

        const SizedBox(height: 12),
        _buildActionTile(
          icon: Icons.logout,
          title: 'Sign Out',
          subtitle: 'Log out of your account',
          onTap: () {
            _showLogoutDialog();
          },
          isDestructive: true,
        ),
      ],
    );
  }

  // Combined Permissions Section with Dropdown
  Widget _buildPermissionsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header (always visible)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColorScheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.settings,
                color: AppColorScheme.primaryColor,
                size: 24,
              ),
            ),
            title: Text(
              'App Permissions',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            subtitle: Text(
              'Manage notification and location settings',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            trailing: Icon(
              _permissionsExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.grey[400],
            ),
            onTap: () {
              setState(() {
                _permissionsExpanded = !_permissionsExpanded;
              });
            },
          ),

          // Dropdown content
          if (_permissionsExpanded) ...[
            Divider(height: 1, color: Colors.grey[200]),

            // Notification Permission
            _buildPermissionItem(
              icon: Icons.notifications,
              title: 'Notifications',
              subtitle: 'Receive booking updates and alerts',
              route: '/notification-settings',
            ),

            Divider(height: 1, color: Colors.grey[200], indent: 72),

            // Location Permission
            _buildPermissionItem(
              icon: Icons.location_on,
              title: 'Location',
              subtitle: 'Find nearby services and providers',
              route: '/location-settings',
            ),

            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.grey[700], size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
      onTap: () {
        Navigator.pushNamed(context, route);
      },
    );
  }

  Widget _buildAppVersion() {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Loading version...',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        if (snapshot.hasData) {
          final info = snapshot.data!;
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Manong v${info.version} (${info.buildNumber})',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  '© ${DateTime.now().year} Manong Information Services',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive
                ? Colors.red.withOpacity(0.1)
                : AppColorScheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.red : AppColorScheme.primaryColor,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: isDestructive ? Colors.red : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColorScheme.backgroundGrey,
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _performLogout();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(color: AppColorScheme.primaryColor),
        );
      },
    );

    try {
      await authService.logout();

      Provider.of<BottomNavProvider>(
        navigatorKey.currentContext!,
        listen: false,
      ).changeIndex(0);

      if (mounted) {
        // Close loading dialog
        Navigator.of(navigatorKey.currentContext!).pop();

        Navigator.of(
          navigatorKey.currentContext!,
        ).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      logger.severe('Logout error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: myAppBar(
        leading: Icon(Icons.settings_outlined),
        title: 'Settings',
      ),
      backgroundColor: AppColorScheme.backgroundGrey,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return RefreshIndicator(
              onRefresh: _getProfile,
              color: AppColorScheme.primaryColor,
              backgroundColor: AppColorScheme.backgroundGrey,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: isLoading
                    ? SizedBox(
                        height: constraints.maxHeight * 0.6,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColorScheme.primaryColor,
                          ),
                        ),
                      )
                    : errorMessage != null
                    ? SizedBox(
                        height: constraints.maxHeight * 0.6,
                        child: ErrorStateWidget(
                          errorText: errorMessage ?? 'Something went wrong',
                          onPressed: _getProfile,
                        ),
                      )
                    : Column(
                        children: [
                          _isLoggedIn
                              ? _buildLoggedInUI()
                              : _buildNotLoggedInUI(),

                          const SizedBox(height: 16),
                          _buildAppVersion(),
                          const SizedBox(height: 16),
                        ],
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}
