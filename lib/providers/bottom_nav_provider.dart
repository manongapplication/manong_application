import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/auth_service.dart';
import 'package:manong_application/api/service_request_api_service.dart';
import 'package:manong_application/models/app_user.dart';
import 'package:manong_application/models/manong.dart';
import 'package:manong_application/models/service_request.dart';

class BottomNavProvider with ChangeNotifier {
  final Logger logger = Logger('BottomNavProvider');

  // State variables
  int _selectedIndex = 0;
  PageController? _controller;
  ServiceRequest? _ongoingServiceRequest;
  bool? _manongArrived;
  ManongDailyLimit? _manongDailyLimit;
  dynamic _serviceRequestStatus;
  bool? _serviceRequestIsExpired;
  bool? _hasNoFeedback;
  int? _statusIndex = 0;
  int? _serviceRequestId = 0;
  bool _loadingOngoing = false;
  String? _serviceRequestMessage;
  bool? _isManong;
  bool _loadingGetProfile = false;
  AppUser? _user;

  // Getters
  int get selectedindex => _selectedIndex;
  PageController? get controller => _controller;
  bool? get manongArrived => _manongArrived;
  ManongDailyLimit? get manongDailyLimit => _manongDailyLimit;
  dynamic get serviceRequestStatus => _serviceRequestStatus;
  bool? get serviceRequestIsExpired => _serviceRequestIsExpired;
  bool? get hasNoFeedback => _hasNoFeedback;
  int? get statusIndex => _statusIndex;
  int? get serviceRequestId => _serviceRequestId;
  bool get loadingOngoing => _loadingOngoing;
  String? get serviceRequestMessage => _serviceRequestMessage;
  bool? get isManong => _isManong;
  bool get loadingGetProfile => _loadingGetProfile;
  AppUser? get user => _user;
  ServiceRequest? get ongoingServiceRequest => _ongoingServiceRequest;

