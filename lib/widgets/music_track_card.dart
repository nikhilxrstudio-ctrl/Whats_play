import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../controllers/player_controller.dart';
import '../models/audio_verification_model.dart';
import '../models/track_model.dart';
import 'music_wave_equalizer.dart';
import 'track_options_sheet.dart';

class MusicTrackCard extends StatelessWidget {
  final TrackModel track;
  final AudioVerificationModel? verification;
  final bool isVerifying;
  final VoidCallback? onVerifyPressed;
  final VoidCallback? onTap;
  final VoidCallback? onMoreTap;
  final int? rank;

  const MusicTrackCard({
    super.key,
    required this.track,
    this.verification,
    this.isVerifying = false,
    this.onVerifyPressed,
    this.onTap,
    this.onMoreTap,
    this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final playerCtrl = Get.isRegistered<PlayerController>()
        ? Get.find<PlayerController>()
        : null;

    if (playerCtrl == null) {
      return _buildContent(context, isCurrentTrack: false, isPlaying: false);
    }

    return Obx(() {
      final currentTrackId = playerCtrl.currentTrack.value?.trackId;
      final isCurrentTrack = currentTrackId != null && currentTrackId == track.trackId;
      final isPlaying = isCurrentTrack && playerCtrl.isPlaying.value;

      return _buildContent(context, isCurrentTrack: isCurrentTrack, isPlaying: isPlaying);
    });
  }

  Widget _buildContent(
    BuildContext context, {
    required bool isCurrentTrack,
    required bool isPlaying,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          child: Row(
            children: [
              if (rank != null) ...[
                SizedBox(
                  width: 28.w,
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      color: isCurrentTrack || (rank != null && rank! <= 3)
                          ? AppColors.primary
                          : AppColors.textMuted,
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(width: 8.w),
              ],
                // 48x48 rounded album artwork with wave equalizer overlay when playing
                _buildArtwork(isCurrentTrack: isCurrentTrack, isPlaying: isPlaying),
                SizedBox(width: 12.w),
                // Track Details (Title + Artist & Album)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        track.title,
                        style: TextStyle(
                          color: isCurrentTrack
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontSize: 14.5.sp,
                          fontWeight: isCurrentTrack
                              ? FontWeight.w700
                              : FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    SizedBox(height: 3.h),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            track.artistName,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: Text(
                            '•',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            track.albumName,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              // Like heart button (real-time reactive)
              if (Get.isRegistered<PlayerController>())
                Obx(() {
                  final playerCtrl = Get.find<PlayerController>();
                  final isLiked = playerCtrl.isTrackLiked(track.trackId);
                  final isDownloaded = playerCtrl.isTrackDownloaded(track.trackId);
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isDownloaded)
                        Padding(
                          padding: EdgeInsets.only(right: 6.w),
                          child: Icon(
                            CupertinoIcons.arrow_down_circle_fill,
                            color: AppColors.primary,
                            size: 15.sp,
                          ),
                        ),
                      GestureDetector(
                        onTap: () => playerCtrl.toggleLike(track),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: Icon(
                            isLiked
                                ? CupertinoIcons.heart_fill
                                : CupertinoIcons.heart,
                            color: isLiked
                                ? AppColors.primary
                                : AppColors.textMuted.withValues(alpha: 0.5),
                            size: 16.sp,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              // Track Duration & Option Menu
              Text(
                track.formattedDuration,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(width: 6.w),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onMoreTap ?? () => TrackOptionsSheet.show(context, track),
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.textMuted,
                    size: 18.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArtwork({
    required bool isCurrentTrack,
    required bool isPlaying,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4.r),
      child: SizedBox(
        width: 48.w,
        height: 48.w,
        child: Stack(
          fit: StackFit.expand,
          children: [
            track.artworkUrl != null && track.artworkUrl!.isNotEmpty
                ? Image.network(
                    track.artworkUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, _) => _buildArtworkFallback(),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: AppColors.surfaceLight,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                      );
                    },
                  )
                : _buildArtworkFallback(),
            // When currently playing: Show translucent dark overlay + animated wave equalizer directly ON the artwork!
            if (isCurrentTrack)
              Container(
                color: Colors.black.withValues(alpha: 0.55),
                child: Center(
                  child: MusicWaveEqualizer(
                    isPlaying: isPlaying,
                    size: 18.h,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtworkFallback() {
    return Container(
      color: AppColors.surfaceLight,
      child: Icon(
        Icons.music_note_rounded,
        size: 24.sp,
        color: AppColors.primary,
      ),
    );
  }
}
