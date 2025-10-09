import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/service_request_api_service.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/models/manong.dart';
import 'package:manong_application/models/payment_status.dart';
import 'package:manong_application/models/service_request.dart';
import 'package:manong_application/screens/home/home_screen.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/calculation_totals.dart';
import 'package:manong_application/utils/color_utils.dart';
import 'package:manong_application/utils/snackbar_utils.dart';
import 'package:manong_application/utils/status_utils.dart';
import 'package:manong_application/widgets/card_container.dart';
import 'package:manong_application/widgets/circle_countdown_timer.dart';
import 'package:manong_application/widgets/dashed_divider.dart';
import 'package:manong_application/widgets/dashed_vertical_divider.dart';
import 'package:manong_application/widgets/error_state_widget.dart';
import 'package:manong_application/widgets/icon_card.dart';
import 'package:manong_application/widgets/label_value_row.dart';
import 'package:manong_application/widgets/price_tag.dart';

class PaymentProcessingScreen extends StatefulWidget {
  final ServiceRequest? serviceRequest;
  final Manong? manong;

  const PaymentProcessingScreen({super.key, this.serviceRequest, this.manong});

  @override
  State<PaymentProcessingScreen> createState() =>
      _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState extends State<PaymentProcessingScreen> {
  final Logger logger = Logger('PaymentProcessingScreen');
  late ServiceRequest? _serviceRequest;
  late Manong? _manong;
  late ServiceRequestApiService serviceRequestApiService;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    initializedComponents();
  }

  void initializedComponents() {
    _serviceRequest = widget.serviceRequest;
    _manong = widget.manong;
    serviceRequestApiService = ServiceRequestApiService();
  }

  void _completeRequest() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      if (_serviceRequest == null || _manong == null) return;

      final response = await serviceRequestApiService.completeRequest(
        _serviceRequest!.id!,
        _manong!.appUser.id,
      );

