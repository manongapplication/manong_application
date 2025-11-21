import 'package:manong_application/models/app_user.dart';
import 'package:manong_application/models/service_request.dart';

class UserFeedback {
  final int id;
  final int serviceRequestId;
  final int reviewerId;
  final int revieweeId;
  final int rating;
  final String? comment;
  final String? attachmentPath;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  final ServiceRequest? serviceRequest;
  final AppUser? reviewer;
  final AppUser? reviewee;

  UserFeedback({
    required this.id,
    required this.serviceRequestId,
    required this.reviewerId,
    required this.revieweeId,
    required this.rating,
    this.comment,
    this.attachmentPath,

    this.createdAt,
    this.updatedAt,

    this.serviceRequest,
    this.reviewer,
    this.reviewee,
  });

  factory UserFeedback.fromJson(Map<String, dynamic> json) {
    return UserFeedback(
      id: json['id'],
      serviceRequestId: json['serviceRequestId'],
      reviewerId: json['reviewerId'],
      revieweeId: json['revieweeId'],
      rating: json['rating'],
      comment: json['comment'],

      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,

      serviceRequest: json['serviceRequest'] != null
          ? ServiceRequest.fromJson(
              json['serviceRequest'] as Map<String, dynamic>,
            )
          : null,
      reviewer: json['reviewer'] != null
          ? AppUser.fromJson(json['reviewer'] as Map<String, dynamic>)
          : null,
      reviewee: json['reviewee'] != null
          ? AppUser.fromJson(json['reviewee'] as Map<String, dynamic>)
          : null,
    );
  }
}
