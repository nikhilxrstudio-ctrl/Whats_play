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
/// shelf, category, or recommendation collection.
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

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Top Pinned App Bar with Spotify Back Button and Right-to-Left Expanding Search
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.surface,
                elevation: 0,
                leadingWidth: 54.w,
                leading: const SpotifyBackButton(),
                titleSpacing: 0,
                title: LayoutBuilder(
                  builder: (context, constraints) {
                    return SizedBox(
                      height: 38.h,
                      child: Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          // Section Title (smoothly fades out when search expands)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: isSearch ? 0.0 : 1.0,
                              child: Text(
                                title,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),

                          // Expanding Search TextField inside AppBar (smoothly expands right to left)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                            width: isSearch ? constraints.maxWidth : 0.0,
                            height: 38.h,
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: isSearch ? AppColors.surfaceLight : Colors.transparent,
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: isSearch
                                ? Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(width: 12.w),
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
                                              fontWeight: FontWeight.w400,
                                            ),
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.zero,
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
                                      SizedBox(width: 4.w),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                centerTitle: false,
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
              ),

              // Section Header: Subtitle, Track Count, Play & Shuffle controls
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
