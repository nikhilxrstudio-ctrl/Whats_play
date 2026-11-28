import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../controllers/music_controller.dart';
import '../controllers/player_controller.dart';
import '../services/auth_service.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.isRegistered<AuthService>()
        ? Get.find<AuthService>()
        : Get.put(AuthService());
    final playerCtrl = Get.isRegistered<PlayerController>()
        ? Get.find<PlayerController>()
        : null;
    final musicCtrl = Get.isRegistered<MusicController>()
        ? Get.find<MusicController>()
        : null;

    return Obx(() {
      final isLoggedIn = auth.isLoggedIn.value;

      return ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
        children: [
          // Hero User Profile Card
          if (isLoggedIn)
            _buildLoggedInHeader(context, auth)
          else
            _buildLoggedOutHeader(context, auth),

          SizedBox(height: 24.h),

          // Vibrant 4-Grid Activity Section
          _buildActivitySection(context, playerCtrl, musicCtrl),

          SizedBox(height: 24.h),

          // Audio & Streaming Preferences Section
          _buildPreferencesSection(context),

          SizedBox(height: 24.h),

          // Sign Out Button (if logged in)
          if (isLoggedIn) ...[
            _buildSignOutButton(context, auth),
            SizedBox(height: 24.h),
          ],

          // Footer
          _buildAppInfoFooter(),
          SizedBox(height: 60.h),
        ],
      );
    });
  }

  Widget _buildLoggedInHeader(BuildContext context, AuthService auth) {
    final name = auth.userName.value.isNotEmpty ? auth.userName.value : 'Music Lover';
    final email = auth.userEmail.value.isNotEmpty ? auth.userEmail.value : 'Google Account Connected';
    final photo = auth.userPhotoUrl.value;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1DB954).withValues(alpha: 0.32),
            const Color(0xFF262626),
            const Color(0xFF181818),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: const Color(0xFF1DB954).withValues(alpha: 0.45),
          width: 1.2.w,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1DB954).withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Glowing Avatar with Double Ring
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF1DB954), Color(0xFF00E5FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1DB954).withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 34.r,
              backgroundColor: const Color(0xFF242424),
              backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
              onBackgroundImageError: photo.isNotEmpty
                  ? (exception, stackTrace) {
                      debugPrint('[ProfileView] Avatar load error: $exception');
                    }
                  : null,
              child: photo.isEmpty
                  ? Icon(
                      CupertinoIcons.person_fill,
                      size: 34.sp,
                      color: AppColors.primary,
                    )
                  : null,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18.5.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Icon(
                      Icons.verified_rounded,
                      color: AppColors.primary,
                      size: 18.sp,
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  email,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 3.5.h),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6.w,
                            height: 6.w,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 5.w),
                          Text(
                            'Google Connected',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedOutHeader(BuildContext context, AuthService auth) {
    return Container(
      padding: EdgeInsets.all(22.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1DB954).withValues(alpha: 0.24),
            const Color(0xFF282828),
            const Color(0xFF191919),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: const Color(0xFF1DB954).withValues(alpha: 0.4),
          width: 1.2.w,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1DB954).withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1DB954), Color(0xFF00E5FF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1DB954).withValues(alpha: 0.4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/icons/app_logo.png',
                    width: 48.w,
                    height: 48.w,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 48.w,
                      height: 48.w,
                      color: const Color(0xFF242424),
                      child: const Icon(Icons.music_note_rounded, color: AppColors.primary),
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
                      'Welcome to WhatsPlay',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      'Sign in to sync your music & favorites',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),

          // Feature Benefit Pills
          Wrap(
            spacing: 8.w,
            runSpacing: 6.h,
            children: [
              _buildFeaturePill(Icons.cloud_sync_rounded, 'Cloud Sync'),
              _buildFeaturePill(CupertinoIcons.heart_fill, 'Liked Songs Backup'),
              _buildFeaturePill(CupertinoIcons.device_phone_portrait, 'Cross-Device'),
            ],
          ),

          SizedBox(height: 20.h),

          // Google Sign-In Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(28.r),
              onTap: auth.isLoading.value
                  ? null
                  : () async {
                      HapticFeedback.mediumImpact();
                      final success = await auth.signInWithGoogle(source: 'your_library');
                      if (success) {
                        Get.snackbar(
                          'Welcome!',
                          'Signed in successfully as ${auth.userName.value}',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: const Color(0xFF1E1E1E),
                          colorText: Colors.white,
                          duration: const Duration(seconds: 3),
                        );
                      }
                    },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 13.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: auth.isLoading.value
                      ? SizedBox(
                          width: 22.w,
                          height: 22.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.g_mobiledata_rounded,
                              size: 32.sp,
                              color: Colors.black,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'Continue with Google',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14.5.sp,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePill(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: AppColors.primary),
          SizedBox(width: 5.w),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySection(
    BuildContext context,
    PlayerController? playerCtrl,
    MusicController? musicCtrl,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Activity',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _buildActivityCard(
                icon: CupertinoIcons.heart_fill,
                accentColor: const Color(0xFFE040FB),
                gradientColors: [
                  const Color(0xFF8E24AA).withValues(alpha: 0.28),
                  const Color(0xFF222222),
                ],
                title: 'Liked Songs',
                value: '${playerCtrl?.likedTracks.length ?? 0}',
                subtitle: 'Tracks saved',
                onTap: () {
                  Get.back();
                  musicCtrl?.changeTab(2);
                  musicCtrl?.openLikedSongs();
                },
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildActivityCard(
                icon: CupertinoIcons.arrow_down_circle_fill,
                accentColor: const Color(0xFF00E5FF),
                gradientColors: [
                  const Color(0xFF0288D1).withValues(alpha: 0.28),
                  const Color(0xFF222222),
                ],
                title: 'Downloads',
                value: '${playerCtrl?.downloadedTracks.length ?? 0}',
                subtitle: 'Offline tracks',
                onTap: () {
                  Get.back();
                  musicCtrl?.changeTab(2);
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _buildActivityCard(
                icon: CupertinoIcons.music_albums_fill,
                accentColor: AppColors.primary,
                gradientColors: [
                  const Color(0xFF1DB954).withValues(alpha: 0.28),
                  const Color(0xFF222222),
                ],
                title: 'Playlists',
                value: '${musicCtrl?.customPlaylists.length ?? 0}',
                subtitle: 'Custom sets',
                onTap: () {
                  Get.back();
                  musicCtrl?.changeTab(2);
                },
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildActivityCard(
                icon: CupertinoIcons.clock_fill,
                accentColor: const Color(0xFFFFAB00),
                gradientColors: [
                  const Color(0xFFFF6F00).withValues(alpha: 0.28),
                  const Color(0xFF222222),
                ],
                title: 'History',
                value: '${musicCtrl?.listeningHistory.length ?? 0}',
                subtitle: 'Recently played',
                onTap: () {
                  Get.back();
                  musicCtrl?.changeTab(2);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityCard({
    required IconData icon,
    required Color accentColor,
    required List<Color> gradientColors,
    required String title,
    required String value,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.35),
            width: 1.2.w,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(icon, color: accentColor, size: 20.sp),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.textMuted,
                  size: 12.sp,
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              title,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10.5.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings & Audio',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF202020),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              _buildSettingTile(
                icon: Icons.high_quality_rounded,
                title: 'Streaming Quality',
                subtitle: 'High (320 kbps AAC & MP3)',
              ),
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
              _buildSettingTile(
                icon: Icons.offline_pin_rounded,
                title: 'Offline Storage',
                subtitle: 'Encrypted sandbox cache with no media scanner leaks',
              ),
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
              _buildSettingTile(
                icon: Icons.music_note_rounded,
                title: 'Dual-Engine Audio',
                subtitle: 'Official JioSaavn & decentralized Audius streams',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context, AuthService auth) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Get.defaultDialog(
          title: 'Sign Out',
          titleStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
          backgroundColor: const Color(0xFF242424),
          radius: 14.r,
          content: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Text(
              'Are you sure you want to sign out of your Google account?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13.sp,
              ),
            ),
          ),
          textConfirm: 'Sign Out',
          textCancel: 'Cancel',
          confirmTextColor: Colors.white,
          cancelTextColor: AppColors.textSecondary,
          buttonColor: const Color(0xFFD32F2F),
          onConfirm: () {
            Get.back();
            auth.signOut();
          },
        );
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 13.h),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.4),
            width: 1.2.w,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18.sp),
            SizedBox(width: 8.w),
            Text(
              'Sign Out of Google',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfoFooter() {
    return Column(
      children: [
        Text(
          '${AppConstants.appTitle} • v1.0.0',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11.5.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          'Crafted with ❤️ by Nikhil',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11.sp,
          ),
        ),
      ],
    );
  }
}
