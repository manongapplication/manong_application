import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/payment_method_api_service.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/models/manong.dart';
import 'package:manong_application/models/service_request.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/card_number_input_formatter.dart';
import 'package:manong_application/utils/expiration_date_text_input_formatter.dart';
import 'package:manong_application/utils/snackbar_utils.dart';

class AddCardPayment extends StatefulWidget {
  final String? proceed;
  final ServiceRequest? serviceRequest;
  final Manong? manong;
  final double? meters;
  const AddCardPayment({
    super.key,
    this.proceed,
    this.serviceRequest,
    this.manong,
    this.meters,
  });

  @override
  State<AddCardPayment> createState() => _AddCardPaymentState();
}

class _AddCardPaymentState extends State<AddCardPayment> {
  final _formKey = GlobalKey<FormState>();

  final Logger logger = Logger('AddCardPayment');
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expController = TextEditingController();
  final TextEditingController _cvcController = TextEditingController();
  final TextEditingController _cardHolderNameController =
      TextEditingController();

  bool _isButtonLoading = false;

  InputDecoration _inputDecoration(
    String hint, {
    Widget? suffixIcon,
    String? labelText,
    TextStyle? labelStyle,
    FloatingLabelBehavior? floatingLabelBehavior,
  }) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColorScheme.primaryColor,
          width: 2,
        ),
      ),
      suffixIcon: suffixIcon,
      labelText: labelText,
      labelStyle: labelStyle,
      floatingLabelBehavior: floatingLabelBehavior,
    );
  }

  Future<void> _submitCard() async {
    setState(() {
      _isButtonLoading = true;
    });

    try {
      if (!(_formKey.currentState!.validate())) {
        SnackBarUtils.showWarning(
          navigatorKey.currentContext!,
          'Invalid inputs!',
        );
        return;
      }

      final expParts = _expController.text.split('/');
      final expMonth = expParts[0];
      final expYear = expParts[1];

      final response = await PaymentMethodApiService().createCard(
        number: _cardNumberController.text.replaceAll(' ', ''),
        expMonth: expMonth,
        expYear: expYear,
        cvc: _cvcController.text,
        cardHolderName: _cardHolderNameController.text,
        email: _emailController.text,
        type: 'card',
      );

      if (response != null) {
        if (response['errors'] != null) {
          final errors = response['errors'] as List;
          final firstError = errors.first as Map<String, dynamic>;
          final message = firstError['detail'] ?? 'Something went wrong';

          SnackBarUtils.showError(navigatorKey.currentContext!, message);
          return;
        } else {
          SnackBarUtils.showInfo(
            navigatorKey.currentContext!,
            response['message'].toString(),
          );

          if (response['data']['id'] != null) {
            if (widget.proceed != null && widget.proceed == 'processing') {
              if (widget.serviceRequest == null || widget.manong == null) {
                return;
              }

              Navigator.pushNamed(
                navigatorKey.currentContext!,
                '/payment-processing',
                arguments: {
                  'serviceRequest': widget.serviceRequest,
                  'manong': widget.manong,
                  'meters': widget.meters,
                },
              );
              return;
            }

            Navigator.pop(navigatorKey.currentContext!, true);
          }
        }
      }
    } catch (e) {
      logger.severe(navigatorKey.currentContext!, 'Failed to save card: $e');
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
      appBar: AppBar(
        title: const Text("Add a credit or debit card"),
        backgroundColor: AppColorScheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: _inputDecoration(
                  '',
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: Colors.black),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                  if (!emailRegex.hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _cardNumberController,
                decoration: _inputDecoration('Card Number'),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CardNumberInputFormatter(),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please input the card number';
                  }

                  String cleanNumber = value.replaceAll(' ', '');

                  if (cleanNumber.length < 13 || cleanNumber.length > 19) {
                    return 'Invalid card number length';
                  }

                  if (!CardNumberInputFormatter().isValidCardNumber(
                    cleanNumber,
                  )) {
                    return 'Invalid card number';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expController,
                      decoration: _inputDecoration('MM/YY'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                        ExpirationDateTextInputFormatter(),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter expiration date';
                        }

                        // Remove slash if ExpirationDateTextInputFormatter adds it
                        String cleanValue = value.replaceAll('/', '');

                        if (cleanValue.length != 4) {
                          return 'Enter as MM/YY';
                        }

                        int month = int.parse(cleanValue.substring(0, 2));
                        int year = int.parse(cleanValue.substring(2, 4));

                        // Validate month
                        if (month < 1 || month > 12) {
                          return 'Invalid month';
                        }

                        // Convert YY to 20YY
                        int fourDigitYear = 2000 + year;

                        // Get current month/year
                        DateTime now = DateTime.now();
                        int currentYear = now.year;
                        int currentMonth = now.month;

                        // Expired check
                        if (fourDigitYear < currentYear ||
                            (fourDigitYear == currentYear &&
                                month < currentMonth)) {
                          return 'Card expired';
                        }

                        return null; // valid
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextFormField(
                      controller: _cvcController,
                      decoration: _inputDecoration(
                        'CVC',
                        suffixIcon: const Icon(Icons.credit_card),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter CVC';
                        }

                        if (value.length < 3 || value.length > 4) {
                          return 'CVC must be 3 or 4 digits';
                        }

                        return null; // valid
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              TextFormField(
                controller: _cardHolderNameController,
                decoration: _inputDecoration(
                  '',
                  labelText: 'Name of the card holder',
                  labelStyle: const TextStyle(color: Colors.black),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the card holder name';
                  }

                  // Only letters and spaces allowed
                  final nameRegex = RegExp(r'^[a-zA-Z ]+$');
                  if (!nameRegex.hasMatch(value.trim())) {
                    return 'Name can only contain letters';
                  }

                  // Require at least 2 words (first + last name)
                  if (value.trim().split(' ').length < 2) {
                    return 'Enter first and last name';
                  }

                  return null; // valid
                },
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorScheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: !_isButtonLoading ? _submitCard : null,
                  child: _isButtonLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _cardNumberController.dispose();
    _expController.dispose();
    _cvcController.dispose();
    _cardHolderNameController.dispose();
    super.dispose();
  }
}
