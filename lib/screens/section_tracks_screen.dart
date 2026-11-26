import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../controllers/music_controller.dart';
import '../controllers/player_controller.dart';
import '../controllers/section_tracks_controller.dart';
import '../routes/app_routes.dart';
import '../widgets/mini_player_bar.dart';
import '../widgets/music_track_card.dart';
import '../widgets/spotify_back_button.dart';
import '../widgets/track_options_sheet.dart';

/// Reusable multi-purpose screen to view full track lists for any home screen section,
/// shelf, category, or recommendation collection with a Spotify-style hero header.
class SectionTracksScreen extends GetView<SectionTracksController> {
  const SectionTracksScreen({super.key});

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
          final trackList = controller.filteredTracks;
          final title = controller.title.value;
          final subtitle = controller.subtitle.value;
          final isSearch = controller.isSearchActive.value;
          final imageUrl = controller.resolvedImageUrl;
          final sectionType = controller.sectionType.value;

          return CustomScrollView(
            controller: controller.scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Spotify-Style Hero SliverAppBar (Like Artist & Category screens)
              SliverAppBar(
                expandedHeight: 270.h,
                pinned: true,
                stretch: true,
                backgroundColor: AppColors.surface,
                leadingWidth: 52.w,
                titleSpacing: 8.w,
                centerTitle: false,
                leading: const SpotifyBackButton(),
                title: _CollapsedSectionTitle(
                  title: title,
                  controller: controller,
                ),
                actions: [
                  IconButton(
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: Icon(
                        isSearch
                            ? CupertinoIcons.xmark
                            : CupertinoIcons.search,
                        key: ValueKey<bool>(isSearch),
                        color: AppColors.textPrimary,
                        size: 21.sp,
                      ),
                    ),
                    onPressed: controller.toggleSearch,
                  ),
                  SizedBox(width: 8.w),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  background: _SectionFlexibleHeader(
                    title: title,
                    subtitle: subtitle,
                    imageUrl: imageUrl,
                    sectionType: sectionType,
                  ),
                ),
              ),

              // Action Bar: Subtitle, Track Count, Play & Shuffle controls
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 12.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Subtitle and Song count
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (subtitle.isNotEmpty) ...[
                              Text(
                                subtitle,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12.5.sp,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4.h),
                            ],
                            Text(
                              '${trackList.length} ${trackList.length == 1 ? 'song' : 'songs'}',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      // Shuffle Button
                      IconButton(
                        onPressed: trackList.isEmpty
                            ? null
                            : () => controller.playAll(shuffle: true),
                        icon: Icon(
                          CupertinoIcons.shuffle,
                          color: trackList.isEmpty
                              ? AppColors.textMuted.withValues(alpha: 0.3)
                              : AppColors.primary,
                          size: 22.sp,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      // Big Spotify Green Play Button
                      GestureDetector(
                        onTap: trackList.isEmpty ? null : () => controller.playAll(),
                        child: Container(
                          width: 48.w,
                          height: 48.w,
                          decoration: BoxDecoration(
                            color: trackList.isEmpty
                                ? AppColors.surfaceLight
                                : AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: trackList.isEmpty
                                ? null
                                : [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.45),
                                      blurRadius: 16.r,
                                      offset: Offset(0, 4.h),
                                    ),
                                  ],
                          ),
                          child: Center(
                            child: Icon(
                              CupertinoIcons.play_fill,
                              color: trackList.isEmpty
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

              // Track List or Empty View
              if (trackList.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.music_note_list,
                            size: 54.sp,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            controller.searchQuery.value.isNotEmpty
                                ? 'No matching songs found'
                                : 'No songs available in this section',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            controller.searchQuery.value.isNotEmpty
                                ? 'Try searching with a different song or artist name.'
                                : 'Songs for this section will update automatically.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.5.sp,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
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
                        final track = trackList[index];
                        final verification = musicCtrl?.audioVerifications[track.trackId];
                        final isVerifying = musicCtrl?.verifyingTrackIds.contains(track.trackId) ?? false;

                        return MusicTrackCard(
                          track: track,
                          rank: controller.showRank.value ? (index + 1) : null,
                          verification: verification,
                          isVerifying: isVerifying,
                          onVerifyPressed: () => musicCtrl?.verifyAudio(track),
                          onTap: () {
                            if (playerCtrl != null) {
                              playerCtrl.playTrack(track, queue: trackList);
                            }
                            Get.toNamed(AppRoutes.player, arguments: track);
                          },
                          onMoreTap: () => TrackOptionsSheet.show(context, track),
                        );
                      },
                      childCount: trackList.length,
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
/// or displays expanding search bar when isSearchActive is true.
class _CollapsedSectionTitle extends StatelessWidget {
  final String title;
  final SectionTracksController controller;

  const _CollapsedSectionTitle({
    required this.title,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isSearch = controller.isSearchActive.value;
      if (isSearch) {
        return Container(
          height: 38.h,
          margin: EdgeInsets.only(right: 4.w),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(width: 10.w),
              Icon(
                CupertinoIcons.search,
                color: AppColors.primary,
                size: 16.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: TextField(
                  controller: controller.searchTextController,
                  focusNode: controller.searchFocusNode,
                  onChanged: controller.onSearchChanged,
                  textAlignVertical: TextAlignVertical.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    isCollapsed: true,
                    hintText: 'Search in $title...',
                    hintStyle: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13.sp,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (controller.searchQuery.value.isNotEmpty)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: controller.clearSearch,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: Icon(
                      CupertinoIcons.clear_circled_solid,
                      color: AppColors.textMuted,
                      size: 16.sp,
                    ),
                  ),
                ),
            ],
          ),
        );
      }

      final offset = controller.scrollOffset.value;
      // Fades in smoothly between scroll offset 130 and 185
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

/// Hero Header Background with Left-Aligned Large Section Name & Badge when Expanded
class _SectionFlexibleHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String imageUrl;
  final String sectionType;

  const _SectionFlexibleHeader({
    required this.title,
    this.subtitle,
    required this.imageUrl,
    required this.sectionType,
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

        String badgeText = 'PLAYLIST';
        if (sectionType == 'trending') {
          badgeText = 'TOP CHARTS';
        } else if (sectionType == 'new_releases') {
          badgeText = 'NEW RELEASES';
        } else if (sectionType == 'suggested') {
          badgeText = 'MADE FOR YOU';
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            // Background Artwork
            if (imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.surfaceLight,
                  child: const Center(
                    child: Icon(
                      CupertinoIcons.music_note_list,
                      size: 54,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              )
            else
              Container(
                color: AppColors.surfaceLight,
                child: const Center(
                  child: Icon(
                    CupertinoIcons.music_note_list,
                    size: 54,
                    color: AppColors.textMuted,
                  ),
                ),
              ),

            // Deep Spotify Vibrant Gradient Overlay (Top dark -> subtle center -> deep bottom)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.transparent,
                    AppColors.background.withValues(alpha: 0.85),
                    AppColors.background,
                  ],
                  stops: const [0.0, 0.35, 0.80, 1.0],
                ),
              ),
            ),

            // Large Title and Badge positioned at bottom-left when expanded
            if (expandedOpacity > 0.0)
              Positioned(
                left: 16.w,
                bottom: 16.h,
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
                          color: AppColors.primary.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
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
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.9),
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
