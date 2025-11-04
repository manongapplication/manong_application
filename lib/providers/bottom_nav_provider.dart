import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/auth_service.dart';
import 'package:manong_application/api/service_request_api_service.dart';
import 'package:manong_application/models/app_user.dart';
import 'package:manong_application/models/service_request.dart';

class BottomNavProvider with ChangeNotifier {
  final Logger logger = Logger('BottomNavProvider');
  int _selectedIndex = 0;
  PageController? _controller;
  ServiceRequest? _ongoingServiceRequest;
  ServiceRequest? get ongoingServiceRequest => _ongoingServiceRequest;
  bool? _manongArrived;
  dynamic _serviceRequestStatus;
  bool? _serviceRequestIsExpired;
  bool? _hasNoFeedback;

  void setController(PageController controller) {
    _controller = controller;
  }

  int get selectedindex => _selectedIndex;
  PageController? get controller => _controller;
  bool? get manongArrived => _manongArrived;
  dynamic get serviceRequestStatus => _serviceRequestStatus;
  bool? get serviceRequestIsExpired => _serviceRequestIsExpired;
  bool? get hasNoFeedback => _hasNoFeedback;

  void setHasNoFeedback(bool value) {
    _hasNoFeedback = value;
    notifyListeners();
  }

  void setServiceRequestIsExpired(bool value) {
    _serviceRequestIsExpired = value;
    notifyListeners();
  }

  void setServiceRequestStatus(dynamic value) {
    _serviceRequestStatus = value;
    notifyListeners();
  }

  void setManongArrived(bool value) {
    _manongArrived = value;
    notifyListeners();
  }

  void changeIndex(int newIndex) {
    _selectedIndex = newIndex;
    _controller?.animateToPage(
      newIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    notifyListeners();
  }

  void setIndex(int newIndex) {
    _selectedIndex = newIndex;
    notifyListeners();
  }

  void setOngoingServiceRequest(ServiceRequest request) {
    _ongoingServiceRequest = request;
    notifyListeners();
  }

  int? _statusIndex = 0;
  int? get statusIndex => _statusIndex;

  void setStatusIndex(int index) {
    _statusIndex = index;
    notifyListeners();
  }

  int? _serviceRequestId = 0;
  int? get serviceRequestId => _serviceRequestId;

  void setServiceRequestId(int? index) {
    _serviceRequestId = index;
    notifyListeners();
  }

  bool _loadingOngoing = false;
  bool get loadingOngoing => _loadingOngoing;

  String? _serviceRequestMessage;
  String? get serviceRequestMessage => _serviceRequestMessage;

  bool? _isManong;
  bool? get isManong => _isManong;

  Future<void> fetchOngoingServiceRequest() async {
    _loadingOngoing = true;
    notifyListeners();

    try {
      final response = await ServiceRequestApiService()
          .getOngoingServiceRequest();
      logger.info(
        'fetchOngoingServiceRequest() triggerd ${jsonEncode(response)}',
      );
      if (response != null) {
        if (response['data'] != null) {
          final sr = ServiceRequest.fromJson(response['data']);
          final isManong = response['isManong'];
          final message = response['message'];

          _ongoingServiceRequest = sr;
          _serviceRequestMessage = message;
          _isManong = isManong;

          if (sr.createdAt != null) {
            final now = DateTime.now();
            Duration diff = now.difference(sr.createdAt!);
            if (diff.inHours >= 4) {
              final updated = await ServiceRequestApiService()
                  .expiredServiceRequest(sr.id!);

              if (updated != null) {
                _ongoingServiceRequest = ServiceRequest.fromJson(
                  updated['data'],
                );
              }

              notifyListeners();
              _serviceRequestIsExpired = true;
            }
          }
        } else {
          _ongoingServiceRequest = null;
        }
      }
    } catch (e) {
      logger.severe('Error fetching ongoing request: $e');
    } finally {
      _loadingOngoing = false;
      notifyListeners();
    }
  }

  bool _loadingGetProfile = false;
  bool get loadingGetProfile => _loadingGetProfile;

  AppUser? _user;
  AppUser? get user => _user;

  Future<void> getProfile() async {
    _loadingGetProfile = true;
    notifyListeners();
    try {
      final response = await AuthService().getMyProfile();

      _user = response;
    } catch (e) {
      logger.severe('Error fetching user: $e');
    } finally {
      _loadingGetProfile = false;
      notifyListeners();
    }
  }
}
