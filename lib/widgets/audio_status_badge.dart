import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../models/track_model.dart';

class AudioStatusBadge extends StatelessWidget {
  final AudioStatusType statusType;
  final String statusText;
  final bool isVerified;
  final String? verificationDetails;

  const AudioStatusBadge({
    super.key,
    required this.statusType,
    required this.statusText,
    this.isVerified = false,
    this.verificationDetails,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    switch (statusType) {
      case AudioStatusType.fullTrack:
        bg = AppColors.statusSuccessBg.withValues(alpha: 0.4);
        fg = AppColors.statusSuccess;
        icon = isVerified ? Icons.verified : Icons.music_note;
        break;
      case AudioStatusType.previewOnly:
        bg = AppColors.statusWarning.withValues(alpha: 0.2);
        fg = AppColors.statusWarning;
        icon = Icons.timelapse;
        break;
      case AudioStatusType.unavailable:
        bg = AppColors.statusErrorBg.withValues(alpha: 0.3);
        fg = AppColors.statusError;
        icon = Icons.volume_off;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: fg.withValues(alpha: 0.3), width: 1.w),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.sp, color: fg),
          SizedBox(width: 4.w),
          Flexible(
            child: Text(
              isVerified ? 'Live Verified: Full MP3' : statusText,
              style: TextStyle(
                color: fg,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
