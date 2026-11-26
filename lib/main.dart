import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'constants/app_colors.dart';
import 'constants/app_constants.dart';
import 'controllers/player_controller.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'services/audio_player_handler.dart';
import 'services/local_database_service.dart';

late AudioPlayerHandler audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize background AudioService with Media Notification settings
  audioHandler = await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.whatsplay.music.channel.audio',
      androidNotificationChannelName: 'WhatsPlay Music Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'drawable/ic_notification',
      notificationColor: AppColors.primary,
    ),
  );

  // Register AudioPlayerHandler, LocalDatabaseService, and PlayerController globally
  final databaseService = LocalDatabaseService();
  Get.put<ILocalDatabaseService>(databaseService, permanent: true);
  Get.put<AudioPlayerHandler>(audioHandler, permanent: true);
  Get.put<PlayerController>(
    PlayerController(audioHandler, databaseService: databaseService),
    permanent: true,
  );

  runApp(const WhatsPlayApp());
}

class WhatsPlayApp extends StatelessWidget {
  const WhatsPlayApp({super.key});

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
          initialRoute: AppRoutes.catalogue,
          getPages: AppPages.routes,
          defaultTransition: Transition.cupertino,
          transitionDuration: const Duration(milliseconds: 280),
          ),
        );
      },
    );
  }
}
