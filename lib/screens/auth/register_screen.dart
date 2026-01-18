import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/auth_service.dart';
import 'package:manong_application/api/referral_code_api_service.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/hint_phone_numbers.dart';
import 'package:manong_application/utils/snackbar_utils.dart';
import 'package:manong_application/widgets/input_decorations.dart';
import 'package:manong_application/widgets/my_app_bar.dart';

class RegisterScreen extends StatefulWidget {
  final bool? isLoginFlow;
  const RegisterScreen({super.key, this.isLoginFlow});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final Logger logger = Logger('RegisterScreen');
  final _formKey = GlobalKey<FormState>();
  final authService = AuthService();
  PhoneNumber? phone;
  String selectedCountry = 'PH';
  bool _isLoading = false;
  String? _error;
  final TextEditingController _referralCodeController = TextEditingController();

  // Determine if we're in login or signup flow
  bool get isLoginFlow => widget.isLoginFlow ?? false;

  Future<bool> _validateReferralCode() async {
    try {
      final response = await ReferralCodeApiService().validateCode(
        _referralCodeController.text,
      );

      if (response != null) {
        if (response['success'] == true) {
          return true;
        } else {
          SnackBarUtils.showWarning(
            navigatorKey.currentContext!,
            response['message'],
          );
          return false;
        }
      }
    } catch (e) {
      if (!mounted) return false;
      setState(() {
        _error = e.toString();
      });
      logger.severe('Error validating code $_error');
    }

    return false;
  }

