import 'package:flutter/material.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/widgets/my_app_bar.dart';

class GalleryTutorialScreen extends StatefulWidget {
  const GalleryTutorialScreen({super.key});

  @override
  State<GalleryTutorialScreen> createState() => _GalleryTutorialScreenState();
}

class _GalleryTutorialScreenState extends State<GalleryTutorialScreen> {
  final PageController _galleryController = PageController(
    viewportFraction: 0.8,
  );
  int _galleryPage = 0;

  final List<Map<String, dynamic>> _galleryItems = [
    {
      'image': 'assets/screenshots/01.png',
      'title': 'Browse Services',
      'description':
          'Choose from various home services like appliance repair, carpentry, cleaning, and electrical work.',
      'icon': Icons.home_repair_service, // 🏠 Home repair icon
    },
    {
      'image': 'assets/screenshots/02.png',
      'title': 'Select Specific Service',
      'description':
          'Pick the exact service you need, like Door & Cabinet repair within Carpentry.',
      'icon': Icons.build, // 🔨 Build/tools icon
    },
    {
      'image': 'assets/screenshots/03.png',
      'title': 'Auto-Detected Location',
      'description':
          'We automatically detect your location to find nearby Manongs.',
      'icon': Icons.my_location, // 📍 My location icon
    },
    {
      'image': 'assets/screenshots/04.png',
      'title': 'Set Priority Level',
      'description':
          'Choose urgency level from Standard to Emergency based on your needs.',
      'icon': Icons.priority_high, // ⚠️ Priority icon
    },
    {
      'image': 'assets/screenshots/05.png',
      'title': 'Find Available Manongs',
      'description':
          'Browse available professionals with their skills and ratings.',
      'icon': Icons.engineering, // 👷 Engineering/worker icon
    },
    {
      'image': 'assets/screenshots/06.png',
      'title': 'View Manong Details',
      'description':
          'See location, distance, and information about each Manong.',
      'icon': Icons.account_circle, // 👤 Account/profile icon
    },
    {
      'image': 'assets/screenshots/07.png',
      'title': 'Complete Booking',
      'description': 'Review service details and choose payment method.',
      'icon': Icons.shopping_cart_checkout, // 🛒 Shopping cart checkout
    },
    {
      'image': 'assets/screenshots/08.png',
      'title': 'Track Arrival in Real-Time',
      'description': 'Monitor your Manong\'s arrival time and booking status.',
      'icon': Icons.directions_run, // 🏃 Directions run for en route
    },
    {
      'image': 'assets/screenshots/09.png',
      'title': 'Live Tracking on Map',
      'description': 'Track your Manong\'s location in real-time on the map.',
      'icon': Icons.gps_not_fixed, // 🛰️ GPS tracking icon
    },
    {
      'image': 'assets/screenshots/10.png',
      'title': 'Rate & Review',
      'description': 'Leave feedback and reviews after service completion.',
      'icon': Icons.thumb_up, // 👍 Thumbs up for rating
    },
  ];

  @override
  void initState() {
    super.initState();
  }

  void _onGalleryPageChanged(int index) {
    setState(() {
      _galleryPage = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: myAppBar(title: 'How Manong Works'),
      body: SafeArea(
        child: Column(
          children: [
            // Header similar to onboarding
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Column(
                children: [
                  // Header row with centered logo
                  Stack(
                    children: [
                      // Logo centered
                      Center(
                        child: Image.asset(
                          'assets/icon/logo.png',
                          width: 48,
                          height: 48,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'How Manong Works',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColorScheme.deepTeal,
                    ),
                  ),
                  Text(
                    'Your trusted home service partner',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // Gallery with larger images - SAME AS ONBOARDING
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: PageView.builder(
                  controller: _galleryController,
                  itemCount: _galleryItems.length,
                  onPageChanged: _onGalleryPageChanged,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final item = _galleryItems[index];
                    final isLastGalleryItem = index == _galleryItems.length - 1;

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        children: [
                          // Feature indicator - compact (SAME AS ONBOARDING)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColorScheme.primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item['title']!,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppColorScheme.deepTeal,
                                    ),
                                    maxLines: 2,
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Image - MAXIMUM SIZE (SAME AS ONBOARDING)
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  item['image']!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),

                          // Description with optional "Done" button (SIMILAR TO ONBOARDING)
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  item['description']!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.4,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                ),
                                if (isLastGalleryItem) ...[
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppColorScheme.primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                          horizontal: 32,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 4,
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text(
                                        'Got it! Return to App',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // Compact navigation - Hide on last gallery screen (SAME AS ONBOARDING)
            if (_galleryPage < _galleryItems.length - 1)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  children: [
                    // Progress dots (SAME DOTS STYLE AS ONBOARDING)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _galleryItems.length,
                        (dotIndex) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _galleryPage == dotIndex ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _galleryPage == dotIndex
                                ? AppColorScheme.primaryColor
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Simple instruction
                    Text(
                      'Swipe to continue',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }
}
