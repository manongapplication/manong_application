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
  final FocusNode _passwordFocusNode = FocusNode();
  bool _keyboardVisible = false;

  @override
  void initState() {
    super.initState();
    _phone = widget.phone;

    // Listen to keyboard visibility changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Add a listener to detect keyboard visibility
      _passwordFocusNode.addListener(() {
        if (_passwordFocusNode.hasFocus && !_keyboardVisible) {
          // Keyboard will show
          setState(() {
            _keyboardVisible = true;
          });
        }
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check keyboard visibility on mount
    _keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
  }

  @override
  void dispose() {
    _passwordFocusNode.dispose();
    _passwordController.dispose();
    super.dispose();
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

    FocusScope.of(context).unfocus();

    if (_isLoading) return;

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

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final hasKeyboard = keyboardHeight > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: myAppBar(title: 'Enter Password'),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.only(
              bottom: keyboardHeight + 120, // Fixed bottom padding
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section - Always show
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon (only show when no keyboard or small keyboard)
                    if (!hasKeyboard || keyboardHeight < 100) ...[
                      Container(
                        width: 60,
                        height: 60,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColorScheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.lock_outline,
                          size: 32,
                          color: AppColorScheme.primaryColor,
                        ),
                      ),
                    ],

                    // Title
                    Text(
                      'Enter Password',
                      style: TextStyle(
                        fontSize: hasKeyboard ? 24 : 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                        height: 1.2,
                      ),
                    ),

                    // Subtitle
                    const SizedBox(height: 8),
                    Text(
                      'Enter password for your account',
                      style: TextStyle(
                        fontSize: hasKeyboard ? 14 : 16,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: hasKeyboard ? 16 : 32),

                // Phone Display
                if (_phone != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.phone_android,
                          size: 20,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mobile Number',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _phone!,
                                style: TextStyle(
                                  fontSize: hasKeyboard ? 14 : 16,
                                  color: Colors.grey[900],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: hasKeyboard ? 16 : 32),
                ],

                // Password Section
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Password Field
                      Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        autofocus:
                            true, // Keep autofocus but don't trigger extra logic
                        obscureText: _obscureText,
                        enabled: !_isLoading,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => loginWithPassword(),
                        decoration: inputDecoration(
                          'Enter your password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey[600],
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                          ),
                        ).copyWith(filled: true, fillColor: Colors.grey[50]),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Forgot Password Link
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: _isLoading ? null : _forgotPassword,
                          child: Text(
                            'Forgot password?',
                            style: TextStyle(
                              color: _isLoading
                                  ? Colors.grey[400]
                                  : AppColorScheme.primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),

                      // Info Container - Only show when no keyboard
                      if (!hasKeyboard) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(top: 32),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue[100]!),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue[700],
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Forgot your password? Tap "Forgot password" above to reset via SMS.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Extra space at bottom - fixed amount
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // Bottom Button (adjusts with keyboard)
      bottomNavigationBar: Transform.translate(
        offset: Offset(0.0, -keyboardHeight),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorScheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 0),
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
                          "Log In",
                          style: TextStyle(fontSize: 16, color: Colors.white),
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
