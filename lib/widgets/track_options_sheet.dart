import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../controllers/music_controller.dart';
import '../controllers/player_controller.dart';
import '../models/artist_category_model.dart';
import '../models/track_model.dart';
import '../routes/app_routes.dart';
import 'add_to_collection_sheet.dart';

class TrackOptionsSheet {
  static void show(
    BuildContext? context,
    TrackModel track, {
    String? currentPlaylistId,
    VoidCallback? onOpenCreatePlaylist,
  }) {
    final effectiveContext = context ?? Get.overlayContext ?? Get.context;
    if (effectiveContext == null) return;

    final playerCtrl = Get.isRegistered<PlayerController>()
        ? Get.find<PlayerController>()
        : null;
    final musicCtrl = Get.isRegistered<MusicController>()
        ? Get.find<MusicController>()
        : null;

    showModalBottomSheet(
      context: effectiveContext,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        final isLiked = playerCtrl?.isTrackLiked(track.trackId) ?? false;

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
                    // Track Header
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6.r),
                          child: SizedBox(
                            width: 52.w,
                            height: 52.w,
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
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.title,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                '${track.artistName} • ${track.albumName}',
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
                    SizedBox(height: 8.h),

                    // Option 1: Add to Collection / Playlist
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        CupertinoIcons.text_badge_plus,
                        color: AppColors.textPrimary,
                        size: 22.sp,
                      ),
                      title: Text(
                        'Add / Transfer to collection',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(bottomSheetContext);
                        AddToCollectionSheet.show(
                          effectiveContext,
                          track,
                          onOpenCreatePlaylist: onOpenCreatePlaylist,
                        );
                      },
                    ),

                    // Option 2: Like / Remove from Liked Songs
                    if (playerCtrl != null)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          isLiked
                              ? CupertinoIcons.heart_fill
                              : CupertinoIcons.heart,
                          color: isLiked ? AppColors.primary : AppColors.textPrimary,
                          size: 22.sp,
                        ),
                        title: Text(
                          isLiked
                              ? 'Remove from Liked Songs'
                              : 'Add to Liked Songs',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14.5.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(bottomSheetContext);
                          playerCtrl.toggleLike(track);
                        },
                      ),

                    // Option 3: Download / Remove from Downloads
                    if (playerCtrl != null)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          playerCtrl.isTrackDownloaded(track.trackId)
                              ? CupertinoIcons.arrow_down_circle_fill
                              : CupertinoIcons.arrow_down_circle,
                          color: playerCtrl.isTrackDownloaded(track.trackId)
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          size: 22.sp,
                        ),
                        title: Text(
                          playerCtrl.isTrackDownloaded(track.trackId)
                              ? 'Remove from Downloads'
                              : 'Download Song',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14.5.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(bottomSheetContext);
                          playerCtrl.toggleDownload(track);
                        },
                      ),

                    // Option 3: Remove from current custom playlist (if in playlist view)
                    if (currentPlaylistId != null && musicCtrl != null)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          CupertinoIcons.minus_circle,
                          color: Colors.redAccent,
                          size: 22.sp,
                        ),
                        title: Text(
                          'Remove from this playlist',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 14.5.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () async {
                          Navigator.pop(bottomSheetContext);
                          await musicCtrl.removeTrackFromPlaylist(
                            currentPlaylistId,
                            track.trackId,
                          );
                          Get.snackbar(
                            'Removed',
                            '"${track.title}" removed from collection',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: AppColors.surfaceLight,
                            colorText: AppColors.textPrimary,
                            duration: const Duration(seconds: 2),
                          );
                        },
                      ),

                    // Option 4: Go to Artist
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        CupertinoIcons.person_crop_circle,
                        color: AppColors.textPrimary,
                        size: 22.sp,
                      ),
                      title: Text(
                        'View artist (${track.artistName})',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(bottomSheetContext);
                        final artistModel = ArtistCategoryModel(
                          id: track.artistName.toLowerCase().replaceAll(' ', '_'),
                          name: track.artistName,
                          query: track.artistName,
                          categoryLabel: 'Artist',
                          imageUrl: track.artworkUrl,
                        );
                        Get.toNamed(AppRoutes.artist, arguments: artistModel);
                      },
                    ),
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
