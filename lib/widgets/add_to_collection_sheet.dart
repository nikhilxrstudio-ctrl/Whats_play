import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../controllers/music_controller.dart';
import '../controllers/player_controller.dart';
import '../models/track_model.dart';
import 'playlist_icon_helper.dart';

class AddToCollectionSheet {
  static void show(
    BuildContext context,
    TrackModel track, {
    VoidCallback? onOpenCreatePlaylist,
  }) {
    if (!Get.isRegistered<MusicController>()) return;
    final controller = Get.find<MusicController>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            systemNavigationBarColor: Color(0xFF191919),
            systemNavigationBarIconBrightness: Brightness.light,
            systemNavigationBarDividerColor: Colors.transparent,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF191919),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
            child: SafeArea(
              top: false,
              bottom: true,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pull Handle
                    Container(
                      width: 38.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    // Track Info Header
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4.r),
                          child: SizedBox(
                            width: 46.w,
                            height: 46.w,
                            child: track.artworkUrl != null &&
                                    track.artworkUrl!.isNotEmpty
                                ? Image.network(
                                    track.artworkUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                      color: AppColors.surfaceLight,
                                      child: const Icon(
                                        Icons.music_note_rounded,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: AppColors.surfaceLight,
                                    child: const Icon(
                                      Icons.music_note_rounded,
                                      color: AppColors.primary,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.title,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14.5.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 3.h),
                              Text(
                                track.artistName,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12.sp,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),
                    const Divider(color: Colors.white12, height: 1),
                    SizedBox(height: 14.h),
                    // Section Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Add to collection',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (onOpenCreatePlaylist != null)
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(bottomSheetContext);
                              onOpenCreatePlaylist();
                            },
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons.plus,
                                  color: AppColors.primary,
                                  size: 16.sp,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  'New Playlist',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    // Liked Songs Section
                    if (Get.isRegistered<PlayerController>())
                      Obx(() {
                        final playerCtrl = Get.find<PlayerController>();
                        final isLiked = playerCtrl.isTrackLiked(track.trackId);
                        final count = playerCtrl.likedTracks.length;
                        return ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 4.w,
                            vertical: 2.h,
                          ),
                          splashColor: Colors.transparent,
                          leading: Container(
                            width: 44.w,
                            height: 44.w,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF450AF5), Color(0xFFC4EFD9)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Icon(
                              CupertinoIcons.heart_fill,
                              color: Colors.white,
                              size: 22.sp,
                            ),
                          ),
                          title: Text(
                            'Liked Songs',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Playlist • $count ${count == 1 ? 'song' : 'songs'}',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.sp,
                            ),
                          ),
                          trailing: Icon(
                            isLiked
                                ? CupertinoIcons.checkmark_circle_fill
                                : CupertinoIcons.plus_circle,
                            color: isLiked ? AppColors.primary : AppColors.textMuted,
                            size: 24.sp,
                          ),
                          onTap: () {
                            playerCtrl.toggleLike(track);
                          },
                        );
                      }),
                    SizedBox(height: 4.h),
                    // List of Custom Playlists
                    Obx(() {
                      final playlists = controller.customPlaylists;
                      if (playlists.isEmpty) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.h),
                          child: Column(
                            children: [
                              Icon(
                                CupertinoIcons.music_note_list,
                                size: 40.sp,
                                color: AppColors.textMuted,
                              ),
                              SizedBox(height: 10.h),
                              Text(
                                'No collections yet',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14.5.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Create a playlist first from Your Library (+ button)',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12.sp,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      return ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: 0.45.sh,
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: playlists.length,
                          separatorBuilder: (context, index) =>
                              SizedBox(height: 6.h),
                          itemBuilder: (context, index) {
                            final pl = playlists[index];
                            final gradient =
                                PlaylistIconHelper.getGradient(pl.iconKey);
                            final icon = PlaylistIconHelper.getIcon(pl.iconKey);

                            return FutureBuilder<bool>(
                              future: controller.isTrackInPlaylist(
                                pl.id,
                                track.trackId,
                              ),
                              builder: (context, snapshot) {
                                final isAlreadyIn = snapshot.data ?? false;

                                return ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 4.w,
                                    vertical: 2.h,
                                  ),
                                  leading: Container(
                                    width: 44.w,
                                    height: 44.w,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: gradient,
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                    child: Icon(
                                      icon,
                                      color: Colors.white,
                                      size: 22.sp,
                                    ),
                                  ),
                                  title: Text(
                                    pl.name,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${pl.songCount} ${pl.songCount == 1 ? 'song' : 'songs'}',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                  trailing: Icon(
                                    isAlreadyIn
                                        ? CupertinoIcons.checkmark_circle_fill
                                        : CupertinoIcons.plus_circle,
                                    color: isAlreadyIn
                                        ? AppColors.primary
                                        : AppColors.textMuted,
                                    size: 22.sp,
                                  ),
                                  onTap: () async {
                                    final nav = Navigator.of(bottomSheetContext);
                                    if (isAlreadyIn) {
                                      await controller.removeTrackFromPlaylist(
                                        pl.id,
                                        track.trackId,
                                      );
                                      nav.pop();
                                      Get.snackbar(
                                        'Removed from Collection',
                                        '"${track.title}" removed from "${pl.name}"',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: AppColors.surfaceLight,
                                        colorText: AppColors.textPrimary,
                                        duration: const Duration(seconds: 2),
                                      );
                                    } else {
                                      await controller.addTrackToPlaylist(
                                        pl.id,
                                        track,
                                      );
                                      nav.pop();
                                      Get.snackbar(
                                        'Added to Collection',
                                        '"${track.title}" added to "${pl.name}"',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: AppColors.surfaceLight,
                                        colorText: AppColors.textPrimary,
                                        duration: const Duration(seconds: 2),
                                      );
                                    }
                                  },
                                );
                              },
                            );
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
