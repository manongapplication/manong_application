import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/tracking_api_service.dart';
import 'package:manong_application/models/app_user.dart';
import 'package:manong_application/models/service_request_status.dart';
import 'package:manong_application/models/user_role.dart';
import 'package:manong_application/providers/bottom_nav_provider.dart';
import 'package:manong_application/screens/home/home_screen.dart';
import 'package:manong_application/screens/profile/profile_screen.dart';
import 'package:manong_application/screens/service_requests/service_requests_screen.dart';
import 'package:manong_application/screens/wallet/wallet_screen.dart';
import 'package:manong_application/services/update_checker.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/api/auth_service.dart';
import 'package:manong_application/widgets/auth_footer.dart';
import 'package:manong_application/widgets/bottom_nav_swipe.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  final int? index;
  final int? serviceRequestStatusIndex;
  final int? serviceRequestId;
  const MainScreen({
    super.key,
    this.index,
    this.serviceRequestStatusIndex,
    this.serviceRequestId,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String? _token;
  final Logger logger = Logger('MainScreen');
  final AuthService _authService = AuthService();
  final PageController _pageController = PageController();
  String? _error;
  bool _isLoading = true;
  late TrackingApiService _trackingApiService;
  late int? _index;
  late int? _serviceRequestStatusIndex;
  late int? _serviceRequestId;
  late BottomNavProvider? _navProvider;
  AppUser? _user;
  late UpdateChecker _updateChecker;

  final List<Widget> _pages = const [
    HomeScreen(),
    ServiceRequestsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeComponents();
    _loadToken();
    _getProfile();
  }

  void _initializeComponents() {
    _index = widget.index;
    _serviceRequestStatusIndex = widget.serviceRequestStatusIndex;
    _serviceRequestId = widget.serviceRequestId;
    _navProvider = Provider.of<BottomNavProvider>(context, listen: false);
    _navProvider?.setController(_pageController);
    _trackingApiService = TrackingApiService();
    _updateChecker = UpdateChecker();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchOngoingServiceRequest();
    });
  }

  Future<void> _checkForUpdates() async {
    // Add delay to ensure context is ready
    await Future.delayed(const Duration(milliseconds: 500));

    if (_user != null && mounted) {
      logger.info('Checking for updates for user ID: ${_user!.id}');
      await _updateChecker.checkAndShowUpdate(
        context: context, // Use current widget's context
        userId: _user!.id,
        forceCheck: false,
      );
    }
  }

  Future<void> _fetchOngoingServiceRequest() async {
    try {
      await _navProvider?.fetchOngoingServiceRequest();
      final ongoingRequest = _navProvider?.ongoingServiceRequest;

      if (ongoingRequest != null && mounted) {
        _pageController.animateToPage(
          1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } catch (e) {
      logger.severe('Error fetching ongoing service request: $e');
    }
  }

  Future<void> _loadToken() async {
    setState(() {
      _isLoading = true;
    });

    final token = await _authService.getNodeToken();

    setState(() {
      _isLoading = false;
    });

    if (token == null) {
      return;
    }

    setState(() {
      _token = token;
    });

    if (_index != null && _token != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_serviceRequestStatusIndex != null && _navProvider != null) {
          _navProvider?.setStatusIndex(_serviceRequestStatusIndex!);
        }
        if (_serviceRequestId != null && _navProvider != null) {
          _navProvider?.setServiceRequestId(_serviceRequestId!);
        }
        _pageController.animateToPage(
          _index!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  Future<void> _getProfile() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AuthService().getMyProfile();

      if (!mounted) return;

      setState(() {
        _user = response;
      });

      logger.info('User main_screen $_user');

      // Check for updates after getting profile
      if (mounted) {
        _checkForUpdates();
        logger.info('_checkForUpdates');
      }

      if (_user?.givenFeedbacks != null && _user!.givenFeedbacks!.isNotEmpty) {
        if (_user!.givenFeedbacks![0].serviceRequest?.status ==
            ServiceRequestStatus.completed) {
          _navProvider?.setHasNoFeedback(false);
        } else {
          logger.info('Has givenFeedbacks but status not completed');
        }
      } else {
        if (_user?.userRequests != null &&
            _user!.userRequests!.isNotEmpty &&
            _user!.userRequests![0].status == ServiceRequestStatus.completed) {
          final now = DateTime.now();
          final difference = now
              .difference(_user!.userRequests![0].createdAt!)
              .inDays;

          if (difference >= 0 && difference <= 7) {
            _navProvider?.setHasNoFeedback(true);
          }
        } else {
          _navProvider?.setHasNoFeedback(false);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
      logger.severe('Error getting profile _mainScreen $_error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: false,
      body: _token != null
          ? Consumer<BottomNavProvider>(
              builder: (context, navProvider, _) {
                // Get isManong from navProvider OR from user role
                final bool isManong =
                    navProvider.isManong ?? (_user?.role == UserRole.manong);

                // Create pages list based on isManong status
                final List<Widget> pages = [
                  HomeScreen(),
                  ServiceRequestsScreen(),
                  ProfileScreen(),
                ];

                // Add WalletScreen if user is Manong
                if (isManong) {
                  pages.add(
                    WalletScreen(),
                  ); // Make sure you have a WalletScreen widget
                }

                return BottomNavSwipe(
                  pages: pages, // Pass the dynamic pages list
                  pageController: _pageController,
                  currentIndex: navProvider.selectedindex,
                  onPageChanged: (index) => navProvider.setIndex(index),
                  onItemTapped: (index) {
                    navProvider.setIndex(index);
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  serviceRequest: navProvider.ongoingServiceRequest,
                  serviceRequestMessage: navProvider.serviceRequestMessage,
                  // Pass isManong correctly
                  isManong: isManong,
                  serviceRequestStatus: navProvider.serviceRequestStatus,
                  onTapContainer: () {
                    Navigator.pushNamed(
                      context,
                      '/service-request-details',
                      arguments: {
                        'serviceRequest': navProvider.ongoingServiceRequest,
                        'isManong': isManong,
                        'manongLatLng':
                            _trackingApiService.manongLatLngNotifier.value,
                      },
                    );
                  },
                  manongArrived: navProvider.manongArrived,
                  serviceRequestIsExpired: navProvider.serviceRequestIsExpired,
                  user: _user,
                  hasNoFeedback: navProvider.hasNoFeedback,
                  onTapCompleteProfile: () async {
                    final result = await Navigator.pushNamed(
                      context,
                      '/complete-profile',
                    );

                    if (result != null && result is Map) {
                      if (result['update'] == true) {
                        _getProfile();
                      }
                    }
                  },
                  navProvider: navProvider,
                );
              },
            )
          : Stack(
              children: [
                const Positioned.fill(child: HomeScreen()),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _isLoading
                      ? const SizedBox(
                          height: 10,
                          child: CircularProgressIndicator(
                            color: AppColorScheme.primaryColor,
                          ),
                        )
                      : const AuthFooter(),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
