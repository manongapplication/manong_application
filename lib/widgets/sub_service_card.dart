import 'package:flutter/material.dart';
import 'package:manong_application/api/bookmark_item_manager.dart';
import 'package:manong_application/models/bookmark_item_type.dart';
import 'package:manong_application/models/sub_service_item.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/widgets/icon_card.dart';

class SubServiceCard extends StatefulWidget {
  final SubServiceItem subServiceItem;
  final VoidCallback onTap;
  final Color iconColor;
  final Color iconTextColor;
  final bool? isBookmarked; // IMPORTANT: Parent will pass this
  final VoidCallback onBookmarkToggled; // Changed to required

  const SubServiceCard({
    super.key,
    required this.subServiceItem,
    required this.onTap,
    required this.iconColor,
    required this.iconTextColor,
    required this.isBookmarked, // Now required
    required this.onBookmarkToggled, // Now required
  });

  @override
  State<SubServiceCard> createState() => _SubServiceCardState();
}

class _SubServiceCardState extends State<SubServiceCard> {
  bool? _isBookmarked;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // REMOVED: No individual API call
    _isBookmarked = widget.isBookmarked;
  }

  @override
  void didUpdateWidget(covariant SubServiceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isBookmarked != oldWidget.isBookmarked) {
      setState(() {
        _isBookmarked = widget.isBookmarked;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final wasBookmarked = _isBookmarked ?? false;
      final newBookmarkStatus = !wasBookmarked;

      // CRITICAL: Use the instance method to update status
      BookmarkItemManager().updateBookmarkStatus(
        itemId: widget.subServiceItem.id,
        type: BookmarkItemType.SUB_SERVICE_ITEM,
        isBookmarked: newBookmarkStatus,
      );

      if (mounted) {
        setState(() {
          _isBookmarked = newBookmarkStatus;
        });
      }

      // Let parent handle the API call
      widget.onBookmarkToggled();
    } catch (e) {
      debugPrint('Error toggling bookmark: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
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
      color: AppColorScheme.primaryLight,
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          padding: EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              iconCard(
                iconColor: widget.iconColor,
                iconName: widget.subServiceItem.iconName,
                iconTextColor: widget.iconTextColor,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Text(
                              widget.subServiceItem.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        _buildBookmarkButton(),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookmarkButton() {
    if (_isBookmarked == null || _isLoading) {
      return Container(
        width: 32,
        height: 32,
        margin: EdgeInsets.only(left: 4),
        child: Center(
          child: _isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColorScheme.primaryColor,
                  ),
                )
              : SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.grey[300],
                  ),
                ),
        ),
      );
    }

    return GestureDetector(
      onTap: _toggleBookmark,
      child: Container(
        width: 32,
        height: 32,
        margin: EdgeInsets.only(left: 4),
        child: Center(
          child: Icon(
            _isBookmarked == true
                ? Icons.bookmark_added
                : Icons.bookmark_add_outlined,
            color: _isBookmarked == true ? Colors.amber : Colors.grey[600],
            size: 24,
          ),
        ),
      ),
    );
  }
}
