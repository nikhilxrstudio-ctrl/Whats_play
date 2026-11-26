import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../controllers/artist_detail_controller.dart';
import '../controllers/player_controller.dart';
import '../routes/app_routes.dart';
import '../widgets/mini_player_bar.dart';
import '../widgets/music_track_card.dart';
import '../widgets/spotify_back_button.dart';
import '../widgets/track_options_sheet.dart';

class ArtistDetailScreen extends GetView<ArtistDetailController> {
  const ArtistDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          final artist = controller.artist.value;
          final artistName = artist?.name ?? 'Artist';
          final imageUrl = artist?.imageUrl;

          return CustomScrollView(
            controller: controller.scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Spotify-Style Hero SliverAppBar
              SliverAppBar(
                expandedHeight: 280.h,
                pinned: true,
                stretch: true,
                backgroundColor: AppColors.surface,
                leadingWidth: 52.w,
                titleSpacing: 8.w,
                centerTitle: false,
                leading: const SpotifyBackButton(),
                title: _CollapsedAppBarTitle(
                  artistName: artistName,
                  controller: controller,
                ),
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  background: _ArtistFlexibleHeader(
                    artistName: artistName,
                    imageUrl: imageUrl,
                  ),
                ),
              ),

              // Action Bar: Play Button, Shuffle, Follow, Listeners Count
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  child: Row(
                    children: [
                      // Verified Artist & Listeners Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              controller.artist.value?.categoryLabel == 'Playlist'
                                  ? 'Playlist'
                                  : 'Verified Artist',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              '${controller.tracks.length} Popular Songs Available',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Follow / Unfollow Button
                      Obx(() {
                        final isFollowing = controller.isFollowing.value;
                        return GestureDetector(
                          onTap: () => controller.toggleFollow(),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: isFollowing ? AppColors.surfaceHighlight : Colors.transparent,
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: isFollowing ? Colors.transparent : AppColors.textMuted,
                                width: 1.w,
                              ),
                            ),
                            child: Text(
                              isFollowing ? 'Following' : 'Follow',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }),
                      SizedBox(width: 12.w),

                      // Shuffle Button
                      IconButton(
                        icon: Icon(
                          CupertinoIcons.shuffle,
                          color: AppColors.textSecondary,
                          size: 22.sp,
                        ),
                        onPressed: () => controller.playAll(shuffle: true),
                      ),

                      // Big Spotify Green Play All Button
                      GestureDetector(
                        onTap: () => controller.playAll(shuffle: false),
                        child: Container(
                          width: 48.w,
                          height: 48.w,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 12.r,
                                offset: Offset(0, 4.h),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              CupertinoIcons.play_fill,
                              color: Colors.black,
                              size: 22.sp,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // "Popular Songs" / "Playlist Tracks" Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
                  child: Text(
                    controller.artist.value?.categoryLabel == 'Playlist'
                        ? 'Playlist Tracks'
                        : 'Popular Songs',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),

              // Tracks List or Loading Shimmer
              if (controller.isLoading.value)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              else if (controller.errorMessage.value.isNotEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          controller.errorMessage.value,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
                        ),
                        SizedBox(height: 12.h),
                        ElevatedButton(
                          onPressed: () {
                            if (artist != null) controller.loadArtistTracks(artist);
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (controller.tracks.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No tracks found for $artistName.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13.sp),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final track = controller.tracks[index];
                        return MusicTrackCard(
                          track: track,
                          rank: index + 1,
                          onTap: () {
                            if (Get.isRegistered<PlayerController>()) {
                              final playerCtrl = Get.find<PlayerController>();
                              playerCtrl.playTrack(track, queue: controller.tracks);
                            }
                            Get.toNamed(AppRoutes.player, arguments: track);
                          },
                          onMoreTap: () => TrackOptionsSheet.show(context, track),
                        );
                      },
                      childCount: controller.tracks.length,
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

/// Collapsed AppBar Title that smoothly fades in when scrolled up,
/// perfectly vertically centered with SpotifyBackButton via SliverAppBar.title
class _CollapsedAppBarTitle extends StatelessWidget {
  final String artistName;
  final ArtistDetailController controller;

  const _CollapsedAppBarTitle({
    required this.artistName,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final offset = controller.scrollOffset.value;
      // Fades in smoothly between scroll offset 130 and 185
      final opacity = ((offset - 130.0) / 55.0).clamp(0.0, 1.0);

      if (opacity == 0.0) return const SizedBox.shrink();

      return Opacity(
        opacity: opacity,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                artistName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            SizedBox(width: 6.w),
            Icon(
              CupertinoIcons.checkmark_seal_fill,
              color: AppColors.primary,
              size: 15.sp,
            ),
          ],
        ),
      );
    });
  }
}

/// Hero Header Background with Left-Aligned Large Artist Name when Expanded
class _ArtistFlexibleHeader extends StatelessWidget {
  final String artistName;
  final String? imageUrl;

  const _ArtistFlexibleHeader({
    required this.artistName,
    this.imageUrl,
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

        // Big name on the left fades out as user scrolls up
        final expandedOpacity = (1.0 - t * 2.2).clamp(0.0, 1.0);

        return Stack(
          fit: StackFit.expand,
          children: [
            // Hero Photo
            if (imageUrl != null && imageUrl!.isNotEmpty)
              Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.surfaceLight,
                  child: const Icon(CupertinoIcons.music_mic,
                      size: 64, color: AppColors.textMuted),
                ),
              )
            else
              Container(
                color: AppColors.surfaceLight,
                child: const Icon(CupertinoIcons.music_mic,
                    size: 64, color: AppColors.textMuted),
              ),

            // Gradient Shadows
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.transparent,
                    AppColors.background.withValues(alpha: 0.8),
                    AppColors.background,
                  ],
                  stops: const [0.0, 0.35, 0.8, 1.0],
                ),
              ),
            ),

            // Bold Artist Name at the Bottom-Left when expanded
            if (expandedOpacity > 0.0)
              Positioned(
                left: 16.w,
                right: 16.w,
                bottom: 16.h,
                child: Opacity(
                  opacity: expandedOpacity,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          artistName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26.sp,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.9),
                                blurRadius: 10.r,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Icon(
                        CupertinoIcons.checkmark_seal_fill,
                        color: AppColors.primary,
                        size: 20.sp,
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
