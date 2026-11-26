import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../controllers/music_controller.dart';
import '../controllers/player_controller.dart';
import '../models/track_model.dart';
import '../utils/artwork_color_extractor.dart';
import '../widgets/add_to_collection_sheet.dart';
import '../widgets/spotify_back_button.dart';

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({super.key});

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  PlayerController get controller => Get.find<PlayerController>();
  Color _artworkColor = const Color(0xFF282828);
  String? _lastArtworkUrl;

  late PageController _artworkPageController;
  int _currentPage = 0;
  bool _isSwipingFromPage = false;
  Worker? _trackWorker;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<PlayerController>()) {
      final playerCtrl = Get.find<PlayerController>();
      if (Get.arguments is TrackModel) {
        final track = Get.arguments as TrackModel;
        if (playerCtrl.currentTrack.value?.trackId != track.trackId) {
          playerCtrl.playTrack(track);
        }
      }

      if (playerCtrl.playlist.isEmpty) {
        if (Get.isRegistered<MusicController>()) {
          final musicCtrl = Get.find<MusicController>();
          if (musicCtrl.suggestedTracks.isNotEmpty) {
            playerCtrl.playlist.assignAll(musicCtrl.suggestedTracks);
            final idx = playerCtrl.playlist.indexWhere(
              (t) => t.trackId == playerCtrl.currentTrack.value?.trackId,
            );
            playerCtrl.currentIndex.value = idx >= 0 ? idx : 0;
          }
        }
        if (playerCtrl.playlist.isEmpty && playerCtrl.currentTrack.value != null) {
          playerCtrl.playlist.assignAll([playerCtrl.currentTrack.value!]);
          playerCtrl.currentIndex.value = 0;
        }
      }

      final initialIdx = playerCtrl.currentIndex.value.clamp(
        0,
        playerCtrl.playlist.isNotEmpty ? playerCtrl.playlist.length - 1 : 0,
      );
      final loopOffset = playerCtrl.playlist.length > 1
          ? 1000 * playerCtrl.playlist.length
          : 0;
      _currentPage = loopOffset + initialIdx;
      _artworkPageController = PageController(initialPage: _currentPage);

      _trackWorker = ever(playerCtrl.currentTrack, (track) {
        if (track != null && !_isSwipingFromPage && mounted) {
          _syncPageToCurrentTrack();
        }
      });

      _updateColor(playerCtrl.currentTrack.value?.artworkUrl);
    } else {
      _artworkPageController = PageController();
    }
  }

  void _syncPageToCurrentTrack() {
    if (_isSwipingFromPage ||
        !_artworkPageController.hasClients ||
        controller.playlist.isEmpty) {
      return;
    }

    final targetIndex = controller.currentIndex.value;
    final currentPage = _artworkPageController.page?.round() ?? _currentPage;
    final currentActual = currentPage % controller.playlist.length;

    if (currentActual == targetIndex) return;

    int diff = targetIndex - currentActual;
    final len = controller.playlist.length;
    if (diff > len / 2) diff -= len;
    if (diff < -len / 2) diff += len;

    final targetPage = currentPage + diff;
    _currentPage = targetPage;
    _artworkPageController.animateToPage(
      targetPage,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _onArtworkPageChanged(int pageIndex) {
    _currentPage = pageIndex;
    if (controller.playlist.isEmpty) return;

    final actualIndex = pageIndex % controller.playlist.length;
    if (actualIndex != controller.currentIndex.value) {
      _isSwipingFromPage = true;
      final track = controller.playlist[actualIndex];
      controller.currentIndex.value = actualIndex;
      controller.playTrack(track);
      _updateColor(track.artworkUrl);

      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) _isSwipingFromPage = false;
      });
    }
  }

  void _handleNext() {
    controller.playNext();
    _syncPageToCurrentTrack();
  }

  void _handlePrevious() {
    controller.playPrevious();
    _syncPageToCurrentTrack();
  }

  @override
  void dispose() {
    _trackWorker?.dispose();
    _artworkPageController.dispose();
    super.dispose();
  }

  void _updateColor(String? artworkUrl) {
    if (artworkUrl == null || artworkUrl.isEmpty) {
      if (mounted) setState(() => _artworkColor = const Color(0xFF282828));
      return;
    }
    final cached = ArtworkColorExtractor.getCachedColor(artworkUrl);
    if (cached != null && _artworkColor != cached) {
      if (mounted) setState(() => _artworkColor = cached);
    }
    ArtworkColorExtractor.extractDominantColor(artworkUrl).then((color) {
      if (mounted && _artworkColor != color) {
        setState(() => _artworkColor = color);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PlayerController>();

    const baseDark = Color(0xFF101010);
    final bgTop = Color.lerp(baseDark, _artworkColor, 0.68)!;
    final bgMid = Color.lerp(baseDark, _artworkColor, 0.28)!;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          // Full-screen Spotify-style ambient gradient derived from song artwork
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgTop, bgMid, baseDark, const Color(0xFF080808)],
            stops: const [0.0, 0.38, 0.72, 1.0],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: const SpotifyBackButton(),
            centerTitle: true,
            title: Column(
              children: [
                Text(
                  'PLAYING FROM CATALOGUE',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 2.h),
                Obx(() => Text(
                      controller.currentTrack.value?.albumName ?? 'Now Playing',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 22.sp,
                  color: AppColors.textPrimary,
                ),
                onPressed: () {
                  final track = controller.currentTrack.value;
                  if (track != null) {
                    AddToCollectionSheet.show(context, track);
                  }
                },
              ),
            ],
          ),
          body: Obx(() {
            final track = controller.currentTrack.value;
            if (track == null) {
              return const Center(
                child: Text(
                  'No track selected',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              );
            }

            if (_lastArtworkUrl != track.artworkUrl) {
              _lastArtworkUrl = track.artworkUrl;
              _updateColor(track.artworkUrl);
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  children: [
                    const Spacer(flex: 1),
                    // Spotify Large Square Artwork with ambient shadow & interactive swipe carousel
                    _buildArtworkCarousel(controller),
                    const Spacer(flex: 2),
                    // Track Info Header (Title, Artist, Like Heart)
                    _buildTrackInfo(context, track),
                    SizedBox(height: 10.h),
                    // Subtle Media Notification Active Badge
                    _buildMediaNotificationBadge(),
                    SizedBox(height: 14.h),
                    // Progress Slider & Timestamps
                    _buildProgressSlider(context),
                    SizedBox(height: 12.h),
                    // Playback Controls Row (Spotify Shuffle, Prev, White Play/Pause, Next, Repeat)
                    _buildPlaybackControls(),
                    SizedBox(height: 20.h),
                    // Spotify Bottom Controls (Device Connect & Queue)
                    _buildBottomIcons(),
                    const Spacer(flex: 1),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildArtworkCarousel(PlayerController controller) {
    return Obx(() {
      final playlist = controller.playlist;
      final int count = playlist.length > 1 ? playlist.length * 2000 : 1;

      return SizedBox(
        height: 310.w,
        child: PageView.builder(
          controller: _artworkPageController,
          itemCount: count,
          physics: const BouncingScrollPhysics(),
          clipBehavior: Clip.none,
          onPageChanged: _onArtworkPageChanged,
          itemBuilder: (context, index) {
            final track = playlist.isNotEmpty
                ? playlist[index % playlist.length]
                : controller.currentTrack.value;
            if (track == null) return const SizedBox.shrink();
            return Center(
              child: _buildArtwork(track),
            );
          },
        ),
      );
    });
  }

  Widget _buildArtwork(TrackModel track) {
    final cachedColor = ArtworkColorExtractor.getCachedColor(track.artworkUrl);
    final glowColor = cachedColor ?? _artworkColor;

    return Container(
      width: 290.w,
      height: 290.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          // Soft ambient color glow matching the song artwork
          BoxShadow(
            color: glowColor.withValues(alpha: 0.38),
            blurRadius: 36.r,
            offset: Offset(0, 14.h),
            spreadRadius: 2.r,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 24.r,
            offset: Offset(0, 10.h),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: track.artworkUrl != null && track.artworkUrl!.isNotEmpty
            ? Image.network(
                track.artworkUrl!,
                key: ValueKey(track.artworkUrl ?? track.trackId),
                fit: BoxFit.cover,
                errorBuilder: (context, error, _) => _buildArtworkFallback(),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: AppColors.surfaceLight,
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  );
                },
              )
            : _buildArtworkFallback(),
      ),
    );
  }

  Widget _buildArtworkFallback() {
    return Container(
      color: AppColors.surfaceLight,
      child: Icon(
        Icons.music_note_rounded,
        size: 80.sp,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildTrackInfo(BuildContext context, TrackModel track) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                track.title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4.h),
              Text(
                track.artistName,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            controller.toggleLike(track);
            // Open the collection/wishlist transfer sheet when clicking like
            AddToCollectionSheet.show(context, track);
          },
          onLongPress: () {
            HapticFeedback.mediumImpact();
            AddToCollectionSheet.show(context, track);
          },
          child: Padding(
            padding: EdgeInsets.all(8.w),
            child: Icon(
              controller.isTrackLiked(track.trackId)
                  ? CupertinoIcons.heart_fill
                  : CupertinoIcons.heart,
              size: 26.sp,
              color: controller.isTrackLiked(track.trackId)
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
          ),
        ),
        SizedBox(width: 4.w),
        // Download option
        Obx(() {
          final isDownloaded = controller.isTrackDownloaded(track.trackId);
          final isDownloading = controller.isDownloading(track.trackId);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.lightImpact();
              controller.toggleDownload(track);
            },
            child: Padding(
              padding: EdgeInsets.all(8.w),
              child: isDownloading
                  ? SizedBox(
                      width: 24.w,
                      height: 24.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2.w,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    )
                  : Icon(
                      isDownloaded
                          ? CupertinoIcons.arrow_down_circle_fill
                          : CupertinoIcons.arrow_down_circle,
                      size: 26.sp,
                      color: isDownloaded
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMediaNotificationBadge() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.graphic_eq_rounded,
              size: 13.sp,
              color: AppColors.primary,
            ),
            SizedBox(width: 6.w),
            Text(
              'Media Notification Active',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSlider(BuildContext context) {
    final pos = controller.position.value;
    final dur = controller.duration.value;
    final maxSec = dur.inMilliseconds.toDouble();
    final currentSec =
        pos.inMilliseconds.toDouble().clamp(0.0, maxSec > 0 ? maxSec : 1.0);

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3.h,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5.r),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 12.r),
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: const Color(0xFF383838),
            thumbColor: Colors.white,
            overlayColor: AppColors.primary.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: currentSec,
            min: 0.0,
            max: maxSec > 0 ? maxSec : 1.0,
            onChanged: (val) {
              controller.seek(Duration(milliseconds: val.toInt()));
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                controller.formatDuration(pos),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5.sp,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                controller.formatDuration(dur),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5.sp,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybackControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Shuffle
        IconButton(
          icon: Icon(
            Icons.shuffle_rounded,
            size: 22.sp,
            color: controller.isShuffle.value
                ? AppColors.primary
                : AppColors.textMuted,
          ),
          onPressed: () => controller.toggleShuffle(),
        ),
        // Previous
        IconButton(
          icon: Icon(
            Icons.skip_previous_rounded,
            size: 38.sp,
            color: AppColors.textPrimary,
          ),
          onPressed: _handlePrevious,
        ),
        // Big White Play/Pause Button (Spotify Signature High Contrast)
        GestureDetector(
          onTap: () => controller.togglePlayPause(),
          child: Container(
            width: 64.w,
            height: 64.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Center(
              child: controller.isBuffering.value
                  ? SizedBox(
                      width: 26.w,
                      height: 26.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : Icon(
                      controller.isPlaying.value
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 36.sp,
                      color: Colors.black,
                    ),
            ),
          ),
        ),
        // Next
        IconButton(
          icon: Icon(
            Icons.skip_next_rounded,
            size: 38.sp,
            color: AppColors.textPrimary,
          ),
          onPressed: _handleNext,
        ),
        // Repeat
        IconButton(
          icon: Icon(
            Icons.repeat_rounded,
            size: 22.sp,
            color: controller.isRepeat.value
                ? AppColors.primary
                : AppColors.textMuted,
          ),
          onPressed: () => controller.toggleRepeat(),
        ),
      ],
    );
  }

  Widget _buildBottomIcons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(
            Icons.devices_rounded,
            size: 20.sp,
            color: AppColors.textSecondary,
          ),
          tooltip: 'Connect to a device',
          onPressed: () {},
        ),
        Row(
          children: [
            TextButton.icon(
              onPressed: () => controller.seekBackward10(),
              icon: Icon(
                Icons.replay_10_rounded,
                size: 16.sp,
                color: AppColors.textSecondary,
              ),
              label: Text(
                '-10s',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.sp,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => controller.seekForward10(),
              icon: Icon(
                Icons.forward_10_rounded,
                size: 16.sp,
                color: AppColors.textSecondary,
              ),
              label: Text(
                '+10s',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.sp,
                ),
              ),
            ),
          ],
        ),
        IconButton(
          icon: Icon(
            Icons.queue_music_rounded,
            size: 22.sp,
            color: AppColors.textSecondary,
          ),
          tooltip: 'Queue',
          onPressed: () {},
        ),
      ],
    );
  }
}
