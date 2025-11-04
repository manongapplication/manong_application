import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/manong_api_service.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/models/manong.dart';
import 'package:manong_application/models/service_item.dart';
import 'package:manong_application/models/service_request.dart';
import 'package:manong_application/models/sub_service_item.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/distance_matrix.dart';
import 'package:manong_application/widgets/empty_state_widget.dart';
import 'package:manong_application/widgets/error_state_widget.dart';
import 'package:manong_application/widgets/manong_list_card.dart';
import 'package:manong_application/widgets/search_input.dart';
import 'package:manong_application/widgets/step_appbar.dart';
import 'package:latlong2/latlong.dart' as latlong;

class ManongListScreen extends StatefulWidget {
  final ServiceRequest serviceRequest;

  const ManongListScreen({super.key, required this.serviceRequest});
  @override
  State<ManongListScreen> createState() => _ManongListScreenState();
}

class _ManongListScreenState extends State<ManongListScreen> {
  final Logger logger = Logger('ManongListScreen');
  late ManongApiService manongApiService;
  List<Manong> manongs = [];
  late double? meters;
  bool isLoading = true;
  String? _error;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final distance = latlong.Distance();
  LatLng? _currentLatLng;
  bool _argumentsInitialized = false;
  ServiceRequest? _serviceRequest;

