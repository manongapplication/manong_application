import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/firebase_api_token.dart';
import 'package:manong_application/api/socket_api_service.dart';
import 'package:manong_application/models/manong.dart';
import 'package:manong_application/models/service_request.dart';
import 'package:manong_application/providers/app_maintenance_provider.dart';
import 'package:manong_application/providers/bottom_nav_provider.dart';
import 'package:manong_application/screens/app_maintenance_screen.dart';
import 'package:manong_application/screens/auth/change_password_screen.dart';
import 'package:manong_application/screens/auth/create_password_Screen.dart';
import 'package:manong_application/screens/auth/enter_password_screen.dart';
import 'package:manong_application/screens/auth/password_reset.dart';
import 'package:manong_application/screens/auth/register_screen.dart';
import 'package:manong_application/screens/auth/verify_screen.dart';
import 'package:manong_application/screens/booking/add_card_payment.dart';
import 'package:manong_application/screens/booking/booking_summary_screen.dart';
import 'package:manong_application/screens/booking/card_add_payment_method_screen.dart';
import 'package:manong_application/screens/booking/manong_details_screen.dart';
import 'package:manong_application/screens/booking/manong_list_screen.dart';
import 'package:manong_application/screens/booking/payment_methods_screen.dart';
import 'package:manong_application/screens/booking/payment_processing_screen.dart';
import 'package:manong_application/screens/booking/payment_redirect_screen.dart';
import 'package:manong_application/screens/booking/problem_details_screen.dart';
import 'package:manong_application/screens/booking/sub_service_list_screen.dart';
import 'package:manong_application/screens/home/user_notification_screen.dart';
import 'package:manong_application/screens/main_screen.dart';
import 'package:manong_application/screens/onboarding_screen.dart';
import 'package:manong_application/screens/profile/complete_profile_screen.dart';
import 'package:manong_application/screens/profile/edit_profile.dart';
import 'package:manong_application/screens/profile/help_and_support_screen.dart';
import 'package:manong_application/screens/profile/location_settings_screen.dart';
import 'package:manong_application/screens/profile/notification_settings_screen.dart';
import 'package:manong_application/screens/profile/profile_screen.dart';
import 'package:manong_application/screens/service_requests/chat_manong_screen.dart';
import 'package:manong_application/screens/service_requests/route_tracking_screen.dart';
import 'package:manong_application/screens/service_requests/service_requests_details_screen.dart';
import 'package:manong_application/screens/service_requests/transaction_screen.dart';
import 'package:manong_application/screens/wallet/cash_in_screen.dart';
import 'package:manong_application/services/notification_service.dart';
import 'package:manong_application/utils/onboarding_storage.dart';
import 'package:manong_application/widgets/authenticated_screen.dart';
import 'package:manong_application/widgets/gallery_tutorial_screen.dart';
import 'package:manong_application/widgets/location_map.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final socketService = SocketApiService();
final Logger logger = Logger('MainApp');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint(
      '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}',
    );
  });

  await dotenv.load(fileName: ".env");
  await GetStorage.init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Future.delayed(Duration(seconds: 1));
  FlutterNativeSplash.remove();

  // System UI setup...
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  socketService.connect();

  // Initialize Local Notifications FIRST (with iOS settings)
  await NotificationService.init();

  // Then setup Firebase Messaging with safe token handling
  await _setupFirebaseMessaging();

  final onboarding = OnboardingStorage();
  await onboarding.init();

  final maintenanceProvider = AppMaintenanceProvider();
  await maintenanceProvider.fetchMaintenance();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BottomNavProvider()),
        ChangeNotifierProvider.value(value: onboarding),
        ChangeNotifierProvider(create: (_) => maintenanceProvider),
      ],
      child: MyApp(),
    ),
  );
}

