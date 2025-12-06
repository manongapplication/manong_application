import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:manong_application/models/bookmark_item_type.dart';
import 'package:manong_application/models/service_item.dart';
import 'package:manong_application/models/service_item_status.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/color_utils.dart';
import 'package:manong_application/widgets/icon_card.dart';
import 'package:manong_application/api/bookmark_item_api_service.dart';
import 'package:manong_application/api/bookmark_item_manager.dart';

class ServiceCardLite extends StatefulWidget {
  final ServiceItem serviceItem;
  final VoidCallback onTap;

  const ServiceCardLite({
    super.key,
    required this.serviceItem,
    required this.onTap,
  });

  @override
  State<ServiceCardLite> createState() => _ServiceCardLiteState();
}

class _ServiceCardLiteState extends State<ServiceCardLite> {
  bool _isBookmarked = false;
  bool _isLoading = false;
  Timer? _singleTapTimer;
  DateTime? _lastTapTime;
  static const int _doubleTapInterval = 300;

  @override
  void initState() {
    super.initState();
    _fetchBookmarkStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check for cache updates when parent rebuilds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCacheForUpdates();
    });
  }

  @override
  void didUpdateWidget(ServiceCardLite oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.serviceItem.id != widget.serviceItem.id) {
      _fetchBookmarkStatus();
    } else {
      _checkCacheForUpdates();
    }
  }

  void _checkCacheForUpdates() {
    final cached = BookmarkItemManager.getCachedStatus(
      widget.serviceItem.id,
      BookmarkItemType.SERVICE_ITEM,
    );

    if (cached != null && cached != _isBookmarked) {
      if (mounted) {
        setState(() {
          _isBookmarked = cached;
        });
      }
    }
  }

  @override
  void dispose() {
    _singleTapTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchBookmarkStatus() async {
    try {
      final cached = BookmarkItemManager.getCachedStatus(
        widget.serviceItem.id,
        BookmarkItemType.SERVICE_ITEM,
      );

      if (cached != null) {
        if (mounted) {
          setState(() {
            _isBookmarked = cached;
          });
        }
        return;
      }

      final isBookmarked = await BookmarkItemManager().getBookmarkStatus(
        itemId: widget.serviceItem.id,
        type: BookmarkItemType.SERVICE_ITEM,
      );

      if (mounted) {
        setState(() {
          _isBookmarked = isBookmarked;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBookmarked = false;
        });
      }
    }
  }

  void _handleTap() {
    final now = DateTime.now();

    if (_lastTapTime != null &&
        now.difference(_lastTapTime!) <
            Duration(milliseconds: _doubleTapInterval)) {
      _singleTapTimer?.cancel();
      _handleDoubleTap();
    } else {
      _lastTapTime = now;
      _singleTapTimer?.cancel();
      _singleTapTimer = Timer(
        const Duration(milliseconds: _doubleTapInterval),
        () {
          if (mounted) {
            widget.onTap();
          }
        },
      );
    }
  }

  void _handleDoubleTap() {
    if (widget.serviceItem.status != ServiceItemStatus.comingSoon &&
        !_isLoading) {
      _toggleBookmark();
    }
  }

  Future<void> _toggleBookmark() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isBookmarked) {
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

      BookmarkItemManager().updateBookmarkStatus(
        itemId: widget.serviceItem.id,
        type: BookmarkItemType.SERVICE_ITEM,
        isBookmarked: !_isBookmarked,
      );

      if (mounted) {
        setState(() {
          _isBookmarked = !_isBookmarked;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update bookmark'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.serviceItem.status == ServiceItemStatus.comingSoon
            ? null
            : _handleTap,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Material(
                  color: AppColorScheme.primaryLight,
                  shape: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Stack(
                      children: [
                        iconCard(
                          iconColor: colorFromHex(widget.serviceItem.iconColor),
                          iconName: widget.serviceItem.iconName,
                          iconTextColor: colorFromHex(
                            widget.serviceItem.iconTextColor,
                          ),
                          size: 38,
                        ),

                        if (_isBookmarked)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.bookmark,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                if (widget.serviceItem.status == ServiceItemStatus.comingSoon)
                  Positioned(
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColorScheme.goldDeep.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Coming Soon',
                        style: TextStyle(
                          fontSize: 7,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                if (_isLoading)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                widget.serviceItem.title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                  letterSpacing: -0.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
