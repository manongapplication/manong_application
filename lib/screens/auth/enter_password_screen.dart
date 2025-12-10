import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/auth_service.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/snackbar_utils.dart';
import 'package:manong_application/widgets/input_decorations.dart';
import 'package:manong_application/widgets/my_app_bar.dart';

class EnterPasswordScreen extends StatefulWidget {
  final String? phone;
  const EnterPasswordScreen({super.key, this.phone});

  @override
  State<EnterPasswordScreen> createState() => _EnterPasswordScreenState();
}

class _EnterPasswordScreenState extends State<EnterPasswordScreen> {
  final Logger logger = Logger('EnterPasswordScreen');
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;
  String? _error;
  late String? _phone;
  final authService = AuthService();

  @override
  void initState() {
    super.initState();
    _phone = widget.phone;
  }

  void loginWithPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      try {
        if (_phone == null) return;
        final response = await AuthService().login(
          phone: _phone ?? '',
          password: _passwordController.text,
        );

        if (response != null) {
          if (response['token'] != null) {
            Navigator.pushNamedAndRemoveUntil(
              navigatorKey.currentContext!,
              '/',
              (route) => false,
            );
          } else {
            SnackBarUtils.showWarning(
              navigatorKey.currentContext!,
              response['message'],
            );
          }
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _error = e.toString();
        });

        logger.severe('Cannot login with password! $_error');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _forgotPassword() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    if (_phone == null) {
      setState(() => _isLoading = false);
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
          _isLoading = false;
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              "Password",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Stack(
              children: [
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscureText,
                  enabled: !_isLoading,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => loginWithPassword(),
                  decoration: inputDecoration(
                    'Enter your password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password cannot be empty';
                    }
                    return null;
                  },
                ),

                if (_isLoading) ...[
                  Positioned(
                    top: 4,
                    right: 0,
                    left: 0,
                    child: Container(
                      color: Colors.white.withOpacity(0.8),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColorScheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _forgotPassword,
              child: Text(
                'Forgot password?',
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildState() {
    return _buildForm();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: myAppBar(title: 'Enter Password'),
      body: _buildState(),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorScheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _isLoading ? null : loginWithPassword,
            child: _isLoading
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
