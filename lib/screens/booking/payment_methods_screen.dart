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
  bool _isButtonLoading = false;
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _getDefaultPaymentMethod() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await userPaymentMethodApiService
          .fetchDefaultUserPaymentMethod();

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
        });
      }
    }
  }

  void _onPaymentMethodSelected(int index) {
    setState(() {
      _selectedIndex = index;
      _selectedPaymentName = _paymentMethods?[index].name;
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
        SnackBarUtils.showInfo(context, response['message'] ?? '');
        Navigator.pop(context, {
          'id': _selectedIndex,
          'name': _selectedPaymentName,
        });
      } else {
        SnackBarUtils.showWarning(context, 'Failed to save payment method!');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isButtonLoading = false;
      });
      logger.severe('Error saving user payment method $e');
    }
  }

  Future<void> _onConfirm() async {
    if (_selectedIndex == null) {
      SnackBarUtils.showWarning(context, 'Please select a payment method');
      return;
    }

    final selectedMethod = _paymentMethods![_selectedIndex!];

    switch (selectedMethod.code.toLowerCase()) {
      case 'card':
      case 'gcash':
      case 'cash':
      case 'paymaya':
        _saveUserPaymentMethod();
        break;
      default:
        SnackBarUtils.showWarning(context, 'Payment method not supported.');
    }
  }

  Widget _buildPaymentMethodItem({
    required PaymentMethod method,
    required int index,
    required bool isSelected,
  }) {
    // Get icon and color based on payment method code
    IconData icon;
    Color color;

    switch (method.code.toLowerCase()) {
      case 'gcash':
        icon = Icons.phone_android;
        color = const Color(0xFF0066B3);
        break;
      case 'paymaya':
        icon = Icons.credit_card;
        color = const Color(0xFF00B5B0);
        break;
      case 'card':
        icon = Icons.credit_card;
        color = const Color(0xFF3A3A3A);
        break;
      case 'cash':
        icon = Icons.money;
        color = Colors.green;
        break;
      default:
        icon = Icons.payment;
        color = AppColorScheme.primaryColor;
    }

    return GestureDetector(
      onTap: () => _onPaymentMethodSelected(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColorScheme.primaryColor.withOpacity(0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColorScheme.primaryColor : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColorScheme.primaryDark,
                    ),
                  ),
                ],
              ),
            ),

            // Selection indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColorScheme.primaryColor
                      : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColorScheme.primaryColor,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodItems() {
    if (_paymentMethods == null || _paymentMethods!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No payment methods available',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _paymentMethods!.length,
      itemBuilder: (context, index) {
        final method = _paymentMethods![index];
        final isSelected = _selectedIndex == index;

        return _buildPaymentMethodItem(
          method: method,
          index: index,
          isSelected: isSelected,
        );
      },
    );
  }

  Widget _buildState() {
    if (_error != null) {
      return ErrorStateWidget(
        errorText: 'Error fetching payment methods. Please try again.',
        onPressed: _fetchPaymentMethods,
      );
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColorScheme.primaryColor),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColorScheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.payment,
                  color: AppColorScheme.primaryColor,
                  size: 40,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Payment Method',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColorScheme.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose how you want to pay for services',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Payment Methods List
          _buildPaymentMethodItems(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey[200]!)),
        ),
        child: ElevatedButton(
          onPressed: _isButtonLoading || _selectedIndex == null
              ? null
              : _onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColorScheme.primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
          ),
          child: _isButtonLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Confirm Payment Method',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorScheme.backgroundGrey,
      appBar: myAppBar(title: 'Payment Methods'),
      body: SafeArea(
        child: Padding(padding: const EdgeInsets.all(16), child: _buildState()),
      ),
      bottomNavigationBar: _buildConfirmButton(),
    );
  }
}
