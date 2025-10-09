import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/user_notification_api_service.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/models/user_notification.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/notification_card.dart';
import 'package:manong_application/utils/status_utils.dart';
import 'package:manong_application/widgets/empty_state_widget.dart';
import 'package:manong_application/widgets/error_state_widget.dart';
import 'package:manong_application/widgets/my_app_bar.dart';

class UserNotificationScreen extends StatefulWidget {
  const UserNotificationScreen({super.key});
  @override
  State<UserNotificationScreen> createState() => _UserNotificationScreenState();
}

class _UserNotificationScreenState extends State<UserNotificationScreen> {
  final Logger logger = Logger('NotificationsScreen');
  String? _error;
  bool? _isLoading;
  final ScrollController _scrollController = ScrollController();
  List<UserNotification> _userNotifications = [];
  late UserNotificationApiService _userNotificationApiService;

  int _currentPage = 1;
  final int _limit = 10; // Items per page
  bool _isLoadingMore = false;
  bool _hasMore = true;

  final tabs = ['All', 'Unread'];
  int _statusIndex = 0;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeComponents();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupScrollListener();
    });
    _fetchUserNotifications();
    _getUnreadCount();
  }

  void _initializeComponents() {
    _userNotificationApiService = UserNotificationApiService();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoadingMore &&
          _hasMore) {
        _fetchMoreUserNotifications();
      }
    });
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

  Future<void> _fetchUserNotifications({bool loadMore = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _userNotificationApiService.fetchNotifications();
      if (loadMore) {
        setState(() {
          _isLoadingMore = true;
        });
      } else {
        setState(() {
          _error = null;
          _currentPage = 1;
        });
      }

      if (loadMore) _isLoadingMore = true;

      if (response == null || response.isEmpty) {
        setState(() {
          if (loadMore) {
            _hasMore = false;
          } else {
            _userNotifications = [];
            _isLoadingMore = false;
          }
        });

        return;
      }

      setState(() {
        if (loadMore) {
          _userNotifications.addAll(response);
          _isLoadingMore = false;
        } else {
          _userNotifications = response;
        }
        if (response.length < _limit) _hasMore = false;
      });

      _currentPage++;

      logger.info('Fetched ${response.length} user notifications');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
      logger.severe('Error fetching notifications $_error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchMoreUserNotifications() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final response = await _userNotificationApiService.fetchNotifications(
        page: _currentPage,
        limit: _limit,
      );

      if (response == null) {
        setState(() => _hasMore = false);
        return;
      }

      setState(() {
        _userNotifications.addAll(response);
        _currentPage++;
        if (response.length < _limit) _hasMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
      logger.severe('Error fetching user notifications $_error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  List<UserNotification> _getFilteredUserNotifications() {
    final tab = tabs[_statusIndex];

    if (tab == 'Unread') {
      return _userNotifications.where((n) => n.seenAt == null).toList();
    }

    return _userNotifications;
  }

  void _onStatusChanged(int index) {
    if (index != _statusIndex) {
      setState(() {
        _statusIndex = index;
      });
    }
  }

  Widget _buildStatusChip({
    required String title,
    required int index,
    required bool active,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: FilterChip(
        label: Text(title),
        selected: active,
        onSelected: (_) => _onStatusChanged(index),
        selectedColor: AppColorScheme.primaryColor,
        backgroundColor: AppColorScheme.primaryLight,
        labelStyle: TextStyle(
          color: active ? Colors.white : Colors.grey.shade700,
          fontWeight: active ? FontWeight.w600 : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildStatusRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(
          tabs.length,
          (index) => _buildStatusChip(
            title: tabs[index],
            index: index,
            active: _statusIndex == index,
          ),
        ),
      ),
    );
  }

  void _onTapNotification(UserNotification notificationItem) async {
    if (notificationItem.data == null) return;
    final jsonData = jsonDecode(notificationItem.data!);

    try {
      final response = await UserNotificationApiService().seenNotification(
        notificationItem.id,
      );

      if (response != null) {
        logger.info('Seen notification ${notificationItem.id}!');

        Navigator.of(navigatorKey.currentContext!).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
          arguments: {
            'index': 1,
            'serviceRequestId': jsonData['serviceRequestId'] != null
                ? int.tryParse(jsonData['serviceRequestId'])
                : null,
          },
        );
      }
    } catch (e) {
      logger.severe('Error seen notification ${notificationItem.id} $e');
    }
  }

  Widget _buildUserNotifications() {
    final notifications = _getFilteredUserNotifications();

    if (notifications.isEmpty) {
      return EmptyStateWidget(
        searchQuery: '',
        emptyMessage: 'No notifications',
        onRefresh: _fetchUserNotifications,
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
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
        child: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 12),
          child: RefreshIndicator(
            color: AppColorScheme.primaryColor,
            backgroundColor: AppColorScheme.backgroundGrey,
            onRefresh: _fetchUserNotifications,
            child: Scrollbar(
              controller: _scrollController,
              child: ListView.builder(
                itemCount: notifications.length,
                physics: const AlwaysScrollableScrollPhysics(),
                controller: _scrollController,
                itemBuilder: (context, index) {
                  if (index >= notifications.length) {
                    return const Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                          color: AppColorScheme.primaryColor,
                        ),
                      ),
                    );
                  }

                  UserNotification notificationItem = notifications[index];

                  return NotificationCard(
                    notificationItem: notificationItem,
                    onTap: () => _onTapNotification(notificationItem),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildState() {
    if (_error != null) {
      return ErrorStateWidget(
        errorText: _error.toString(),
        onPressed: _fetchUserNotifications,
      );
    }

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          _buildStatusRow(),
          const SizedBox(height: 4),
          if (_isLoading == true) ...[
            Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColorScheme.primaryColor,
                ),
              ),
            ),
          ] else ...[
            Expanded(child: _buildUserNotifications()),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorScheme.backgroundGrey,
      appBar: myAppBar(
        title: 'Notifications',
        trailing: Stack(
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
      body: _buildState(),
    );
  }
}
