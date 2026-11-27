import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../widgets/profile_view.dart';
import '../widgets/spotify_back_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Ambient emerald/primary radial glow at top of screen
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 320.h,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1DB954).withValues(alpha: 0.35),
                    const Color(0xFF0F3E22).withValues(alpha: 0.16),
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Custom Transparent Header with Spotify Back Button
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Row(
                    children: [
                      const SpotifyBackButton(),
                      SizedBox(width: 14.w),
                      Text(
                        'Profile & Account',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // Expanded Scrollable Profile View
                const Expanded(
                  child: ProfileView(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
