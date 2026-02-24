import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/manong_wallet_transaction_api_service.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/models/manong_wallet_transaction.dart';
import 'package:manong_application/models/wallet_transaction_status.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/snackbar_utils.dart';
import 'package:manong_application/utils/url_utils.dart';
import 'package:manong_application/widgets/error_state_widget.dart';
import 'package:manong_application/widgets/my_app_bar.dart';

class JobFeesPaymentRedirectScreen extends StatefulWidget {
  final List<int>? jobFeeIds;
  final String? redirectUrl;
  final String? returnUrl;

  const JobFeesPaymentRedirectScreen({
    super.key,
    this.jobFeeIds,
    this.redirectUrl,
    this.returnUrl,
  });

  @override
  State<JobFeesPaymentRedirectScreen> createState() =>
      _JobFeesPaymentRedirectScreenState();
}

class _JobFeesPaymentRedirectScreenState
    extends State<JobFeesPaymentRedirectScreen>
    with WidgetsBindingObserver {
  final Logger logger = Logger('JobFeesPaymentRedirectScreen');
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  List<ManongWalletTransaction>? _pendingJobFees;
  bool _isLoading = false;
  String? _error;
  String _title = 'Processing payment...';
  bool _paymentCompleted = false;
  double _totalAmount = 0;
  int _completedCount = 0;
  String? _paymentStatus;

  bool _paymentFailed = false;
  int _checkAttempts = 0;
  static const int MAX_CHECK_ATTEMPTS = 30;
  static const int CHECK_INTERVAL_SECONDS = 2;

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
    _appLinks = AppLinks();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      if (widget.jobFeeIds != null && !_paymentCompleted) {
        logger.info('App resumed, checking payment status');
        _checkPaymentStatus(widget.jobFeeIds!);
      }
    }
  }

  Future<void> _initDeeplinks() async {
    try {
      final Uri? initialLink = await _appLinks.getInitialLink();

      if (initialLink != null) {
        logger.info('Initial deep link: $initialLink');
        _handleIncomingLink(initialLink);
      }

      _linkSubscription = _appLinks.uriLinkStream.listen((Uri uri) {
        logger.info('Deep link stream: $uri');
        _handleIncomingLink(uri);
      });
    } catch (e) {
      logger.severe('Error initializing deep links', e);
    }
  }

  Future<void> _checkPaymentStatus(List<int> ids) async {
    // Prevent multiple simultaneous checks
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      logger.info('Checking payment status for IDs: $ids');
      final response = await ManongWalletTransactionApiService()
          .getJobFeesPaymentStatus(ids);

      logger.info('Payment status response: $response');

      if (response != null && mounted) {
        final completedIds = response['completedIds'] as List? ?? [];
        final pendingIds = response['pendingIds'] as List? ?? [];
        final failedIds = response['failedIds'] as List? ?? [];
        final totalAmount = (response['totalAmount'] as num?)?.toDouble() ?? 0;
        final status = response['status'] as String? ?? 'pending';
        final summary = response['summary'] as Map? ?? {};

        setState(() {
          _completedCount = completedIds.length;
          _totalAmount = totalAmount;
          _paymentStatus = status;

          // Payment is completed only if ALL IDs are completed
          _paymentCompleted = status == 'completed';

          // Payment failed if all failed
          _paymentFailed = status == 'failed';

          if (_paymentCompleted) {
            _title = 'Payment Successful!';
          } else if (status == 'failed') {
            _title = 'Payment Failed';
          } else if (status == 'partial' || status == 'partial_failed') {
            _title = 'Partial Payment (${completedIds.length}/${ids.length})';
          } else {
            _title = 'Payment Pending';
          }
        });

        if (_paymentCompleted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully paid $_completedCount job fee(s)!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Pop with arguments to indicate success and where to go
          Navigator.pop(context, {'success': true, 'navigateTo': 'cash-out'});
        } else if (status == 'failed') {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Payment failed for ${failedIds.length} job fee(s)',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        } else if (pendingIds.isNotEmpty) {
          // Still pending, maybe schedule another check after delay
          // but only if we haven't checked too many times
          if (_checkAttempts < MAX_CHECK_ATTEMPTS) {
            _checkAttempts++;
            Future.delayed(Duration(seconds: CHECK_INTERVAL_SECONDS), () {
              if (mounted && !_paymentCompleted) {
                _checkPaymentStatus(ids);
              }
            });
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
      logger.severe('Error checking payment status', e);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _goToRedirectUrl() async {
    if (widget.redirectUrl == null) return;

    // Check if payment is already completed before redirecting
    if (_paymentCompleted) {
      return;
    }

    // Small delay to ensure screen is built
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      logger.info('Opening redirect URL: ${widget.redirectUrl}');
      launchInBrowser(widget.redirectUrl);
    }
  }

  void _handleIncomingLink(Uri uri) {
    logger.info('Handling incoming deep link: $uri');

    if (uri.host == 'job-fees-payment-complete') {
      final idsParam = uri.queryParameters['ids'];
      final paymentIntentId = uri.queryParameters['payment_intent_id'];

      logger.info(
        'IDs from deep link: $idsParam, Payment Intent: $paymentIntentId',
      );

      if (widget.jobFeeIds != null) {
        // Immediately check payment status when deep link is received
        _checkPaymentStatus(widget.jobFeeIds!);
      }
    }
  }

  Widget _buildExpiredState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error, color: Colors.red, size: 120),
        const SizedBox(height: 18),
        const Text(
          'Payment session has expired.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Go Back'),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 60,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Payment Successful!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColorScheme.primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You have successfully paid $_completedCount job fee(s)',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            'Total amount: ₱${_totalAmount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColorScheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Redirecting to wallet...',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              color: AppColorScheme.primaryColor,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Processing Payment',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColorScheme.primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please complete the payment in the browser',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          if (widget.jobFeeIds != null)
            Text(
              'Job Fees: ${widget.jobFeeIds!.length} item(s)',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorScheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              if (widget.redirectUrl != null) {
                launchInBrowser(widget.redirectUrl);
              }
            },
            child: const Text('Open Payment Page Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildPartialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange.shade700,
              size: 60,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Partial Payment',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColorScheme.primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_completedCount out of ${widget.jobFeeIds?.length ?? 0} job fees paid',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            'Paid amount: ₱${_totalAmount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColorScheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorScheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildState() {
    if (_error != null) {
      return ErrorStateWidget(
        errorText: _error!,
        onPressed: () {
          if (widget.jobFeeIds != null) {
            _checkPaymentStatus(widget.jobFeeIds!);
          }
        },
      );
    }

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColorScheme.primaryColor),
      );
    }

    if (_paymentCompleted) {
      return _buildSuccessState();
    }

    if (_completedCount > 0) {
      return _buildPartialState();
    }

    return _buildProcessingState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorScheme.backgroundGrey,
      appBar: myAppBar(title: _title),
      body: Padding(padding: const EdgeInsets.all(24), child: _buildState()),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSubscription?.cancel();
    super.dispose();
  }
}
