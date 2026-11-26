import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../controllers/category_detail_controller.dart';
import '../controllers/music_controller.dart';
import '../controllers/player_controller.dart';
import '../routes/app_routes.dart';
import '../widgets/mini_player_bar.dart';
import '../widgets/music_track_card.dart';
import '../widgets/spotify_back_button.dart';
import '../widgets/track_options_sheet.dart';

class CategoryDetailScreen extends GetView<CategoryDetailController> {
  const CategoryDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerCtrl = Get.isRegistered<PlayerController>()
        ? Get.find<PlayerController>()
        : null;
    final musicCtrl = Get.isRegistered<MusicController>()
        ? Get.find<MusicController>()
        : null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Obx(() {
          final title = controller.title.value;
          final imageUrl = controller.imageUrl.value;
          final color = controller.color.value;
          final tracks = controller.tracks;

          return CustomScrollView(
            controller: controller.scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Spotify-Style Hero SliverAppBar (Like Artist Screen)
              SliverAppBar(
                expandedHeight: 270.h,
                pinned: true,
                stretch: true,
                backgroundColor: AppColors.surface,
                leadingWidth: 52.w,
                titleSpacing: 8.w,
                centerTitle: false,
                leading: const SpotifyBackButton(),
                title: _CollapsedCategoryTitle(
                  title: title,
                  controller: controller,
                ),
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  background: _CategoryFlexibleHeader(
                    title: title,
                    imageUrl: imageUrl,
                    color: color,
                  ),
                ),
              ),

              // Action Bar: Category Info, Shuffle, Big Spotify Green Play Button
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  child: Row(
                    children: [
                      // Category Tag and Songs Count
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Category • Top Hits',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              '${tracks.length} ${tracks.length == 1 ? 'Song' : 'Songs'} Available',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Shuffle Button
                      IconButton(
                        icon: Icon(
                          CupertinoIcons.shuffle,
                          color: tracks.isEmpty
                              ? AppColors.textMuted.withValues(alpha: 0.3)
                              : AppColors.primary,
                          size: 22.sp,
                        ),
                        onPressed: tracks.isEmpty
                            ? null
                            : () => controller.playAll(shuffle: true),
                      ),
                      SizedBox(width: 4.w),

                      // Big Spotify Green Play Button with glow shadow
                      GestureDetector(
                        onTap: tracks.isEmpty
                            ? null
                            : () => controller.playAll(shuffle: false),
                        child: Container(
                          width: 48.w,
                          height: 48.w,
                          decoration: BoxDecoration(
                            color: tracks.isEmpty
                                ? AppColors.surfaceLight
                                : AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: tracks.isEmpty
                                ? null
                                : [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.4),
                                      blurRadius: 14.r,
                                      offset: Offset(0, 4.h),
                                    ),
                                  ],
                          ),
                          child: Center(
                            child: Icon(
                              CupertinoIcons.play_fill,
                              color: tracks.isEmpty
                                  ? AppColors.textMuted
                                  : Colors.black,
                              size: 22.sp,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // "Popular Songs" Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
                  child: Text(
                    'Popular Songs',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),

              // Tracks List or Loading Shimmer or Empty
              if (controller.isLoading.value && tracks.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              else if (controller.errorMessage.value.isNotEmpty && tracks.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          controller.errorMessage.value,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13.sp,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        ElevatedButton(
                          onPressed: () => controller.loadCategoryTracks(controller.query.value),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (tracks.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No tracks found for $title.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.only(bottom: 24.h),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final track = tracks[index];
                        final verification = musicCtrl?.audioVerifications[track.trackId];
                        final isVerifying = musicCtrl?.verifyingTrackIds.contains(track.trackId) ?? false;

                        return MusicTrackCard(
                          track: track,
                          rank: index + 1,
                          verification: verification,
                          isVerifying: isVerifying,
                          onVerifyPressed: () => musicCtrl?.verifyAudio(track),
                          onTap: () {
                            if (playerCtrl != null) {
                              playerCtrl.playTrack(track, queue: tracks);
                            }
                            Get.toNamed(AppRoutes.player, arguments: track);
                          },
                          onMoreTap: () => TrackOptionsSheet.show(context, track),
                        );
                      },
                      childCount: tracks.length,
                    ),
                  ),
                ),
            ],
          );
        }),
        bottomNavigationBar: SafeArea(
          top: false,
          bottom: true,
          child: Get.isRegistered<PlayerController>()
              ? const MiniPlayerBar()
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// Collapsed AppBar Title that smoothly fades in when scrolled up
class _CollapsedCategoryTitle extends StatelessWidget {
  final String title;
  final CategoryDetailController controller;

  const _CollapsedCategoryTitle({
    required this.title,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final offset = controller.scrollOffset.value;
      final opacity = ((offset - 130.0) / 55.0).clamp(0.0, 1.0);

      if (opacity == 0.0) return const SizedBox.shrink();

      return Opacity(
        opacity: opacity,
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: 17.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      );
    });
  }
}

/// Hero Header Background with Left-Aligned Large Category Name when Expanded
class _CategoryFlexibleHeader extends StatelessWidget {
  final String title;
  final String imageUrl;
  final Color color;

  const _CategoryFlexibleHeader({
    required this.title,
    required this.imageUrl,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final settings =
            context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
        final double t = settings != null
            ? ((settings.maxExtent - settings.currentExtent) /
                    (settings.maxExtent - settings.minExtent))
                .clamp(0.0, 1.0)
            : 0.0;

        final expandedOpacity = (1.0 - t * 2.2).clamp(0.0, 1.0);

        return Stack(
          fit: StackFit.expand,
          children: [
            // Background Artwork
            if (imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: color,
                  child: const Center(
                    child: Icon(
                      CupertinoIcons.music_note_2,
                      color: Colors.white70,
                      size: 48,
                    ),
                  ),
                ),
              )
            else
              Container(color: color),

            // Deep Spotify Vibrant Gradient Overlay (Category Color -> Deep Spotify Background)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.70),
                    Colors.black.withValues(alpha: 0.55),
                    AppColors.background,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),

            // Large Title and Category Badge positioned at bottom-left when expanded
            Positioned(
              left: 16.w,
              bottom: 18.h,
              right: 16.w,
              child: Opacity(
                opacity: expandedOpacity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        'CATEGORY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 10.r,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
