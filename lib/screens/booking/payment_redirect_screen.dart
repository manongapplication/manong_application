import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/service_request_api_service.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/models/payment_status.dart';
import 'package:manong_application/models/service_request.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/snackbar_utils.dart';
import 'package:manong_application/utils/status_utils.dart';
import 'package:manong_application/utils/url_utils.dart';
import 'package:manong_application/widgets/error_state_widget.dart';
import 'package:manong_application/widgets/my_app_bar.dart';

class PaymentRedirectScreen extends StatefulWidget {
  final ServiceRequest? serviceRequest;
  const PaymentRedirectScreen({super.key, this.serviceRequest});

  @override
  State<PaymentRedirectScreen> createState() => _PaymentRedirectScreenState();
}

class _PaymentRedirectScreenState extends State<PaymentRedirectScreen>
    with WidgetsBindingObserver {
  final Logger logger = Logger('PaymentRedirectScreen');
  late ServiceRequest? _serviceRequest;
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  PaymentStatus? _paymentStatus;
  DateTime? _createdAt;
  bool _isLoading = false;
  String? _error;
  String _title = 'Redirecting payment...';
  bool? _isExpired;

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
    _serviceRequest = widget.serviceRequest;
    if (_serviceRequest != null) {
      DateTime now = DateTime.now();
      setState(() {
        _isExpired =
            now.difference(_serviceRequest!.createdAt!) >=
            const Duration(hours: 4);
      });

      if (_isExpired != null) {
        if (_isExpired!) {
          if (_serviceRequest?.status != 'expired') {
            _setToExpiration();
          }
        }
      }
    }
    _appLinks = AppLinks();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      if (_serviceRequest?.id != null) {
        _getServiceRequest(_serviceRequest!.id!);
      }
    }
  }

  Future<void> _setToExpiration() async {
    setState(() {
      _isLoading = true;
    });
    try {
      if (_serviceRequest == null) return;
      final response = await ServiceRequestApiService().expiredServiceRequest(
        _serviceRequest!.id!,
      );

      if (response != null) {
        SnackBarUtils.showWarning(
          navigatorKey.currentContext!,
          response['message'] ?? 'Service request already expired.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      logger.info('Unable to set expired ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
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
    if (_serviceRequest == null || _serviceRequest?.id == null) return;
    logger.info('Incoming link $uri');

    if (uri.host == 'payment-complete') {
      final paymentIntentId = uri.queryParameters['payment_intent_id'];
      if (paymentIntentId != null) {
        _getServiceRequest(_serviceRequest!.id!);
      }
    }
  }

  Future<void> _goToServiceRequestScreenPending(
    PaymentStatus paymentStatus,
  ) async {
    await Future.delayed(Duration(seconds: 1));
    Navigator.pushNamedAndRemoveUntil(
      navigatorKey.currentContext!,
      '/',
      (route) => false,
      arguments: {
        'index': 1,
        'serviceRequestStatusIndex': getTabIndex(paymentStatus),
      },
    );
  }

  Future<void> _getServiceRequest(int id) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ServiceRequestApiService().fetchUserServiceRequest(
        id,
      );

      if (response != null) {
        final paymentStatus = response.paymentStatus;
        final createdAt = response.createdAt;
        if (paymentStatus != null) {
          bool isExpired = false;
          if (createdAt != null) {
            final now = DateTime.now().toUtc();
            isExpired =
                now.difference(createdAt.toUtc()) >= const Duration(hours: 4);
          }

          setState(() {
            _paymentStatus = paymentStatus;
            _createdAt = createdAt;
            if (isExpired) {
              _title = 'Service request has expired';
            } else if (paymentStatus == PaymentStatus.paid) {
              _title = 'Payment successful';
            } else {
              _title = 'Redirecting payment...';
            }
          });

          if (paymentStatus == PaymentStatus.paid) {
            await _goToServiceRequestScreenPending(paymentStatus);
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });

      logger.severe('Error fetching service request $_error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _expiredServiceRequest() {
    return Column(
      children: [
        Icon(Icons.error, color: Colors.red, size: 120),
        const SizedBox(height: 18),
        const Text(
          'Service request has expired. Please request a new one.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ],
    );
  }

  Widget _buildRedirectingArea() {
    if (_serviceRequest == null) return const SizedBox.shrink();
    DateTime now = DateTime.now().toUtc();
    _isExpired =
        now.difference(_serviceRequest!.createdAt!) >= const Duration(hours: 4);

    if (_isExpired != null) {
      if (_isExpired!) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [_expiredServiceRequest()],
          ),
        );
      }
    }

    if (_paymentStatus != null && _createdAt != null) {
      bool isExpired = now.difference(_createdAt!) >= const Duration(hours: 4);

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_paymentStatus == PaymentStatus.paid) ...[
              Icon(Icons.check_circle, color: Colors.green, size: 120),
              const SizedBox(height: 18),
              Text(
                'Service Request paid. Redirecting to home...',
                style: TextStyle(fontSize: 18),
              ),
            ] else ...[
              if (isExpired) ...[
                _expiredServiceRequest(),
              ] else ...[
                Icon(Icons.error, color: Colors.red, size: 120),
                const SizedBox(height: 18),
                Text(
                  'Service request is ${_paymentStatus?.value}',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ],
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_serviceRequest != null)
            if (_serviceRequest?.paymentStatus == PaymentStatus.paid) ...[
              Icon(Icons.check_circle, color: Colors.green, size: 120),
              const SizedBox(height: 18),
              Text(
                'Service Request paid. Redirecting to home...',
                style: TextStyle(fontSize: 18),
              ),
            ] else ...[
              if (_serviceRequest?.paymentRedirectUrl != null) ...[
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
                  'Redirecting url for ${_serviceRequest?.paymentMethod?.name ?? 'payment'}...',
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
    if (_serviceRequest == null) return;
    Future.delayed(Duration(seconds: 2));
    if (_isExpired != null) {
      if (!(_isExpired!)) {
        if (_serviceRequest?.paymentStatus != null) {
          if (_serviceRequest?.paymentStatus != PaymentStatus.paid) {
            launchInBrowser(_serviceRequest?.paymentRedirectUrl);
          } else {
            await _goToServiceRequestScreenPending(
              _serviceRequest!.paymentStatus!,
            );
          }
        }
      }
    }
  }

  Widget _buildState() {
    if (_error != null) {
      return ErrorStateWidget(
        errorText: _error ?? '',
        onPressed: () => _getServiceRequest,
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
