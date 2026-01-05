import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/auth_service.dart';
import 'package:manong_application/api/user_api_service.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/snackbar_utils.dart';
import 'package:manong_application/widgets/error_state_widget.dart';
import 'package:manong_application/widgets/input_decorations.dart';
import 'package:manong_application/widgets/my_app_bar.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String? phone;
  const ChangePasswordScreen({super.key, this.phone});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final Logger logger = Logger('ChangePasswordScreen');
  final _formKey = GlobalKey<FormState>();
  bool _isButtonLoading = false;
  String? _error;
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscureCurrentText = true;
  bool _obscureNewText = true;
  bool _obscureConfirmText = true;
  late String? _phone;
  final authService = AuthService();

  @override
  void initState() {
    super.initState();
    _phone = widget.phone;
  }

  void _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate password match
    if (_newPasswordController.text != _confirmPasswordController.text) {
      SnackBarUtils.showWarning(
        navigatorKey.currentContext!,
        'New password and confirmation do not match',
      );
      return;
    }

    setState(() {
      _isButtonLoading = true;
      _error = null;
    });

    try {
      final response = await UserApiService().changePassword(
        password: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (response != null) {
        if (response['success'] == true) {
          SnackBarUtils.showSuccess(
            navigatorKey.currentContext!,
            response['message'] ?? 'Password changed successfully',
          );

          Navigator.pop(navigatorKey.currentContext!);
        } else {
          SnackBarUtils.showWarning(
            navigatorKey.currentContext!,
            response['message'] ?? 'Failed to change password',
          );
        }
      } else {
        SnackBarUtils.showWarning(
          navigatorKey.currentContext!,
          'Failed to change password. Please try again.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
      logger.severe('Cannot change password! $_error');
      SnackBarUtils.showError(
        navigatorKey.currentContext!,
        'Failed to change password: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isButtonLoading = false;
        });
      }
    }
  }

  void _forgotPassword() async {
    if (!mounted) return;

    setState(() {
      _isButtonLoading = true;
      _error = null;
    });

    if (_phone == null) {
      setState(() => _isButtonLoading = false);
      SnackBarUtils.showWarning(context, 'Phone number cannot be empty');
      return;
    }

    try {
      await authService.sendVerificationTwilio(_phone ?? '');

      if (!mounted) return;

      SnackBarUtils.showInfo(
        context,
        'We\'ve sent a 6-digit code to your phone. Enter it below to verify your number.',
      );

      Navigator.pushNamed(
        context,
        '/verify',
        arguments: {
          'authService': authService,
          'phoneNumber': _phone,
          'isPasswordReset': true,
        },
      );
    } catch (e) {
      if (!mounted) return;

      final errorMessage = e.toString().contains('blocked')
          ? 'This number prefix is temporarily blocked. Please try a different number.'
          : 'Failed to send code: $e';

      SnackBarUtils.showError(context, errorMessage);

      setState(() {
        _error = errorMessage;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isButtonLoading = false;
        });
      }
    }
  }

  String? _validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your current password';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a new password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (value == _currentPasswordController.text) {
      return 'New password must be different from current password';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Widget _buildRequirementItem(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            color: met ? Colors.green : Colors.grey.shade400,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: met ? Colors.green : Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              "Change Password",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Update your account password",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),

            // Current Password
            TextFormField(
              controller: _currentPasswordController,
              enabled: !_isButtonLoading,
              obscureText: _obscureCurrentText,
              validator: _validateCurrentPassword,
              maxLength: 128,
              decoration: inputDecoration(
                'Enter your current password',
                labelStyle: TextStyle(color: AppColorScheme.primaryDark),
                labelText: 'Current Password',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: AppColorScheme.primaryDark,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureCurrentText
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: AppColorScheme.primaryDark,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureCurrentText = !_obscureCurrentText;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // New Password
            TextFormField(
              controller: _newPasswordController,
              enabled: !_isButtonLoading,
              obscureText: _obscureNewText,
              validator: _validateNewPassword,
              maxLength: 128,
              onChanged: (value) {
                // Re-validate confirm password when new password changes
                if (_confirmPasswordController.text.isNotEmpty) {
                  _formKey.currentState!.validate();
                }
              },
              decoration: inputDecoration(
                'Enter your new password',
                labelStyle: TextStyle(color: AppColorScheme.primaryDark),
                labelText: 'New Password',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: AppColorScheme.primaryDark,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNewText ? Icons.visibility_off : Icons.visibility,
                    color: AppColorScheme.primaryDark,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureNewText = !_obscureNewText;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Confirm New Password
            TextFormField(
              controller: _confirmPasswordController,
              enabled: !_isButtonLoading,
              obscureText: _obscureConfirmText,
              validator: _validateConfirmPassword,
              maxLength: 128,
              onChanged: (value) {
                if (_formKey.currentState != null) {
                  _formKey.currentState!.validate();
                }
              },
              decoration: inputDecoration(
                'Confirm your new password',
                labelStyle: TextStyle(color: AppColorScheme.primaryDark),
                labelText: 'Confirm New Password',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: AppColorScheme.primaryDark,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmText
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: AppColorScheme.primaryDark,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmText = !_obscureConfirmText;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Password requirements
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Password Requirements:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildRequirementItem(
                    'Current password is entered',
                    _currentPasswordController.text.isNotEmpty,
                  ),
                  _buildRequirementItem(
                    'New password is at least 8 characters',
                    _newPasswordController.text.length >= 8,
                  ),
                  _buildRequirementItem(
                    'New password is different from current',
                    _newPasswordController.text.isNotEmpty &&
                        _currentPasswordController.text.isNotEmpty &&
                        _newPasswordController.text !=
                            _currentPasswordController.text,
                  ),
                  _buildRequirementItem(
                    'Passwords match',
                    _newPasswordController.text.isNotEmpty &&
                        _newPasswordController.text ==
                            _confirmPasswordController.text,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Forgot Password Link
            GestureDetector(
              onTap: _isButtonLoading ? null : _forgotPassword,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Forgot password?',
                  style: TextStyle(
                    color: _isButtonLoading ? Colors.grey : Colors.blue,
                    decoration: TextDecoration.underline,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorScheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: !_isButtonLoading ? _changePassword : null,
                child: _isButtonLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : const Text(
                        'Change Password',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildState() {
    if (_error != null) {
      return ErrorStateWidget(
        errorText: _error.toString(),
        onPressed: () {
          setState(() {
            _error = null;
          });
        },
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: _buildForm(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: myAppBar(title: 'Change Password'),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: _buildState(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
