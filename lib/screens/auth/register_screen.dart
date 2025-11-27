import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/auth_service.dart';
import 'package:manong_application/api/firebase_api_token.dart';
import 'package:manong_application/api/referral_code_api_service.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/screens/home/home_screen.dart';
import 'package:manong_application/screens/main_screen.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/hint_phone_numbers.dart';
import 'package:manong_application/utils/snackbar_utils.dart';
import 'package:manong_application/widgets/input_decorations.dart';
import 'package:manong_application/widgets/my_app_bar.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

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

  // void _submitRegisterPhone() async {
  //   if (!mounted) return;

  //   setState(() {
  //     _isLoading = true;
  //   });

  //   if (_formKey.currentState!.validate()) {
  //     if (_formKey.currentState!.validate()) {
  //       if (phone == null || phone!.number.isEmpty) {
  //         setState(() {
  //           _isLoading = false;
  //         });

  //         SnackBarUtils.showWarning(context, 'Phone number cannot be empty');
  //         return;
  //       }
  //     }

  //     authService.verifyPhoneNumber(
  //       phoneNumber: phone!.completeNumber,
  //       onAutoVerified: (credential) async {
  //         if (!mounted) return;

  //         setState(() {
  //           _isLoading = false;
  //         });

  //         try {
  //           final result = await FirebaseAuth.instance.signInWithCredential(
  //             credential,
  //           );
  //           if (result.user != null) {
  //             SnackBarUtils.showSuccess(
  //               navigatorKey.currentContext!,
  //               'User signed in automatically!',
  //             );

  //             if (mounted) {
  //               Navigator.of(context).pushAndRemoveUntil(
  //                 MaterialPageRoute(builder: (context) => HomeScreen()),
  //                 (route) => false,
  //               );
  //             }
  //           }
  //         } catch (e) {
  //           SnackBarUtils.showError(
  //             navigatorKey.currentContext!,
  //             'Auto sign-in failed: $e',
  //           );
  //         }
  //       },
  //       onFailed: (error) {
  //         setState(() {
  //           _isLoading = false;
  //         });

  //         if (!mounted) return;

  //         SnackBarUtils.showError(
  //           context,
  //           'Verification failed: ${error.message}',
  //         );
  //       },
  //       onCodeSent: (verificationId) {
  //         setState(() {
  //           _isLoading = false;
  //         });

  //         if (!mounted) return;

  //         SnackBarUtils.showSuccess(context, 'Code Sent! Check your messages.');

  //         Navigator.pushNamed(
  //           navigatorKey.currentContext!,
  //           '/verify',
  //           arguments: {
  //             'verificationId': verificationId,
  //             'authService': authService,
  //             'phoneNumber': phone!.completeNumber,
  //           },
  //         );
  //       },
  //     );
  //   } else {
  //     setState(() {
  //       _isLoading = false;
  //     });

  //     if (!mounted) return;

  //     SnackBarUtils.showWarning(context, 'Please enter a valid phone number');
  //   }
  // }

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
        // ONLY validate referral code if it's not empty
        if (_referralCodeController.text.isNotEmpty) {
          final isValid = await _validateReferralCode();
          if (!isValid) {
            setState(() => _isLoading = false);
            return; // Stop if referral code is invalid
          }
        }

        // Proceed with verification regardless of referral code
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
                : null, // Send null if empty
          },
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);

        final errorMessage = e.toString().contains('blocked')
            ? 'This number prefix is temporarily blocked. Please try a different number.'
            : 'Failed to send code: $e';

        SnackBarUtils.showError(context, errorMessage);
      }
    } else {
      setState(() => _isLoading = false);
      SnackBarUtils.showWarning(context, 'Please enter a valid phone number');
    }
  }

  void _authenticateUser() async {
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

        // if (response != null) {
        //   SnackBarUtils.showSuccess(navigatorKey.currentContext!, 'Success');
        //   Navigator.pushNamedAndRemoveUntil(
        //     navigatorKey.currentContext!,
        //     '/',
        //     (route) => false,
        //   );
        // } else {
        //   SnackBarUtils.showWarning(navigatorKey.currentContext!, 'Warning');
        // }
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

  void _registerInstant() async {
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
        final response = await authService.registerOrLoginUser(
          phone?.completeNumber ?? '',
        );

        if (response != null) {
          SnackBarUtils.showSuccess(navigatorKey.currentContext!, 'Success');
          Navigator.pushNamedAndRemoveUntil(
            navigatorKey.currentContext!,
            '/',
            (route) => false,
          );
        } else {
          SnackBarUtils.showWarning(navigatorKey.currentContext!, 'Warming');
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _error = e.toString();
        });

        logger.severe('Error $_error');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    String exampleNumber = getExampleNumber(selectedCountry);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: myAppBar(title: 'Get Started'),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Text("Mobile"),
              SizedBox(height: 20),
              IntlPhoneField(
                decoration: inputDecoration(
                  getExampleNumber(selectedCountry),
                  labelText: 'Phone Number',
                ),
                enabled: !_isLoading,
                initialCountryCode: 'PH',
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    String newText = newValue.text;

                    // For Philippines only, remove leading zero
                    if (selectedCountry == 'PH' && newText.startsWith('0')) {
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
                onChanged: (phone) {
                  // Process the number to remove leading zero
                  String processedNumber = phone.number;
                  if (selectedCountry == 'PH' &&
                      processedNumber.startsWith('0')) {
                    processedNumber = processedNumber.substring(1);
                  }

                  // Create a new phone object with processed number
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
                    processedNumber = processedNumber.substring(1);
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

              const SizedBox(height: 16),

              TextFormField(
                controller: _referralCodeController,
                decoration: inputDecoration(
                  'MANGO25',
                  labelText: 'Referral Code (Optional)',
                ),
                textCapitalization: TextCapitalization.words,
                inputFormatters: [
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    return TextEditingValue(
                      text: newValue.text.toUpperCase(),
                      selection: newValue.selection,
                    );
                  }),
                ],
                enabled: !_isLoading,
                validator: (value) {
                  // Since it's optional, only validate if user entered something
                  if (value == null || value.isEmpty) {
                    return null; // No error for empty optional field
                  }

                  // Remove any spaces and check length
                  final cleanedValue = value.trim();

                  // Check minimum length
                  if (cleanedValue.length < 6) {
                    return 'Referral code must be at least 6 characters';
                  }

                  // Check maximum length
                  if (cleanedValue.length > 12) {
                    return 'Referral code cannot exceed 12 characters';
                  }

                  // Check format - only letters and numbers allowed
                  if (!RegExp(r'^[A-Z0-9]+$').hasMatch(cleanedValue)) {
                    return 'Referral code can only contain letters and numbers';
                  }

                  // No errors
                  return null;
                },
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(color: Colors.black),
                  children: [
                    TextSpan(text: "Send me a verification code through "),
                    TextSpan(
                      text: "SMS",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColorScheme.primaryColor,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _isLoading ? null : _authenticateUser,
                      child: _isLoading
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              "Next",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
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
