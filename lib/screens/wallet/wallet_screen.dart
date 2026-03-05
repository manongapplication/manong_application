import 'package:flutter/material.dart';
import 'dart:ui'; // For BackdropFilter
import 'package:logging/logging.dart';
import 'package:manong_application/api/manong_wallet_api_service.dart';
import 'package:manong_application/api/manong_wallet_transaction_api_service.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/models/manong_wallet.dart';
import 'package:manong_application/models/manong_wallet_transaction.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/snackbar_utils.dart';
import 'package:manong_application/widgets/error_state_widget.dart';
import 'package:manong_application/widgets/manong_wallet_card.dart';
import 'package:manong_application/widgets/manong_wallet_transaction_list.dart';
import 'package:manong_application/widgets/my_app_bar.dart';
import 'package:manong_application/widgets/pending_job_fees_widget.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with TickerProviderStateMixin {
  final Logger logger = Logger('WalletScreen');
  bool _isLoading = false;
  bool _isButtonLoading = false;
  String? _error;
  final String _selectedCurrency = "PHP";
  ManongWallet? _wallet;
  bool _noManongWallet = false;
  List<ManongWalletTransaction>? _pendingJobFees;

  // Variables for transactions
  List<ManongWalletTransaction> _walletTransactions = [];
  bool _isLoadingTransactions = false;
  bool _hasLoadedTransactions = false;

  @override
  void initState() {
    super.initState();
    _fetchManongWallet();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check if we just returned to this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ModalRoute? route = ModalRoute.of(context);
      if (route != null && route.isCurrent) {
        // We're the current screen - check if we need to refresh
        _checkAndRefresh();
      }
    });
  }

  Future<void> _checkAndRefresh() async {
    await _fetchManongWallet();
    if (_wallet != null) {
      await _loadWalletTransactions();
    }
  }

  Future<void> _createManongWallet() async {
    setState(() {
      _isButtonLoading = true;
      _error = null;
    });

    try {
      final response = await ManongWalletApiService()
          .createManongWalletService();

      if (!mounted) return;

      // Show success message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => SafeArea(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Wallet Created',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColorScheme.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    response?['message'] ??
                        'Your ManongWallet has been created successfully!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColorScheme.primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      });

      // Refresh wallet data
      await _fetchManongWallet();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Error'),
            content: Text(_error ?? 'Something went wrong'),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      });

      logger.severe('Unable to create manong wallet $_error');
    } finally {
      if (mounted) {
        setState(() {
          _isButtonLoading = false;
        });
      }
    }
  }

  Future<void> _loadWalletTransactions() async {
    if (_wallet == null || _isLoadingTransactions) return;

    setState(() {
      _isLoadingTransactions = true;
    });

    try {
      final response = await ManongWalletTransactionApiService()
          .fetchWalletTransactionsByWalletId(walletId: _wallet!.id);

      if (response != null && response['data'] != null) {
        final List<dynamic> transactionData = response['data'];
        setState(() {
          _walletTransactions = transactionData
              .map((json) => ManongWalletTransaction.fromJson(json))
              .toList();
          _hasLoadedTransactions = true;
        });
      }
    } catch (e) {
      logger.severe('Error loading wallet transactions: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTransactions = false;
        });
      }
    }
  }

  Future<void> _fetchManongWallet() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _noManongWallet = false;
    });

    logger.info('_fetchManongWallet started');

    try {
      final response = await ManongWalletApiService()
          .fetchManongWalletService();

      logger.info('_fetchManongWallet $response');

      if (response != null) {
        if (response['data'] != null) {
          final data = ManongWallet.fromJson(response['data']);
          logger.info('_fetchManongWallet $data');
          setState(() {
            _wallet = data;
            _noManongWallet = false;
          });

          // Load transactions after wallet is fetched
          if (!_hasLoadedTransactions) {
            _loadWalletTransactions();
          }
        } else {
          if (response['message'].toString().contains('Wallet not found')) {
            setState(() {
              _noManongWallet = true;
              _walletTransactions.clear();
              _hasLoadedTransactions = false;
            });
          } else {
            SnackBarUtils.showWarning(
              navigatorKey.currentContext!,
              response['message'],
            );
          }
        }
      } else {
        SnackBarUtils.showWarning(
          navigatorKey.currentContext!,
          response?['message'] ?? 'No wallet',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });

      logger.severe('Error to fetch manong wallet $_error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildCard() {
    return Stack(
      children: [
        // The actual wallet card
        ManongWalletCard(wallet: _wallet),

        // Overlay to deactivate the card when there's no wallet
        if (_noManongWallet)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.wallet_outlined,
                        size: 48,
                        color: AppColorScheme.primaryColor.withOpacity(0.7),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No Wallet Found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColorScheme.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a wallet to view your balance',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildButtonChip({
    required String title,
    required VoidCallback? onPressed,
  }) {
    final isDisabled = onPressed == null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled
              ? AppColorScheme.primaryColor.withOpacity(0.3)
              : AppColorScheme.primaryColor,
          foregroundColor: isDisabled
              ? Colors.white.withOpacity(0.7)
              : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildCashActionButtons() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _buildButtonChip(
            title: 'Cash In',
            onPressed: _noManongWallet
                ? null
                : () {
                    Navigator.pushNamed(
                      navigatorKey.currentContext!,
                      '/wallet-cash-in',
                    );
                  },
          ),
          _buildButtonChip(
            title: 'Cash Out',
            onPressed: _noManongWallet
                ? null
                : () {
                    _handleCashOutPressed();
                  },
          ),
        ],
      ),
    );
  }

  Future<void> _handleCashOutPressed() async {
    // Show loading indicator
    setState(() {
      _isButtonLoading = true;
    });

    try {
      // Fetch pending job fees
      await _fetchPendingJobFees();

      if (_pendingJobFees != null && _pendingJobFees!.isNotEmpty) {
        // Show pending jobs dialog
        _showPendingJobDialog();
      } else {
        // No pending jobs, proceed to cashout
        Navigator.pushNamed(navigatorKey.currentContext!, '/wallet-cash-out');
      }
    } catch (e) {
      logger.severe('Error checking pending job fees: $e');
      // If there's an error checking, still allow cashout or show error
      SnackBarUtils.showError(
        navigatorKey.currentContext!,
        'Unable to check pending job fees. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isButtonLoading = false;
        });
      }
    }
  }

  Future<void> _showPendingJobDialog() async {
    if (_pendingJobFees == null || _pendingJobFees!.isEmpty) return;

    final pendingCount = _pendingJobFees!.length;

    // Calculate total amount
    final totalAmount = _pendingJobFees!.fold<double>(
      0,
      (sum, tx) => sum + (tx.amount?.abs() ?? 0),
    );

    return showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.pending_actions, color: Colors.orange, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pending Job Fees',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColorScheme.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              Divider(height: 1, color: Colors.grey.shade200),

              // Content - Scrollable
              PendingJobFeesWidget(
                pendingCount: pendingCount,
                totalAmount: totalAmount,
                pendingJobFees: _pendingJobFees,
              ),

              // Divider
              Divider(height: 1, color: Colors.grey.shade200),

              // Actions
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColorScheme.primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('PAY LATER'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColorScheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        final result = await Navigator.pushNamed(
                          navigatorKey.currentContext!,
                          '/pay-job-fees',
                        );

                        if (result != null && result is Map) {
                          final success = result['success'] as bool? ?? false;
                          final navigateTo = result['navigateTo'] as String?;

                          if (success && navigateTo == 'cash-out') {
                            Navigator.of(context).pop();
                            // Navigate to cash out screen
                            Navigator.pushNamed(
                              navigatorKey.currentContext!,
                              '/wallet-cash-out',
                            );
                          }
                        }
                      },
                      child: const Text('PAY NOW'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  Widget _buildCreateWalletSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Explanation text
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColorScheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColorScheme.primaryColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppColorScheme.primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What is ManongWallet?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColorScheme.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your digital wallet for secure job payments, cash ins/outs, and transaction history. Start accepting cash payments today!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Create wallet button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isButtonLoading ? null : _createManongWallet,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorScheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isButtonLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Create ManongWallet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    if (_noManongWallet || _wallet == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColorScheme.primaryDark,
                ),
              ),
              if (_walletTransactions.isNotEmpty)
                IconButton(
                  onPressed: () {
                    // Refresh transactions
                    _loadWalletTransactions();
                  },
                  icon: Icon(
                    Icons.refresh,
                    color: AppColorScheme.primaryColor,
                    size: 20,
                  ),
                  tooltip: 'Refresh transactions',
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (_isLoadingTransactions)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColorScheme.primaryColor,
              ),
            ),
          )
        else if (_walletTransactions.isEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  'No transactions yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your wallet transactions will appear here',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      navigatorKey.currentContext!,
                      '/wallet-cash-in',
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColorScheme.primaryColor),
                  ),
                  child: Text(
                    'Make your first cash in',
                    style: TextStyle(color: AppColorScheme.primaryColor),
                  ),
                ),
              ],
            ),
          )
        else
          ManongWalletTransactionList(
            transactions: _walletTransactions,
            title: 'Recent Transactions',
            showHeader: false, // We're already showing the header above
            maxItems: 3,
          ),
      ],
    );
  }

  Widget _buildWalletContent() {
    return Column(
      children: [
        _buildCard(),
        const SizedBox(height: 16),

        // Show create wallet section with explanation when there's no wallet
        if (_noManongWallet)
          _buildCreateWalletSection()
        else
          _buildCashActionButtons(),

        // Add recent transactions section
        _buildRecentTransactions(),

        const SizedBox(height: 24), // Add some bottom padding
      ],
    );
  }

  Widget _buildState() {
    if (_error != null) {
      return SizedBox(
        height: MediaQuery.of(context).size.height - kToolbarHeight,
        child: const Center(child: ErrorStateWidget()),
      );
    }

    if (_isLoading) {
      return SizedBox(
        height: MediaQuery.of(context).size.height - kToolbarHeight,
        child: const Center(
          child: CircularProgressIndicator(color: AppColorScheme.primaryColor),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: _buildWalletContent(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorScheme.backgroundGrey,
      appBar: myAppBar(leading: Icon(Icons.wallet), title: 'Wallet'),
      body: Stack(
        children: [
          SafeArea(
            child: RefreshIndicator(
              color: AppColorScheme.primaryColor,
              backgroundColor: AppColorScheme.backgroundGrey,
              onRefresh: () async {
                await _fetchManongWallet();
                if (_wallet != null) {
                  await _loadWalletTransactions();
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        MediaQuery.of(context).size.height - kToolbarHeight,
                  ),
                  child: _buildState(),
                ),
              ),
            ),
          ),

          // Loading overlay for button actions
          if (_isButtonLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CircularProgressIndicator(
                      color: AppColorScheme.primaryColor,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
