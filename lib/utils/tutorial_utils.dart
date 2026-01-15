import 'package:flutter/material.dart';

class TutorialUtils {
  final List<Map<String, dynamic>> galleryItems = [
    {
      'image': 'assets/screenshots/01.png',
      'title': 'Browse Services',
      'description': 'Choose from various home services...',
      'icon': Icons.home_repair_service, // 🏠 Home repair icon
    },
    {
      'image': 'assets/screenshots/02.png',
      'title': 'Select Specific Service',
      'description': 'Pick the exact service you need...',
      'icon': Icons.build, // 🔨 Build/tools icon
    },
    {
      'image': 'assets/screenshots/03.png',
      'title': 'Auto-Detected Location',
      'description': 'We automatically detect your location...',
      'icon': Icons.my_location, // 📍 My location icon
    },
    {
      'image': 'assets/screenshots/04.png',
      'title': 'Set Priority Level',
      'description': 'Choose urgency level...',
      'icon': Icons.priority_high, // ⚠️ Priority icon
    },
    {
      'image': 'assets/screenshots/05.png',
      'title': 'Find Available Manongs',
      'description': 'Browse available professionals...',
      'icon': Icons.engineering, // 👷 Engineering/worker icon
    },
    {
      'image': 'assets/screenshots/06.png',
      'title': 'View Manong Details',
      'description': 'See location, distance...',
      'icon': Icons.account_circle, // 👤 Account/profile icon
    },
    {
      'image': 'assets/screenshots/07.png',
      'title': 'Complete Booking',
      'description': 'Review service details...',
      'icon': Icons.shopping_cart_checkout, // 🛒 Shopping cart checkout
    },
    {
      'image': 'assets/screenshots/08.png',
      'title': 'Track Arrival in Real-Time',
      'description': 'Monitor your Manong\'s arrival...',
      'icon': Icons.directions_run, // 🏃 Directions run for en route
    },
    {
      'image': 'assets/screenshots/09.png',
      'title': 'Live Tracking on Map',
      'description': 'Track your Manong\'s location...',
      'icon': Icons.gps_not_fixed, // 🛰️ GPS tracking icon
    },
    {
      'image': 'assets/screenshots/10.png',
      'title': 'Rate & Review',
      'description': 'Leave feedback and reviews...',
      'icon': Icons.thumb_up, // 👍 Thumbs up for rating
    },
  ];
}
