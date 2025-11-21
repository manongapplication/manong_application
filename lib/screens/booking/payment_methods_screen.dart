import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/auth_service.dart';
import 'package:manong_application/api/payment_method_api_service.dart';
import 'package:manong_application/api/service_request_api_service.dart';
import 'package:manong_application/api/user_payment_method_api_service.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/models/app_user.dart';
import 'package:manong_application/models/payment_method.dart';
import 'package:manong_application/models/service_request.dart';
import 'package:manong_application/models/user_payment_method.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/snackbar_utils.dart';
import 'package:manong_application/widgets/error_state_widget.dart';
import 'package:manong_application/widgets/my_app_bar.dart';
import 'package:manong_application/widgets/selectable_icon_list.dart';

class PaymentMethodsScreen extends StatefulWidget {
  final int? selectedIndex;
  final bool? toUpdate;
  final ServiceRequest? serviceRequest;

  const PaymentMethodsScreen({
    super.key,
    this.selectedIndex,
    this.toUpdate,
    this.serviceRequest,
  });

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final Logger logger = Logger('PaymentMethodScreen');
  late PaymentMethodApiService paymentMethodApiService;
  late ServiceRequestApiService serviceRequestApiService;
  late UserPaymentMethodApiService userPaymentMethodApiService;
  List<PaymentMethod>? _paymentMethods;
  bool _isLoading = true;
  bool _isButtonLoading = true;
  String? _error;
  int? _selectedIndex;
  String? _selectedPaymentName;
  late bool? _toUpdate;
  late ServiceRequest? _serviceRequest;
  String? _userPaymentMethodLast4;
  AppUser? _user;

  @override
  void initState() {
    super.initState();
    _initializeComponents();
    _fetchPaymentMethods();
    _getDefaultPaymentMethod();
  }

  void _initializeComponents() {
    paymentMethodApiService = PaymentMethodApiService();
    serviceRequestApiService = ServiceRequestApiService();
    userPaymentMethodApiService = UserPaymentMethodApiService();
    _selectedIndex = widget.selectedIndex;
    _toUpdate = widget.toUpdate ?? false;
    _serviceRequest = widget.serviceRequest;
  }

  Future<void> _fetchPaymentMethods() async {
    setState(() {
      _isLoading = true;
      _isButtonLoading = true;
      _error = null;
    });

    try {
      final response = await paymentMethodApiService.fetchPaymentMethods();

      setState(() {
        _paymentMethods = response.isNotEmpty ? response : null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
      });

      logger.severe('An error occured $_error');
    } finally {
      if (mounted) {
        _isLoading = false;
        _isButtonLoading = false;
      }
    }
  }

  // Future<void> _getProfile() async {
  //   setState(() {
  //     _isButtonLoading = true;
  //   });
  //   try {
  //     final response = await AuthService().getMyProfile();

  //     if (!mounted) return;

  //     setState(() {
  //       _user = response;
  //     });
  //   } catch (e) {
  //     if (!mounted) return;
  //     setState(() {
  //       _error = e.toString();
  //     });
  //     logger.severe('Error getting profile $_error');
  //   } finally {
  //     if (mounted) {
  //       setState(() {
  //         _isButtonLoading = false;
  //       });
  //     }
  //   }
  // }

