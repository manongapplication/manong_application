import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/payment_method_api_service.dart';
import 'package:manong_application/api/user_payment_method_api_service.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/models/user_payment_method.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/card_number_input_formatter.dart';
import 'package:manong_application/utils/expiration_date_text_input_formatter.dart';
import 'package:manong_application/utils/snackbar_utils.dart';
import 'package:manong_application/widgets/error_state_widget.dart';
import 'package:manong_application/widgets/input_decorations.dart';
import 'package:manong_application/widgets/my_app_bar.dart';

class CardAddPaymentMethodScreen extends StatefulWidget {
  const CardAddPaymentMethodScreen({super.key});
  @override
  State<CardAddPaymentMethodScreen> createState() =>
      _CardAddPaymentMethodScreenState();
}

class _CardAddPaymentMethodScreenState
    extends State<CardAddPaymentMethodScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expController = TextEditingController();
  final TextEditingController _cvcController = TextEditingController();
  final TextEditingController _cardHolderNameController =
      TextEditingController();

  bool _isLoading = false;
  bool _isButtonLoading = false;
  String? _error;
  List<UserPaymentMethod> _userPaymentMethod = [];

  late UserPaymentMethodApiService userPaymentMethodApiService;

  final Logger logger = Logger('CardAddPaymentMethodScreen');

  final Map<String, String> _fieldMap = {
    'details.exp_year': 'Expiration year',
    'details.exp_month': 'Expiration month',
    'details.number': 'Card number',
    'details.billingEmail': 'Email',
    'details.cvc': 'CVC',
    'details.cardHolderName': 'Card holder name',
  };

  String _formatErrorMessage(String message) {
    String formatted = message;

    _fieldMap.forEach((key, value) {
      if (formatted.contains(key)) {
        formatted = formatted.replaceAll(key, value);
      }
    });

    return formatted;
  }

  @override
  void initState() {
    super.initState();
    initializeComponents();
    _fetchUserPaymentCards();
  }

  void initializeComponents() {
    userPaymentMethodApiService = UserPaymentMethodApiService();
  }

  Future<void> _fetchUserPaymentCards() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await userPaymentMethodApiService
          .fetchUserPaymentMethods();

      if (!mounted) return;

      final data = response ?? [];

      final parsedResponse = data
          .map(
            (json) => UserPaymentMethod.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      setState(() {
        _isLoading = false;
        _error = null;
        _userPaymentMethod = parsedResponse;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString();
      });

      logger.severe('Faild fetching user payment methods $_error');
    }
  }

  List<UserPaymentMethod> _getFilteredUserPaymentMethod() {
    List<UserPaymentMethod>? filtered = _userPaymentMethod
        .where((pm) => pm.paymentMethod.code == 'card')
        .toList();

    filtered.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMicrosecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMicrosecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return filtered;
  }

  Future<void> _goAddCardPayment() async {
    final result = await Navigator.pushNamed(
      navigatorKey.currentContext!,
      '/add-card',
    );

    if (result == true) {
      _fetchUserPaymentCards();
    }
  }

  Future<void> _saveCardAsDefault(String paymentMethodIdOnGateway) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await userPaymentMethodApiService.saveCardAsDefault(
        paymentMethodIdOnGateway,
      );

      if (response != null && response['message'] != null) {
        SnackBarUtils.showInfo(
          navigatorKey.currentContext!,
          response['message'] ?? '',
        );

        _fetchUserPaymentCards();

        Navigator.pop(navigatorKey.currentContext!);
      } else {
        SnackBarUtils.showInfo(
          navigatorKey.currentContext!,
          'Failed setting the card as default. Please try again later.',
        );
      }
    } catch (e) {
      if (!mounted) {}
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
      SnackBarUtils.showInfo(
        navigatorKey.currentContext!,
        'Errror setting the card as default $_error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildUserPaymentMethodList(List<UserPaymentMethod> data) {
    return RefreshIndicator(
      color: AppColorScheme.primaryColor,
      onRefresh: _fetchUserPaymentCards,
      child: Scrollbar(
        child: ListView.builder(
          itemCount: data.length + 1,
          physics: const AlwaysScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            if (index == data.length) {
              return Container(
                margin: const EdgeInsets.only(top: 24),
                child: InkWell(
                  onTap: _goAddCardPayment,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Add Card',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.add_circle, color: Colors.grey.shade600),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            UserPaymentMethod uPM = data[index];

            return Container(
              padding: const EdgeInsets.only(top: 12),
              child: InkWell(
                onTap: () => uPM.paymentMethodIdOnGateway != null
                    ? _saveCardAsDefault(uPM.paymentMethodIdOnGateway!)
                    : null,
                child: ListTile(
                  leading: Icon(Icons.credit_card),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('**** **** **** ${uPM.last4 ?? ""}'),
                      Text(uPM.cardHolderName ?? ""),
                    ],
                  ),
                  trailing: Column(
                    spacing: 4,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (uPM.isDefault)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade300,
                          ),
                          child: Text('default'),
                        ),
                      GestureDetector(
                        onTap: () {
                          if (uPM.paymentMethodIdOnGateway != null) {
                            showAreYouSureDialog(
                              navigatorKey.currentContext!,
                              () => _deleteCard(uPM.paymentMethodIdOnGateway!),
                            );
                          }
                        },
                        child: Icon(Icons.delete),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardForm() {
    if (_getFilteredUserPaymentMethod().isNotEmpty) {
      final filteredUserPaymentMethod = _getFilteredUserPaymentMethod();
      return Container(
        margin: const EdgeInsets.only(top: 24),
        padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
        child: _buildUserPaymentMethodList(filteredUserPaymentMethod),
      );
    }

    return Padding(
      padding: EdgeInsets.all(18),
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            decoration: inputDecoration(
              '',
              labelText: 'Email',
              labelStyle: TextStyle(color: Colors.black),
              floatingLabelBehavior: FloatingLabelBehavior.always,
            ),
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _cardNumberController,
            decoration: inputDecoration('Card Number'),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              CardNumberInputFormatter(),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // TextField inputFormatters for MM/YY
              Expanded(
                child: TextFormField(
                  controller: _expController,
                  decoration: inputDecoration('MM/YY'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                    ExpirationDateTextInputFormatter(),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: TextFormField(
                  controller: _cvcController,
                  decoration: inputDecoration(
                    'CVC',
                    suffixIcon: Icon(Icons.credit_card),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          TextFormField(
            controller: _cardHolderNameController,
            decoration: inputDecoration(
              '',
              labelText: 'Name of the card holder',
              labelStyle: TextStyle(color: Colors.black),
              floatingLabelBehavior: FloatingLabelBehavior.always,
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorScheme.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: !_isButtonLoading ? _submitCard : null,
              child: _isButtonLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildState() {
    if (_error != null) {
      return ErrorStateWidget(
        errorText: _error!,
        onPressed: _fetchUserPaymentCards,
      );
    }

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColorScheme.primaryColor),
      );
    }

    return _buildCardForm();
  }

  Future<void> showAreYouSureDialog(
    BuildContext context,
    VoidCallback onConfirm,
  ) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Are you sure?'),
          content: const Text('Do you really want to delete this card?'),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text("Delete"),
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCard(String paymentMethodIdOnGateway) async {
    setState(() {
      _isButtonLoading = true;
      _error = null;
    });

    try {
      final response = await userPaymentMethodApiService.deleteUserPaymentCard(
        paymentMethodIdOnGateway,
      );

      if (response != null) {
        SnackBarUtils.showInfo(navigatorKey.currentContext!, response);
        _fetchUserPaymentCards();
      } else {
        SnackBarUtils.showInfo(
          navigatorKey.currentContext!,
          'Failed deleting payment card. Please try again.',
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      logger.severe('Error deleting payment card $_error');
    } finally {
      if (mounted) {
        setState(() {
          _isButtonLoading = false;
        });
      }
    }
  }

  Future<void> _submitCard() async {
    setState(() {
      _isButtonLoading = true;
    });

    try {
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
          final rawMessage = firstError['detail'] ?? 'Something went wrong';

          final userFriendlyMessage = _formatErrorMessage(rawMessage);

          SnackBarUtils.showError(
            navigatorKey.currentContext!,
            userFriendlyMessage,
          );
          return;
        } else {
          SnackBarUtils.showInfo(
            navigatorKey.currentContext!,
            response['message'].toString(),
          );

          if (response['data']['id'] != null) {
            Navigator.pop(navigatorKey.currentContext!);
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
      appBar: myAppBar(title: 'Add a credit or debit card'),
      body: Form(child: _buildState()),
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
