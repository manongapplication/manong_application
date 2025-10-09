import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:manong_application/api/auth_service.dart';
import 'package:manong_application/api/service_item_api_service.dart';
import 'package:manong_application/api/user_notification_api_service.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/models/service_item.dart';
import 'package:manong_application/providers/bottom_nav_provider.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/color_utils.dart';
import 'package:manong_application/utils/permission_utils.dart';
import 'package:manong_application/widgets/gradient_header_container.dart';
import 'package:manong_application/widgets/instruction_steps.dart';
import 'package:manong_application/widgets/manong_icon.dart';
import 'package:manong_application/widgets/manong_representational_icon.dart';
import 'package:manong_application/widgets/modal_icon_overlay.dart';
import 'package:manong_application/widgets/service_card_lite.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  final String? token;
  const HomeScreen({super.key, this.token});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Logger logger = Logger('HomeScreen');
  List<ServiceItem> _allServiceItems = [];
  List<ServiceItem> _filteredServiceItems = [];
  bool _isLoading = true;
  String? _error;
  late ServiceItemApiService _serviceItemApiService;
  late PermissionUtils? _permissionUtils;

  final TextEditingController _firstSearchController = TextEditingController();
  final TextEditingController _secondSearchController = TextEditingController();
  String? _token;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeComponents();
    _loadServiceItems();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPermissionDialog();
    });
  }

  void _initializeComponents() {
    _permissionUtils = PermissionUtils();
    _permissionUtils?.checkLocationPermission();
    _serviceItemApiService = ServiceItemApiService();
    _loadToken();
    _getUnreadCount();
  }

  Future<void> _loadServiceItems() async {
    try {
      if (!mounted) return;

      setState(() {
        _isLoading = true;
        _error = null;
      });

      final serviceItems = await _serviceItemApiService
          .fetchServiceItemsCacheFirst();

      // Add this mounted check before setState
      if (!mounted) return;

      setState(() {
        _allServiceItems = serviceItems;
        _filteredServiceItems = serviceItems;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _filterServiceItems(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredServiceItems = _allServiceItems.where((service) {
        bool titleMatches = service.title.toLowerCase().contains(lowerQuery);

        bool subServiceMatches = false;
        if (service.subServiceItems.isNotEmpty) {
          subServiceMatches = service.subServiceItems.any(
            (subService) => subService.title.toLowerCase().contains(lowerQuery),
          );
        }

        return titleMatches || subServiceMatches;
      }).toList();
    });
  }

  void _changeSecondSearch(String query) {
    _secondSearchController.text = query;
    _filterServiceItems(query);
  }

  Future<void> _loadToken() async {
    setState(() {
      _isLoading = true;
    });

    final token = await AuthService().getNodeToken();

    setState(() {
      _isLoading = false;
    });

    if (token == null) {
      return;
    }

    setState(() {
      _token = token;
    });
  }

  Widget _buildServiceGrid() {
    if (_error != null) {
      Future.delayed(Duration(seconds: 1), () {
        _loadServiceItems();
      });

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 100),
        child: Center(
          child: Column(
            children: [
              Text(
                'Error loading services. Please try again.',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadServiceItems,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorScheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 100),
        child: Center(
          child: CircularProgressIndicator(color: AppColorScheme.tealDark),
        ),
      );
    }

    if (_filteredServiceItems.isEmpty) {
      Future.delayed(Duration(seconds: 1), () {
        _loadServiceItems();
      });

      return SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 70),
          child: Center(
            child: Column(
              children: [
                CircularProgressIndicator(color: AppColorScheme.primaryColor),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Wrap(
        spacing: 4,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: _filteredServiceItems.map((serviceItem) {
          return SizedBox(
            width: (MediaQuery.of(context).size.width - 48 - 12) / 4,
            height: 100,
            child: ServiceCardLite(
              serviceItem: serviceItem,
              iconColor: colorFromHex(serviceItem.iconColor),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/sub-service-list',
                  arguments: {
                    'serviceItem': serviceItem,
                    'iconColor': colorFromHex(serviceItem.iconColor),
                  },
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _showPermissionDialog() async {
    if (_permissionUtils != null) {
      bool granted = await _permissionUtils!.isNotificationPermissionGranted();
      if (!granted && mounted) {
        showDialog(
          context: navigatorKey.currentContext!,
          builder: (context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ModalIconOverlay(
                onPressed: () async {
                  await _permissionUtils!.checkNotificationPermission();
                  if (mounted) Navigator.of(navigatorKey.currentContext!).pop();
                },
                icons: Icons.notifications_active,
                description:
                    'We’d like to send you notifications about updates, reminders, and important alerts.',
              ),
            );
          },
        );
      }
    }
  }

  Future<void> _getUnreadCount() async {
    try {
      final response = await UserNotificationApiService().getUnreadCount();

      if (response != null) {
        if (response['data'] != null) {
          final count = response['data']['count'];
          setState(() {
            _unreadCount = count;
          });
        }
      }
    } catch (e) {
      logger.severe('Error getting unread notifications $e');
    }
  }

  Widget _buildSearchHeader() {
    return Column(
      children: [
        Text(
          'Choose Your Service',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Professional help is just a tap away",
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            controller: _firstSearchController,
            onChanged: _changeSecondSearch,
            decoration: InputDecoration(
              hintText: 'Search services...',
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade700),
              filled: true,
              hintStyle: TextStyle(color: Colors.grey.shade700),
              fillColor: AppColorScheme.primaryLight,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationBell() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(30),
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(navigatorKey.currentContext!, '/notifications');
        },
        behavior: HitTestBehavior.translucent,
        child: Container(
          padding: const EdgeInsets.all(0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.notifications, color: Colors.white, size: 28),
              if (_unreadCount > 0) ...[
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    height: 15,
                    width: 15,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _unreadCount.toString(),
                      style: TextStyle(color: Colors.white, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewsRoom() {
    return InstructionSteps();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorScheme.backgroundGrey,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            // expandedHeight: 170,
            expandedHeight: 70,
            floating: false,
            pinned: true,
            snap: false,
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final top = constraints.biggest.height;
                final collapsed =
                    top <= kToolbarHeight + MediaQuery.of(context).padding.top;

                return FlexibleSpaceBar(
                  background: SafeArea(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      // borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  manongIcon(size: 40, fit: BoxFit.contain),
                                  const SizedBox(width: 4),
                                  Center(
                                    child: Text(
                                      'Manong App',
                                      style: TextStyle(
                                        color: AppColorScheme.primaryLight,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // -- Notification bell
                              if (_token != null) ...[
                                Positioned(
                                  top: 6,
                                  right: 4,
                                  child: _buildNotificationBell(),
                                ),
                              ],
                            ],
                          ),

                          // Row(
                          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          //   crossAxisAlignment: CrossAxisAlignment.end,
                          //   children: [
                          //     Container(
                          //       width: 130,
                          //       padding: const EdgeInsets.only(
                          //         bottom: 24,
                          //         left: 14,
                          //       ),
                          //       child: Text(
                          //         'Home services, anytime you need.',
                          //         style: TextStyle(
                          //           fontSize: 14,
                          //           color: AppColorScheme.backgroundGrey,
                          //           height: 1.3,
                          //         ),
                          //       ),
                          //     ),
                          //     Flexible(child: manongRepresentationalIcon()),
                          //   ],
                          // ),
                        ],
                      ),
                    ),
                  ),

                  title: collapsed
                      ? Padding(
                          padding: const EdgeInsets.only(
                            top: 20,
                            left: 20,
                            right: 20,
                          ),
                          child: Row(
                            children: [
                              manongIcon(size: 40, fit: BoxFit.contain),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _secondSearchController,
                                  onChanged: _filterServiceItems,
                                  decoration: InputDecoration(
                                    hintText: 'Search services...',
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: Colors.grey.shade700,
                                    ),
                                    filled: true,
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
                                    fillColor: AppColorScheme.primaryLight,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 0,
                                      horizontal: 16,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildNotificationBell(),
                            ],
                          ),
                        )
                      : null,
                  centerTitle: true,
                );
              },
            ),
            backgroundColor: AppColorScheme.primaryColor,
          ),

          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildSearchHeader(),
                  ),
                  _buildServiceGrid(),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.network(
                          'https://scontent.fcrk1-4.fna.fbcdn.net/v/t39.30808-6/558396638_122101818243050982_2984028404746068847_n.jpg?_nc_cat=111&ccb=1-7&_nc_sid=127cfc&_nc_ohc=cfN3BWfEWWIQ7kNvwHc_u5K&_nc_oc=Adm4YseuHy-SBZHUiifE5GOqO8WPzZx6_LmORiT_pHrMcVH6PlVzAymvzCMgd_6HKYE&_nc_zt=23&_nc_ht=scontent.fcrk1-4.fna&_nc_gid=lS69ZD74eULOwdud6u35qw&oh=00_Afduks5k6z8zbkyF_FL2F8Ti7N2afH2717LQYHyfLDFILA&oe=68EA4AA0',
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.broken_image),
                          height: 180,
                          width: 500,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(children: [_buildNewsRoom()]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
