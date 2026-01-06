import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/auth_service.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/models/app_user.dart';
import 'package:manong_application/providers/bottom_nav_provider.dart';
import 'package:manong_application/theme/colors.dart';
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

  @override
  void initState() {
    super.initState();
    _getProfile();
  }

  Future<void> _getProfile() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final response = await authService.getMyProfile();

      if (mounted) {
        setState(() {
          profile = response;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to load profile. Please try again.';
        });
      }
      logger.severe('Error loading profile: $e');
    }
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
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
    return Container(
      margin: const EdgeInsets.only(top: 24),
      child: Column(
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
          ],

          // const SizedBox(height: 12),
          // _buildActionTile(
          //   icon: Icons.security,
          //   title: 'Security Settings',
          //   subtitle: 'Manage your account security',
          //   onTap: () {
          //     // Navigate to security settings
          //   },
          // ),
          const SizedBox(height: 12),
          _buildActionTile(
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Configure your preferences',
            onTap: () {
              Navigator.pushNamed(
                navigatorKey.currentContext!,
                '/notification-settings',
              );
            },
          ),
          const SizedBox(height: 12),
          _buildActionTile(
            icon: Icons.help,
            title: 'Help & Support',
            subtitle: 'Get help and contact support',
            onTap: () {
              // Navigate to help
              Navigator.pushNamed(context, '/help-and-support');
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

          const SizedBox(height: 24),
          FutureBuilder<PackageInfo>(
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
          ),
        ],
      ),
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

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            errorMessage ?? 'Something went wrong',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _getProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorScheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: myAppBar(leading: Icon(Icons.person), title: 'Account'),
      backgroundColor: AppColorScheme.backgroundGrey,
      body: RefreshIndicator(
        onRefresh: _getProfile,
        color: AppColorScheme.primaryColor,
        backgroundColor: AppColorScheme.backgroundGrey,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: isLoading
              ? SizedBox(
                  height:
                      MediaQuery.of(navigatorKey.currentContext!).size.height *
                      0.6,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColorScheme.primaryColor,
                    ),
                  ),
                )
              : errorMessage != null
              ? SizedBox(
                  height:
                      MediaQuery.of(navigatorKey.currentContext!).size.height *
                      0.6,
                  child: _buildErrorState(),
                )
              : profile == null
              ? SizedBox(
                  height:
                      MediaQuery.of(navigatorKey.currentContext!).size.height *
                      0.6,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColorScheme.primaryColor,
                    ),
                  ),
                )
              : Column(
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
                    const SizedBox(height: 32),
                  ],
                ),
        ),
      ),
    );
  }
}
