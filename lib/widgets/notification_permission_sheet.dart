import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../services/notification_service.dart';

class NotificationPermissionSheet extends StatefulWidget {
  final bool isFromSettings;

  const NotificationPermissionSheet({
    super.key,
    this.isFromSettings = false,
  });

  static Future<void> show(BuildContext context, {bool isFromSettings = false}) async {
    final notifService = Get.isRegistered<NotificationService>()
        ? NotificationService.to
        : null;

    if (notifService != null) {
      final allowed = await notifService.checkPermissionStatus();
      if (allowed && !isFromSettings) {
        return;
      }
    }

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => NotificationPermissionSheet(isFromSettings: isFromSettings),
    );
  }

  @override
  State<NotificationPermissionSheet> createState() => _NotificationPermissionSheetState();
}

class _NotificationPermissionSheetState extends State<NotificationPermissionSheet> {
  bool _isRequesting = false;
  bool _isPermanentlyDenied = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    if (Get.isRegistered<NotificationService>()) {
      final isPerm = await NotificationService.to.checkPermanentlyDenied();
      if (mounted) {
        setState(() {
          _isPermanentlyDenied = isPerm;
        });
      }
    }
  }

  Future<void> _handlePrimaryAction() async {
    if (_isRequesting) return;
    HapticFeedback.mediumImpact();

    final notifService = Get.isRegistered<NotificationService>()
        ? NotificationService.to
        : null;

    if (notifService == null) {
      Navigator.of(context).pop();
      return;
    }

    if (_isPermanentlyDenied) {
      // Direct user to device system notification settings
      await notifService.openNotificationSettings();
      if (mounted) Navigator.of(context).pop();
      return;
    }

    setState(() => _isRequesting = true);
    final granted = await notifService.requestPermission();
    setState(() => _isRequesting = false);

    if (granted) {
      if (mounted) {
        Navigator.of(context).pop();
        Get.snackbar(
          'Notifications Enabled! 🔔',
          'You will receive alerts for new releases, artist drops, and Blends.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFF1E1E1E),
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle_rounded, color: AppColors.primary),
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(12),
          borderRadius: 14,
        );
      }
    } else {
      // User denied the permission request
      final isNowPerm = await notifService.checkPermanentlyDenied();
      if (mounted) {
        setState(() {
          _isPermanentlyDenied = isNowPerm;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: Color(0xFF181818),
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF181818),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 30,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          bottom: true,
          child: Padding(
            padding: EdgeInsets.fromLTRB(24.w, 14.h, 24.w, 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Pull Bar
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.5.h,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(3.r),
                    ),
                  ),
                ),
                SizedBox(height: 22.h),

                // Glowing Bell Header Icon
                Container(
                  width: 72.w,
                  height: 72.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1DB954), Color(0xFF00BFA5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      _isPermanentlyDenied
                          ? Icons.notifications_off_rounded
                          : Icons.notifications_active_rounded,
                      size: 36.sp,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: 18.h),

                // Title
                Text(
                  _isPermanentlyDenied
                      ? 'Notifications are Disabled'
                      : 'Stay in the Rhythm! 🔔',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 8.h),

                // Subtitle
                Text(
                  _isPermanentlyDenied
                      ? 'Notifications are turned off in Android settings. Open settings to turn on alerts for new music drops and friend Blend invites.'
                      : 'Turn on notifications to get instant alerts when your favorite artists release songs, friends invite you to Blends, and fresh hits arrive.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13.5.sp,
                    height: 1.45,
                  ),
                ),
                SizedBox(height: 20.h),

                // Feature Highlights Box
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildBenefitRow('🎵', 'New Releases & Drops', 'Real-time alerts for your favorite artists'),
                      SizedBox(height: 10.h),
                      _buildBenefitRow('👥', 'Shared Music Blends', 'Instant invites when friends want to listen together'),
                      SizedBox(height: 10.h),
                      _buildBenefitRow('🛡️', 'Zero Spam Guarantee', 'Only authentic music updates and notifications'),
                    ],
                  ),
                ),
                SizedBox(height: 22.h),

                // Primary Action Button (Enable or Open Settings)
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: _isRequesting ? null : _handlePrimaryAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.r),
                      ),
                      elevation: 0,
                    ),
                    child: _isRequesting
                        ? SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.black,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isPermanentlyDenied
                                    ? Icons.settings_rounded
                                    : Icons.notifications_active_rounded,
                                size: 18.sp,
                                color: Colors.black,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                _isPermanentlyDenied
                                    ? 'Open App Settings'
                                    : 'Turn on Notifications',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                SizedBox(height: 10.h),

                // Maybe Later / Dismiss Button
                SizedBox(
                  width: double.infinity,
                  height: 44.h,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22.r),
                      ),
                    ),
                    child: Text(
                      'Maybe Later',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow(String emoji, String title, String subtitle) {
    return Row(
      children: [
        Text(emoji, style: TextStyle(fontSize: 16.sp)),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
