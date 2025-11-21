import 'dart:io';

import 'package:manong_application/models/app_user.dart';
import 'package:manong_application/models/chat.dart';
import 'package:manong_application/models/manong.dart';
import 'package:manong_application/models/manong_report.dart';
import 'package:manong_application/models/payment_method.dart';
import 'package:manong_application/models/payment_status.dart';
import 'package:manong_application/models/payment_transaction.dart';
import 'package:manong_application/models/refund_request.dart';
import 'package:manong_application/models/service_item.dart';
import 'package:manong_application/models/service_request_status.dart';
import 'package:manong_application/models/sub_service_item.dart';
import 'package:manong_application/models/urgency_level.dart';
import 'package:manong_application/models/user_feedback.dart';

class ServiceRequest {
  final int? id;
  final String? requestNumber;
  final int serviceItemId;
  final int? subServiceItemId;
  final int? paymentMethodId;
  final int? userId;
  final int? manongId;
  final String? otherServiceName;
  final String? serviceDetails;
  final int urgencyLevelIndex;
  final List<File> images;

  final String? customerFullAddress;
  final double customerLat;
  final double customerLng;

  final String? notes;
  final ServiceRequestStatus? status;
  final double? total;
  final PaymentStatus? paymentStatus;

  final ServiceItem? serviceItem;
  final SubServiceItem? subServiceItem;
  final UrgencyLevel? urgencyLevel;
  final AppUser? user;
  final Manong? manong;
  final PaymentMethod? paymentMethod;
  final List<Chat>? messages;
  final UserFeedback? feedback;
  final List<PaymentTransaction>? paymentTransactions;
  final List<RefundRequest>? refundRequests;
  final ManongReport? manongReport;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? arrivedAt;
  final DateTime? deletedAt;

  ServiceRequest({
    this.id,
    this.requestNumber,
    required this.serviceItemId,
    this.subServiceItemId,
    this.paymentMethodId,
    this.userId,
    this.manongId,
    this.otherServiceName,
    this.serviceDetails,
    required this.urgencyLevelIndex,
    required this.images,

    this.customerFullAddress,
    required this.customerLat,
    required this.customerLng,

    this.notes,
    this.status,
    this.total,
    this.paymentStatus,

    this.serviceItem,
    this.subServiceItem,
    this.urgencyLevel,
    this.user,
    this.manong,
    this.paymentMethod,
    this.messages,
    this.feedback,
    this.paymentTransactions,
    this.refundRequests,
    this.manongReport,

    this.createdAt,
    this.updatedAt,
    this.arrivedAt,
    this.deletedAt,
  });

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    return ServiceRequest(
      id: json['id'] != null ? json['id'] as int : null,
      requestNumber: json['requestNumber'],
      serviceItemId: int.tryParse(json['serviceItemId'].toString()) ?? 0,
      subServiceItemId: json['subServiceItemId'] != null
          ? int.tryParse(json['subServiceItemId'].toString())
          : null,
      paymentMethodId: int.tryParse(json['paymentMethodId'].toString()) ?? 0,
      userId: json['userId'] != null
          ? int.tryParse(json['userId'].toString())
          : null,
      manongId: json['manongId'] != null
          ? int.tryParse(json['manongId'].toString())
          : null,
      otherServiceName: json['otherServiceName'],
      serviceDetails: json['serviceDetails'],
      urgencyLevelIndex: int.tryParse(json['urgencyLevelId'].toString()) ?? 0,
      images: json['imagesPath'] == null
          ? []
          : (json['imagesPath'] is List
                ? (json['imagesPath'] as List)
                      .map((path) => File(path.toString()))
                      .toList()
                : [File(json['imagesPath'].toString())]),

      customerFullAddress: json['customerFullAddress'],
      customerLat: (json['customerLat'] is num)
          ? (json['customerLat'] as num).toDouble()
          : double.tryParse(json['customerLat'].toString()) ?? 0.0,
      customerLng: (json['customerLng'] is num)
          ? (json['customerLng'] as num).toDouble()
          : double.tryParse(json['customerLng'].toString()) ?? 0.0,

      notes: json['notes'],
      status: ServiceRequestStatus.values.firstWhere(
        (e) => e.name == json['status'].toString(),
        orElse: () => ServiceRequestStatus.pending,
      ),
      total: json['total'] != null ? double.tryParse(json['total']) : null,
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == json['paymentStatus'].toString(),
        orElse: () => PaymentStatus.unpaid,
      ),
      serviceItem: json['serviceItem'] != null
          ? ServiceItem.fromJson(json['serviceItem'])
          : null,
      subServiceItem: json['subServiceItem'] != null
          ? SubServiceItem.fromJson(json['subServiceItem'])
          : null,
      urgencyLevel: json['urgencyLevel'] != null
          ? UrgencyLevel.fromJson(json['urgencyLevel'])
          : null,
      user: json['user'] != null ? AppUser.fromJson(json['user']) : null,
      manong: json['manong'] != null ? Manong.fromJson(json['manong']) : null,
      paymentMethod: json['paymentMethod'] != null
          ? PaymentMethod.fromJson(json['paymentMethod'])
          : null,
      messages: (json['messages'] is List)
          ? (json['messages'] as List)
                .where((e) => e != null)
                .map((e) => Chat.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList()
          : [],

      feedback: json['feedback'] != null
          ? UserFeedback.fromJson(json['feedback'])
          : null,

      paymentTransactions: json['paymentTransactions'] != null
          ? (json['paymentTransactions'] as List<dynamic>?)
                ?.map((e) => PaymentTransaction.fromJson(e))
                .toList()
          : [],

      refundRequests: json['refundRequests'] != null
          ? (json['refundRequests'] as List<dynamic>)
                .map((e) => RefundRequest.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      manongReport: json['manongReport'] != null
          ? ManongReport.fromJson(json['manongReport'])
          : null,

      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : null,
      arrivedAt: json['arrivedAt'] != null
          ? DateTime.parse(json['arrivedAt'].toString())
          : null,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serviceItemId': serviceItemId,
      'subServiceItemId': subServiceItemId,
      'userId': userId,
      'manongId': manongId,
      'otherServiceName': otherServiceName,
      'serviceDetails': serviceDetails,
      'urgencyLevelIndex': urgencyLevelIndex,
      'imagesPath': images.map((file) => file.path).toList(),
      'customerLat': customerLat,
      'customerLng': customerLng,
      'notes': notes,
    };
  }

  @override
  String toString() {
    return 'ServiceRequest('
        'id: $id, '
        'serviceItemId: $serviceItemId, '
        'subServiceItemId: $subServiceItemId, '
        'userId: $userId, '
        'manongId: $manongId, '
        'otherServiceName: $otherServiceName, '
        'serviceDetails: $serviceDetails, '
        'urgencyLevelIndex: $urgencyLevelIndex, '
        'images: ${images.map((f) => f.path).toList()}, '
        'customerLat: $customerLat, '
        'customerLng: $customerLng, '
        'notes: $notes, '
        'status: $status, '
        'total: $total, '
        'paymentStatus: $paymentStatus, '
        'serviceItem: $serviceItem, '
        'subServiceItem: $subServiceItem, '
        'urgencyLevel: $urgencyLevel, '
        'manong: $manong'
        'manong: ${manong?.profile?.id}'
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt, '
        'deletedAt: $arrivedAt, '
        'deletedAt: $deletedAt, '
        ')';
  }
}
