import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/auth_service.dart';
import 'package:manong_application/api/bookmark_item_api_service.dart';
import 'package:manong_application/api/bookmark_item_manager.dart';
import 'package:manong_application/api/service_item_api_service.dart';
import 'package:manong_application/api/user_notification_api_service.dart';
import 'package:manong_application/api/wordpress_post_api_service.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/models/app_user.dart';
import 'package:manong_application/models/bookmark_item_type.dart';
import 'package:manong_application/models/service_item.dart';
import 'package:manong_application/models/wordpress_post.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/color_utils.dart';
import 'package:manong_application/utils/debouncer.dart';
import 'package:manong_application/utils/permission_utils.dart';
import 'package:manong_application/widgets/incomplete_profile_card.dart';
import 'package:manong_application/widgets/instruction_steps.dart';
import 'package:manong_application/widgets/manong_icon.dart';
import 'package:manong_application/widgets/modal_icon_overlay.dart';
import 'package:manong_application/widgets/service_card_lite.dart';
import 'package:manong_application/widgets/wordpress_post_card.dart';

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
  bool _isPostLoading = false;
  String? _error;
  late ServiceItemApiService _serviceItemApiService;
  late PermissionUtils? _permissionUtils;
  late List<WordpressPost> _wordpressPost = [
    WordpressPost(
      id: 0,
      title: "Welcome to Manong App",
      excerpt:
          "Welcome to our latest update! Here, we share insights, stories, and announcements to keep you informed and inspired.",
      imageUrl: null,
      link: "https://manongapp.com",
      content: '',
    ),
  ];

  final TextEditingController _firstSearchController = TextEditingController();
  final TextEditingController _secondSearchController = TextEditingController();
  String? _token;
  int _unreadCount = 0;

  final _homeSearchDebouncer = Debouncer(
    delay: const Duration(milliseconds: 300), // Optimized: 500ms → 300ms
  );
  final _collapsedSearchDebouncer = Debouncer(
    delay: const Duration(milliseconds: 300), // Optimized: 500ms → 300ms
  );

  // PERFORMANCE OPTIMIZATION: Cache for filtered results
  final Map<String, List<ServiceItem>> _filterCache = {};
  AppUser? _profile;

  @override
  void initState() {
    super.initState();
    _initializeComponents();

    // PERFORMANCE OPTIMIZATION: Delay initial load to avoid jank
    Future.delayed(Duration.zero, _loadServiceItems);

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
    _fetchWordpressPost();
    _getProfile();
  }

  Future<void> _getProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final token = await AuthService().getNodeToken();

      if (token == null || token.isEmpty) {
        _debugLog('User is not logged in, skipping profile check');
        return;
      }

      final response = await AuthService().getMyProfile();

      if (mounted) {
        setState(() {
          _profile = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load profile. Please try again.';
        });
      }
      logger.severe('Error loading profile: $e');
    }
  }

  Future<void> _batchCheckServiceBookmarks() async {
    try {
      final serviceIds = _allServiceItems.map((item) => item.id).toList();
      if (serviceIds.isEmpty) return;

      // PERFORMANCE OPTIMIZATION: Use batch API only
      final batchResult = await BookmarkItemApiService().batchCheckBookmarks(
        type: BookmarkItemType.SERVICE_ITEM,
        ids: serviceIds,
      );

      if (batchResult != null && batchResult.isNotEmpty) {
        // Use bulk update for better performance
        BookmarkItemManager().updateMultipleBookmarks(
          batchResult,
          BookmarkItemType.SERVICE_ITEM,
        );
      }
    } catch (e) {
      _debugLog('Error in _batchCheckServiceBookmarks: $e');
    }
  }

  // PERFORMANCE OPTIMIZATION: Combined filter and sort
  void _filterServiceItems(String query) {
    final cacheKey = query.toLowerCase();

    // Check cache first for performance
    if (_filterCache.containsKey(cacheKey)) {
      final cached = _filterCache[cacheKey]!;
      if (!_listEquals(cached, _filteredServiceItems)) {
        setState(() {
          _filteredServiceItems = cached;
        });
      }
      return;
    }

    final lowerQuery = query.toLowerCase();

    // Single-pass filtering with comprehensive search
    final filtered = _allServiceItems.where((service) {
      // 1. Check title match
      final titleMatches = service.title.toLowerCase().contains(lowerQuery);

      // 2. Check description match (if description exists)
      bool descriptionMatches = false;
      if (service.description != null && service.description!.isNotEmpty) {
        descriptionMatches = service.description!.toLowerCase().contains(
          lowerQuery,
        );
      }

      // 3. Check subservices (only if query is long enough for performance)
      bool subServiceMatches = false;
      if (lowerQuery.length >= 2 && service.subServiceItems.isNotEmpty) {
        subServiceMatches = service.subServiceItems.any((subService) {
          // Check subservice title
          final subTitleMatch = subService.title.toLowerCase().contains(
            lowerQuery,
          );

          // Check subservice description if available
          bool subDescriptionMatch = false;
          if (subService.description != null &&
              subService.description!.isNotEmpty) {
            subDescriptionMatch = subService.description!
                .toLowerCase()
                .contains(lowerQuery);
          }

          return subTitleMatch || subDescriptionMatch;
        });
      }

      return titleMatches || descriptionMatches || subServiceMatches;
    }).toList();

    // Sort with prioritization
    filtered.sort((a, b) {
      // 1. Bookmarked items first
      final aBookmarked =
          BookmarkItemManager.getCachedStatus(
            a.id,
            BookmarkItemType.SERVICE_ITEM,
          ) ??
          false;
      final bBookmarked =
          BookmarkItemManager.getCachedStatus(
            b.id,
            BookmarkItemType.SERVICE_ITEM,
          ) ??
          false;

      if (aBookmarked && !bBookmarked) return -1;
      if (!aBookmarked && bBookmarked) return 1;

      // 2. Sort by relevance (items matching in title come before description matches)
      final aTitleMatch = a.title.toLowerCase().contains(lowerQuery);
      final bTitleMatch = b.title.toLowerCase().contains(lowerQuery);
      final aDescMatch = a.description.toLowerCase().contains(lowerQuery);
      final bDescMatch = b.description.toLowerCase().contains(lowerQuery);

      // Title matches prioritized over description matches
      if (aTitleMatch && !bTitleMatch) return -1;
      if (!aTitleMatch && bTitleMatch) return 1;

      // If both match in same field, check description matches
      if (aDescMatch && !bDescMatch) return -1;
      if (!aDescMatch && bDescMatch) return 1;

      // 3. Sort by created date (latest first)
      final aCreatedAt = a.createdAt ?? DateTime(1900);
      final bCreatedAt = b.createdAt ?? DateTime(1900);

      if (aCreatedAt.isAfter(bCreatedAt)) return -1;
      if (aCreatedAt.isBefore(bCreatedAt)) return 1;

      // 4. If same date, sort alphabetically
      return a.title.compareTo(b.title);
    });

    // Cache the result for future identical queries
    _filterCache[cacheKey] = filtered;

    // Only update state if the filtered list has actually changed
    if (!_listEquals(filtered, _filteredServiceItems)) {
      setState(() {
        _filteredServiceItems = filtered;
      });
    }
  }

  // KEEP THIS: It's working correctly
  void _sortServicesWithBookmarksFirst() {
    setState(() {
      _filteredServiceItems.sort((a, b) {
        final aBookmarked =
            BookmarkItemManager.getCachedStatus(
              a.id,
              BookmarkItemType.SERVICE_ITEM,
            ) ??
            false;
        final bBookmarked =
            BookmarkItemManager.getCachedStatus(
              b.id,
              BookmarkItemType.SERVICE_ITEM,
            ) ??
            false;

        // 1. Bookmarked items first
        if (aBookmarked && !bBookmarked) return -1;
        if (!aBookmarked && bBookmarked) return 1;

        // 2. Sort by created date (latest first)
        final aCreatedAt = a.createdAt ?? DateTime(1900);
        final bCreatedAt = b.createdAt ?? DateTime(1900);

        if (aCreatedAt.isAfter(bCreatedAt)) return -1;
        if (aCreatedAt.isBefore(bCreatedAt)) return 1;

        // 3. If same date, sort alphabetically
        return a.title.compareTo(b.title);
      });
    });
  }

  Future<void> _loadServiceItems() async {
    try {
      if (!mounted) return;

      setState(() {
        _isLoading = true;
        _error = null;
      });

      _debugLog('Loading service items...');
      final serviceItems = await _serviceItemApiService
          .fetchServiceItemsCacheFirst();

      if (!mounted) return;

      _debugLog('Loaded ${serviceItems.length} services');

      setState(() {
        _allServiceItems = serviceItems;
        _filteredServiceItems = List.from(serviceItems);
      });

      // PERFORMANCE OPTIMIZATION: Load bookmarks in background
      unawaited(
        _batchCheckServiceBookmarks().then((_) {
          if (mounted) {
            _sortServicesWithBookmarksFirst();
          }
        }),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
      _debugLog('Error loading service items: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // PERFORMANCE OPTIMIZATION: Use Flutter's built-in listEquals
  bool _listEquals(List<ServiceItem> list1, List<ServiceItem> list2) {
    return listEquals(list1, list2);
  }

  void _changeSecondSearch(String query) {
    // Sync to first controller
    _syncSearchControllers(
      query,
      _secondSearchController,
      _firstSearchController,
    );

    _collapsedSearchDebouncer.run(() {
      if (mounted) {
        _filterServiceItems(query);
      }
    });
  }

  void _syncSearchControllers(
    String query,
    TextEditingController source,
    TextEditingController target,
  ) {
    if (source.text != target.text) {
      target.text = query;
      target.selection = TextSelection.fromPosition(
        TextPosition(offset: query.length),
      );
    }
  }

  // PERFORMANCE OPTIMIZATION: Don't set loading state for token load
  Future<void> _loadToken() async {
    final token = await AuthService().getNodeToken();

    if (mounted && token != null) {
      setState(() {
        _token = token;
      });
    }
  }

  Widget _buildServiceGrid() {
    if (_error != null) {
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

    // FIX: Check if search is active
    final isSearching =
        _firstSearchController.text.isNotEmpty ||
        _secondSearchController.text.isNotEmpty;

    if (_filteredServiceItems.isEmpty) {
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 70),
          child: Center(
            child: Column(
              children: [
                if (isSearching)
                  Column(
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No services found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try a different search term',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                else
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
          final cachedBookmark = BookmarkItemManager.getCachedStatus(
            serviceItem.id,
            BookmarkItemType.SERVICE_ITEM,
          );

          return SizedBox(
            width: (MediaQuery.of(context).size.width - 48 - 12) / 4,
            height: 100,
            child: ServiceCardLite(
              key: ValueKey('service_${serviceItem.id}_$cachedBookmark'),
              serviceItem: serviceItem,
              onTap: () async {
                // Store current bookmark status
                final wasBookmarked = cachedBookmark ?? false;

                String searchToPass = _secondSearchController.text.isNotEmpty
                    ? _secondSearchController.text
                    : _firstSearchController.text;

                final result = await Navigator.pushNamed(
                  context,
                  '/sub-service-list',
                  arguments: {
                    'serviceItem': serviceItem,
                    'iconColor': colorFromHex(serviceItem.iconColor),
                    'search': searchToPass,
                  },
                );

                // KEEP THIS: It's working for bookmark updates
                if (result != null &&
                    result is Map &&
                    result['updated'] == true) {
                  final nowBookmarked =
                      BookmarkItemManager.getCachedStatus(
                        serviceItem.id,
                        BookmarkItemType.SERVICE_ITEM,
                      ) ??
                      false;

                  // Only update if bookmark status changed
                  if (wasBookmarked != nowBookmarked) {
                    // Just re-sort (cache is already updated by SubServiceListScreen)
                    _sortServicesWithBookmarksFirst();
                  }
                }
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
                    'We\'d like to send you notifications about updates, reminders, and important alerts.',
              ),
            );
          },
        );
      }
    }
  }

  // PERFORMANCE OPTIMIZATION: Silent fail for non-critical feature
  Future<void> _getUnreadCount() async {
    try {
      final response = await UserNotificationApiService().getUnreadCount();

      if (response != null && response['data'] != null) {
        final count = response['data']['count'];
        if (mounted) {
          setState(() {
            _unreadCount = count;
          });
        }
      }
    } catch (e) {
      // Silent fail
    }
  }

  Widget _buildSearchHeader() {
    return Column(
      children: [
        const Text(
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
            onChanged: (query) {
              // Sync to second controller
              _syncSearchControllers(
                query,
                _firstSearchController,
                _secondSearchController,
              );
              // Trigger search
              _homeSearchDebouncer.run(() {
                if (mounted) {
                  _filterServiceItems(query);
                }
              });
            },
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
              const Icon(Icons.notifications, color: Colors.white, size: 28),
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
                      _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
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

  Widget _buildInstructionsRoom() {
    return InstructionSteps();
  }

  Widget _buildIncompleteProfileCard() {
    if (_profile == null) return const SizedBox.shrink();
    if (!(_profile!.firstName == null || _profile!.email == null)) {
      return const SizedBox.shrink();
    }
    return IncompleteProfileCard(
      onTap: () async {
        final result = await Navigator.pushNamed(context, '/complete-profile');

        if (result != null && result is Map) {
          if (result['update'] == true) {
            _getProfile();
          }
        }
      },
    );
  }

  Future<void> _fetchWordpressPost() async {
    if (_isPostLoading) return;

    setState(() {
      _isPostLoading = true;
    });

    try {
      final response = await WordpressPostApiService().fetchWordpressPosts();

      if (!mounted) return;

      setState(() {
        if (response == null) {
          _wordpressPost = [
            WordpressPost(
              id: 0,
              title: "Welcome to Manong App",
              excerpt:
                  "Welcome to our latest update! Here, we share insights, stories, and announcements to keep you informed and inspired.",
              imageUrl: null,
              link: "https://manongapp.com",
              content: '',
            ),
          ];
        } else {
          _wordpressPost = response;
        }
        _isPostLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isPostLoading = false;
      });
    }
  }

  Widget _wordpressPostCards() {
    if (_wordpressPost.isEmpty) {
      return SizedBox(
        height: 150,
        child: Center(
          child: Text(
            'No posts available',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _wordpressPost.map((post) {
          return WordpressPostCard(
            key: ValueKey('post_${post.id}'), // PERFORMANCE: Add key
            id: post.id,
            title: post.title,
            excerpt: post.excerpt,
            content: post.content,
            imageUrl: post.imageUrl,
            link: post.link,
          );
        }).toList(),
      ),
    );
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      logger.info(message);
    }
  }

  Future<void> _refreshData() async {
    // Clear caches
    _filterCache.clear();

    // Parallel data fetching
    await Future.wait([
      _loadServiceItems(),
      _fetchWordpressPost(),
      _getUnreadCount(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorScheme.backgroundGrey,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppColorScheme.primaryColor,
        backgroundColor: AppColorScheme.backgroundGrey,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 70,
              floating: false,
              pinned: true,
              snap: false,
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  final top = constraints.biggest.height;
                  final collapsed =
                      top <=
                      kToolbarHeight + MediaQuery.of(context).padding.top;

                  return FlexibleSpaceBar(
                    background: SafeArea(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
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
                                    const Center(
                                      child: Text(
                                        'Manong',
                                        style: TextStyle(
                                          color: AppColorScheme.primaryLight,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 22,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                if (_token != null) ...[
                                  Positioned(
                                    top: 6,
                                    right: 4,
                                    child: _buildNotificationBell(),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    title: collapsed
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                manongIcon(size: 40, fit: BoxFit.contain),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _secondSearchController,
                                    onChanged: _changeSecondSearch,
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
                                      contentPadding:
                                          const EdgeInsets.symmetric(
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
                    titlePadding: collapsed
                        ? EdgeInsets.only(
                            top: MediaQuery.of(context).padding.top,
                            left: 0,
                            right: 0,
                            bottom: 0,
                          )
                        : null,
                    centerTitle: false, // Changed from true to false
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
                  _buildIncompleteProfileCard(),
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
                        if (_isPostLoading)
                          SizedBox(
                            height: 150,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColorScheme.primaryColor,
                              ),
                            ),
                          )
                        else
                          _wordpressPostCards(),
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
                    child: Column(children: [_buildInstructionsRoom()]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _homeSearchDebouncer.cancel();
    _collapsedSearchDebouncer.cancel();
    _firstSearchController.dispose();
    _secondSearchController.dispose();
    super.dispose();
  }
}
