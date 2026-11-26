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

  static const List<_BottomNavItemData> _tabs = [
    _BottomNavItemData(
      label: 'Home',
      selectedIcon: CupertinoIcons.house_fill,
      unselectedIcon: CupertinoIcons.house,
    ),
    _BottomNavItemData(
      label: 'Search',
      selectedIcon: CupertinoIcons.search,
      unselectedIcon: CupertinoIcons.search,
    ),
    _BottomNavItemData(
      label: 'Your Library',
      selectedIcon: CupertinoIcons.music_albums_fill,
      unselectedIcon: CupertinoIcons.music_albums,
    ),
    _BottomNavItemData(
      label: 'Profile',
      selectedIcon: CupertinoIcons.person_crop_circle_fill,
      unselectedIcon: CupertinoIcons.person_crop_circle,
    ),
  ];

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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / _tabs.length;
              final safeIndex = currentIndex.clamp(0, _tabs.length - 1);

              return Stack(
                children: [
                  // Smooth animated sliding indicator bar moving left-to-right / right-to-left
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    left: safeIndex * tabWidth,
                    top: 0,
                    width: tabWidth,
                    height: 2.5.h,
                    child: Center(
                      child: Container(
                        width: 32.w,
                        height: 2.5.h,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.6),
                              blurRadius: 4,
                              spreadRadius: 0.5,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Tab Items Row
                  Row(
                    children: List.generate(_tabs.length, (index) {
                      final tab = _tabs[index];
                      return _buildTabItem(
                        index: index,
                        label: tab.label,
                        selectedIcon: tab.selectedIcon,
                        unselectedIcon: tab.unselectedIcon,
                      );
                    }),
                  ),
                ],
              );
            },
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
            AnimatedScale(
              scale: isSelected ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: Icon(
                isSelected ? selectedIcon : unselectedIcon,
                color: color,
                size: 22.sp,
              ),
            ),
            SizedBox(height: 3.h),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                color: color,
                fontSize: 10.5.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontFamily: '.SF Pro Text',
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItemData {
  final String label;
  final IconData selectedIcon;
  final IconData unselectedIcon;

  const _BottomNavItemData({
    required this.label,
    required this.selectedIcon,
    required this.unselectedIcon,
  });
}
