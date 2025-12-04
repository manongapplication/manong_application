import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/auth_service.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/snackbar_utils.dart';
import 'package:manong_application/widgets/error_state_widget.dart';
import 'package:manong_application/widgets/input_decorations.dart';
import 'package:manong_application/widgets/manong_icon.dart';
import 'package:manong_application/widgets/my_app_bar.dart';

class CreatePasswordScreen extends StatefulWidget {
  const CreatePasswordScreen({super.key});

  @override
  State<CreatePasswordScreen> createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends State<CreatePasswordScreen> {
  final Logger logger = Logger('CreatePasswordScreen');
  final _formKey = GlobalKey<FormState>();
  bool _isButtonLoading = false;
  String? _error;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

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

      final response = await AuthService().updateProfile(
        password: _passwordController.text,
      );

      if (response != null) {
        SnackBarUtils.showSuccess(
          navigatorKey.currentContext!,
          response['message'] ?? 'Password created successfully!',
        );

        Navigator.pushNamedAndRemoveUntil(
          navigatorKey.currentContext!,
          '/',
          (route) => false,
        );
      } else {
        SnackBarUtils.showWarning(
          navigatorKey.currentContext!,
          'Error creating password!',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
      logger.severe('Error creating password $_error');
    } finally {
      if (mounted) {
        setState(() {
          _isButtonLoading = false;
        });
      }
    }
  }

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

  Widget _buildFormInputs() {
    return Column(
      children: [
        const SizedBox(height: 24),

        TextFormField(
          controller: _passwordController,
          enabled: !_isButtonLoading,
          obscureText: true,
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
          ),
        ),

        const SizedBox(height: 16),

        TextFormField(
          controller: _confirmPasswordController,
          enabled: !_isButtonLoading,
          obscureText: true,
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
                    _passwordController.text == _confirmPasswordController.text,
              ),
            ],
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
            ),
            onPressed: !_isButtonLoading ? _submitPassword : null,
            child: _isButtonLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : const Text('Create Password', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
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
                // Logo and title
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    manongIcon(size: 32),
                    const SizedBox(width: 8),
                    Text(
                      'Create Password',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColorScheme.primaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Create a strong password to secure your account',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColorScheme.primaryLight.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: _buildFormInputs(),
            ),
          ),
        ],
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
      appBar: myAppBar(title: 'Create Password'),
      body: SafeArea(child: _buildState()),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
