import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/auth_service.dart';
import 'package:manong_application/api/firebase_api_token.dart';
import 'package:manong_application/api/socket_api_service.dart';
import 'package:manong_application/models/manong.dart';
import 'package:manong_application/models/service_request.dart';
import 'package:manong_application/models/sub_service_item.dart';
import 'package:manong_application/providers/bottom_nav_provider.dart';
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
import 'package:manong_application/screens/profile/edit_profile.dart';
import 'package:manong_application/screens/profile/notification_settings_screen.dart';
import 'package:manong_application/screens/service_requests/chat_manong_screen.dart';
import 'package:manong_application/screens/service_requests/route_tracking_screen.dart';
import 'package:manong_application/screens/service_requests/service_requests_details_screen.dart';
import 'package:manong_application/services/notification_service/notification_service.dart';
import 'package:manong_application/utils/onboarding_storage.dart';
import 'package:manong_application/utils/permission_utils.dart';
import 'package:manong_application/widgets/authenticated_screen.dart';
import 'package:manong_application/widgets/location_map.dart';
import 'package:provider/provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final socketService = SocketApiService();
final Logger logger = Logger('MainApp');
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Logger.root.level = Level.ALL; // capture all logs
  Logger.root.onRecord.listen((record) {
    debugPrint(
      '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}',
    );
  });

  await dotenv.load(fileName: ".env");

  await GetStorage.init();
  await Firebase.initializeApp();
  await Future.delayed(Duration(seconds: 1));

  FlutterNativeSplash.remove();

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

  final fcmApi = FirebaseApiToken();
  final fcmToken = await fcmApi.getToken();
  final String? token = await AuthService().getNodeToken();
  logger.info("📱 Securely stored FCM Token: $fcmToken");
  if (fcmToken != null && token != null) {
    await FirebaseApiToken().saveFcmTokenToDatabase();
  }
  await fcmApi.refreshTokenListener();

  await NotificationService.init();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Listen for token changes
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    if (newToken.isNotEmpty) {
      await FirebaseApiToken().saveFcmTokenToDatabase();
    }
  });

  // Foreground notification
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final data = message.data;

    // Add back the debug logging to see what's happening
    logger.info('🔥 FCM Message Received');
    logger.info('📱 Message Data: $data');
    logger.info('🔔 Notification: ${message.notification?.toMap()}');
    logger.info('💬 Full message - $message');

    // Check if we have data or notification content
    String title = '';
    String body = '';

    if (data.isNotEmpty) {
      title = data['title'] ?? '';
      body = data['body'] ?? '';
      logger.info('📦 Using data payload - Title: $title, Body: $body');
    }

    if (title.isEmpty && message.notification != null) {
      title = message.notification!.title ?? '';
      body = message.notification!.body ?? '';
      logger.info('🔔 Using notification payload - Title: $title, Body: $body');
    }

    if (title.isEmpty && body.isEmpty) {
      logger.warning('⚠️ No title or body found in message');
      title = 'New Message';
      body = 'You have a new notification';
    }

    logger.info('🎯 Final notification - Title: $title, Body: $body');

    if (PermissionUtils().locationPermissionGranted == false) return;

    NotificationService.showNotification(title: title, body: body);

    logger.info('✅ NotificationService.showNotification called');
  });

  // App opened from a notification tap
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    logger.info('🔔 Notification tapped: ${message.data}');
  });

  final onboarding = OnboardingStorage();
  await onboarding.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BottomNavProvider()),
        ChangeNotifierProvider.value(value: onboarding),
      ],
      child: MyApp(),
    ),
  );
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

    return MaterialApp(
      title: 'Manong Application',
      initialRoute: '/',
      navigatorKey: navigatorKey,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
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

          case '/register':
            return MaterialPageRoute(builder: (_) => RegisterScreen());
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
              ),
            );
          case '/sub-service-list':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => SubServiceListScreen(
                serviceItem: args['serviceItem'],
                iconColor: args['iconColor'],
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
                isAdmin: args?['isAdmin'] as bool,
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
                subServiceItem: args?['subServiceItem'] != null
                    ? args!['subServiceItem']
                    : null,
              ),
            );

          case '/manong-details':
            final args = settings.arguments as Map<String, dynamic>?;

            return MaterialPageRoute(
              builder: (_) => ManongDetailsScreen(
                currentLatLng: args?['currentLatLng'] as LatLng?,
                manongLatLng: args?['manongLatLng'] as LatLng?,
                manongName: args?['manongName'] as String?,
                manong: args?['manong'] as Manong?,
                serviceRequest: args?['serviceRequest'] as ServiceRequest?,
                subServiceItem: args?['subServiceItem'] as SubServiceItem?,
              ),
            );

          case '/service-request-details':
            final args = settings.arguments as Map<String, dynamic>?;

            return MaterialPageRoute(
              builder: (_) => ServiceRequestsDetailsScreen(
                serviceRequest: args?['serviceRequest'] as ServiceRequest?,
                isAdmin: args?['isAdmin'] != null
                    ? args!['isAdmin'] as bool
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
              ),
            );
          case '/payment-processing':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => PaymentProcessingScreen(
                serviceRequest: args['serviceRequest'],
                manong: args['manong'],
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
          case '/payment-redirect':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (_) => PaymentRedirectScreen(
                serviceRequest: args?['serviceRequest'] as ServiceRequest?,
              ),
            );
          case '/notifications':
            return MaterialPageRoute(builder: (_) => UserNotificationScreen());
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
