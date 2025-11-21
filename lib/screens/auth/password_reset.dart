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

  void _submitPassword() async {
    if (!_formKey.currentState!.validate()) return;
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
          response['message'],
        );

        Navigator.pushNamedAndRemoveUntil(
          navigatorKey.currentContext!,
          '/',
          (route) => false,
        );
      } else {
        SnackBarUtils.showSuccess(
          navigatorKey.currentContext!,
          response?['message'] ?? 'Error reseting password!',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
      logger.severe('Error resetting password $_error');
    } finally {
      if (mounted) {
        setState(() {
          _isButtonLoading = false;
        });
      }
    }
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const SizedBox(height: 14),

            TextFormField(
              controller: _passwordController,
              enabled: !_isButtonLoading,
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                if (value.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                return null;
              },
              maxLength: 128,
              decoration: inputDecoration(
                'New Password',
                labelStyle: TextStyle(color: AppColorScheme.primaryDark),
                labelText: 'Password',
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: _confirmPasswordController,
              enabled: !_isButtonLoading,
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
              maxLength: 128,
              onChanged: (value) {
                if (_formKey.currentState != null) {
                  _formKey.currentState!.validate();
                }
              },
              decoration: inputDecoration(
                'Confirm Password',
                labelStyle: TextStyle(color: AppColorScheme.primaryDark),
                labelText: 'Confirm Password',
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildState() {
    if (_error != null) {
      return ErrorStateWidget(errorText: _error.toString());
    }

    return _buildForm();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: myAppBar(title: 'Reset Password'),
      body: _buildState(),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorScheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _isButtonLoading ? null : _submitPassword,
            child: _isButtonLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    "Continue",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
          ),
        ),
      ),
    );
  }
}
