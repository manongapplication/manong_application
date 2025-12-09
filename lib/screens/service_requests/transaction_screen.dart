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
  final Set<TransactionType> _selectedTypes = {
    TransactionType.payment,
    TransactionType.refund,
    TransactionType.adjustment,
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

  List<PaymentTransaction> get _filteredTransactions {
    if (_selectedTypes.isEmpty) {
      return _paymentTransactions;
    }
    return _paymentTransactions
        .where((transaction) => _selectedTypes.contains(transaction.type))
        .toList();
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
              },
              selectedColor: AppColorScheme.primaryColor.withOpacity(0.2),
              checkmarkColor: AppColorScheme.primaryColor,
              backgroundColor: Colors.grey.shade200,
              labelStyle: TextStyle(
                color: isSelected
                    ? AppColorScheme.primaryColor
                    : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTransactions() {
    final filtered = _filteredTransactions;

    if (filtered.isEmpty) {
      return _buildEmptyState();
    }

    if (_user == null) return const SizedBox.shrink();

    return Scrollbar(
      controller: _scrollController,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: filtered.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= filtered.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  color: AppColorScheme.primaryColor,
                ),
              ),
            );
          }

          final selectedTransaction = filtered[index];
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
      searchQuery: '',
      onRefresh: _fetchTransactions,
      emptyMessage: _selectedTypes.isEmpty
          ? 'Looks like it\'s empty here!'
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

    if (_paymentTransactions.isEmpty) {
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              _buildFilterChips(),
              Expanded(child: _buildState()),
            ],
          ),
        ),
      ),
    );
  }
}
