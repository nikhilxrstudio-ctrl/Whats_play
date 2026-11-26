import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// Standard Spotify-styled circular back button with chevron_left icon.
/// Used consistently across all screens (Artist detail, Library playlists, Music Player).
class SpotifyBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;

  const SpotifyBackButton({
    super.key,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Container(
        width: 34.w,
        height: 34.w,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            CupertinoIcons.chevron_left,
            color: iconColor ?? Colors.white,
            size: 18.sp,
          ),
        ),
      ),
      onPressed: onPressed ?? () => Get.back(),
    );
  }
}