  void _submitRegisterPhone() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    if (_formKey.currentState!.validate()) {
      if (phone == null || phone!.number.isEmpty) {
        setState(() => _isLoading = false);
        SnackBarUtils.showWarning(context, 'Phone number cannot be empty');
        return;
      }

      try {
        if (_referralCodeController.text.isNotEmpty) {
          final isValid = await _validateReferralCode();
          if (!isValid) {
            setState(() => _isLoading = false);
            return;
          }
        }

        await authService.sendVerificationTwilio(phone?.completeNumber ?? '');

        if (!mounted) return;

        SnackBarUtils.showInfo(
          context,
          'We\'ve sent a 6-digit code to your phone. Enter it below to verify your number.',
        );

        setState(() => _isLoading = false);

        Navigator.pushNamed(
          context,
          '/verify',
          arguments: {
            'authService': authService,
            'phoneNumber': phone!.completeNumber,
            'referralCode': _referralCodeController.text.isNotEmpty
                ? _referralCodeController.text
                : null,
            'isLoginFlow': isLoginFlow,
          },
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);

        String errorMessage;
        final errorString = e.toString();

        if (errorString.contains('blocked') ||
            errorString.contains('60410') ||
            errorString.contains('temporarily blocked')) {
          errorMessage =
              'This number prefix (+63995) is temporarily blocked by our provider. Please try a different mobile number.';
        } else if (errorString.contains('invalid') ||
            errorString.contains('not valid')) {
          errorMessage = 'Please enter a valid Philippine mobile number.';
        } else if (errorString.contains('quota') ||
            errorString.contains('limit')) {
          errorMessage = 'SMS sending limit reached. Please try again later.';
        } else {
          errorMessage = 'Failed to send verification code: $e';
        }

        SnackBarUtils.showError(context, errorMessage);
        logger.severe('SMS sending error: $e');
      }
    } else {
      setState(() => _isLoading = false);
      SnackBarUtils.showWarning(context, 'Please enter a valid phone number');
    }
  }

  void _authenticateUser() async {
    FocusScope.of(context).unfocus();

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    if (_formKey.currentState!.validate()) {
      if (phone == null || phone!.number.isEmpty) {
        setState(() => _isLoading = false);
        SnackBarUtils.showWarning(context, 'Phone number cannot be empty');
        return;
      }

      try {
        final hasPassword = await authService.checkIfHasPassword(
          phone?.completeNumber ?? '',
        );

        if (hasPassword != null) {
          if (hasPassword == true) {
            if (_referralCodeController.text.isNotEmpty) {
              SnackBarUtils.showWarning(
                navigatorKey.currentContext!,
                'You are already registered. Referral codes are only for new users.',
              );
            }
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            Navigator.pushNamed(
              navigatorKey.currentContext!,
              '/enter-password',
              arguments: {'phone': phone?.completeNumber},
            );
          } else {
            _submitRegisterPhone();
          }
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
        logger.severe('Error $_error');
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: myAppBar(title: isLoginFlow ? 'Log In' : 'Create Account'),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon
                          Container(
                            width: 60,
                            height: 60,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColorScheme.primaryColor.withOpacity(
                                0.1,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.phone_android,
                              size: 32,
                              color: AppColorScheme.primaryColor,
                            ),
                          ),

                          // Title
                          Text(
                            isLoginFlow ? 'Welcome Back' : 'Create Account',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[900],
                              height: 1.2,
                            ),
                          ),

                          // Subtitle
                          const SizedBox(height: 8),
                          Text(
                            isLoginFlow
                                ? 'Enter your phone number to log in to your account'
                                : 'Enter your phone number to create your Manong account',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Form Section
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Phone Field
                            Text(
                              'Mobile Number',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),

                            IntlPhoneField(
                              decoration: inputDecoration(
                                getExampleNumber(selectedCountry),
                                labelText: 'Phone Number',
                              ),
                              enabled: !_isLoading,
                              initialCountryCode: 'PH',
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                TextInputFormatter.withFunction((
                                  oldValue,
                                  newValue,
                                ) {
                                  String newText = newValue.text;
                                  if (selectedCountry == 'PH' &&
                                      newText.startsWith('0')) {
                                    newText = newText.substring(1);
                                  }
                                  return TextEditingValue(
                                    text: newText,
                                    selection: TextSelection.collapsed(
                                      offset: newText.length,
                                    ),
                                  );
                                }),
                              ],
                              textInputAction: TextInputAction.done,
                              keyboardType: TextInputType.phone,
                              onSubmitted: (value) {
                                FocusScope.of(context).unfocus();
                                _authenticateUser();
                              },
                              onChanged: (phone) {
                                String processedNumber = phone.number;
                                if (selectedCountry == 'PH' &&
                                    processedNumber.startsWith('0')) {
                                  processedNumber = processedNumber.substring(
                                    1,
                                  );
                                }

                                this.phone = PhoneNumber(
                                  countryCode: phone.countryCode,
                                  countryISOCode: phone.countryISOCode,
                                  number: processedNumber,
                                );
                              },
                              validator: (phone) {
                                if (phone == null || phone.number.isEmpty) {
                                  return 'Please enter your phone number';
                                }

                                String processedNumber = phone.number;
                                if (selectedCountry == 'PH' &&
                                    processedNumber.startsWith('0')) {
                                  processedNumber = processedNumber.substring(
                                    1,
                                  );
                                }

                                if (selectedCountry == 'PH') {
                                  if (processedNumber.length != 10) {
                                    return 'Please enter a valid 10-digit Philippine number';
                                  }

                                  if (!processedNumber.startsWith('9')) {
                                    return 'Philippine mobile numbers must start with 9';
                                  }
                                }

                                return null;
                              },
                              onCountryChanged: (country) {
                                setState(() {
                                  selectedCountry = country.code;
                                });
                              },
                            ),

                            const SizedBox(height: 24),

                            // Referral Code Field (Only for signup) - Compact version
                            if (!isLoginFlow) ...[
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: TextField(
                                          controller: _referralCodeController,
                                          decoration: InputDecoration(
                                            hintText:
                                                'Referral code (optional)',
                                            hintStyle: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 14,
                                            ),
                                            border: InputBorder.none,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  vertical: 16,
                                                ),
                                          ),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[800],
                                          ),
                                          textCapitalization:
                                              TextCapitalization.characters,
                                          textInputAction: TextInputAction.done,
                                          onSubmitted: (value) {
                                            FocusScope.of(context).unfocus();
                                            _authenticateUser();
                                          },
                                          inputFormatters: [
                                            TextInputFormatter.withFunction((
                                              oldValue,
                                              newValue,
                                            ) {
                                              return TextEditingValue(
                                                text: newValue.text
                                                    .toUpperCase(),
                                                selection: newValue.selection,
                                              );
                                            }),
                                          ],
                                          enabled: !_isLoading,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 8),
                              // Small helper text
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Text(
                                  'Referral codes are completely optional',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // SMS Notice (moved up here)
                            Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(top: 24),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue[100]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.sms_outlined,
                                    color: Colors.blue[700],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'We\'ll send a verification code via SMS',
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

                            if (!isLoginFlow) ...[
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Already have an account? ',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pushReplacementNamed(
                                        context,
                                        '/register',
                                        arguments: {'isLoginFlow': true},
                                      );
                                    },
                                    child: Text(
                                      'Log In',
                                      style: TextStyle(
                                        color: AppColorScheme.primaryColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            // Extra space at bottom for better scrolling
                            SizedBox(
                              height:
                                  MediaQuery.of(context).viewInsets.bottom > 0
                                  ? 80 // Less space when keyboard is visible
                                  : 100,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Transform.translate(
        offset: Offset(0.0, -MediaQuery.of(context).viewInsets.bottom),
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
                    minimumSize: const Size(double.infinity, 0), // Full width
                  ),
                  onPressed: _isLoading ? null : _authenticateUser,
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
                          "Next",
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

  @override
  void dispose() {
    _referralCodeController.dispose();
    super.dispose();
  }
}
