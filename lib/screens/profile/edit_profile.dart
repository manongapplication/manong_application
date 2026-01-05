import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/auth_service.dart';
import 'package:manong_application/api/user_api_service.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/models/app_user.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/snackbar_utils.dart';
import 'package:manong_application/widgets/card_container_2.dart';
import 'package:manong_application/widgets/input_decorations.dart';
import 'package:manong_application/widgets/my_app_bar.dart';

final Logger logger = Logger('edit_profile');

class EditProfile extends StatefulWidget {
  final String? destination;
  const EditProfile({super.key, this.destination});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  AuthService? authService = AuthService();
  bool _isLoading = true;
  bool _isButtonLoading = false;
  AppUser? profile;
  String? _error;
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  bool _isChangingPassword = false;

  @override
  void initState() {
    super.initState();
    _getProfile();
    firstNameController.addListener(() => setState(() {}));
    lastNameController.addListener(() => setState(() {}));
    emailController.addListener(() => setState(() {}));
  }

  Future<void> _getProfile() async {
    try {
      setState(() {
        _isLoading = false;
        _error = null;
      });

      final response = await authService!.getMyProfile();

      if (mounted) {
        setState(() {
          profile = response;
          firstNameController.text = profile!.firstName ?? '';
          lastNameController.text = profile!.lastName ?? '';
          emailController.text = profile!.email ?? '';
          _isLoading = false;
        });

        logger.info('Fetched profile email: ${profile!.email}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load profile. Please try again.';
        });
      }
      logger.severe('Error loading profile: $e');
    }
  }

  bool hasChanges() {
    if (profile == null) return false; // no profile to compare

    final currentFirstName = firstNameController.text.trim();
    final currentLastName = lastNameController.text.trim();
    final currentEmail = emailController.text.trim();

    final originalFirstName = profile!.firstName?.trim() ?? '';
    final originalLastName = profile!.lastName?.trim() ?? '';
    final originalEmail = profile!.email?.trim() ?? '';

    return currentFirstName != originalFirstName ||
        currentLastName != originalLastName ||
        currentEmail != originalEmail;
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _error ?? "Something went wrong",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorScheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: _getProfile,
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return CardContainer2(
      margin: EdgeInsets.all(0),
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

      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.white.withOpacity(0.2),
          child: Icon(Icons.person, size: 60, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          profile!.phone,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 26,
          ),
        ),
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
      ],
    );
  }

  void _changePassword() async {
    if (_isChangingPassword) return;

    setState(() => _isChangingPassword = true);

    if (profile?.phone == null) {
      setState(() => _isChangingPassword = false);
      SnackBarUtils.showWarning(context, 'Phone number cannot be empty');
      return;
    }

    try {
      await Navigator.pushNamed(
        context,
        '/change-password',
        arguments: {'phone': profile?.phone},
      );
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
      _getProfile();
    }
  }

  void _deleteAccount() async {
    // First confirmation dialog
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColorScheme.primaryColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Password confirmation dialog
      final passwordController = TextEditingController();
      bool obscurePassword = true;

      final passwordConfirmed = await showDialog(
        context: navigatorKey.currentContext!,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                backgroundColor: Colors.white,
                title: const Text('Confirm Password'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Please enter your password to confirm account deletion.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        '⚠️ Warning: This will permanently delete ALL your data, conversations, and history.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: inputDecoration(
                        'Password',
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppColorScheme.primaryColor),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (passwordController.text.isNotEmpty) {
                        Navigator.pop(context, true);
                      }
                    },
                    child: const Text(
                      'Confirm',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );

      if (passwordConfirmed == true) {
        // Show loading indicator
        showDialog(
          context: navigatorKey.currentContext!,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        try {
          // Call your API to delete account
          final response = await UserApiService().deleteUserdata(
            passwordController.text,
          );

          Navigator.pop(navigatorKey.currentContext!);

          if (response != null) {
            if (response['success'] == true) {
              // Show success message and navigate
              if (mounted) {
                SnackBarUtils.showSuccess(
                  navigatorKey.currentContext!,
                  response['message'] ?? 'Account deleted successfully',
                );

                Navigator.of(
                  navigatorKey.currentContext!,
                ).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
              }
            } else {
              SnackBarUtils.showWarning(
                navigatorKey.currentContext!,
                response['message'] ?? 'Account deleted successfully',
              );
            }
          } else {
            if (mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Error'),
                  content: const Text(
                    'Failed to delete account. Please try again.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            }
          }
        } catch (e) {
          Navigator.pop(navigatorKey.currentContext!);

          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Error'),
                content: Text('An error occurred: ${e.toString()}'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        }
      }
    }
  }

  List<Widget> _buildDeleteAccountArea() {
    return [
      Container(
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade300, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.red.shade100.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _deleteAccount,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_forever,
                      color: Colors.red.shade800,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delete Account',
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Permanently delete your account and all data',
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.red.shade600),
                ],
              ),
            ),
          ),
        ),
      ),

      const SizedBox(height: 12),

      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          '⚠️ This action cannot be undone. All your conversations, history, and settings will be permanently deleted.',
          style: TextStyle(
            color: Colors.red.shade700,
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    ];
  }

  Widget _buildChangePasswordButton() {
    return GestureDetector(
      onTap: _isChangingPassword ? null : _changePassword,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColorScheme.primaryColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            _isChangingPassword
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColorScheme.primaryColor,
                    ),
                  )
                : Icon(
                    Icons.lock_reset,
                    color: AppColorScheme.primaryColor,
                    size: 20,
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _isChangingPassword ? 'Changing...' : 'Change Password',
                style: TextStyle(
                  color: AppColorScheme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            if (!_isChangingPassword)
              Icon(
                Icons.chevron_right,
                color: AppColorScheme.primaryColor.withOpacity(0.7),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileEdit() {
    return CardContainer2(
      children: [
        _buildTextFields(title: 'First Name', controller: firstNameController),
        _buildTextFields(title: 'Last Name', controller: lastNameController),
        const SizedBox(height: 14),

        _buildChangePasswordButton(),

        const SizedBox(height: 32),

        Divider(color: Colors.red.shade300),

        const SizedBox(height: 24),

        ..._buildDeleteAccountArea(),

        const SizedBox(height: 14),

        // _buildTextFields(title: 'Email', controller: emailController),
      ],
    );
  }

  Widget _buildTextFields({
    required String title,
    required TextEditingController controller,
  }) {
    return Padding(
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.black, fontSize: 14)),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColorScheme.primaryColor),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColorScheme.deepTeal),
              ),
              hintText: controller.text == "" ? "Not Set" : controller.text,
            ),
            textCapitalization: TextCapitalization.words,
          ),
        ],
      ),
    );
  }

  void _updateProfile() async {
    if (emailController.text.trim().isNotEmpty &&
        !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(emailController.text.trim())) {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(content: Text('Please enter a valid email address')),
      );

      return;
    }

    setState(() {
      _isButtonLoading = true;
    });

    try {
      if (widget.destination != null) {
        if (firstNameController.text.trim().isEmpty ||
            lastNameController.text.trim().isEmpty ||
            emailController.text.trim().isEmpty) {
          SnackBarUtils.showWarning(
            navigatorKey.currentContext!,
            'Please complete your profile first',
          );

          return;
        }

        Navigator.pushNamed(
          navigatorKey.currentContext!,
          widget.destination ?? '',
        );
      }

      final response = await authService?.updateProfile(
        firstName: firstNameController.text,
        lastName: lastNameController.text,
        email: emailController.text,
      );

      if (response != null && response['success'] == true) {
        ScaffoldMessenger.of(
          navigatorKey.currentContext!,
        ).showSnackBar(SnackBar(content: Text('Profile Updated Successfully')));

        await _getProfile();
      } else {
        final messages = response?['message'];
        if (messages is List) {
          for (var msg in messages) {
            SnackBarUtils.showWarning(
              navigatorKey.currentContext!,
              msg.toString()[0].toUpperCase() + msg.toString().substring(1),
            );
          }
        } else {
          ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
            SnackBar(
              content: Text(
                response?['message'] ??
                    'Failed to update profile. Please try again.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
      logger.severe('Error saving profile $_error');
    } finally {
      if (mounted) {
        setState(() {
          _isButtonLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorScheme.backgroundGrey,
      appBar: myAppBar(
        title: 'Edit Profile',
        trailing: hasChanges()
            ? GestureDetector(
                onTap: _isButtonLoading ? null : _updateProfile,
                child: _isButtonLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text('Save', style: TextStyle(color: Colors.white)),
              )
            : null,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: RefreshIndicator(
          onRefresh: _getProfile,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: _isLoading
                ? SizedBox(
                    height:
                        MediaQuery.of(
                          navigatorKey.currentContext!,
                        ).size.height *
                        0.8,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColorScheme.primaryColor,
                      ),
                    ),
                  )
                : _error != null
                ? SizedBox(
                    height:
                        MediaQuery.of(
                          navigatorKey.currentContext!,
                        ).size.height *
                        0.6,
                    child: _buildErrorState(),
                  )
                : profile == null
                ? SizedBox(
                    height:
                        MediaQuery.of(
                          navigatorKey.currentContext!,
                        ).size.height *
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
                      SafeArea(child: _buildProfileEdit()),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    super.dispose();
  }
}
