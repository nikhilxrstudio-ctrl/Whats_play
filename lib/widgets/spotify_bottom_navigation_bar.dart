import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';

class SpotifyBottomNavigationBar extends StatelessWidget {
  final TabController tabController;
  final ValueChanged<int> onTabSelected;

  const SpotifyBottomNavigationBar({
    super.key,
    required this.tabController,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bottomBar,
        border: Border(
          top: BorderSide(
            color: const Color(0xFF1E1E1E),
            width: 1.w,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: SizedBox(
          height: 52.h,
          child: AnimatedBuilder(
            animation: tabController,
            builder: (context, _) {
              final activeIndex = tabController.index;
              return TabBar(
                controller: tabController,
                onTap: onTabSelected,
                indicator: const BoxDecoration(),
                indicatorColor: Colors.transparent,
                dividerColor: Colors.transparent,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textMuted,
                splashFactory: NoSplash.splashFactory,
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                labelStyle: TextStyle(
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w500,
                ),
                tabs: [
                  Tab(
                    iconMargin: EdgeInsets.only(bottom: 3.h),
                    icon: Icon(
                      activeIndex == 0
                          ? CupertinoIcons.house_fill
                          : CupertinoIcons.house,
                      color: activeIndex == 0
                          ? AppColors.primary
                          : AppColors.textMuted,
                      size: 22.sp,
                    ),
                    text: 'Home',
                  ),
                  Tab(
                    iconMargin: EdgeInsets.only(bottom: 3.h),
                    icon: Icon(
                      CupertinoIcons.search,
                      color: activeIndex == 1
                          ? AppColors.primary
                          : AppColors.textMuted,
                      size: 22.sp,
                    ),
                    text: 'Search',
                  ),
                  Tab(
                    iconMargin: EdgeInsets.only(bottom: 3.h),
                    icon: Icon(
                      activeIndex == 2
                          ? CupertinoIcons.music_albums_fill
                          : CupertinoIcons.music_albums,
                      color: activeIndex == 2
                          ? AppColors.primary
                          : AppColors.textMuted,
                      size: 22.sp,
                    ),
                    text: 'Your Library',
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