  Future<void> _getDefaultPaymentMethod() async {
    setState(() {
      _isLoading = true;
      _isButtonLoading = true;
      _error = null;
    });

    try {
      final response = await userPaymentMethodApiService
          .fetchDefaultUserPaymentMethod();

      setState(() {
        _isLoading = false;
        _isButtonLoading = false;
        _error = null;
      });

      if (response != null) {
        if (response['data']?['paymentMethod'] == null ||
            response['data'] == null) {
          return;
        }

        final userpaymentmethodPaymentmethod = PaymentMethod.fromJson(
          response['data']?['paymentMethod'],
        );

        final userPaymentMethod = UserPaymentMethod.fromJson(response['data']);

        final index = _paymentMethods?.indexWhere(
          (pm) => pm.id == userpaymentmethodPaymentmethod.id,
        );

        setState(() {
          _userPaymentMethodLast4 = userPaymentMethod.last4;
          if (_toUpdate == true) return;
          _selectedIndex = index;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
      });

      logger.severe('An error occured $_error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isButtonLoading = false;
        });
      }
    }
  }

  void _onPaymentMethodSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _saveUserPaymentMethod() async {
    setState(() {
      _isButtonLoading = true;
    });

    try {
      if (_selectedIndex == null || _paymentMethods == null) return;

      Map<String, dynamic>? response;

      if (_toUpdate == true) {
        if (_serviceRequest == null) return;

        response = await serviceRequestApiService.updatePaymentMethodId(
          _serviceRequest!.id!,
          _selectedIndex!,
        );
        await userPaymentMethodApiService.saveUserPaymentMethod(
          _selectedIndex!,
          _paymentMethods![_selectedIndex!].code,
        );
        logger.info('updatePaymentMethodId ${_selectedIndex! + 1}');
      } else {
        response = await userPaymentMethodApiService.saveUserPaymentMethod(
          _selectedIndex!,
          _paymentMethods![_selectedIndex!].code,
        );
        logger.info('saveUserPaymentMethod');
      }

      if (!mounted) return;

      setState(() {
        _isButtonLoading = false;
      });

      if (response != null) {
        SnackBarUtils.showInfo(
          navigatorKey.currentContext!,
          response['message'] ?? '',
        );
        Navigator.pop(navigatorKey.currentContext!, {
          'id': _selectedIndex,
          'name': _selectedPaymentName,
        });
      } else {
        SnackBarUtils.showWarning(
          navigatorKey.currentContext!,
          'Failed to save payment method!',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isButtonLoading = false;
      });
      logger.severe('Error saving user payment method $e');
    }
  }

  bool _checkProfileIfComplete() {
    logger.info('Checking profile started');
    if (_user == null) return false;
    logger.info('Checking profile');

    if (_user?.firstName == null ||
        _user?.lastName == null ||
        _user?.email == null) {
      SnackBarUtils.showWarning(
        navigatorKey.currentContext!,
        'Please setup your profile first',
      );
      Navigator.pushNamed(
        navigatorKey.currentContext!,
        '/edit-profile',
        arguments: {'destination': '/add-card'},
      );
      return false;
    }

    return true;
  }

  Future<void> _onConfirm() async {
    if (_selectedIndex == null) {
      SnackBarUtils.showWarning(
        navigatorKey.currentContext!,
        'Please select a payment method',
      );

      return;
    }

    final selectedMethod = _paymentMethods![_selectedIndex!];

    switch (selectedMethod.code.toLowerCase()) {
      case 'card':
        // await _getProfile();
        // await _getDefaultPaymentMethod();
        // if (!(_checkProfileIfComplete())) return;

        // logger.info('Card: $_userPaymentMethodLast4');
        // if (_userPaymentMethodLast4 == null) {
        //   SnackBarUtils.showWarning(
        //     navigatorKey.currentContext!,
        //     'Please add or select your payment card at the payment details.',
        //   );
        //   return;
        // }
        _saveUserPaymentMethod();
        break;
      case 'gcash':
        _saveUserPaymentMethod();
        break;
      case 'cash':
        _saveUserPaymentMethod();
        break;
      case 'paymaya':
        _saveUserPaymentMethod();
        break;
      default:
        SnackBarUtils.showWarning(
          navigatorKey.currentContext!,
          'Payment method not supported.',
        );
    }
  }

  Widget _buildPaymentMethodItems() {
    if (_paymentMethods == null) return const SizedBox.shrink();
    return SelectableIconList(
      selectedIndex: _selectedIndex,
      options: _paymentMethods != null
          ? _paymentMethods!
                .map(
                  (pm) => {
                    'name': pm.name,
                    'code': pm.code,
                    'icon': pm.code,
                    'onTap': () async {
                      _onPaymentMethodSelected(_paymentMethods!.indexOf(pm));
                      setState(() {
                        _selectedPaymentName = pm.name;
                      });

                      // if (pm.code == 'card') {
                      //   await _getProfile();
                      //   if (!(_checkProfileIfComplete())) return;
                      //   logger.info('Profile user $_user');
                      //   Navigator.pushNamed(
                      //     navigatorKey.currentContext!,
                      //     '/card-add-payment-method',
                      //   );
                      // }
                    },
                  },
                )
                .toList()
          : [],
      onRefresh: _fetchPaymentMethods,
    );
  }

  Widget _buildState() {
    if (_error != null) {
      return ErrorStateWidget(
        errorText: 'Error fetchig Payment methods. Please Try again.',
        onPressed: _fetchPaymentMethods,
      );
    }

    if (_isLoading == true) {
      return Center(
        child: CircularProgressIndicator(color: AppColorScheme.primaryColor),
      );
    }

    return _buildPaymentMethodItems();
  }

  Widget _buildConfirmButton() {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.only(left: 12, right: 12, bottom: 12, top: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.4),
              offset: Offset(0, -4),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorScheme.primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: !_isButtonLoading ? _onConfirm : null,
                child: _isButtonLoading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColorScheme.primaryColor,
                          ),
                        ),
                      )
                    : const Text(
                        "Confirm",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorScheme.backgroundGrey,
      appBar: myAppBar(title: 'Select a payment method'),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight:
                MediaQuery.of(navigatorKey.currentContext!).size.height -
                kToolbarHeight -
                MediaQuery.of(navigatorKey.currentContext!).padding.top -
                100,
          ),
          child: _buildState(),
        ),
      ),

      bottomNavigationBar: _buildConfirmButton(),
    );
  }
}
