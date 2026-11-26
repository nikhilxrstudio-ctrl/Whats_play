import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';

class SpotifyBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const SpotifyBottomNavigationBar({
    super.key,
    required this.currentIndex,
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTabItem(
                index: 0,
                label: 'Home',
                selectedIcon: CupertinoIcons.house_fill,
                unselectedIcon: CupertinoIcons.house,
              ),
              _buildTabItem(
                index: 1,
                label: 'Search',
                selectedIcon: CupertinoIcons.search,
                unselectedIcon: CupertinoIcons.search,
              ),
              _buildTabItem(
                index: 2,
                label: 'Your Library',
                selectedIcon: CupertinoIcons.music_albums_fill,
                unselectedIcon: CupertinoIcons.music_albums,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required String label,
    required IconData selectedIcon,
    required IconData unselectedIcon,
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected ? AppColors.primary : AppColors.textMuted;

    return Expanded(
      child: InkWell(
        onTap: () => onTabSelected(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                if (isSelected)
                  Container(
                    width: 36.w,
                    height: 24.h,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 10.r,
                          spreadRadius: 1.r,
                        ),
                      ],
                    ),
                  ),
                Icon(
                  isSelected ? selectedIcon : unselectedIcon,
                  color: color,
                  size: 22.sp,
                  shadows: isSelected
                      ? [
                          Shadow(
                            color: AppColors.primary.withValues(alpha: 0.55),
                            blurRadius: 8.r,
                          ),
                        ]
                      : null,
                ),
              ],
            ),
            SizedBox(height: 3.h),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10.5.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