  // Manong Pages
  int _currentPage = 1;
  final int _limit = 10; // Items per page
  bool _isLoadingMore = false;
  bool _hasMore = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_argumentsInitialized) {
      _argumentsInitialized = true;
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeComponents();
    _serviceRequest = widget.serviceRequest;
    _fetchManongs();
    setupScrollListener();
  }

  void _initializeComponents() {
    manongApiService = ManongApiService();
  }

  void setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoadingMore &&
          _hasMore) {
        _fetchManongs(loadMore: true);
      }
    });
  }

  Future<void> _fetchManongs({
    bool loadMore = false,
    bool fromRefresh = false,
  }) async {
    if (!mounted) return;
    if (!fromRefresh && (_isLoadingMore || !_hasMore)) return;

    try {
      if (loadMore) {
        setState(() => _isLoadingMore = true);
      } else if (!fromRefresh) {
        // only show loader on first load, not when refreshing
        setState(() {
          isLoading = true;
          _error = null;
          _currentPage = 1;
          _hasMore = true;
          manongs.clear();
        });
      } else {
        // from pull-to-refresh
        setState(() {
          _error = null;
          _currentPage = 1;
          _hasMore = true;
        });
      }

      if (loadMore) _isLoadingMore = true;

      final response = await manongApiService.fetchManongs(
        serviceItemId: _serviceRequest?.serviceItemId ?? 1,
        page: _currentPage,
        limit: _limit,
      );

      final data = response as List<dynamic>? ?? [];

      final parsedResponse = data
          .map((json) => Manong.fromJson(json as Map<String, dynamic>))
          .toList();

      setState(() {
        if (loadMore) {
          manongs.addAll(parsedResponse);
          _isLoadingMore = false;
        } else {
          manongs = parsedResponse;
          isLoading = false;
        }

        if (parsedResponse.length < _limit) _hasMore = false;
        _currentPage++;
      });
    } catch (e) {
      logger.severe('Error fetching manongs $e');
      setState(() {
        if (loadMore) {
          _isLoadingMore = false;
        } else {
          _error = 'Failed to load list of manongs. Please try again.';
          isLoading = false;
        }
      });
    }
  }

  Widget _buildResultsInfo(int count) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '($count result${count != 1 ? 's' : ''})',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  List<Manong> _getFilteredManongs() {
    List<Manong>? filtered = List.from(manongs);

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((req) {
        final manong = req.appUser.firstName?.toLowerCase() ?? '';
        final specialites =
            req.profile?.specialities
                ?.map((s) => s.subServiceItem.title.toLowerCase())
                .toList() ??
            [];

        final matches =
            manong.contains(query) ||
            specialites.any((title) => title.contains(query));

        return matches;
      }).toList();
    }

    filtered.sort((a, b) {
      final distA = _calculateDistance(a);
      final distB = _calculateDistance(b);

      if (distA == null && distB == null) return 0;
      if (distA == null) return 1;
      if (distB == null) return -1;
      return distA.compareTo(distB);
    });

    return filtered;
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.trim();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  Widget _buildEmptyState() {
    if (_error != null) {
      return ErrorStateWidget(
        errorText: _error!,
        onPressed: () => _fetchManongs(fromRefresh: true),
      );
    }

    return RefreshIndicator(
      color: AppColorScheme.primaryColor,
      backgroundColor: AppColorScheme.backgroundGrey,
      onRefresh: () async {
        await _fetchManongs(fromRefresh: true);
      },
      child: Scrollbar(
        controller: _scrollController,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
            EmptyStateWidget(
              searchQuery: _searchQuery,
              emptyMessage: 'No Manongs found',
              onPressed: _clearSearch,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: SearchInput(
              controller: _searchController,
              onChanged: _onSearchChanged,
            ),
          ),
        ],
      ),
    );
  }

  double? _calculateDistance(Manong manong) {
    if (manong.appUser.latitude == null || manong.appUser.longitude == null) {
      return null;
    }

    return distance.as(
      latlong.LengthUnit.Meter,
      latlong.LatLng(
        _serviceRequest!.customerLat,
        _serviceRequest!.customerLng,
      ),
      latlong.LatLng(manong.appUser.latitude!, manong.appUser.longitude!),
    );
  }

  Widget _buildManongsList(List<Manong> filteredManongs) {
    if (_serviceRequest == null) return SizedBox.shrink();
    return RefreshIndicator(
      color: AppColorScheme.primaryColor,
      backgroundColor: AppColorScheme.backgroundGrey,
      onRefresh: () async {
        await _fetchManongs(fromRefresh: true);
      },
      child: Scrollbar(
        controller: _scrollController,
        child: ListView.builder(
          itemCount: filteredManongs.length + (_isLoadingMore ? 1 : 0),
          physics: const AlwaysScrollableScrollPhysics(),
          controller: _scrollController,
          itemBuilder: (context, index) {
            if (index >= filteredManongs.length) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircularProgressIndicator(
                    color: AppColorScheme.primaryColor,
                  ),
                ),
              );
            }

            Manong manong = filteredManongs[index];

            meters = DistanceMatrix().calculateDistance(
              startLat: _serviceRequest?.customerLat ?? 0,
              startLng: _serviceRequest?.customerLng ?? 0,
              endLat: manong.appUser.latitude,
              endLng: manong.appUser.longitude,
            );

            return Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: ManongListCard(
                manong: manong,
                iconColor: AppColorScheme.primaryColor,
                onTap: () {
                  Navigator.pushNamed(
                    navigatorKey.currentContext!,
                    '/manong-details',
                    arguments: {
                      'manong': manong,
                      'serviceRequest': _serviceRequest,
                    },
                  );
                },
                meters: meters,
                subServiceItem: _serviceRequest!.subServiceItem,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredManongs = _getFilteredManongs();

    return Scaffold(
      backgroundColor: AppColorScheme.backgroundGrey,
      appBar: StepAppbar(
        title: 'Find Manong',
        subtitle: 'Choose your manong',
        currentStep: 3,
        totalSteps: 3,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          _buildSearchBar(),
          const SizedBox(height: 2),
          _buildResultsInfo(filteredManongs.length),
          Expanded(
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColorScheme.primaryColor,
                          ),
                        )
                      : filteredManongs.isEmpty
                      ? _buildEmptyState()
                      : Padding(
                          padding: const EdgeInsets.all(12),
                          child: _buildManongsList(filteredManongs),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