  // Safe notification helper
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      // Use scheduleMicrotask to avoid notifying during build
      scheduleMicrotask(() {
        if (!_isDisposed) {
          notifyListeners();
        }
      });
    }
  }

  // Controller management
  void setController(PageController controller) {
    _controller = controller;
  }

  // State setters with safe notification
  void setHasNoFeedback(bool value) {
    if (_hasNoFeedback != value) {
      _hasNoFeedback = value;
      _safeNotifyListeners();
    }
  }

  void setServiceRequestIsExpired(bool value) {
    if (_serviceRequestIsExpired != value) {
      _serviceRequestIsExpired = value;
      _safeNotifyListeners();
    }
  }

  void setServiceRequestStatus(dynamic value) {
    if (_serviceRequestStatus != value) {
      _serviceRequestStatus = value;
      _safeNotifyListeners();
    }
  }

  void setManongArrived(bool value) {
    if (_manongArrived != value) {
      _manongArrived = value;
      _safeNotifyListeners();
    }
  }

  void setManongDailyLimit(ManongDailyLimit value) {
    if (_manongDailyLimit != value) {
      _manongDailyLimit = value;
      _safeNotifyListeners();
    }
  }

  void changeIndex(int newIndex) {
    if (_selectedIndex != newIndex) {
      _selectedIndex = newIndex;
      _controller?.animateToPage(
        newIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _safeNotifyListeners();
    }
  }

  void setIndex(int newIndex) {
    if (_selectedIndex != newIndex) {
      _selectedIndex = newIndex;
      _safeNotifyListeners();
    }
  }

  void setOngoingServiceRequest(ServiceRequest request) {
    if (_ongoingServiceRequest?.id != request.id) {
      _ongoingServiceRequest = request;
      _safeNotifyListeners();
    }
  }

  void setStatusIndex(int index) {
    if (_statusIndex != index) {
      _statusIndex = index;
      _safeNotifyListeners();
    }
  }

  void setServiceRequestId(int? index) {
    if (_serviceRequestId != index) {
      _serviceRequestId = index;
      _safeNotifyListeners();
    }
  }

  // Main method to fetch ongoing service request
  Future<void> fetchOngoingServiceRequest() async {
    // Don't start if already loading
    if (_loadingOngoing) return;

    _loadingOngoing = true;
    _safeNotifyListeners();

    try {
      final response = await ServiceRequestApiService()
          .getOngoingServiceRequest();

      logger.info(
        'fetchOngoingServiceRequest() triggered ${jsonEncode(response)}',
      );

      if (response != null) {
        bool shouldNotify = false;

        if (response['data'] != null) {
          final sr = ServiceRequest.fromJson(response['data']);
          final isManong = response['isManong'];
          final message = response['message'];

          // Only update if something changed
          if (_ongoingServiceRequest?.id != sr.id) {
            _ongoingServiceRequest = sr;
            shouldNotify = true;
          }

          if (_serviceRequestMessage != message) {
            _serviceRequestMessage = message;
            shouldNotify = true;
          }

          if (_isManong != isManong) {
            _isManong = isManong;
            shouldNotify = true;
          }

          // Check for expiration
          if (sr.createdAt != null) {
            final now = DateTime.now();
            Duration diff = now.difference(sr.createdAt!);
            if (diff.inHours >= 4) {
              final updated = await ServiceRequestApiService()
                  .expiredServiceRequest(sr.id!);

              if (updated != null) {
                final expiredRequest = ServiceRequest.fromJson(updated['data']);
                if (_ongoingServiceRequest?.id != expiredRequest.id) {
                  _ongoingServiceRequest = expiredRequest;
                  shouldNotify = true;
                }
              }

              if (_serviceRequestIsExpired != true) {
                _serviceRequestIsExpired = true;
                shouldNotify = true;
              }
            } else if (_serviceRequestIsExpired == true) {
              _serviceRequestIsExpired = false;
              shouldNotify = true;
            }
          }
        } else {
          // Clear ongoing request if no data
          if (_ongoingServiceRequest != null) {
            _ongoingServiceRequest = null;
            shouldNotify = true;
          }
        }

        // Only notify if something actually changed
        if (shouldNotify) {
          _safeNotifyListeners();
        }
      }
    } catch (e) {
      logger.severe('Error fetching ongoing request: $e');
      // Don't notify on error to avoid build issues
    } finally {
      _loadingOngoing = false;
      // Only notify if we're not already disposed
      if (!_isDisposed) {
        _safeNotifyListeners();
      }
    }
  }

  // Profile fetching
  Future<void> getProfile() async {
    if (_loadingGetProfile) return;

    _loadingGetProfile = true;
    _safeNotifyListeners();

    try {
      final response = await AuthService().getMyProfile();

      if (_user?.id != response?.id) {
        _user = response;
        _safeNotifyListeners();
      }
    } catch (e) {
      logger.severe('Error fetching user: $e');
    } finally {
      _loadingGetProfile = false;
      if (!_isDisposed) {
        _safeNotifyListeners();
      }
    }
  }

  // Clear ongoing service request
  void clearOngoingServiceRequest() {
    if (_ongoingServiceRequest != null) {
      _ongoingServiceRequest = null;
      _serviceRequestMessage = null;
      _serviceRequestIsExpired = null;
      _manongArrived = null;
      _safeNotifyListeners();
    }
  }

  // Reset all state
  void reset() {
    _selectedIndex = 0;
    _ongoingServiceRequest = null;
    _manongArrived = null;
    _serviceRequestStatus = null;
    _serviceRequestIsExpired = null;
    _hasNoFeedback = null;
    _statusIndex = 0;
    _serviceRequestId = 0;
    _serviceRequestMessage = null;
    _isManong = null;
    _user = null;
    _safeNotifyListeners();
  }

  // Dispose management
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    _controller?.dispose();
    super.dispose();
  }

  // Helper method to check if we have an ongoing request
  bool get hasOngoingRequest => _ongoingServiceRequest != null;

  // Helper method to check if ongoing request needs attention
  bool get needsAttention =>
      _serviceRequestIsExpired == true ||
      _manongArrived == true ||
      _hasNoFeedback == true;
}
