import 'package:flutter/material.dart';
import 'package:manong_application/api/manong_wallet_api_service.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/models/manong_wallet.dart';
import 'package:manong_application/models/manong_wallet_transaction.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/banks_utils.dart';
import 'package:manong_application/widgets/my_app_bar.dart';
import 'package:manong_application/widgets/success_dialog.dart';

class CashOutScreen extends StatefulWidget {
  const CashOutScreen({super.key});

  @override
  State<CashOutScreen> createState() => _CashOutScreenState();
}

class _CashOutScreenState extends State<CashOutScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  final FocusNode _accountNameFocusNode = FocusNode();
  final FocusNode _accountNumberFocusNode = FocusNode();

  double _selectedAmount = 0.0;
  String _selectedBank = '';
  bool _isButtonLoading = false;
  String? _error;

  // Minimum cash out amount
  static const double _minimumCashOutAmount = 100.0;

  // Preset amounts (all above minimum)
  final List<double> _presetAmounts = [300, 500, 1000, 2000];

  // Bank list including GCash and Maya
  final List<Map<String, dynamic>> _banks = BanksUtils().banks;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _accountNameController.dispose();
    _accountNumberController.dispose();
    _amountFocusNode.dispose();
    _accountNameFocusNode.dispose();
    _accountNumberFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkBalanceAndCashOut() async {
    try {
      // Validate minimum amount
      if (_selectedAmount < _minimumCashOutAmount) {
        _showError(
          'Minimum cash out amount is ₱${_minimumCashOutAmount.toStringAsFixed(2)}',
          showTryAgain: false,
        );
        return;
      }

      // First fetch the current wallet balance
      final walletResponse = await ManongWalletApiService()
          .fetchManongWalletService();

      if (walletResponse != null && walletResponse['data'] != null) {
        final walletData = ManongWallet.fromJson(walletResponse['data']);
        final currentBalance = walletData.balance;

        final totalDeduction = _selectedAmount;

        if (currentBalance < totalDeduction) {
          _showError(
            'Insufficient balance. Your current balance is ₱${currentBalance.toStringAsFixed(2)}, but you need ₱${totalDeduction.toStringAsFixed(2)} including service fee.',
            showTryAgain: false,
          );
          return;
        }

        // If balance is sufficient, proceed with cash out
        await _submitCashOut();
      } else {
        _showError(
          'Unable to fetch your wallet balance. Please try again.',
          showTryAgain: true,
        );
      }
    } catch (e) {
      _showError(
        'Failed to check balance: ${e.toString()}',
        showTryAgain: true,
      );
    }
  }

  Future<void> _submitCashOut() async {
    setState(() {
      _isButtonLoading = true;
      _error = null;
    });

    try {
      // Validate all fields
      if (_accountNameController.text.isEmpty) {
        throw Exception('Please enter account name');
      }

      if (_accountNumberController.text.isEmpty) {
        throw Exception('Please enter account number');
      }

      if (_selectedBank.isEmpty) {
        throw Exception('Please select a bank or e-wallet');
      }

      // Find the selected bank to get both name and code
      final selectedBank = _banks.firstWhere(
        (bank) => bank['id'] == _selectedBank,
        orElse: () => _banks[0],
      );

      final response = await ManongWalletApiService().cashOutManongWallet(
        amount: _selectedAmount,
        bankCode: selectedBank['code'] as String, // Send bank code
        bankName: selectedBank['name'] as String, // Send bank name
        accountName: _accountNameController.text,
        accountNumber:
            int.tryParse(_accountNumberController.text) ??
            0, // Send account number
      );

      if (response != null && response['data'] != null) {
        final data = ManongWalletTransaction.fromJson(response['data']);

        // Show success dialog
        _showSuccessDialog();
      } else {
        throw Exception('No response received from server');
      }
    } catch (e) {
      if (!mounted) return;

      // Extract the actual error message
      String errorMessage = e.toString();

      // Remove the "Exception: " prefix if it exists
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }

      // Check for specific error patterns and provide user-friendly messages
      if (errorMessage.contains('Insufficient balance')) {
        // The error already contains the message we want to show
        _showError(errorMessage, showTryAgain: false);
      } else if (errorMessage.contains('502') ||
          errorMessage.contains('Bad Gateway')) {
        // Handle Bad Gateway errors
        _showError(
          'Service temporarily unavailable. Please try again later.',
          showTryAgain: true,
        );
      } else {
        // For other errors, show the message
        _showError(
          'Failed to process cash out: $errorMessage',
          showTryAgain: true,
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

  void _onAmountChanged() {
    final text = _amountController.text.replaceAll(',', '');
    if (text.isNotEmpty) {
      final amount = double.tryParse(text) ?? 0.0;
      setState(() {
        _selectedAmount = amount;
      });
    }
  }

  void _selectPresetAmount(double amount) {
    setState(() {
      _selectedAmount = amount;
      _amountController.text = amount.toStringAsFixed(0);
    });
  }

  void _selectBank(String bankId) {
    setState(() {
      _selectedBank = bankId;
    });
  }

  Future<void> _processCashOut() async {
    if (_selectedAmount < _minimumCashOutAmount) {
      _showError(
        'Minimum cash out amount is ₱${_minimumCashOutAmount.toStringAsFixed(2)}',
        showTryAgain: false,
      );
      return;
    }

    if (_accountNameController.text.isEmpty) {
      _showError('Please enter account name', showTryAgain: false);
      return;
    }

    if (_accountNumberController.text.isEmpty) {
      _showError('Please enter account number', showTryAgain: false);
      return;
    }

    if (_selectedBank.isEmpty) {
      _showError('Please select a bank or e-wallet', showTryAgain: false);
      return;
    }

    await _checkBalanceAndCashOut();
  }

  void _showError(String message, {bool showTryAgain = false}) {
    // Clean up the error message for better display
    String displayMessage = message;

    // Remove any JSON formatting or technical details for user-friendly display
    if (displayMessage.contains('{"message":')) {
      try {
        final jsonMatch = RegExp(
          r'\{"message":"([^"]+)"',
        ).firstMatch(displayMessage);
        if (jsonMatch != null && jsonMatch.groupCount >= 1) {
          displayMessage = jsonMatch.group(1)!;
        }
      } catch (e) {
        // Keep original message if parsing fails
      }
    }

    // Remove HTML tags if present
    displayMessage = displayMessage.replaceAll(RegExp(r'<[^>]*>'), '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'Cash Out Error',
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
            Text(displayMessage),
            SizedBox(height: 16),
            if (showTryAgain)
              Text(
                'Please check your internet connection and try again.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
          if (showTryAgain)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorScheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                _processCashOut();
              },
              child: Text('Try Again'),
            ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showSuccessDialog() {
    final selectedBank = _banks.firstWhere(
      (bank) => bank['id'] == _selectedBank,
      orElse: () => _banks[0],
    );

    // Create custom content for bank details
    final customContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bank/EWallet info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (selectedBank['color'] as Color).withOpacity(0.1),
                ),
                child: Icon(
                  selectedBank['icon'] as IconData,
                  color: selectedBank['color'] as Color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                selectedBank['name'] as String,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColorScheme.primaryDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Account details
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                _accountNameController.text,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColorScheme.primaryDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _accountNumberController.text,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );

    // Show the reusable success dialog
    showSuccessDialog(
      context: context,
      title: 'Cash Out Requested!',
      subtitle: '₱${_selectedAmount.toStringAsFixed(2)} cash out initiated',
      message: 'Your cash out request has been submitted successfully.',
      actionButtonText: 'Done',
      secondaryButtonText: 'Close',
      customContent: customContent,
      onActionPressed: () {
        Navigator.of(context).pop(); // Close dialog
        Navigator.of(context).pop(); // Go back to previous screen
      },
      onSecondaryPressed: () => Navigator.of(context).pop(),
      icon: Icons.check,
      iconColor: Colors.white,
    );
  }

  Widget _buildAmountInput() {
    final isBelowMinimum =
        _selectedAmount > 0 && _selectedAmount < _minimumCashOutAmount;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Amount to Cash Out',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColorScheme.primaryDark,
                  ),
                ),
                Text(
                  'Min: ₱${_minimumCashOutAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Amount Input Field
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isBelowMinimum
                      ? Colors.orange
                      : (_amountFocusNode.hasFocus
                            ? AppColorScheme.primaryColor
                            : Colors.grey[300]!),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[50],
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '₱',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColorScheme.primaryDark,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      focusNode: _amountFocusNode,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '0.00',
                        hintStyle: TextStyle(fontSize: 24, color: Colors.grey),
                      ),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColorScheme.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Minimum amount warning
            if (isBelowMinimum)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.orange),
                    SizedBox(width: 4),
                    Text(
                      'Minimum amount is ₱${_minimumCashOutAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // Preset Amounts
            Text(
              'Quick Select',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),

            // Preset Amount Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.5,
              ),
              itemCount: _presetAmounts.length,
              itemBuilder: (context, index) {
                final amount = _presetAmounts[index];
                final isSelected = _selectedAmount == amount;

                return GestureDetector(
                  onTap: () => _selectPresetAmount(amount),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColorScheme.primaryColor.withOpacity(0.1)
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColorScheme.primaryColor
                            : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '₱${amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? AppColorScheme.primaryColor
                              : AppColorScheme.primaryDark,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountDetails() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColorScheme.primaryDark,
              ),
            ),
            const SizedBox(height: 16),

            // Account Name
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Name',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _accountNameFocusNode.hasFocus
                          ? AppColorScheme.primaryColor
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[50],
                  ),
                  child: TextField(
                    controller: _accountNameController,
                    focusNode: _accountNameFocusNode,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                      hintText: 'Enter account name (e.g., John Doe)',
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColorScheme.primaryDark,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Account Number
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Number',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _accountNumberFocusNode.hasFocus
                          ? AppColorScheme.primaryColor
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[50],
                  ),
                  child: TextField(
                    controller: _accountNumberController,
                    focusNode: _accountNumberFocusNode,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                      hintText: 'Enter account number',
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColorScheme.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankSelection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Bank or E-Wallet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColorScheme.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose where to transfer your funds',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            // Digital Wallets Section
            if (_banks.any((bank) => bank['type'] == 'digital_wallet'))
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'E-Wallets',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._banks
                      .where((bank) => bank['type'] == 'digital_wallet')
                      .map((bank) => _buildBankItem(bank)),
                  const SizedBox(height: 16),
                ],
              ),

            // Banks Section
            if (_banks.any((bank) => bank['type'] == 'bank'))
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Traditional Banks',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._banks
                      .where((bank) => bank['type'] == 'bank')
                      .map((bank) => _buildBankItem(bank)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankItem(Map<String, dynamic> bank) {
    final isSelected = _selectedBank == bank['id'];

    return GestureDetector(
      onTap: () => _selectBank(bank['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColorScheme.primaryColor.withOpacity(0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
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
                color: (bank['color'] as Color).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                bank['icon'] as IconData,
                color: bank['color'] as Color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bank['name'] as String,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColorScheme.primaryDark,
                    ),
                  ),
                  if (bank['code'] != null)
                    Text(
                      bank['code'] as String,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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

  Widget _buildSummary() {
    if (_selectedAmount <= 0) return const SizedBox();

    final serviceFee = _selectedAmount * 0.015; // 1.5% service fee
    final totalDeduction = _selectedAmount + serviceFee;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColorScheme.primaryDark,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cash out amount:',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                Text(
                  '₱${_selectedAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColorScheme.primaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Service fee (1.5%):',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                Text(
                  '₱${serviceFee.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),

            const Divider(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total deduction:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColorScheme.primaryDark,
                  ),
                ),
                Text(
                  '₱${totalDeduction.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColorScheme.primaryColor,
                  ),
                ),
              ],
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
      appBar: myAppBar(title: 'Cash Out'),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Hero/Info Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColorScheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: AppColorScheme.primaryColor,
                        size: 40,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Withdraw Funds',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColorScheme.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Minimum cash out: ₱${_minimumCashOutAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            Text(
                              'Transfer money from your ManongWallet to your bank or e-wallet',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Amount Input
                _buildAmountInput(),

                const SizedBox(height: 24),

                // Account Details
                _buildAccountDetails(),

                const SizedBox(height: 24),

                // Bank Selection (including GCash and Maya)
                _buildBankSelection(),

                const SizedBox(height: 24),

                // Summary
                _buildSummary(),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),

      // Bottom Action Button
      bottomNavigationBar: Transform.translate(
        offset: Offset(0.0, -MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: ElevatedButton(
              onPressed: _isButtonLoading ? null : _processCashOut,
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
                        Icon(Icons.arrow_forward, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Request Cash Out',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
