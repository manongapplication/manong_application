import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/auth_service.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/snackbar_utils.dart';
import 'package:manong_application/widgets/error_state_widget.dart';
import 'package:manong_application/widgets/input_decorations.dart';
import 'package:manong_application/widgets/my_app_bar.dart';

class PasswordReset extends StatefulWidget {
  final bool? resetPassword;
  const PasswordReset({super.key, this.resetPassword});

  @override
  State<PasswordReset> createState() => _PasswordResetState();
}

class _PasswordResetState extends State<PasswordReset> {
  final Logger logger = Logger('PasswordReset');
  bool _isButtonLoading = false;
  String? _error;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePasswordText = true;
  bool _obscureConfirmText = true;

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  void _submitPassword() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate password match
    if (_passwordController.text != _confirmPasswordController.text) {
      SnackBarUtils.showWarning(
        navigatorKey.currentContext!,
        'Passwords do not match',
      );
      return;
    }

    setState(() {
      _isButtonLoading = true;
      _error = null;
    });

    try {
      if (_passwordController.text.isEmpty) return;

      final response = await AuthService().resetPassword(
        _passwordController.text,
      );

      if (response != null) {
        SnackBarUtils.showSuccess(
          navigatorKey.currentContext!,
          response['message'] ?? 'Password reset successfully!',
        );

        Navigator.pushNamedAndRemoveUntil(
          navigatorKey.currentContext!,
          '/',
          (route) => false,
        );
      } else {
        SnackBarUtils.showWarning(
          navigatorKey.currentContext!,
          'Error resetting password!',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
      logger.severe('Error resetting password $_error');
      SnackBarUtils.showError(
        navigatorKey.currentContext!,
        'Failed to reset password: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isButtonLoading = false;
        });
      }
    }
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
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                "Reset Password",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Create a new password for your account",
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),

              // New Password
              TextFormField(
                controller: _passwordController,
                enabled: !_isButtonLoading,
                obscureText: _obscurePasswordText,
                validator: _validatePassword,
                maxLength: 128,
                onChanged: (value) {
                  // Re-validate confirm password when password changes
                  if (_confirmPasswordController.text.isNotEmpty) {
                    _formKey.currentState!.validate();
                  }
                },
                decoration: inputDecoration(
                  'Enter new password',
                  labelStyle: TextStyle(color: AppColorScheme.primaryDark),
                  labelText: 'New Password',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: AppColorScheme.primaryDark,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePasswordText
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColorScheme.primaryDark,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePasswordText = !_obscurePasswordText;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Confirm Password
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
                  'Confirm your password',
                  labelStyle: TextStyle(color: AppColorScheme.primaryDark),
                  labelText: 'Confirm Password',
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
                      'At least 8 characters long',
                      _passwordController.text.length >= 8,
                    ),
                    _buildRequirementItem(
                      'Passwords match',
                      _passwordController.text.isNotEmpty &&
                          _passwordController.text ==
                              _confirmPasswordController.text,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
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

    return _buildForm();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorScheme.backgroundGrey,
      appBar: myAppBar(title: 'Reset Password'),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: _buildState(),
        ),
      ),
      bottomNavigationBar: Transform.translate(
        offset: Offset(0, -MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorScheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _isButtonLoading ? null : _submitPassword,
              child: _isButtonLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : const Text(
                      'Reset Password',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
