import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/tracking_api_service.dart';
import 'package:manong_application/providers/bottom_nav_provider.dart';
import 'package:manong_application/screens/home/home_screen.dart';
import 'package:manong_application/screens/profile/profile_screen.dart';
import 'package:manong_application/screens/service_requests/service_requests_screen.dart';
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
  bool _isLoading = true;
  late TrackingApiService _trackingApiService;
  late int? _index;
  late int? _serviceRequestStatusIndex;
  late int? _serviceRequestId;
  late BottomNavProvider? _navProvider;

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
  }

  void _initializeComponents() {
    _index = widget.index;
    _serviceRequestStatusIndex = widget.serviceRequestStatusIndex;
    _serviceRequestId = widget.serviceRequestId;
    _navProvider = Provider.of<BottomNavProvider>(context, listen: false);
    _navProvider?.setController(_pageController);
    _trackingApiService = TrackingApiService();
    _navProvider?.fetchOngoingServiceRequest().then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_navProvider?.ongoingServiceRequest == null) return;
        _pageController.animateToPage(
          1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    });
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

    if (_index != null && _token != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_serviceRequestStatusIndex != null && _navProvider != null) {
          _navProvider?.setStatusIndex(_serviceRequestStatusIndex!);
        }
        if (_serviceRequestId != null && _navProvider != null) {
          _navProvider?.setServiceRequestId(_serviceRequestId!);
          logger.info('setServiceRequestId $_serviceRequestId');
        }
        _pageController.animateToPage(
          _index!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
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
                logger.info('navProvider.isAdmin ${navProvider.isAdmin}');

                return BottomNavSwipe(
                  pages: _pages,
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
                  isAdmin: navProvider.isAdmin,
                  serviceRequestStatus: navProvider.serviceRequestStatus,
                  onTapContainer: () {
                    Navigator.pushNamed(
                      context,
                      '/service-request-details',
                      arguments: {
                        'serviceRequest': navProvider.ongoingServiceRequest,
                        'isAdmin': navProvider.isAdmin,
                        'manongLatLng':
                            _trackingApiService.manongLatLngNotifier.value,
                      },
                    );
                  },
                  manongArrived: navProvider.manongArrived,
                  serviceRequestIsExpired: navProvider.serviceRequestIsExpired,
                );
              },
            )
          : Stack(
              children: [
                // Main content
                const Positioned.fill(child: HomeScreen()),

                // Footer pinned at bottom
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
