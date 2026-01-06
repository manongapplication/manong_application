import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/auth_service.dart';
import 'package:manong_application/api/payment_transaction_api_service.dart';
import 'package:manong_application/models/app_user.dart';
import 'package:manong_application/models/payment_transaction.dart';
import 'package:manong_application/models/transaction_type.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/widgets/empty_state_widget.dart';
import 'package:manong_application/widgets/error_state_widget.dart';
import 'package:manong_application/widgets/my_app_bar.dart';
import 'package:manong_application/widgets/transaction_card.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final Logger logger = Logger('TransactionScreen');
  bool _isLoading = false;
  String? _error;
  List<PaymentTransaction> _paymentTransactions = [];
  List<PaymentTransaction> _filteredTransactions = [];
  final Set<TransactionType> _selectedTypes = {
    TransactionType.payment,
    TransactionType.refund,
    TransactionType.adjustment,
  };

  // Search properties
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  final FocusNode _searchFocusNode = FocusNode();

  // Sort properties
  SortBy _currentSort = SortBy.dateDesc;
  Map<SortBy, String> sortOptions = {
    SortBy.dateDesc: 'Date (Newest)',
    SortBy.dateAsc: 'Date (Oldest)',
    SortBy.amountDesc: 'Amount (High to Low)',
    SortBy.amountAsc: 'Amount (Low to High)',
    SortBy.requestNumber: 'Request Number',
  };

  // Scroll-to-load properties
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  final int _limit = 10; // Items per page
  bool _isLoadingMore = false;
  bool _hasMore = true;
  AppUser? _user;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupScrollListener();
    });
    _getProfile();
    _fetchTransactions();
    _seenAll();
  }

  Future<void> _getProfile() async {
    try {
      setState(() {
        _isLoading = false;
        _error = null;
      });

      final response = await AuthService().getMyProfile();

      if (mounted) {
        setState(() {
          _user = response;
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

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoadingMore &&
          _hasMore) {
        _fetchMoreTransactions();
      }
    });
  }

  Future<void> _seenAll() async {
    try {
      await PaymentTransactionApiService().seenAllPaymentTransactions();
    } catch (e) {
      if (!mounted) return;
      logger.severe('Error seen all Payment Transactions ${e.toString()}');
    }
  }

  Future<void> _fetchTransactions({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        _isLoading = true;
        _error = null;
        _currentPage = 1;
        _hasMore = true;
      });
    }

    try {
      final response = await PaymentTransactionApiService()
          .fetchPaymentTransaction(
            page: loadMore ? _currentPage : 1,
            limit: _limit,
          );

      if (!mounted) return;

      if (response.isEmpty) {
        setState(() {
          if (loadMore) {
            _hasMore = false;
          } else {
            _paymentTransactions = [];
            _filteredTransactions = [];
          }
        });
        return;
      }

      setState(() {
        if (loadMore) {
          _paymentTransactions.addAll(response);
        } else {
          _paymentTransactions = response;
        }

        // Apply filters and search after fetching
        _applyFiltersAndSearch();

        if (response.length < _limit) _hasMore = false;
      });

      if (!loadMore) _currentPage = 2;

      logger.info('Fetched ${response.length} transactions');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
      logger.severe('Error fetching payment transactions $_error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchMoreTransactions() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final response = await PaymentTransactionApiService()
          .fetchPaymentTransaction(page: _currentPage, limit: _limit);

      if (!mounted) return;

      if (response == null || response.isEmpty) {
        setState(() => _hasMore = false);
        return;
      }

      setState(() {
        _paymentTransactions.addAll(response);
        _applyFiltersAndSearch();
        _currentPage++;
        if (response.length < _limit) _hasMore = false;
      });

      logger.info('Loaded ${response.length} more transactions');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
      logger.severe('Error fetching more transactions $_error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  void _applyFiltersAndSearch() {
    List<PaymentTransaction> filtered = _paymentTransactions;

    // Apply type filters
    if (_selectedTypes.isNotEmpty) {
      filtered = filtered
          .where((transaction) => _selectedTypes.contains(transaction.type))
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((transaction) {
        return _matchesSearchQuery(transaction);
      }).toList();
    }

    // Apply sorting
    filtered = _sortTransactions(filtered);

    setState(() {
      _filteredTransactions = filtered;
    });
  }

  bool _matchesSearchQuery(PaymentTransaction transaction) {
    final query = _searchQuery.toLowerCase();

    // Search in request number
    final requestNumber =
        transaction.metadata?['requestNumber']?.toString().toLowerCase() ?? '';
    if (requestNumber.contains(query)) return true;

    // Search in amount
    final amountString = transaction.amount.toString();
    if (amountString.contains(query)) return true;

    // Search in sub service type
    final subServiceType =
        transaction.metadata?['subServiceType']?.toString().toLowerCase() ?? '';
    if (subServiceType.contains(query)) return true;

    // Search in service type
    final serviceType =
        transaction.metadata?['serviceType']?.toString().toLowerCase() ?? '';
    if (serviceType.contains(query)) return true;

    // Search in description
    final description = transaction.description?.toLowerCase() ?? '';
    if (description.contains(query)) return true;

    // Search in payment ID
    final paymentId = transaction.paymentIdOnGateway?.toLowerCase() ?? '';
    if (paymentId.contains(query)) return true;

    // Search in refund ID
    final refundId = transaction.refundIdOnGateway?.toLowerCase() ?? '';
    if (refundId.contains(query)) return true;

    // Search in transaction type
    final typeString = transaction.type.toString().toLowerCase();
    if (typeString.contains(query)) return true;

    return false;
  }

  List<PaymentTransaction> _sortTransactions(
    List<PaymentTransaction> transactions,
  ) {
    List<PaymentTransaction> sorted = List.from(transactions);

    switch (_currentSort) {
      case SortBy.dateDesc:
        sorted.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
        break;
      case SortBy.dateAsc:
        sorted.sort((a, b) => a.createdAt!.compareTo(b.createdAt!));
        break;
      case SortBy.amountDesc:
        sorted.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case SortBy.amountAsc:
        sorted.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case SortBy.requestNumber:
        sorted.sort((a, b) {
          final aNum = a.metadata?['requestNumber']?.toString() ?? '';
          final bNum = b.metadata?['requestNumber']?.toString() ?? '';
          return aNum.compareTo(bNum);
        });
        break;
    }

    return sorted;
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _isSearching = value.isNotEmpty;
    });
    _applyFiltersAndSearch();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _isSearching = false;
    });
    _applyFiltersAndSearch();
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Search transactions...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _isSearching
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: _clearSearch,
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColorScheme.primaryColor,
              width: 1,
            ),
          ),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildSortButton() {
    return PopupMenuButton<SortBy>(
      color: Colors.white,
      onSelected: (SortBy sortBy) {
        setState(() {
          _currentSort = sortBy;
        });
        _applyFiltersAndSearch();
      },
      itemBuilder: (BuildContext context) {
        return sortOptions.entries.map((entry) {
          return PopupMenuItem<SortBy>(
            value: entry.key,
            child: Row(
              children: [
                Text(entry.value),
                if (_currentSort == entry.key)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.check, size: 16),
                  ),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort, size: 18, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              'Sort: ${sortOptions[_currentSort]}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCount() {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Row(
        children: [
          Text(
            '${_filteredTransactions.length} ${_filteredTransactions.length == 1 ? 'result' : 'results'}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          // Show "+" if more available but not loading
          if (_hasMore && !_isLoadingMore && _filteredTransactions.length > 0)
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(
                '+',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          // Show loading spinner when loading more
          if (_isLoadingMore)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColorScheme.primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Column(
      children: [
        // Search Bar (full width)
        _buildSearchBar(),

        // Type Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: TransactionType.values.map((type) {
              final isSelected = _selectedTypes.contains(type);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    type.value.substring(0, 1).toUpperCase() +
                        type.value.substring(1),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTypes.add(type);
                      } else {
                        _selectedTypes.remove(type);
                      }
                    });
                    _applyFiltersAndSearch();
                  },
                  selectedColor: AppColorScheme.primaryColor.withOpacity(0.2),
                  checkmarkColor: AppColorScheme.primaryColor,
                  backgroundColor: Colors.grey.shade200,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppColorScheme.primaryColor
                        : Colors.grey.shade700,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Results count and Sort button row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_buildSortButton(), _buildResultsCount()],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactions() {
    if (_filteredTransactions.isEmpty) {
      return _buildEmptyState();
    }

    if (_user == null) return const SizedBox.shrink();

    return Scrollbar(
      controller: _scrollController,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _filteredTransactions.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Loading indicator at the bottom
          if (index >= _filteredTransactions.length) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColorScheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Loading more...',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          }

          final selectedTransaction = _filteredTransactions[index];
          return TransactionCard(
            paymentTransaction: selectedTransaction,
            user: _user,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyStateWidget(
      searchQuery: _searchQuery,
      onRefresh: _fetchTransactions,
      emptyMessage: _selectedTypes.isEmpty && !_isSearching
          ? 'Looks like it\'s empty here!'
          : _isSearching
          ? 'No transactions found for "$_searchQuery"'
          : 'No transactions found for selected filters',
    );
  }

  Widget _buildState() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColorScheme.primaryColor),
      );
    }

    if (_error != null) {
      return Center(
        child: ErrorStateWidget(
          errorText: _error!,
          onPressed: _fetchTransactions,
        ),
      );
    }

    if (_filteredTransactions.isEmpty) {
      return _buildEmptyState();
    }

    return _buildTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorScheme.backgroundGrey,
      appBar: myAppBar(title: 'Transactions'),
      body: RefreshIndicator(
        onRefresh: _fetchTransactions,
        child: Column(
          children: [
            _buildFilterChips(),
            Expanded(child: _buildState()),
          ],
        ),
      ),
    );
  }
}

enum SortBy { dateDesc, dateAsc, amountDesc, amountAsc, requestNumber }
