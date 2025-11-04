import 'package:flutter/material.dart';
import 'package:iconify_design/iconify_design.dart';
import 'package:manong_application/models/service_item.dart';
import 'package:manong_application/models/sub_service_item.dart';
import 'package:manong_application/utils/color_utils.dart';
import 'package:manong_application/widgets/my_app_bar.dart';
import 'package:manong_application/widgets/icon_card.dart';
import 'package:manong_application/widgets/sub_service_card.dart';

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

  @override
  void initState() {
    super.initState();
    _filteredSubServiceItems = widget.serviceItem.subServiceItems;
    _updateDisplayedItems();
    _searchController.addListener(_onSearchChanged);

    // Setup scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
      _resetPagination();

      if (_searchQuery.isEmpty) {
        _filteredSubServiceItems = widget.serviceItem.subServiceItems;
      } else {
        _filteredSubServiceItems = widget.serviceItem.subServiceItems.where((
          item,
        ) {
          final title = item.title.toLowerCase();
          final description = item.description?.toLowerCase() ?? '';

          return title.contains(_searchQuery) ||
              description.contains(_searchQuery);
        }).toList();
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
    final startIndex = 0;
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
      _filteredSubServiceItems = widget.serviceItem.subServiceItems;
      _resetPagination();
    });
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
              child: _displayedSubServiceItems.isEmpty
                  ? _buildEmptyState()
                  : SafeArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 4),

                          Expanded(
                            child: Scrollbar(
                              controller: _scrollController,
                              thumbVisibility: true,
                              child: ListView.builder(
                                itemCount:
                                    _displayedSubServiceItems.length +
                                    (_hasMore ? 1 : 0) +
                                    1, // +1 for upcoming services card
                                controller: _scrollController,
                                itemBuilder: (context, index) {
                                  // Loading indicator for pagination (only show if there are more items to load)
                                  if (_hasMore &&
                                      index ==
                                          _displayedSubServiceItems.length) {
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