      if (response != null && response['success'] == true) {
        if (!mounted) return;

        SnackBarUtils.showInfo(
          navigatorKey.currentContext!,
          response['message'] ?? 'Service request completed.',
        );

        if (response['data'] != null) {
          final data = ServiceRequest.fromJson(response['data']);

          if (data.paymentRedirectUrl != null) {
            Navigator.pushReplacementNamed(
              navigatorKey.currentContext!,
              '/payment-redirect',
              arguments: {'serviceRequest': data},
            );

            return;
          }

          Navigator.of(navigatorKey.currentContext!).pushNamedAndRemoveUntil(
            '/',
            (route) => false,
            arguments: {
              'index': 1,
              'serviceRequestStatusIndex': data.paymentStatus?.index != null
                  ? (getTabIndex(data.paymentStatus!.value)!)
                  : null,
            },
          );
        }
      } else {
        if (response?['message'] != null) {
          if (response!['message'].toString().contains('request already')) {
            final sr = ServiceRequest.fromJson(response['data']);
            Navigator.of(navigatorKey.currentContext!).pushNamedAndRemoveUntil(
              '/',
              (route) => false,
              arguments: {
                'index': 1,
                'serviceRequestStatusIndex': sr.paymentStatus != null
                    ? (getTabIndex(sr.paymentStatus!.value))
                    : null,
              },
            );
          }
        }

        SnackBarUtils.showWarning(
          navigatorKey.currentContext!,
          response?['message'] ??
              'Failed submitting your service request. Please try again later.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
      logger.severe('Error completing your service request $_error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildProcessingContainer() {
    return CardContainer(
      children: [
        ListTile(
          title: Row(
            children: [
              Text(
                'Processing',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(width: 12),

              CircleCountdownTimer(
                duration: Duration(seconds: 5),
                size: 30.0,
                progressColor: AppColorScheme.primaryColor,
                backgroundColor: Colors.grey.shade300,
                strokeWidth: 8.0,
                textStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColorScheme.primaryColor,
                ),
                onComplete: _completeRequest,
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: const Text(
              'Sending your order...',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          trailing: GestureDetector(
            onTap: () {
              Navigator.pop(navigatorKey.currentContext!);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 14, color: Colors.blue),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 12, right: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Image.asset('assets/icon/logo.png', scale: 10),

              const SizedBox(width: 8),
              Expanded(
                child: DashedDivider(
                  color: AppColorScheme.primaryColor,
                  height: 2,
                  dashWidth: 4,
                  dashSpace: 3,
                ),
              ),

              const SizedBox(width: 4),
              Icon(Icons.plumbing, color: Colors.grey.shade600),
              const SizedBox(width: 8),

              Expanded(
                child: DashedDivider(
                  color: AppColorScheme.primaryColor,
                  height: 2,
                  dashWidth: 4,
                  dashSpace: 3,
                ),
              ),

              const SizedBox(width: 4),
              Icon(Icons.local_shipping, color: Colors.grey.shade600),
              const SizedBox(width: 4),

              Expanded(
                child: DashedDivider(
                  color: AppColorScheme.primaryColor,
                  height: 2,
                  dashWidth: 4,
                  dashSpace: 3,
                ),
              ),
              Icon(Icons.home, color: Colors.grey.shade600),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotals() {
    if (_serviceRequest == null) const SizedBox.shrink();

    return CardContainer(
      children: [
        Row(
          children: [
            iconCard(
              iconColor: colorFromHex(_serviceRequest!.serviceItem!.iconColor),
              iconName: _serviceRequest!.subServiceItem?.iconName ?? '',
            ),
            const SizedBox(width: 12),
            Text(
              _serviceRequest!.subServiceItem?.title ?? '',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),

        Divider(color: Colors.grey, thickness: 1, indent: 20, endIndent: 20),
        LabelValueRow(
          label: 'Service:',
          valueWidget: Text(
            _serviceRequest?.otherServiceName ??
                _serviceRequest?.subServiceItem?.title ??
                '',
          ),
        ),
        LabelValueRow(
          label: 'Payment:',
          valueWidget: Text(_serviceRequest?.paymentMethod?.name ?? ''),
        ),
        const SizedBox(height: 4),
        LabelValueRow(
          label: 'Base Fee:',
          valueWidget: _serviceRequest?.subServiceItem?.fee != null
              ? PriceTag(
                  price: _serviceRequest!.subServiceItem!.fee!.toDouble(),
                )
              : null,
        ),
        LabelValueRow(
          label: 'Urgency Fee:',
          valueWidget: _serviceRequest?.urgencyLevel?.level != null
              ? PriceTag(
                  price: _serviceRequest!.urgencyLevel!.price!.toDouble(),
                )
              : null,
        ),
        Divider(color: Colors.grey, thickness: 1, indent: 20, endIndent: 20),
        LabelValueRow(
          label: 'Subtotal',
          valueWidget: PriceTag(
            price: CalculationTotals().calculateSubTotal(_serviceRequest),
          ),
        ),
        LabelValueRow(
          label:
              'Service Tax (${(CalculationTotals().serviceTaxRate * 100).toStringAsFixed(0)})',
          valueWidget: PriceTag(
            price: double.parse(
              CalculationTotals()
                  .calculateServiceTaxAmount(_serviceRequest)
                  .toStringAsFixed(2),
            ),
          ),
        ),
        Divider(color: Colors.grey, thickness: 1, indent: 20, endIndent: 20),
        LabelValueRow(
          label: 'Total To Pay:',
          valueWidget: PriceTag(
            price: CalculationTotals().calculateTotal(_serviceRequest),
          ),
        ),
      ],
    );
  }

  Widget _buildDistanceContainer() {
    if (_serviceRequest == null) const SizedBox.shrink();

    return CardContainer(
      children: [
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColorScheme.primaryDark,
                      ),
                      child: Icon(Icons.circle, color: Colors.white, size: 8),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _manong?.appUser.firstName ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _serviceRequest?.serviceItem?.title ?? '',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(width: 12),
                const DashedVerticalDivider(height: 60),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(Icons.location_pin, color: Colors.redAccent, size: 30),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        _serviceRequest!.customerFullAddress ?? '',
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProcessing() {
    return Column(
      spacing: 24,
      children: [
        _buildProcessingContainer(),
        _buildTotals(),
        _buildDistanceContainer(),
      ],
    );
  }

  Widget _buildState() {
    if (_error != null) {
      return ErrorStateWidget(errorText: _error!, onPressed: () {});
    }

    if (_isLoading || _serviceRequest == null || _manong == null) {
      return Center(
        child: CircularProgressIndicator(color: AppColorScheme.primaryColor),
      );
    }

    return _buildProcessing();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppColorScheme.backgroundGrey,
        padding: const EdgeInsets.all(24),
        child: SafeArea(child: _buildState()),
      ),
    );
  }
}
