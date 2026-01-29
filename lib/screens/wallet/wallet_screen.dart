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
  bool _showWalletCreationOverlay = false;
  String? _error;
  final String _selectedCurrency = "PHP";
  ManongWallet? _wallet;
  bool _noManongWallet = false;

  // Variables for transactions
  List<ManongWalletTransaction> _walletTransactions = [];
  bool _isLoadingTransactions = false;
  bool _hasLoadedTransactions = false;

  // Animation controllers
  late AnimationController _overlayController;
  late Animation<double> _overlayAnimation;

  @override
  void initState() {
    super.initState();
    _fetchManongWallet();

    // Initialize animations
    _overlayController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _overlayAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _overlayController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _overlayController.dispose();
    super.dispose();
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
    // You could check if a certain amount of time has passed
    // Or use a flag to know when to refresh
    await _fetchManongWallet();
    if (_wallet != null) {
      await _loadWalletTransactions();
    }
  }

  void _showCreateManongWalletOverlay() {
    setState(() {
      _showWalletCreationOverlay = true;
    });
    _overlayController.forward();
  }

  void _hideCreateManongWalletOverlay() {
    // Hide keyboard if open
    FocusScope.of(context).unfocus();

    _overlayController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showWalletCreationOverlay = false;
        });
      }
    });
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

      // Hide overlay first
      _hideCreateManongWalletOverlay();

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

      // Hide overlay and show error
      _hideCreateManongWalletOverlay();

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
            // Show overlay instead of dialog
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showCreateManongWalletOverlay();
            });

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

  Widget _buildCreateManongWalletOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _hideCreateManongWalletOverlay,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
          child: Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  // Prevent dismiss when tapping content
                },
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  constraints: const BoxConstraints(maxWidth: 500),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Your ManongWallet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColorScheme.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Create your ManongWallet now to start taking requests!',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColorScheme.primaryDark
                              .withOpacity(0.1),
                          foregroundColor: AppColorScheme.primaryDark,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          // Currency selection is disabled for now
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.currency_exchange, size: 20),
                            const SizedBox(width: 8),
                            Text('Currency: $_selectedCurrency'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _hideCreateManongWalletOverlay,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColorScheme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColorScheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _isButtonLoading
                                ? null
                                : _createManongWallet,
                            child: _isButtonLoading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Create Wallet',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
                    Navigator.pushNamed(context, '/wallet-cash-in');
                  },
          ),
          _buildButtonChip(
            title: 'Cash Out',
            onPressed: _noManongWallet
                ? null
                : () {
                    // open cash out dialog / page
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildCreateWalletButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: ElevatedButton(
        onPressed: _showCreateManongWalletOverlay,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorScheme.primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, size: 20),
            SizedBox(width: 8),
            Text(
              'Create ManongWallet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
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
                    Navigator.pushNamed(context, '/wallet-cash-in');
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

        // Show create wallet button when there's no wallet
        if (_noManongWallet) _buildCreateWalletButton(),

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
      appBar: myAppBar(title: 'Wallet'),
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

          // Conditionally show the animated wallet creation overlay
          if (_showWalletCreationOverlay)
            FadeTransition(
              opacity: _overlayAnimation,
              child: _buildCreateManongWalletOverlay(),
            ),
        ],
      ),
    );
  }
}