Future<void> _setupFirebaseMessaging() async {
  final messaging = FirebaseMessaging.instance;

  // iOS-specific setup
  await messaging.setForegroundNotificationPresentationOptions(
    alert: true, // Show alert when in foreground
    badge: true, // Update badge when in foreground
    sound: true, // Play sound when in foreground
  );

  // Request permissions with provisional for iOS 12+
  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: true, // Allow silent notifications first (iOS 12+)
    criticalAlert: false, // Only enable if you need critical alerts
  );

  logger.info("📱 Notification permission: ${settings.authorizationStatus}");

  // Get APNs token (iOS only)
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    final apnsToken = await messaging.getAPNSToken();
    logger.info("🍎 APNs Token: $apnsToken");
  }

  // Initialize token refresh listener
  await FirebaseApiToken().refreshTokenListener();

  // Safe token handling for iOS
  if (settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional) {
    // For iOS, wait longer for APNs token to be ready
    Future.delayed(Duration(seconds: 5), () async {
      try {
        await FirebaseApiToken().saveFcmTokenToDatabase();
      } catch (e) {
        logger.warning("⚠️ Initial FCM token save failed: $e");
        // Retry after longer delay for iOS
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          Future.delayed(Duration(seconds: 10), () async {
            try {
              await FirebaseApiToken().saveFcmTokenToDatabase();
            } catch (e) {
              logger.warning("⚠️ Second FCM token save attempt failed: $e");
            }
          });
        }
      }
    });
  }

  // Background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Foreground message handler
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    logger.info('🔥 FCM Foreground message received');

    // Handle iOS-specific notification structure
    _handleForegroundMessage(message);
  });

  // App opened from notification
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    logger.info('🔔 Notification tapped: ${message.data}');
    _handleNotificationTap(message);
  });

  // Get initial notification if app was launched from terminated state
  final initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null) {
    logger.info('🚀 App launched from notification: ${initialMessage.data}');
    _handleNotificationTap(initialMessage);
  }
}

void _handleForegroundMessage(RemoteMessage message) {
  final data = message.data;

  String title = data['title'] ?? message.notification?.title ?? 'New Message';
  String body =
      data['body'] ??
      message.notification?.body ??
      'You have a new notification';

  // For iOS, we need to handle both notification and data payloads
  logger.info(
    '📱 Foreground Notification - Title: $title, Body: $body, Data: $data',
  );

  // Show local notification
  NotificationService.showNotification(
    title: title,
    body: body,
    payload: data.isNotEmpty ? jsonEncode(data) : null,
  );
}

void _handleNotificationTap(RemoteMessage message) {
  final data = message.data;
  logger.info('👆 Notification tapped with data: $data');

  // Handle navigation based on notification data
  _navigateFromNotification(data);
}

