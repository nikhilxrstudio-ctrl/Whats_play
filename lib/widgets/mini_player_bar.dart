import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../controllers/player_controller.dart';
import '../routes/app_routes.dart';
import '../utils/artwork_color_extractor.dart';
import 'music_wave_equalizer.dart';

class MiniPlayerBar extends StatefulWidget {
  const MiniPlayerBar({super.key});

  @override
  State<MiniPlayerBar> createState() => _MiniPlayerBarState();
}

class _MiniPlayerBarState extends State<MiniPlayerBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Animation<double>? _slideAnimation;
  double _dragOffset = 0.0;
  String? _lastTrackId;
  String? _lastArtworkUrl;
  Color _artworkColor = const Color(0xFF282828);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animController.addListener(() {
      if (_slideAnimation != null) {
        setState(() {
          _dragOffset = _slideAnimation!.value;
        });
      }
    });
  }

  void _updateArtworkColor(String? artworkUrl) {
    if (artworkUrl == null || artworkUrl.isEmpty) {
      if (mounted) setState(() => _artworkColor = const Color(0xFF282828));
      return;
    }
    final cached = ArtworkColorExtractor.getCachedColor(artworkUrl);
    if (cached != null) {
      _artworkColor = cached;
    }
    ArtworkColorExtractor.extractDominantColor(artworkUrl).then((color) {
      if (mounted && _artworkColor != color) {
        setState(() => _artworkColor = color);
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _animateTo(double target, {VoidCallback? onComplete}) {
    _animController.stop();
    _slideAnimation = Tween<double>(begin: _dragOffset, end: target).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward(from: 0.0).then((_) {
      onComplete?.call();
    });
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    _animController.stop();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.primaryDelta ?? 0.0;
      _dragOffset = _dragOffset.clamp(-120.0, 120.0);
    });
  }

  void _onHorizontalDragEnd(
      DragEndDetails details, PlayerController controller) {
    final velocity = details.primaryVelocity ?? 0.0;
    if (_dragOffset < -35 || velocity < -120) {
      // Swiped right-to-left -> Next track
      controller.playNext();
      _animateTo(-140, onComplete: () {
        if (mounted) {
          _dragOffset = 140;
          _animateTo(0.0);
        }
      });
    } else if (_dragOffset > 35 || velocity > 120) {
      // Swiped left-to-right -> Previous track
      controller.playPrevious();
      _animateTo(140, onComplete: () {
        if (mounted) {
          _dragOffset = -140;
          _animateTo(0.0);
        }
      });
    } else {
      // Small drag -> Snap back to center
      _animateTo(0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PlayerController>();

    return Obx(() {
      final track = controller.currentTrack.value;
      if (track == null) return const SizedBox.shrink();

      if (_lastTrackId != track.trackId) {
        _lastTrackId = track.trackId;
      }

      if (_lastArtworkUrl != track.artworkUrl) {
        _lastArtworkUrl = track.artworkUrl;
        _updateArtworkColor(track.artworkUrl);
      }

      final posMs = controller.position.value.inMilliseconds.toDouble();
      final durMs = controller.duration.value.inMilliseconds.toDouble();
      final progress = (durMs > 0 ? (posMs / durMs) : 0.0).clamp(0.0, 1.0);

      final contentOpacity =
          (1.0 - (_dragOffset.abs() / 180.0)).clamp(0.4, 1.0);

      // Smooth, fully opaque color gradient from artwork color into deep dark Spotify surface
      // Eliminates muddy transparency artifacts and banding
      const baseDark = Color(0xFF1E1E1E);
      final c0 = Color.lerp(baseDark, _artworkColor, 0.72)!;
      final c1 = Color.lerp(baseDark, _artworkColor, 0.44)!;
      final c2 = Color.lerp(baseDark, _artworkColor, 0.22)!;
      final c3 = Color.lerp(baseDark, _artworkColor, 0.08)!;
      final c4 = baseDark;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: baseDark,
          // Internal color gradient: rich artwork color on the left, smoothly diffusing into dark on the right
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [c0, c1, c2, c3, c4],
            stops: const [0.0, 0.25, 0.50, 0.78, 1.0],
          ),
          boxShadow: [
            // Upward drop shadow over scrolling content
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 8.r,
              offset: Offset(0, -2.h),
            ),
          ],
        ),
        child: ClipRect(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Get.toNamed(AppRoutes.player),
            onHorizontalDragStart: _onHorizontalDragStart,
            onHorizontalDragUpdate: _onHorizontalDragUpdate,
            onHorizontalDragEnd: (details) =>
                _onHorizontalDragEnd(details, controller),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                  child: Row(
                    children: [
                      // Interactive Sliding Song Info (Artwork + Title/Artist)
                      Expanded(
                        child: ClipRect(
                          child: Transform.translate(
                            offset: Offset(_dragOffset, 0),
                            child: Opacity(
                              opacity: contentOpacity,
                              child: Row(
                                children: [
                                  // Artwork Thumbnail
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4.r),
                                    child: SizedBox(
                                      width: 40.w,
                                      height: 40.w,
                                      child: track.artworkUrl != null &&
                                              track.artworkUrl!.isNotEmpty
                                          ? Image.network(
                                              track.artworkUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, _) =>
                                                      Container(
                                                color: AppColors.surfaceLight,
                                                child: Icon(
                                                  Icons.music_note_rounded,
                                                  color: AppColors.primary,
                                                  size: 20.sp,
                                                ),
                                              ),
                                            )
                                          : Container(
                                              color: AppColors.surfaceLight,
                                              child: Icon(
                                                Icons.music_note_rounded,
                                                color: AppColors.primary,
                                                size: 20.sp,
                                              ),
                                            ),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  // Track Title and Artist
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                track.title,
                                                style: TextStyle(
                                                  color: AppColors.textPrimary,
                                                  fontSize: 13.sp,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (controller.isPlaying.value) ...[
                                              SizedBox(width: 6.w),
                                              MusicWaveEqualizer(
                                                isPlaying: true,
                                                size: 11.h,
                                                color: AppColors.primary,
                                              ),
                                            ],
                                          ],
                                        ),
                                        SizedBox(height: 2.h),
                                        Text(
                                          track.artistName,
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 11.sp,
                                            fontWeight: FontWeight.w400,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Heart Icon (Toggle Like)
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          controller.isTrackLiked(track.trackId)
                              ? CupertinoIcons.heart_fill
                              : CupertinoIcons.heart,
                          size: 19.sp,
                          color: controller.isTrackLiked(track.trackId)
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        onPressed: () => controller.toggleLike(track),
                      ),
                      SizedBox(width: 8.w),
                      // Previous Track Icon
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          Icons.skip_previous_rounded,
                          size: 23.sp,
                          color: Colors.white,
                        ),
                        onPressed: () => controller.playPrevious(),
                      ),
                      SizedBox(width: 1.w),
                      // Play / Pause Button
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                        icon: controller.isBuffering.value
                            ? SizedBox(
                                width: 20.w,
                                height: 20.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Icon(
                                controller.isPlaying.value
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 28.sp,
                              ),
                        onPressed: () => controller.togglePlayPause(),
                      ),
                      SizedBox(width: 1.w),
                      // Next Track Icon
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          Icons.skip_next_rounded,
                          size: 23.sp,
                          color: Colors.white,
                        ),
                        onPressed: () => controller.playNext(),
                      ),
                    ],
                  ),
                ),
                // Spotify Slim 2px Progress Line
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 2.h,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  backgroundColor: const Color(0xFF383838),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
