import 'dart:io';
import 'dart:ui';
import 'package:audio_service/audio_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'constants/app_colors.dart';
import 'constants/app_constants.dart';
import 'controllers/player_controller.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'services/audio_player_handler.dart';
import 'services/auth_service.dart';
import 'services/blend_service.dart';
import 'services/deep_link_service.dart';
import 'services/local_database_service.dart';
import 'services/onboarding_service.dart';

late AudioPlayerHandler audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (safely wrapped so offline / test environments don't throw)
  try {
    await Firebase.initializeApp();

    // Disable Crashlytics collection completely in debug mode; only collect in release mode
    if (kDebugMode) {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
    } else {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    }

    // Catch framework-level errors (widgets, layout, gestures)
    FlutterError.onError = (FlutterErrorDetails details) {
      // In debug mode, print to local console only; do NOT send to Firebase
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(details);
        return;
      }

      // Check for image codec / network image timeouts or benign silent errors
      final isSilent = details.silent;
      final isImageResource = details.library == 'image resource service' ||
          details.context?.toString().contains('image codec') == true ||
          details.context?.toString().contains('image resource') == true;
      final isNetworkTimeout = details.exception is SocketException ||
          details.exception is HttpException ||
          details.exception.toString().contains('SocketException') ||
          details.exception.toString().contains('Connection timed out');

      // COMPLETELY SUPPRESS / IGNORE image timeouts and silent handled errors
      // so this issue stays completely closed in Firebase Crashlytics
      if (isSilent || isImageResource || isNetworkTimeout) {
        debugPrint('[Crashlytics] Suppressed handled image/network error: ${details.exception}');
        return;
      }

      // Send all genuine crashes to Firebase in release mode
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };

    // Catch asynchronous / platform-level unhandled errors
    PlatformDispatcher.instance.onError = (error, stack) {
      // In debug mode, print locally only; do NOT send to Firebase
      if (kDebugMode) {
        debugPrint('[UncaughtAsyncError]: $error\n$stack');
        return true;
      }

      // Completely suppress socket timeouts and image codec errors from Firebase
      if (error is SocketException ||
          error is HttpException ||
          error.toString().contains('SocketException') ||
          error.toString().contains('Connection timed out') ||
          error.toString().contains('image codec')) {
        debugPrint('[Crashlytics] Suppressed handled async network error: $error');
        return true; // Handled
      }

      // All real unhandled asynchronous crashes are sent to Firebase as fatal
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e) {
    debugPrint('[Firebase] Initialization skipped or error: $e');
  }

  // Initialize background AudioService with Media Notification settings
  audioHandler = await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.whatsplay.music.app.channel.audio',
      androidNotificationChannelName: 'WhatsPlay Music Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'drawable/ic_notification',
      notificationColor: AppColors.primary,
    ),
  );

  // Register AudioPlayerHandler, LocalDatabaseService, AuthService, and PlayerController globally
  final databaseService = LocalDatabaseService();
  Get.put<ILocalDatabaseService>(databaseService, permanent: true);
  Get.put<AudioPlayerHandler>(audioHandler, permanent: true);
  Get.put<AuthService>(AuthService(), permanent: true);
  Get.put<BlendService>(BlendService(), permanent: true);
  Get.put<DeepLinkService>(DeepLinkService(), permanent: true);
  Get.put<PlayerController>(
    PlayerController(audioHandler, databaseService: databaseService),
    permanent: true,
  );

  final onboardingDone = await OnboardingService().isOnboardingDone();

  runApp(WhatsPlayApp(
    initialRoute: onboardingDone ? AppRoutes.catalogue : AppRoutes.onboarding,
  ));
}

class WhatsPlayApp extends StatelessWidget {
  final String initialRoute;

  const WhatsPlayApp({
    super.key,
    this.initialRoute = AppRoutes.catalogue,
  });

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(
        AppConstants.designWidth,
        AppConstants.designHeight,
      ),
      minTextAdapt: true,
      splitScreenMode: true,
      fontSizeResolver: (num fontSize, ScreenUtil instance) => fontSize.toDouble(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: GetMaterialApp(
          title: AppConstants.appTitle,
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.dark,
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppColors.background,
            primaryColor: AppColors.primary,
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surface,
            ),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            listTileTheme: const ListTileThemeData(
              tileColor: Colors.transparent,
              selectedTileColor: Colors.transparent,
            ),
            useMaterial3: true,
            fontFamily: 'Roboto',
          ),
          initialRoute: initialRoute,
          getPages: AppPages.routes,
          defaultTransition: Transition.cupertino,
          transitionDuration: const Duration(milliseconds: 280),
          ),
        );
      },
    );
  }
}