void _navigateFromNotification(Map<String, dynamic> data) {
  // Example navigation logic - customize based on your app structure
  if (data['serviceRequestId'] != null) {
    // Navigate to service request details
    navigatorKey.currentState?.pushNamed(
      '/service-request-details',
      arguments: {'serviceRequestId': int.tryParse(data['serviceRequestId'])},
    );
  } else if (data['type'] == 'chat') {
    if (data['serviceRequestIdForChat'] != null) {
      navigatorKey.currentState?.pushNamed(
        '/service-request-details',
        arguments: {
          'serviceRequestId': int.tryParse(data['serviceRequestIdForChat']),
          'goToChat': true,
        },
      );
    }
  }
  // Add more navigation cases as needed
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  logger.info("📩 Background message received");
  logger.info("📩 Background title: ${message.notification?.title}");
  logger.info("📩 Background data: ${message.data}");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final onboarding = context.watch<OnboardingStorage>();
    final maintenanceProvider = context.watch<AppMaintenanceProvider>();

    return MaterialApp(
      title: 'Manong Application',
      initialRoute: '/',
      navigatorKey: navigatorKey,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            if (maintenanceProvider.hasMaintenance) {
              return MaterialPageRoute(
                builder: (_) => AppMaintenanceScreen(
                  appMaintenance: maintenanceProvider.appMaintenance!,
                  onRefresh: () async {
                    await maintenanceProvider.fetchMaintenance();
                  },
                ),
              );
            }

            if (onboarding.isFirstTimeValue == null) {
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            if (onboarding.isFirstTimeValue == true) {
              return MaterialPageRoute(
                builder: (_) => const OnboardingScreen(),
              );
            } else {
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (_) => MainScreen(
                  index: args?['index'] != null ? args!['index'] as int : null,
                  serviceRequestStatusIndex:
                      args?['serviceRequestStatusIndex'] != null
                      ? args!['serviceRequestStatusIndex'] as int
                      : null,
                  serviceRequestId: args?['serviceRequestId'] != null
                      ? args!['serviceRequestId'] as int
                      : null,
                ),
              );
            }
          case '/app-maintenance':
            if (maintenanceProvider.hasMaintenance) {
              return MaterialPageRoute(
                builder: (_) => AppMaintenanceScreen(
                  appMaintenance: maintenanceProvider.appMaintenance!,
                  onRefresh: () async {
                    await maintenanceProvider.fetchMaintenance();
                  },
                ),
              );
            }
          case '/gallery-tutorial':
            return MaterialPageRoute(
              builder: (_) => const GalleryTutorialScreen(),
            );
          case '/register':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (_) => RegisterScreen(isLoginFlow: args?['isLoginFlow']),
            );
          case '/enter-password':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (_) => EnterPasswordScreen(phone: args?['phone']),
            );
          case '/change-password':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (_) => ChangePasswordScreen(phone: args?['phone']),
            );
          case '/verify':
            final args = settings.arguments as Map<String, dynamic>?;

            return MaterialPageRoute(
              builder: (_) => VerifyScreen(
                authService: args?['authService'] != null
                    ? args!['authService']
                    : null,
                verificationId: args?['verificationId'] != null
                    ? args!['verificationId']
                    : null,
                phoneNumber: args?['phoneNumber'] != null
                    ? args!['phoneNumber']
                    : null,
                isPasswordReset: args?['isPasswordReset'] != null
                    ? args!['isPasswordReset']
                    : null,
                referralCode: args?['referralCode'] != null
                    ? args!['referralCode']
                    : null,
              ),
            );
          case '/password-reset':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (_) =>
                  PasswordReset(resetPassword: args?['resetPassword']),
            );
          case '/sub-service-list':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => SubServiceListScreen(
                serviceItem: args['serviceItem'],
                iconColor: args['iconColor'],
                search: args['search'],
              ),
            );
          case '/problem-details':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (_) => AuthenticatedScreen(
                child: ProblemDetailsScreen(
                  serviceItem: args?['serviceItem'],
                  subServiceItem: args?['subServiceItem'] != null
                      ? args!['subServiceItem']
                      : null,
                  iconColor: args?['iconColor'],
                ),
              ),
            );
          case '/location-map':
            return MaterialPageRoute(builder: (_) => LocationMap());
          case '/route-tracking':
            final args = settings.arguments as Map<String, dynamic>?;

            return MaterialPageRoute(
              builder: (_) => RouteTrackingScreen(
                currentLatLng: args?['currentLatLng'] as LatLng?,
                manongLatLng: args?['manongLatLng'] as LatLng?,
                manongName: args?['manongName'] as String?,
                isManong: args?['isManong'] as bool,
              ),
            );
          case '/manong-list':
            final args = settings.arguments as Map<String, dynamic>?;

            ServiceRequest? serviceRequest;

            if (args?['serviceRequest'] is ServiceRequest) {
              serviceRequest = args?['serviceRequest'] as ServiceRequest;
            } else {
              serviceRequest = ServiceRequest.fromJson(args?['serviceRequest']);
            }

            return MaterialPageRoute(
              builder: (_) => ManongListScreen(
                serviceRequest: args?['serviceRequest'] != null
                    ? serviceRequest!
                    : throw Exception(
                        'ManongListScreen: serviceRequest is required',
                      ),
              ),
            );

          case '/manong-details':
            final args = settings.arguments as Map<String, dynamic>?;

            return MaterialPageRoute(
              builder: (_) => ManongDetailsScreen(
                manong: args?['manong'] as Manong?,
                serviceRequest: args?['serviceRequest'] as ServiceRequest?,
              ),
            );

          case '/service-request-details':
            final args = settings.arguments as Map<String, dynamic>?;

            return MaterialPageRoute(
              builder: (_) => ServiceRequestsDetailsScreen(
                serviceRequest: args?['serviceRequest'] as ServiceRequest?,
                isManong: args?['isManong'] != null
                    ? args!['isManong'] as bool
                    : null,
                goToChat: args?['goToChat'] != null
                    ? args!['goToChat'] as bool
                    : null,
              ),
            );

          case '/payment-methods':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (_) => PaymentMethodsScreen(
                selectedIndex: args?['selectedIndex'] != null
                    ? int.tryParse(args!['selectedIndex'].toString())
                    : null,
                toUpdate: args?['toUpdate'] != null
                    ? args!['toUpdate'] as bool
                    : null,
                serviceRequest: args?['serviceRequest'] != null
                    ? args!['serviceRequest'] as ServiceRequest
                    : null,
              ),
            );

          case '/card-add-payment-method':
            return MaterialPageRoute(
              builder: (_) => CardAddPaymentMethodScreen(),
            );

          case '/booking-summary':
            final args = settings.arguments as Map<String, dynamic>;

            return MaterialPageRoute(
              builder: (_) => BookingSummaryScreen(
                serviceRequest: args['serviceRequest'] as ServiceRequest,
                manong: args['manong'] as Manong,
                meters: args['meters'] as double,
              ),
            );
          case '/edit-profile':
            final args = settings.arguments as Map<String, dynamic>?;

            return MaterialPageRoute(
              builder: (_) => EditProfile(destination: args?['destination']),
            );
          case '/add-card':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (_) => AddCardPayment(
                proceed: args?['proceed'] != null ? args!['proceed'] : null,
                serviceRequest: args?['serviceRequest'] != null
                    ? args!['serviceRequest']
                    : null,
                manong: args?['manong'] != null ? args!['manong'] : null,
                meters: args?['meters'] != null ? args!['meters'] : null,
              ),
            );
          case '/payment-processing':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => PaymentProcessingScreen(
                serviceRequest: args['serviceRequest'],
                manong: args['manong'],
                meters: args['meters'],
              ),
            );
          case '/chat-manong':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => ChatManongScreen(
                serviceRequest: args['serviceRequest'] as ServiceRequest,
              ),
            );
          case '/notification-settings':
            return MaterialPageRoute(
              builder: (_) => NotificationSettingsScreen(),
            );
          case '/location-settings':
            return MaterialPageRoute(builder: (_) => LocationSettingsScreen());
          case '/payment-redirect':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (_) => PaymentRedirectScreen(
                serviceRequest: args?['serviceRequest'] as ServiceRequest?,
              ),
            );
          case '/transactions':
            return MaterialPageRoute(builder: (_) => TransactionScreen());
          case '/notifications':
            return MaterialPageRoute(builder: (_) => UserNotificationScreen());
          case '/complete-profile':
            return MaterialPageRoute(builder: (_) => CompleteProfileScreen());
          case '/help-and-support':
            return MaterialPageRoute(builder: (_) => HelpAndSupportScreen());
          case '/create-password':
            return MaterialPageRoute(builder: (_) => CreatePasswordScreen());
          case '/profile':
            return MaterialPageRoute(builder: (_) => ProfileScreen());
          case '/wallet-cash-in':
            return MaterialPageRoute(builder: (_) => CashInScreen());
        }
        return null;
      },
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.light,
          elevation: 0,
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
