import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/auth_service.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/models/app_user.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/snackbar_utils.dart';
import 'package:manong_application/widgets/card_container_2.dart';
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

  Widget _buildProfileEdit() {
    return CardContainer2(
      children: [
        _buildTextFields(title: 'First Name', controller: firstNameController),
        _buildTextFields(title: 'Last Name', controller: lastNameController),
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
      body: RefreshIndicator(
        onRefresh: _getProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: _isLoading
              ? SizedBox(
                  height:
                      MediaQuery.of(navigatorKey.currentContext!).size.height *
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
                  children: [_buildProfileHeader(), _buildProfileEdit()],
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
