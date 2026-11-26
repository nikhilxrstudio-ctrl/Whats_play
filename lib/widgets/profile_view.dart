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
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        children: [
          if (isLoggedIn)
            _buildLoggedInHeader(context, auth)
          else
            _buildLoggedOutHeader(context, auth),
          SizedBox(height: 24.h),
          _buildActivitySection(context, playerCtrl, musicCtrl),
          SizedBox(height: 24.h),
          _buildPreferencesSection(context),
          SizedBox(height: 24.h),
          if (isLoggedIn) ...[
            _buildSignOutButton(context, auth),
            SizedBox(height: 24.h),
          ],
          _buildAppInfoFooter(),
          SizedBox(height: 80.h),
        ],
      );
    });
  }

  Widget _buildLoggedInHeader(BuildContext context, AuthService auth) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.22),
            const Color(0xFF1E1E1E),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34.r,
            backgroundColor: AppColors.surfaceLight,
            backgroundImage: auth.userPhotoUrl.isNotEmpty
                ? NetworkImage(auth.userPhotoUrl.value)
                : null,
            child: auth.userPhotoUrl.isEmpty
                ? Icon(
                    CupertinoIcons.person_fill,
                    size: 34.sp,
                    color: AppColors.primary,
                  )
                : null,
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
                        auth.userName.value.isNotEmpty
                            ? auth.userName.value
                            : 'Music Lover',
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
                    SizedBox(width: 6.w),
                    Icon(
                      Icons.verified_rounded,
                      color: AppColors.primary,
                      size: 16.sp,
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  auth.userEmail.value.isNotEmpty
                      ? auth.userEmail.value
                      : 'Google Account Connected',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'Google Account Linked',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
            const Color(0xFF282828),
            const Color(0xFF161616),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: Image.asset(
                  'assets/icons/app_logo.png',
                  width: 44.w,
                  height: 44.w,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 44.w,
                    height: 44.w,
                    color: AppColors.surfaceLight,
                    child: const Icon(Icons.music_note_rounded, color: AppColors.primary),
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sign in to WhatsPlay',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      'Sync your music library across devices',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          Text(
            'Connect with Google to securely backup your custom playlists, favorite artists, and liked tracks in the cloud.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12.5.sp,
              height: 1.45,
            ),
          ),
          SizedBox(height: 20.h),
          GestureDetector(
            onTap: auth.isLoading.value
                ? null
                : () async {
                    HapticFeedback.lightImpact();
                    final success = await auth.signInWithGoogle();
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
                borderRadius: BorderRadius.circular(26.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: auth.isLoading.value
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.g_mobiledata_rounded,
                            size: 30.sp,
                            color: Colors.black,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Continue with Google',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
              ),
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
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _buildActivityCard(
                icon: CupertinoIcons.heart_fill,
                iconColor: AppColors.primary,
                title: 'Liked Songs',
                value: '${playerCtrl?.likedTracks.length ?? 0}',
                subtitle: 'Tracks saved',
                onTap: () {
                  musicCtrl?.changeTab(2);
                  musicCtrl?.openLikedSongs();
                },
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildActivityCard(
                icon: CupertinoIcons.arrow_down_circle_fill,
                iconColor: const Color(0xFF29B6F6),
                title: 'Downloads',
                value: '${playerCtrl?.downloadedTracks.length ?? 0}',
                subtitle: 'Offline tracks',
                onTap: () {
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
                iconColor: const Color(0xFFAB47BC),
                title: 'Playlists',
                value: '${musicCtrl?.customPlaylists.length ?? 0}',
                subtitle: 'Custom collections',
                onTap: () {
                  musicCtrl?.changeTab(2);
                },
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildActivityCard(
                icon: CupertinoIcons.time,
                iconColor: const Color(0xFFFFA726),
                title: 'History',
                value: '${musicCtrl?.listeningHistory.length ?? 0}',
                subtitle: 'Recent plays',
                onTap: () {
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
    required Color iconColor,
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
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: iconColor, size: 22.sp),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.textMuted,
                  size: 12.sp,
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              title,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
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
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(14.r),
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
                subtitle: 'Sandbox encrypted .nomedia storage',
              ),
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
              _buildSettingTile(
                icon: Icons.music_note_rounded,
                title: 'Audio Provider Sources',
                subtitle: 'Official JioSaavn & Audius APIs',
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
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 18.sp),
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
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w600,
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
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.4),
            width: 1,
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
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w600,
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
            fontWeight: FontWeight.w500,
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
