import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/auth_service.dart';
import 'package:manong_application/api/service_request_api_service.dart';
import 'package:manong_application/api/user_payment_method_api_service.dart';
import 'package:manong_application/constants/steps_labels.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/models/app_step_flows.dart';
import 'package:manong_application/models/app_user.dart';
import 'package:manong_application/models/manong.dart';
import 'package:manong_application/models/payment_method.dart';
import 'package:manong_application/models/service_request.dart';
import 'package:manong_application/models/step_flow.dart';
import 'package:manong_application/models/urgency_level.dart';
import 'package:manong_application/models/user_payment_method.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/calculation_totals.dart';
import 'package:manong_application/utils/dialog_utils.dart';
import 'package:manong_application/utils/snackbar_utils.dart';
import 'package:manong_application/utils/urgency_level_util.dart';
import 'package:manong_application/widgets/card_container.dart';
import 'package:manong_application/widgets/error_state_widget.dart';
import 'package:manong_application/widgets/image_dialog.dart';
import 'package:manong_application/widgets/label_value_row.dart';
import 'package:manong_application/widgets/manong_list_card.dart';
import 'package:manong_application/widgets/my_app_bar.dart';
import 'package:manong_application/widgets/price_tag.dart';
import 'package:manong_application/widgets/selectable_item_widget.dart';
import 'package:manong_application/widgets/step_indicator.dart';
import 'package:manong_application/widgets/urgency_selector.dart';

class BookingSummaryScreen extends StatefulWidget {
  final ServiceRequest serviceRequest;
  final Manong manong;

