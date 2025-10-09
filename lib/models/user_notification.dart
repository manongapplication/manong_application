import 'dart:convert';

import 'package:manong_application/models/app_user.dart';

class UserNotification {
  int id;
  String title;
  String body;
  String? data;
  int userId;
  DateTime? seenAt;
  DateTime? createdAt;
  DateTime? updatedAt;
  AppUser? user;

  UserNotification({
    required this.id,
    required this.title,
    required this.body,
    this.data,
    required this.userId,
    this.seenAt,
    this.createdAt,
    this.updatedAt,
    this.user,
  });

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    return UserNotification(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      data: json['data'],
      userId: json['userId'],
      seenAt: json['seenAt'] != null
          ? DateTime.parse(json['seenAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : null,
      user: json['user'] != null ? AppUser.fromJson(json['user']) : null,
    );
  }
}
