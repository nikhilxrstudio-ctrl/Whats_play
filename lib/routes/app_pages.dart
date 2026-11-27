import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/artist_detail_controller.dart';
import '../controllers/category_detail_controller.dart';
import '../controllers/music_controller.dart';
import '../controllers/section_tracks_controller.dart';
import '../repositories/music_repository.dart';
import '../screens/artist_detail_screen.dart';
import '../screens/blend_detail_screen.dart';
import '../screens/category_detail_screen.dart';
import '../screens/music_catalogue_screen.dart';
import '../screens/music_player_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/section_tracks_screen.dart';
import '../services/audius_service.dart';
import '../services/saavn_service.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.catalogue,
      page: () => const MusicCatalogueScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AudiusService>(() => AudiusService());
        Get.lazyPut<SaavnService>(() => SaavnService());
        Get.lazyPut<IMusicRepository>(
          () => MusicRepository(
            audiusService: Get.find<AudiusService>(),
            saavnService: Get.find<SaavnService>(),
          ),
        );
        Get.lazyPut<MusicController>(
          () => MusicController(Get.find<IMusicRepository>()),
        );
      }),
    ),
    GetPage(
      name: AppRoutes.player,
      page: () => const MusicPlayerScreen(),
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      popGesture: true,
    ),
    GetPage(
      name: AppRoutes.artist,
      page: () => const ArtistDetailScreen(),
      transition: Transition.cupertino,
      popGesture: true,
      binding: BindingsBuilder(() {
        Get.lazyPut<ArtistDetailController>(
          () => ArtistDetailController(Get.find<IMusicRepository>()),
        );
      }),
    ),
    GetPage(
      name: AppRoutes.sectionTracks,
      page: () => const SectionTracksScreen(),
      transition: Transition.cupertino,
      popGesture: true,
      binding: BindingsBuilder(() {
        Get.lazyPut<SectionTracksController>(() => SectionTracksController());
      }),
    ),
    GetPage(
      name: AppRoutes.category,
      page: () => const CategoryDetailScreen(),
      transition: Transition.cupertino,
      popGesture: true,
      binding: BindingsBuilder(() {
        Get.lazyPut<CategoryDetailController>(
          () => CategoryDetailController(Get.find<IMusicRepository>()),
        );
      }),
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileScreen(),
      transition: Transition.cupertino,
      popGesture: true,
    ),
    GetPage(
      name: AppRoutes.blendDetail,
      page: () => const BlendDetailScreen(),
      transition: Transition.cupertino,
      popGesture: true,
    ),
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingScreen(),
      transition: Transition.fadeIn,
    ),
  ];
}