  const BookingSummaryScreen({
    super.key,
    required this.serviceRequest,
    required this.manong,
  });
  @override
  State<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends State<BookingSummaryScreen> {
  final Logger logger = Logger('BookingSummaryScreen');
  final baseImageUrl = dotenv.env['APP_URL'];
  late ServiceRequest serviceRequest;
  late Manong manong;
  late StepFlow stepFlow;
  late AuthService authService;
  late ServiceRequestApiService serviceRequestApiService;
  AppUser? user;
  ServiceRequest? userServiceRequest;
  bool _isLoading = true;
  bool _isButtonLoading = false;
  String? _error;
  bool _toggledTotalsContainer = false;
  bool _toggledPaymentMethodContainer = false;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _totalsCardKey = GlobalKey();
  final GlobalKey _paymentMethodCardKey = GlobalKey();
  int? _activeUrgencyLevel;
  String? _userPaymentMethodLast4;
  String? _userPaymentMethodCode;

  @override
  void initState() {
    super.initState();
    initializeComponents();
    _initializeData();
  }

  void initializeComponents() {
    serviceRequest = widget.serviceRequest;
    manong = widget.manong;
    stepFlow = AppStepFlows.serviceBooking;
    authService = AuthService();
    serviceRequestApiService = ServiceRequestApiService();
  }

  void _setActiveUrgencyLevel(int index) {
    setState(() {
      _activeUrgencyLevel = index;
    });
  }

  Future<void> _initializeData() async {
    await _fetchUserServiceRequest();
    await _fetchUser();
  }

  Future<void> _fetchUser() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await authService.getMyProfile();

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = null;
        user = response;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });

      logger.severe('Error fetching user $_error');
    }
  }

  Future<void> _fetchUserServiceRequest() async {
    setState(() {
      _isButtonLoading = true;
      _error = null;
    });

    try {
      final serviceRequestId = serviceRequest.id;
      if (serviceRequestId == null) {
        throw Exception('Service request ID is null');
      }

      final response = await serviceRequestApiService.fetchUserServiceRequest(
        serviceRequestId,
      );

      if (!mounted) return;
      setState(() {
        userServiceRequest = response;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });

      logger.severe('Error fetching user service request $_error');
    } finally {
      if (mounted) {
        setState(() {
          _isButtonLoading = false;
        });
      }
    }
  }

  Widget _buildManongDetails() {
    final manongName = manong.appUser.firstName;
    final manongProfile = manong.profile;

    if (manongName == null || manongProfile == null) {
      return const SizedBox.shrink();
    }

    return CardContainer(
      children: [
        ManongListCard(
          name: manongName,
          iconColor: Colors.blue,
          onTap: () {},
          isProfessionallyVerified: manongProfile.isProfessionallyVerified,
          status: manongProfile.status,
        ),
      ],
    );
  }

  Future<bool> _updateServiceRequest(Map<String, dynamic> updates) async {
    setState(() {
      _isButtonLoading = true;
      _error = null;
    });
    try {
      if (serviceRequest.id == null) return false;
      final response = await serviceRequestApiService.updateServiceRequest(
        serviceRequest.id!,
        updates,
      );

      if (response != null) {
        SnackBarUtils.showInfo(
          navigatorKey.currentContext!,
          response['message'] ?? '',
        );

        return true;
      } else {
        SnackBarUtils.showWarning(
          navigatorKey.currentContext!,
          'Failed updating service request. Please try again later.',
        );

        return false;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }

      logger.severe('Error updating service request $_error');
    } finally {
      if (mounted) {
        setState(() {
          _isButtonLoading = false;
        });
      }
    }

    return false;
  }

  Future<void> showUrgencyLevels(BuildContext context) async {
    final urgencyLevel = userServiceRequest?.urgencyLevel;
    if (urgencyLevel == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    UrgencySelector(
                      levels: UrgencyLevelUtil().getUrgencyLevels,
                      activeIndex: _activeUrgencyLevel ?? urgencyLevel.id - 1,
                      onSelected: (i) async {
                        setModalState(() => _activeUrgencyLevel = i);

                        if (_activeUrgencyLevel == null) return;

                        await _updateServiceRequest({
                          'urgencyLevelId': _activeUrgencyLevel! + 1,
                        });
                        setState(() {
                          _setActiveUrgencyLevel(_activeUrgencyLevel!);
                        });
                        Navigator.pop(navigatorKey.currentContext!);
                        _fetchUserServiceRequest();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPriceTag(UrgencyLevel urgencyLevel) {
    final price = _getUrgencyPrice(urgencyLevel);

    if (price == 0.0) {
      return const SizedBox.shrink(); // returns nothing
    }

    return PriceTag(price: price);
  }

  double _getUrgencyPrice(UrgencyLevel urgencyLevel) {
    if (_activeUrgencyLevel != null) {
      final selected =
          UrgencyLevelUtil().getUrgencyLevels[_activeUrgencyLevel!];
      return selected.price ?? 0.0;
    }
    return urgencyLevel.price ?? 0.0;
  }

  Widget _buildUrgentLevel() {
    final urgencyLevel = userServiceRequest?.urgencyLevel;
    if (urgencyLevel == null) {
      return const SizedBox.shrink();
    }

    return CardContainer(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Urgency Level',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            GestureDetector(
              onTap: () async {
                showUrgencyLevels(navigatorKey.currentContext!);
              },
              child: const Text(
                'Edit',
                style: TextStyle(fontSize: 14, color: Colors.blue),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Material(
          color: Colors.white60,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      _activeUrgencyLevel != null
                          ? UrgencyLevelUtil()
                                .getUrgencyLevels[_activeUrgencyLevel!]
                                .level
                          : urgencyLevel.level,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _activeUrgencyLevel != null
                          ? UrgencyLevelUtil()
                                .getUrgencyLevels[_activeUrgencyLevel!]
                                .time
                          : urgencyLevel.time,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),

                _buildPriceTag(urgencyLevel),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadedPhotos() {
    final images = userServiceRequest?.images;
    if (images == null || images.isEmpty) {
      return const SizedBox.shrink();
    }

    return CardContainer(
      children: [
        const Text(
          'Uploaded Images',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColorScheme.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SingleChildScrollView(
                controller: ScrollController(),
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: images.map((file) {
                    final imageUrl = baseImageUrl != null
                        ? '$baseImageUrl/${file.path.replaceAll("\\", "/")}'
                        : '';

                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () {
                            if (imageUrl.isNotEmpty) {
                              showImageDialog(
                                navigatorKey.currentContext!,
                                imageUrl,
                              );
                            }
                          },
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  errorBuilder: (_, _, _) =>
                                      const Icon(Icons.broken_image),
                                  height: 150,
                                  width: 100,
                                )
                              : const Icon(Icons.broken_image, size: 100),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _goToPaymentMethodsScreen() async {
    final result = await Navigator.pushNamed(
      context,
      '/payment-methods',
      arguments: {
        'selectedIndex': (userServiceRequest?.paymentMethodId as int) - 1,
        'toUpdate': true,
        'serviceRequest': userServiceRequest,
      },
    );

    if (result != null && result is Map) {
      setState(() {
        _fetchUserServiceRequest();
      });
    }
  }

  Widget _buildPaymentMethod() {
    return AnimatedContainer(
      key: _paymentMethodCardKey,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      duration: Duration(milliseconds: 600),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: _toggledPaymentMethodContainer
            ? AppColorScheme.primaryLight
            : Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Payment Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: _goToPaymentMethodsScreen,
                child: const Text(
                  'See All',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width:
                MediaQuery.of(context).size.width *
                0.8, // Use context instead of navigatorKey
            child: const Text(
              'Cashless payments are faster, safer, and preferred by Manongs.',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ),

          const SizedBox(height: 4),

          GestureDetector(
            onTap: _goToPaymentMethodsScreen,
            child: Column(
              children: [
                SelectableItemWidget(
                  title: 'Cards',
                  icon: Icons.credit_card,
                  onTap: _goToPaymentMethodsScreen,
                  trailing: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColorScheme.primaryLight,
                      foregroundColor: AppColorScheme.tealDark,
                    ),
                    child: const Text('Add'),
                  ),
                ),

                SelectableItemWidget(
                  title: _getPaymentMethodName(),
                  icon: Icons.money,
                  onTap: () {},
                  selected: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodName() {
    if (userServiceRequest == null) return '';

    if (userServiceRequest!.paymentMethodId == null) {
      return 'Cash';
    }

    final paymentMethod = userServiceRequest!.paymentMethod;

    if (paymentMethod == null) {
      return 'Unknown Payment';
    }

    return paymentMethod.name;
  }

  Widget _buildTotals() {
    if (userServiceRequest == null) {
      return const SizedBox.shrink();
    }

    final urgencyLevel = userServiceRequest?.urgencyLevel;
    if (urgencyLevel == null) return const SizedBox.shrink();

    return AnimatedContainer(
      key: _totalsCardKey,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      duration: Duration(milliseconds: 600),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: _toggledTotalsContainer
            ? AppColorScheme.primaryLight
            : Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service Request Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Divider(color: Colors.grey, thickness: 1, indent: 20, endIndent: 20),
          Text(
            'Service: ${userServiceRequest?.otherServiceName ?? userServiceRequest?.subServiceItem?.title}',
            style: TextStyle(fontSize: 14),
          ),
          LabelValueRow(
            label: 'Base Fee:',
            valueWidget: userServiceRequest?.subServiceItem?.fee != null
                ? PriceTag(
                    price: userServiceRequest!.subServiceItem!.fee!.toDouble(),
                  )
                : null,
          ),
          LabelValueRow(
            label: 'Urgency Fee:',
            valueWidget: userServiceRequest?.urgencyLevel?.level != null
                ? PriceTag(
                    price: userServiceRequest!.urgencyLevel!.price == 0
                        ? 0
                        : userServiceRequest!.urgencyLevel!.price!.toDouble(),
                  )
                : null,
          ),
          Divider(color: Colors.grey, thickness: 1, indent: 20, endIndent: 20),
          LabelValueRow(
            label: 'Subtotal',
            valueWidget: PriceTag(
              price: CalculationTotals().calculateSubTotal(userServiceRequest),
            ),
          ),
          LabelValueRow(
            label:
                'Service Tax (${(CalculationTotals().serviceTaxRate * 100).toStringAsFixed(0)})',
            valueWidget: PriceTag(
              price: double.parse(
                CalculationTotals()
                    .calculateServiceTaxAmount(userServiceRequest)
                    .toStringAsFixed(2),
              ),
            ),
          ),
          Divider(color: Colors.grey, thickness: 1, indent: 20, endIndent: 20),
          LabelValueRow(
            label: 'Total To Pay:',
            valueWidget: PriceTag(
              price: CalculationTotals().calculateTotal(userServiceRequest),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingSummary() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StepIndicator(
              totalSteps: stepFlow.totalSteps,
              currentStep: 4,
              stepLabels: StepsLabels.serviceBooking,
              padding: const EdgeInsets.symmetric(vertical: 32),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildManongDetails(),
                  const SizedBox(height: 16),
                  _buildUrgentLevel(),
                  const SizedBox(height: 16),
                  _buildUploadedPhotos(),
                  const SizedBox(height: 16),
                  _buildPaymentMethod(),
                  const SizedBox(height: 16),
                  _buildTotals(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void toggleTotalCard() {
    setState(() {
      _toggledTotalsContainer = true;
    });

    final context = _totalsCardKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: Duration(milliseconds: 600),
        curve: Curves.easeOut,
      );
    }

    Future.delayed(Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _toggledTotalsContainer = false;
      });
    });
  }

  void togglePaymentMethodCard() {
    setState(() {
      _toggledPaymentMethodContainer = true;
    });

    final context = _paymentMethodCardKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: Duration(milliseconds: 600),
        curve: Curves.easeOut,
      );
    }

    Future.delayed(Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _toggledPaymentMethodContainer = false;
      });
    });
  }

  Widget _buildState() {
    if (_error != null) {
      return ErrorStateWidget(
        errorText: 'Error loading summary. Please try again later.',
        onPressed: _fetchUserServiceRequest,
      );
    }

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColorScheme.primaryColor),
      );
    }

    return _buildBookingSummary();
  }

  Widget _buildTotalAreaBottom() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Total',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            Text(
              '(incl. fees and tax)',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            Spacer(),
            PriceTag(
              price: CalculationTotals().calculateTotal(userServiceRequest),
              textStyle: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        GestureDetector(
          onTap: toggleTotalCard,
          child: Text(
            'See Summary',
            style: TextStyle(decoration: TextDecoration.underline),
          ),
        ),
      ],
    );
  }

  Future<void> _getDefaultPaymentMethod() async {
    setState(() {
      _isButtonLoading = true;
      _error = null;
    });

    try {
      final response = await UserPaymentMethodApiService()
          .fetchDefaultUserPaymentMethod();

      if (!mounted) return;

      setState(() {
        _isButtonLoading = false;
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

        setState(() {
          _userPaymentMethodCode = userpaymentmethodPaymentmethod.code;
        });

        if (userpaymentmethodPaymentmethod.code == 'card') {
          if (userPaymentMethod.last4 == null) {
            SnackBarUtils.showWarning(
              navigatorKey.currentContext!,
              'Please add or select your payment card at the payment details.',
            );
          }

          return;
        }

        setState(() {
          _userPaymentMethodLast4 = userPaymentMethod.last4;
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
          _isButtonLoading = false;
        });
      }
    }
  }

  Future<void> _handleConfirmPaymentTest() async {
    if (userServiceRequest!.paymentMethod == null) {
      SnackBarUtils.showWarning(
        navigatorKey.currentContext!,
        'Please select your payment method.',
      );

      togglePaymentMethodCard();

      return;
    }

    // if (userServiceRequest!.paymentMethod!.code == 'card' &&
    //     _userPaymentMethodLast4 == null) {
    //   SnackBarUtils.showWarning(
    //     navigatorKey.currentContext!,
    //     'Please add or select your payment card at the payment details.',
    //   );
    //   return;
    // }

    if (userServiceRequest!.paymentMethod!.code == 'card') {
      Navigator.pushNamed(
        navigatorKey.currentContext!,
        '/add-card',
        arguments: {
          'proceed': 'processing',
          'serviceRequest': userServiceRequest,
          'manong': manong,
        },
      );

      return;
    }

    Navigator.pushNamed(
      navigatorKey.currentContext!,
      '/payment-processing',
      arguments: {'serviceRequest': userServiceRequest, 'manong': manong},
    );
  }

  Widget _buildConfirmButton() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: 12,
          top: 20,
        ),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.4),
              offset: const Offset(0, -4),
              blurRadius: 10,
            ),
          ],
        ),

        child: Column(
          spacing: 8,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTotalAreaBottom(),
            Divider(
              color: Colors.grey,
              thickness: 1,
              indent: 20,
              endIndent: 20,
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isButtonLoading
                        ? null
                        : _handleConfirmPaymentTest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColorScheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isButtonLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Confirm & Pay',
                            style: TextStyle(fontSize: 16),
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

  Future<void> _handleConfirmPayment() async {
    setState(() {
      _isButtonLoading = true;
    });

    final currentUserServiceRequest = userServiceRequest;
    final serviceRequestId = currentUserServiceRequest?.id;
    final int manongUserId = manong.appUser.id;

    if (serviceRequestId == null || manongUserId.isNaN) {
      setState(() {
        _isButtonLoading = false;
      });
      if (mounted) {
        SnackBarUtils.showError(context, 'Missing required data for payment');
      }
      return;
    }

    final method = userServiceRequest?.paymentMethod?.code;

    try {
      if (method == 'card') {}
      final response = await serviceRequestApiService.chooseManong(
        serviceRequestId,
        manongUserId,
      );

      if (!mounted) return;
      setState(() {
        _isButtonLoading = false;
      });

      if (response != null && response.isNotEmpty) {
        final warning = response['warning'];
        if (warning != null && warning.toString().trim().isNotEmpty) {
          final context = navigatorKey.currentContext;
          if (context != null) {
            SnackBarUtils.showWarning(
              navigatorKey.currentContext!,
              warning.toString(),
            );
          }
          return;
        }

        final context = navigatorKey.currentContext;
        if (context != null) {
          Navigator.of(
            navigatorKey.currentContext!,
          ).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } else {
        logger.warning('Cannot choose manong. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isButtonLoading = false;
      });
      SnackBarUtils.showError(context, 'Payment failed ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorScheme.backgroundGrey,
      appBar: myAppBar(
        title: 'Booking Summary',
        trailing: GestureDetector(
          onTap: () {},
          child: const Icon(Icons.delete),
        ),
      ),
      resizeToAvoidBottomInset: true,
      body: _buildState(),
      bottomNavigationBar: _buildConfirmButton(),
    );
  }
}
