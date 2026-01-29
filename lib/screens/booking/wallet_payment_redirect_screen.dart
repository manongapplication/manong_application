import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/manong_wallet_transaction_api_service.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/models/manong_wallet_transaction.dart';
import 'package:manong_application/models/wallet_transaction_status.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/url_utils.dart';
import 'package:manong_application/widgets/error_state_widget.dart';
import 'package:manong_application/widgets/my_app_bar.dart';

class WalletPaymentRedirectScreen extends StatefulWidget {
  final ManongWalletTransaction? manongWalletTransaction;
  const WalletPaymentRedirectScreen({super.key, this.manongWalletTransaction});

  @override
  State<WalletPaymentRedirectScreen> createState() =>
      _WalletPaymentRedirectScreenState();
}

class _WalletPaymentRedirectScreenState
    extends State<WalletPaymentRedirectScreen>
    with WidgetsBindingObserver {
  final Logger logger = Logger('WalletPaymentRedirectScreen');
  late ManongWalletTransaction? _manongWalletTransaction;
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  WalletTransactionStatus? _walletTransactionStatus;
  DateTime? _createdAt;
  bool _isLoading = false;
  String? _error;
  String _title = 'Redirecting payment...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeComponents();
    _initDeeplinks();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _goToRedirectUrl();
    });
  }

  void _initializeComponents() {
    _manongWalletTransaction = widget.manongWalletTransaction;
    _appLinks = AppLinks();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      if (_manongWalletTransaction?.id != null) {
        _getManongWalletTransaction(_manongWalletTransaction!.id);
      }
    }
  }

  Future<void> _initDeeplinks() async {
    final Uri? initialLink = await _appLinks.getInitialLink();

    if (initialLink != null) {
      _handleIncomingLink(initialLink);
    }

    _linkSubscription = _appLinks.uriLinkStream.listen((Uri uri) {
      _handleIncomingLink(uri);
    });
  }

  void _handleIncomingLink(Uri uri) {
    if (_manongWalletTransaction == null ||
        _manongWalletTransaction?.id == null)
      return;
    logger.info('Incoming link $uri');

    if (uri.host == 'payment-complete') {
      final paymentIntentId = uri.queryParameters['payment_intent_id'];
      if (paymentIntentId != null) {
        _getManongWalletTransaction(_manongWalletTransaction!.id!);
      }
    }
  }

  Future<void> _getManongWalletTransaction(int id) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ManongWalletTransactionApiService()
          .fetchWalletTransactionById(id);

      if (response != null) {
        final walletTransactionStatus = response.status;
        final createdAt = response.createdAt;
        if (walletTransactionStatus != null) {
          // Check if expired
          if (createdAt != null) {
            final now = DateTime.now().toUtc();
            final isExpired =
                now.difference(createdAt.toUtc()) >= const Duration(hours: 4);

            if (isExpired) {
              Navigator.of(navigatorKey.currentContext!).pop();
              return;
            }
          }

          setState(() {
            _walletTransactionStatus = walletTransactionStatus;
            _createdAt = createdAt;
            if (_walletTransactionStatus == WalletTransactionStatus.completed) {
              _title = 'Payment successful';
            } else {
              _title = 'Redirecting payment...';
            }
          });

          if (_walletTransactionStatus == WalletTransactionStatus.completed) {
            // Show success message FIRST
            ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
              SnackBar(
                content: Text(
                  'Payment completed successfully! ₱${_manongWalletTransaction?.amount.toStringAsFixed(2)} has been added to your wallet.',
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );

            // Then navigate home after a short delay
            Future.delayed(Duration(seconds: 2), () {
              Navigator.of(navigatorKey.currentContext!).pop();
            });
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });

      logger.severe('Error fetching wallet transaction $_error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _expiredManongWalletTransaction() {
    return Column(
      children: [
        Icon(Icons.error, color: Colors.red, size: 120),
        const SizedBox(height: 18),
        const Text(
          'Wallet Transaction has expired.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () {
            Navigator.of(navigatorKey.currentContext!).pop();
          },
          child: const Text('Go to Home'),
        ),
      ],
    );
  }

  Widget _buildRedirectingArea() {
    if (_manongWalletTransaction == null) return const SizedBox.shrink();

    // Check for expiration on UI render
    if (_manongWalletTransaction!.createdAt != null) {
      DateTime now = DateTime.now().toUtc();
      final isExpired =
          now.difference(_manongWalletTransaction!.createdAt!.toUtc()) >=
          const Duration(hours: 4);

      if (isExpired) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [_expiredManongWalletTransaction()],
          ),
        );
      }
    }

    if (_walletTransactionStatus != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_walletTransactionStatus ==
                WalletTransactionStatus.completed) ...[
              Icon(Icons.check_circle, color: Colors.green, size: 120),
              const SizedBox(height: 18),
              Text(
                'Wallet transaction completed. Redirecting to home...',
                style: TextStyle(fontSize: 18),
              ),
            ] else ...[
              Icon(Icons.error, color: Colors.red, size: 120),
              const SizedBox(height: 18),
              Text(
                'Wallet Transaction is ${_walletTransactionStatus?.value}',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_manongWalletTransaction?.status ==
              WalletTransactionStatus.completed) ...[
            Icon(Icons.check_circle, color: Colors.green, size: 120),
            const SizedBox(height: 18),
            Text(
              'Wallet Transaction completed. Redirecting to home...',
              style: TextStyle(fontSize: 18),
            ),
          ] else ...[
            if (_manongWalletTransaction?.metadata?['paymentRedirectUrl'] !=
                null) ...[
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  color: AppColorScheme.primaryColor,
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Redirecting url for ${_manongWalletTransaction?.metadata?['provider'] ?? 'payment'}...',
                style: TextStyle(fontSize: 18),
              ),
            ] else ...[
              Text('Redirecting to payment url'),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _goToRedirectUrl() async {
    if (_manongWalletTransaction == null) return;

    // Check expiration before redirecting
    if (_manongWalletTransaction!.createdAt != null) {
      DateTime now = DateTime.now().toUtc();
      final isExpired =
          now.difference(_manongWalletTransaction!.createdAt!.toUtc()) >=
          const Duration(hours: 4);

      if (isExpired) {
        // Simply show expired UI, user can click button to go home
        return;
      }
    }

    Future.delayed(Duration(seconds: 2));
    if (_manongWalletTransaction?.status != WalletTransactionStatus.completed) {
      launchInBrowser(
        _manongWalletTransaction?.metadata?['paymentRedirectUrl'],
      );
    } else {
      // REMOVE THIS DUPLICATE NAVIGATION - already handled in _getManongWalletTransaction
      // Navigator.pushNamedAndRemoveUntil(
      //   navigatorKey.currentContext!,
      //   '/',
      //   (route) => false,
      //   arguments: {'index': 3, 'transactionStatus': _walletTransactionStatus},
      // );
    }
  }

  Widget _buildState() {
    if (_error != null) {
      return ErrorStateWidget(
        errorText: _error ?? '',
        onPressed: () => _getManongWalletTransaction,
      );
    }

    if (_isLoading == true) {
      return Center(
        child: CircularProgressIndicator(color: AppColorScheme.primaryColor),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(42),
      child: SafeArea(child: _buildRedirectingArea()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorScheme.backgroundGrey,
      appBar: myAppBar(title: _title),
      body: _buildState(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSubscription?.cancel();
    super.dispose();
  }
}
