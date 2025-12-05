import 'package:flutter/material.dart';
import 'package:iconify_design/iconify_design.dart';
import 'package:manong_application/models/service_item.dart';
import 'package:manong_application/models/sub_service_item.dart';
import 'package:manong_application/utils/color_utils.dart';
import 'package:manong_application/widgets/my_app_bar.dart';
import 'package:manong_application/widgets/sub_service_card.dart';
import 'package:manong_application/api/bookmark_item_api_service.dart';

class SubServiceListScreen extends StatefulWidget {
  final ServiceItem serviceItem;
  final Color? iconColor;

  const SubServiceListScreen({
    super.key,
    required this.serviceItem,
    this.iconColor,
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

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _fetchAllBookmarks();
  }

  Future<void> _fetchAllBookmarks() async {
    setState(() {
      _isLoadingBookmarks = true;
    });

    try {
      // Fetch all bookmarked sub-service items
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
      }

      if (mounted) {
        setState(() {
          _bookmarkStatus = newBookmarkStatus;
          // Initialize filtered items with sorting
          _filteredSubServiceItems = List.from(
            widget.serviceItem.subServiceItems,
          );
          _sortItemsByBookmark();
          _updateDisplayedItems();
        });
      }
    } catch (e) {
      print('Error fetching bookmarks: $e');
      // Fallback to original items
      if (mounted) {
        setState(() {
          _filteredSubServiceItems = widget.serviceItem.subServiceItems;
          _updateDisplayedItems();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingBookmarks = false;
        });
      }
    }
  }

  void _sortItemsByBookmark() {
    // Sort: bookmarked items first, then alphabetical
    _filteredSubServiceItems.sort((a, b) {
      final aBookmarked = _bookmarkStatus[a.id] ?? false;
      final bBookmarked = _bookmarkStatus[b.id] ?? false;

      // Bookmarked items come first
      if (aBookmarked && !bBookmarked) return -1;
      if (!aBookmarked && bBookmarked) return 1;

      // Then sort alphabetically by title
      return a.title.compareTo(b.title);
    });
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
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

        // Sort search results by bookmark too
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

    // Simulate API call delay
    Future.delayed(Duration(milliseconds: 500), () {
      if (!mounted) return;

      setState(() {
        _currentPage++;
        _updateDisplayedItems();
        _isLoadingMore = false;

        // Check if we've reached the end
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

    // Update hasMore based on current state
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
    // Store the current state before update
    final wasBookmarked = _bookmarkStatus[subServiceItemId] ?? false;
    final isAddingBookmark = !wasBookmarked;

    // Call API first
    try {
      if (isAddingBookmark) {
        await BookmarkItemApiService().addBookmarkSubServiceItem(
          subServiceItemId,
        );
      } else {
        await BookmarkItemApiService().removeBookmarkSubServiceItem(
          subServiceItemId,
        );
      }
    } catch (e) {
      print('Error toggling bookmark: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update bookmark'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Update the local bookmark status
    if (mounted) {
      setState(() {
        final currentStatus = _bookmarkStatus[subServiceItemId] ?? false;
        _bookmarkStatus[subServiceItemId] = !currentStatus;

        // Re-sort items after toggling bookmark
        _sortItemsByBookmark();

        // If adding a bookmark and not on first page, reset to first page
        // so the newly bookmarked item is visible at the top
        if (isAddingBookmark && _currentPage > 1) {
          _currentPage = 1;
        }

        _updateDisplayedItems();
      });
    }

    // Optional: Scroll to top when bookmarking an item (so user sees it move to top)
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

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serviceItem = widget.serviceItem;
    final iconColor = widget.iconColor ?? Colors.black;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: myAppBar(
        title: serviceItem.title,
        leading: IconifyIcon(
          icon: serviceItem.iconName,
          size: 24,
          color: colorFromHex(serviceItem.iconTextColor),
        ),
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
                          icon: Icon(Icons.clear, color: Colors.grey.shade600),
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
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
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
                            child: ListView.builder(
                              key: PageStorageKey<String>(
                                'subServiceList_${widget.serviceItem.id}',
                              ), // Add this
                              controller: _scrollController,
                              itemCount:
                                  _displayedSubServiceItems.length +
                                  (_hasMore ? 1 : 0) +
                                  1,
                              itemBuilder: (context, index) {
                                // Loading indicator for pagination (only show if there are more items to load)
                                if (_hasMore &&
                                    index == _displayedSubServiceItems.length) {
                                  return _buildLoadingIndicator();
                                }

                                // "Upcoming Services" card at the end
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
                                  ), // IMPORTANT: Add unique key
                                  padding: EdgeInsets.only(bottom: 12),
                                  child: SubServiceCard(
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/problem-details',
                                        arguments: {
                                          'serviceItem': serviceItem,
                                          'subServiceItem': subServiceItem,
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
                                        _bookmarkStatus[subServiceItem.id],
                                    onBookmarkToggled: () =>
                                        _onBookmarkToggled(subServiceItem.id),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    // Only show loading indicator if we're actually loading OR if there are more items to load
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
            : SizedBox.shrink(), // Hide completely when all items are shown
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
