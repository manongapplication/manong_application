import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/manong_wallet_api_service.dart';
import 'package:manong_application/api/manong_wallet_transaction_api_service.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/models/manong.dart';
import 'package:manong_application/models/manong_wallet_transaction.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/snackbar_utils.dart';
import 'package:manong_application/widgets/my_app_bar.dart';

class PayJobFeesScreen extends StatefulWidget {
  const PayJobFeesScreen({super.key});

  @override
  State<PayJobFeesScreen> createState() => _PayJobFeesScreenState();
}

class _PayJobFeesScreenState extends State<PayJobFeesScreen> {
  final logger = Logger('PayJobFeesScreen');
  bool _isLoading = false;
  bool _isButtonLoading = false;
  String? _error;
  ManongWallet? _wallet;
  List<ManongWalletTransaction>? _pendingJobFees;
  String _selectedPaymentMethod = '';
  bool _selectAll = true;
  Map<String, bool> _selectedFees = {};

  // Animation controllers
  bool _toggledPaymentMethodContainer = false;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _paymentMethodCardKey = GlobalKey();

  // Payment methods - Wallet balance REMOVED
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'gcash',
      'name': 'GCash',
      'icon': Icons.phone_android,
      'color': const Color(0xFF0066B3),
      'description': 'Pay using GCash',
    },
    {
      'id': 'paymaya',
      'name': 'Maya',
      'icon': Icons.credit_card,
      'color': const Color(0xFF00B5B0),
      'description': 'Pay using Maya',
    },
    // Wallet balance removed
  ];

  @override
  void initState() {
    super.initState();
    _fetchManongWallet();
  }

  Future<void> _fetchManongWallet() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ManongWalletApiService()
          .fetchManongWalletService();

      if (response != null) {
        final data = ManongWallet.fromJson(response['data']);

        setState(() {
          _wallet = data;
        });
        if (_wallet != null) {
          await _fetchPendingJobFees();
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
      logger.severe('Error fetching manong wallet $_error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchPendingJobFees() async {
    if (_wallet == null) return;
    try {
      final response = await ManongWalletTransactionApiService()
          .fetchPendingJobFees(walletId: _wallet!.id);

      if (response != null && response['data'] != null) {
        logger.info('The ${response['data']}');
        final List<dynamic> data = response['data'];
        setState(() {
          _pendingJobFees = data
              .map((json) => ManongWalletTransaction.fromJson(json))
              .toList();

          _initializeSelection();
        });
      } else {
        setState(() {
          _pendingJobFees = [];
        });
      }
    } catch (e) {
      logger.severe('Error fetching pending job fees ${e.toString()}');
      setState(() {
        _pendingJobFees = [];
      });
      rethrow;
    }
  }

  void _initializeSelection() {
    if (_pendingJobFees != null) {
      setState(() {
        _selectedFees = {
          for (var fee in _pendingJobFees!) fee.id.toString(): true,
        };
        _selectAll = true;
      });
    }
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      for (var key in _selectedFees.keys) {
        _selectedFees[key] = _selectAll;
      }
    });
  }

  void _toggleFeeSelection(String feeId, bool? value) {
    setState(() {
      _selectedFees[feeId] = value ?? false;
      _selectAll =
          _selectedFees.isNotEmpty &&
          _selectedFees.values.every((selected) => selected);
    });
  }

  // Animation method for payment method card
  void togglePaymentMethodCard() {
    setState(() {
      _toggledPaymentMethodContainer = true;
    });

    final context = _paymentMethodCardKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
      );
    }

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _toggledPaymentMethodContainer = false;
      });
    });
  }

  List<int> get _selectedFeeIds {
    return _selectedFees.entries
        .where((entry) => entry.value)
        .map((entry) => int.parse(entry.key))
        .toList();
  }

  double get _selectedTotalAmount {
    if (_pendingJobFees == null) return 0;

    return _pendingJobFees!
        .where((fee) => _selectedFees[fee.id.toString()] == true)
        .fold<double>(0, (sum, fee) => sum + (fee.amount?.abs() ?? 0));
  }

  int get _selectedCount {
    if (_pendingJobFees == null) return 0;
    return _pendingJobFees!
        .where((fee) => _selectedFees[fee.id.toString()] == true)
        .length;
  }

  double get _totalAmount {
    if (_pendingJobFees == null) return 0;
    return _pendingJobFees!.fold<double>(
      0,
      (sum, tx) => sum + (tx.amount?.abs() ?? 0),
    );
  }

  void _selectPaymentMethod(String methodId) {
    setState(() {
      _selectedPaymentMethod = methodId;
    });
  }

  Future<void> _processPayment() async {
    // Validate wallet exists
    if (_wallet == null) {
      SnackBarUtils.showError(
        navigatorKey.currentContext!,
        'Wallet not found. Please try again.',
      );
      return;
    }

    // Validate selections
    if (_selectedCount == 0) {
      SnackBarUtils.showError(
        navigatorKey.currentContext!,
        'Please select at least one job fee to pay',
      );
      return;
    }

    if (_selectedPaymentMethod.isEmpty) {
      SnackBarUtils.showError(
        navigatorKey.currentContext!,
        'Please select a payment method',
      );

      // Animate and scroll to payment method section
      togglePaymentMethodCard();
      return;
    }

    setState(() {
      _isButtonLoading = true;
    });

    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => _buildConfirmationDialog(),
      );

      if (confirm != true) {
        setState(() {
          _isButtonLoading = false;
        });
        return;
      }

      final response = await ManongWalletTransactionApiService()
          .payPendingJobFees(
            walletId: _wallet!.id,
            ids: _selectedFeeIds,
            provider: _selectedPaymentMethod,
          );

      if (!mounted) return;

      logger.info('Payment response: $response');

      // Check if response contains error
      if (response != null && response['error'] != null) {
        // Handle error response
        SnackBarUtils.showError(
          navigatorKey.currentContext!,
          response['message'] ?? 'Payment failed',
        );
        return;
      }

      // Check for redirect URL
      if (response != null &&
          response['data'] != null &&
          response['data']['redirectUrl'] != null) {
        final authUrl = response['data']['redirectUrl'] as String;
        final returnUrl = response['data']['returnUrl'] as String;
        logger.info('Redirect URL: $authUrl');

        final result = await Navigator.pushNamed(
          navigatorKey.currentContext!,
          '/job-fees-payment-redirect',
          arguments: {
            'jobFeeIds': _selectedFeeIds,
            'redirectUrl': authUrl,
            'returnUrl': returnUrl,
          },
        );

        if (result != null && result is Map) {
          final success = result['success'] as bool? ?? false;
          final navigateTo = result['navigateTo'] as String?;

          if (success && navigateTo == 'cash-out') {
            Navigator.pop(navigatorKey.currentContext!, {
              'success': true,
              'navigateTo': 'cash-out',
            });
          }
        }
      } else {
        logger.warning('Unexpected response format: $response');
        SnackBarUtils.showError(
          navigatorKey.currentContext!,
          response?['message'] ?? 'Payment failed. Please try again.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      logger.severe('Error processing payment', e);

      // Check if error message contains the backend error
      final errorMessage = e.toString();
      if (errorMessage.contains('Total amount must be at least 1.00 PHP')) {
        SnackBarUtils.showError(
          navigatorKey.currentContext!,
          'Total amount must be at least ₱1.00',
        );
      } else {
        SnackBarUtils.showError(
          navigatorKey.currentContext!,
          'An error occurred: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isButtonLoading = false;
        });
      }
    }
  }

  Widget _buildConfirmationDialog() {
    final paymentMethod = _paymentMethods.firstWhere(
      (method) => method['id'] == _selectedPaymentMethod,
      orElse: () => _paymentMethods[0],
    );

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.payment, color: AppColorScheme.primaryColor, size: 24),
          const SizedBox(width: 8),
          Text(
            'Confirm Payment',
            style: TextStyle(
              color: AppColorScheme.primaryDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Selected Fees:',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    Text(
                      '$_selectedCount item${_selectedCount == 1 ? '' : 's'}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '₱${_selectedTotalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColorScheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (paymentMethod['color'] as Color).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  paymentMethod['icon'] as IconData,
                  color: paymentMethod['color'] as Color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Method',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      paymentMethod['name'],
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColorScheme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('CONFIRM PAYMENT'),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColorScheme.primaryColor,
            AppColorScheme.primaryColor.withOpacity(0.8),
            AppColorScheme.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColorScheme.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Pending Fees',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            '₱${_totalAmount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_pendingJobFees?.length ?? 0} pending ${(_pendingJobFees?.length ?? 0) == 1 ? 'fee' : 'fees'}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              if (_selectedCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_selectedCount selected',
                    style: TextStyle(
                      color: AppColorScheme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Job Fees Receipt',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColorScheme.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Reference: #${DateTime.now().millisecondsSinceEpoch.toString().substring(0, 10)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColorScheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.receipt_long,
                  color: AppColorScheme.primaryColor,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _selectAll,
                onChanged: _toggleSelectAll,
                activeColor: AppColorScheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Select All',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColorScheme.primaryDark,
                ),
              ),
              const Spacer(),
              Text(
                'Total Selected: ₱${_selectedTotalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColorScheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeeItem(ManongWalletTransaction fee, int index) {
    final feeId = fee.id.toString();
    final isSelected = _selectedFees[feeId] ?? false;

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? AppColorScheme.primaryColor.withOpacity(0.02)
            : null,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (value) => _toggleFeeSelection(feeId, value),
              activeColor: AppColorScheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          fee.description ?? 'Job Fee #${fee.id}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColorScheme.primaryDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '₱${(fee.amount?.abs() ?? 0).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(fee.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Text(
                          'Pending',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (fee.metadata != null && fee.metadata!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Job #: ${fee.metadata!['jobId'] ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.month}/${date.day}/${date.year}';
  }

  Widget _buildPaymentMethods() {
    return AnimatedContainer(
      key: _paymentMethodCardKey,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: _toggledPaymentMethodContainer
            ? AppColorScheme.primaryLight
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _toggledPaymentMethodContainer
              ? AppColorScheme.primaryColor
              : Colors.grey.shade200,
          width: _toggledPaymentMethodContainer ? 2 : 1,
        ),
        boxShadow: _toggledPaymentMethodContainer
            ? [
                BoxShadow(
                  color: AppColorScheme.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.payment,
                  size: 20,
                  color: AppColorScheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Select Payment Method',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColorScheme.primaryDark,
                  ),
                ),
              ],
            ),
          ),
          ..._paymentMethods.map((method) {
            final isSelected = _selectedPaymentMethod == method['id'];
            return GestureDetector(
              onTap: () => _selectPaymentMethod(method['id']),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade100)),
                  color: isSelected
                      ? AppColorScheme.primaryColor.withOpacity(0.05)
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: (method['color'] as Color).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        method['icon'] as IconData,
                        color: method['color'] as Color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            method['name'],
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColorScheme.primaryDark,
                            ),
                          ),
                          Text(
                            method['description'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Radio<String>(
                      value: method['id'],
                      groupValue: _selectedPaymentMethod,
                      onChanged: (String? value) {
                        if (value != null) {
                          _selectPaymentMethod(value);
                        }
                      },
                      activeColor: AppColorScheme.primaryColor,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 60,
              color: Colors.green.shade300,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'All Caught Up!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColorScheme.primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You have no pending job fees',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorScheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('GO BACK'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Error Loading Data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColorScheme.primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Something went wrong',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorScheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: _fetchManongWallet,
            child: const Text('RETRY'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoadingState();
    if (_error != null) return _buildErrorState();
    if (_pendingJobFees == null || _pendingJobFees!.isEmpty) {
      return Scaffold(
        appBar: myAppBar(title: 'Pay Job Fees'),
        body: _buildEmptyState(),
      );
    }

    return Scaffold(
      appBar: myAppBar(title: 'Pay Job Fees'),
      body: Column(
        children: [
          // Summary Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildSummaryCard(),
          ),

          // Main Content
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Receipt Header
                  _buildReceiptHeader(),

                  // Fee List
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: Colors.grey.shade200),
                        right: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _pendingJobFees!.length,
                      separatorBuilder: (context, index) =>
                          Divider(height: 0, color: Colors.grey.shade200),
                      itemBuilder: (context, index) =>
                          _buildFeeItem(_pendingJobFees![index], index),
                    ),
                  ),

                  // Receipt Footer
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(12),
                      ),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Selected:',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        Text(
                          '₱${_selectedTotalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColorScheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Payment Methods with Animation
                  _buildPaymentMethods(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Action Button
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isButtonLoading || _selectedCount == 0
                ? null
                : _processPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorScheme.primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              disabledBackgroundColor: Colors.grey.shade300,
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
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.payment, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _selectedCount == 0
                            ? 'Select Fees to Pay'
                            : 'Pay ₱${_selectedTotalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
