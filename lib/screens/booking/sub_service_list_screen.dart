import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconify_design/iconify_design.dart';
import 'package:manong_application/api/bookmark_item_manager.dart';
import 'package:manong_application/models/bookmark_item_type.dart';
import 'package:manong_application/models/service_item.dart';
import 'package:manong_application/models/sub_service_item.dart';
import 'package:manong_application/utils/color_utils.dart';
import 'package:manong_application/widgets/my_app_bar.dart';
import 'package:manong_application/widgets/sub_service_card.dart';
import 'package:manong_application/api/bookmark_item_api_service.dart';

class SubServiceListScreen extends StatefulWidget {
  final ServiceItem serviceItem;
  final Color? iconColor;
  final String? search;

  const SubServiceListScreen({
    super.key,
    required this.serviceItem,
    this.iconColor,
    this.search,
  });

  @override
  State<SubServiceListScreen> createState() => _SubServiceListScreenState();
}

class _SubServiceListScreenState extends State<SubServiceListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<SubServiceItem> _filteredSubServiceItems = [];
  List<SubServiceItem> _displayedSubServiceItems = [];
  String _searchQuery = '';

  // Pagination variables
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  // Bookmark state
  Map<int, bool> _bookmarkStatus = {};
  bool _isLoadingBookmarks = false;

  // Service item bookmark state
  bool _isServiceBookmarked = false;
  bool _isLoadingServiceBookmark = false;

  // Track if any bookmarks were updated
  bool _hasBookmarkUpdates = false;

  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();

    if (widget.search != null && widget.search!.isNotEmpty) {
      _searchController.text = widget.search!;
      _searchQuery = widget.search!;
    }

    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _fetchAllBookmarks();
    _fetchServiceBookmarkStatus();
  }

  Future<void> _fetchServiceBookmarkStatus() async {
    setState(() {
      _isLoadingServiceBookmark = true;
    });

    try {
      final isBookmarked = await BookmarkItemApiService().isItemBookmarked(
        itemId: widget.serviceItem.id,
        type: BookmarkItemType.SERVICE_ITEM,
      );

      if (mounted) {
        setState(() {
          _isServiceBookmarked = isBookmarked ?? false;
          _isLoadingServiceBookmark = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching service bookmark: $e');
      if (mounted) {
        setState(() {
          _isServiceBookmarked = false;
          _isLoadingServiceBookmark = false;
        });
      }
    }
  }

  Future<void> _toggleServiceBookmark() async {
    if (_isLoadingServiceBookmark) return;

    setState(() {
      _isLoadingServiceBookmark = true;
    });

    try {
      if (_isServiceBookmarked) {
        await BookmarkItemApiService().removeBookmark(
          itemId: widget.serviceItem.id,
          type: BookmarkItemType.SERVICE_ITEM,
        );
      } else {
        await BookmarkItemApiService().addBookmark(
          itemId: widget.serviceItem.id,
          type: BookmarkItemType.SERVICE_ITEM,
        );
      }

      BookmarkItemManager.updateCache(
        widget.serviceItem.id,
        BookmarkItemType.SERVICE_ITEM,
        !_isServiceBookmarked,
      );

      if (mounted) {
        setState(() {
          _isServiceBookmarked = !_isServiceBookmarked;
          _isLoadingServiceBookmark = false;
          _hasBookmarkUpdates = true;
        });
      }
    } catch (e) {
      print('Error toggling service bookmark: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update bookmark'),
          backgroundColor: Colors.red,
        ),
      );

      if (mounted) {
        setState(() {
          _isLoadingServiceBookmark = false;
        });
      }
    }
  }

  Widget _buildBookmarkButton() {
    if (_isLoadingServiceBookmark) {
      return SizedBox(
        width: 32,
        height: 32,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return IconButton(
      icon: Icon(
        _isServiceBookmarked
            ? Icons.bookmark_added
            : Icons.bookmark_add_outlined,
        color: _isServiceBookmarked ? Colors.amber : Colors.white,
      ),
      onPressed: _toggleServiceBookmark,
    );
  }

  // OPTIMIZED VERSION: Use your old working structure but with batch API
  Future<void> _fetchAllBookmarks() async {
    setState(() {
      _isLoadingBookmarks = true;
    });

    try {
      // Try batch API first (fastest)
      final subServiceIds = widget.serviceItem.subServiceItems
          .map((item) => item.id)
          .toList();

      final batchResult = await BookmarkItemApiService().batchCheckBookmarks(
        type: BookmarkItemType.SUB_SERVICE_ITEM,
        ids: subServiceIds,
      );

      if (batchResult != null && batchResult.isNotEmpty) {
        // Update cache with batch results
        BookmarkItemManager().updateMultipleBookmarks(
          batchResult,
          BookmarkItemType.SUB_SERVICE_ITEM,
        );

        final newBookmarkStatus = <int, bool>{};
        for (final item in widget.serviceItem.subServiceItems) {
          newBookmarkStatus[item.id] = batchResult[item.id] ?? false;
        }

        if (mounted) {
          setState(() {
            _bookmarkStatus = newBookmarkStatus;
            _filteredSubServiceItems = List.from(
              widget.serviceItem.subServiceItems,
            );
            _sortItemsByBookmark();
            _updateDisplayedItems();
          });
        }
      } else {
        // Fallback to your old working method
        await _fetchBookmarksOldWay();
      }
    } catch (e) {
      debugPrint('Error with batch bookmarks: $e');
      // Fallback to old method
      await _fetchBookmarksOldWay();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingBookmarks = false;
        });
      }
    }
  }

  // Your old working method (as fallback)
  Future<void> _fetchBookmarksOldWay() async {
    try {
      // Fetch all bookmarked sub-service items (single API call)
      final bookmarks = await BookmarkItemApiService()
          .fetchBookmarkSubServiceItems();

      final bookmarkedIds = <int>{};
      if (bookmarks != null) {
        for (final bookmark in bookmarks) {
          if (bookmark.subServiceItemId != null) {
            bookmarkedIds.add(bookmark.subServiceItemId!);
          }
        }
      }

      // Update bookmark status for all items
      final newBookmarkStatus = <int, bool>{};
      for (final item in widget.serviceItem.subServiceItems) {
        newBookmarkStatus[item.id] = bookmarkedIds.contains(item.id);

        // Also update cache
        BookmarkItemManager.updateCache(
          item.id,
          BookmarkItemType.SUB_SERVICE_ITEM,
          bookmarkedIds.contains(item.id),
        );
      }

      if (mounted) {
        setState(() {
          _bookmarkStatus = newBookmarkStatus;
          _filteredSubServiceItems = List.from(
            widget.serviceItem.subServiceItems,
          );
          _sortItemsByBookmark();
          _updateDisplayedItems();

          if (widget.search != null && widget.search!.isNotEmpty) {
            _processSearch(widget.search!);
          } else {
            _updateDisplayedItems();
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching bookmarks old way: $e');
      // Final fallback: check cache only
      final newBookmarkStatus = <int, bool>{};
      for (final item in widget.serviceItem.subServiceItems) {
        final cached = BookmarkItemManager.getCachedStatus(
          item.id,
          BookmarkItemType.SUB_SERVICE_ITEM,
        );
        newBookmarkStatus[item.id] = cached ?? false;
      }

      if (mounted) {
        setState(() {
          _bookmarkStatus = newBookmarkStatus;
          _filteredSubServiceItems = List.from(
            widget.serviceItem.subServiceItems,
          );
          _sortItemsByBookmark();
          _updateDisplayedItems();
        });
      }
    }
  }

  void _sortItemsByBookmark() {
    _filteredSubServiceItems.sort((a, b) {
      final aBookmarked = _bookmarkStatus[a.id] ?? false;
      final bBookmarked = _bookmarkStatus[b.id] ?? false;

      if (aBookmarked && !bBookmarked) return -1;
      if (!aBookmarked && bBookmarked) return 1;

      return a.title.compareTo(b.title);
    });
  }

  void _onSearchChanged() {
    _searchDebounceTimer?.cancel();

    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      _processSearch(query);
      return;
    }

    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _processSearch(query);
      }
    });
  }

  void _processSearch(String query) {
    setState(() {
      _searchQuery = query;
      _resetPagination();

      if (_searchQuery.isEmpty) {
        _filteredSubServiceItems = List.from(
          widget.serviceItem.subServiceItems,
        );
        _sortItemsByBookmark();
      } else {
        _filteredSubServiceItems = widget.serviceItem.subServiceItems.where((
          item,
        ) {
          final title = item.title.toLowerCase();
          final description = item.description?.toLowerCase() ?? '';

          return title.contains(_searchQuery) ||
              description.contains(_searchQuery);
        }).toList();

        _filteredSubServiceItems.sort((a, b) {
          final aBookmarked = _bookmarkStatus[a.id] ?? false;
          final bBookmarked = _bookmarkStatus[b.id] ?? false;

          if (aBookmarked && !bBookmarked) return -1;
          if (!aBookmarked && bBookmarked) return 1;

          return a.title.compareTo(b.title);
        });
      }

      _updateDisplayedItems();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreItems();
    }
  }

  void _loadMoreItems() {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    Future.delayed(Duration(milliseconds: 500), () {
      if (!mounted) return;

      setState(() {
        _currentPage++;
        _updateDisplayedItems();
        _isLoadingMore = false;

        final totalItems = _filteredSubServiceItems.length;
        final displayedCount = _displayedSubServiceItems.length;
        _hasMore = displayedCount < totalItems;
      });
    });
  }

  void _updateDisplayedItems() {
    final endIndex = _currentPage * _itemsPerPage;

    _displayedSubServiceItems = _filteredSubServiceItems.sublist(
      0,
      endIndex > _filteredSubServiceItems.length
          ? _filteredSubServiceItems.length
          : endIndex,
    );

    final totalItems = _filteredSubServiceItems.length;
    final displayedCount = _displayedSubServiceItems.length;
    _hasMore = displayedCount < totalItems;
  }

  void _resetPagination() {
    setState(() {
      _currentPage = 1;
      _isLoadingMore = false;
      _updateDisplayedItems();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _filteredSubServiceItems = List.from(widget.serviceItem.subServiceItems);
      _sortItemsByBookmark();
      _resetPagination();
    });
  }

  Future<void> _onBookmarkToggled(int subServiceItemId) async {
    final wasBookmarked = _bookmarkStatus[subServiceItemId] ?? false;
    final isAddingBookmark = !wasBookmarked;

    try {
      // USE YOUR WORKING OLD API METHODS
      if (isAddingBookmark) {
        await BookmarkItemApiService().addBookmarkSubServiceItem(
          subServiceItemId,
        );
      } else {
        await BookmarkItemApiService().removeBookmarkSubServiceItem(
          subServiceItemId,
        );
      }

      // UPDATE THE CACHE
      BookmarkItemManager.updateCache(
        subServiceItemId,
        BookmarkItemType.SUB_SERVICE_ITEM,
        !wasBookmarked,
      );

      if (mounted) {
        setState(() {
          _bookmarkStatus[subServiceItemId] = !wasBookmarked;
          _hasBookmarkUpdates = true;
          _sortItemsByBookmark();

          if (isAddingBookmark && _currentPage > 1) {
            _currentPage = 1;
          }

          _updateDisplayedItems();
        });
      }
    } catch (e) {
      debugPrint('Error toggling bookmark: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update bookmark'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (isAddingBookmark && _scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  Future<bool> _onWillPop() async {
    Navigator.of(context).pop({
      'updated': _hasBookmarkUpdates,
      'refreshNeeded': _hasBookmarkUpdates,
    });
    return false;
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serviceItem = widget.serviceItem;
    final iconColor = widget.iconColor ?? Colors.black;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: myAppBar(
          title: serviceItem.title,
          leading: IconifyIcon(
            icon: serviceItem.iconName,
            size: 24,
            color: Colors.white,
          ),
          trailing: _buildBookmarkButton(),
          onBackPressed: () {
            Navigator.of(context).pop({'updated': _hasBookmarkUpdates});
          },
        ),
        body: Container(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 14),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search services...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: Colors.grey.shade600,
                            ),
                            onPressed: _clearSearch,
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Results count with pagination info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _searchQuery.isEmpty
                          ? '${_displayedSubServiceItems.length} of ${_filteredSubServiceItems.length} services'
                          : '${_displayedSubServiceItems.length} of ${_filteredSubServiceItems.length} found',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    if (_hasMore && _displayedSubServiceItems.isNotEmpty)
                      Text(
                        'Page $_currentPage',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(height: 2),

              Expanded(
                child: _isLoadingBookmarks && _filteredSubServiceItems.isEmpty
                    ? Center(
                        child: CircularProgressIndicator(
                          color: colorFromHex(serviceItem.iconTextColor),
                        ),
                      )
                    : _displayedSubServiceItems.isEmpty
                    ? _buildEmptyState()
                    : SafeArea(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(height: 4),

                            Expanded(
                              child:
                                  NotificationListener<
                                    OverscrollIndicatorNotification
                                  >(
                                    onNotification:
                                        (
                                          OverscrollIndicatorNotification
                                          overscroll,
                                        ) {
                                          overscroll.disallowIndicator();
                                          return true;
                                        },
                                    child: ListView.builder(
                                      key: PageStorageKey<String>(
                                        'subServiceList_${widget.serviceItem.id}',
                                      ),
                                      controller: _scrollController,
                                      itemCount:
                                          _displayedSubServiceItems.length +
                                          (_hasMore ? 1 : 0) +
                                          1,
                                      itemBuilder: (context, index) {
                                        if (_hasMore &&
                                            index ==
                                                _displayedSubServiceItems
                                                    .length) {
                                          return _buildLoadingIndicator();
                                        }

                                        if (index ==
                                            _displayedSubServiceItems.length +
                                                (_hasMore ? 1 : 0)) {
                                          return _buildUpcomingServicesCard(
                                            iconColor,
                                            serviceItem,
                                          );
                                        }

                                        final subServiceItem =
                                            _displayedSubServiceItems[index];

                                        return Padding(
                                          key: Key(
                                            'subService_${subServiceItem.id}_${_bookmarkStatus[subServiceItem.id] ?? false}',
                                          ),
                                          padding: EdgeInsets.only(bottom: 12),
                                          child: SubServiceCard(
                                            onTap: () {
                                              Navigator.pushNamed(
                                                context,
                                                '/problem-details',
                                                arguments: {
                                                  'serviceItem': serviceItem,
                                                  'subServiceItem':
                                                      subServiceItem,
                                                  'iconColor': iconColor,
                                                },
                                              );
                                            },
                                            subServiceItem: subServiceItem,
                                            iconColor: iconColor,
                                            iconTextColor: colorFromHex(
                                              serviceItem.iconTextColor,
                                            ),
                                            isBookmarked:
                                                _bookmarkStatus[subServiceItem
                                                    .id],
                                            onBookmarkToggled: () =>
                                                _onBookmarkToggled(
                                                  subServiceItem.id,
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: _isLoadingMore
            ? Column(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.iconColor ?? Colors.blue,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Loading more services...',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              )
            : _hasMore &&
                  _displayedSubServiceItems.length <
                      _filteredSubServiceItems.length
            ? Text(
                'Scroll to load more',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              )
            : SizedBox.shrink(),
      ),
    );
  }

  Widget _buildUpcomingServicesCard(Color iconColor, ServiceItem serviceItem) {
    return InkWell(
      onTap: () {
        // Navigator.pushNamed(
        //   context,
        //   '/problem-details',
        //   arguments: {
        //     'serviceItem': serviceItem,
        //     'iconColor': iconColor,
        //   },
        // );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.build_circle_outlined, color: iconColor, size: 31),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upcoming Services',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Stay Tuned for More Services!',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
          SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? "No services available"
                : "No services found for '$_searchQuery'",
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty) ...[
            SizedBox(height: 8),
            TextButton(
              onPressed: _clearSearch,
              child: Text(
                'Clear search',
                style: TextStyle(color: widget.iconColor ?? Colors.blue),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
