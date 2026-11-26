import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../models/artist_category_model.dart';

class SpotifyArtistSelector extends StatelessWidget {
  final List<ArtistCategoryModel> artists;
  final ArtistCategoryModel? selectedArtist;
  final ValueChanged<ArtistCategoryModel> onArtistSelected;
  final VoidCallback? onLikedSongsSelected;

  const SpotifyArtistSelector({
    super.key,
    required this.artists,
    required this.selectedArtist,
    required this.onArtistSelected,
    this.onLikedSongsSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: EdgeInsets.only(top: 10.h, bottom: 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Featured Artists & Playlists',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (selectedArtist != null)
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      selectedArtist!.name,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          // 3-Row Vertical, 2-Column Horizontal Scrolling Grid (Spotify Home Style)
          SizedBox(
            height: 162.h,
            child: GridView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8.w,
                crossAxisSpacing: 6.h,
                mainAxisExtent: 168.w,
              ),
              itemCount: onLikedSongsSelected != null ? artists.length + 1 : artists.length,
              itemBuilder: (context, index) {
                if (index == 0 && onLikedSongsSelected != null) {
                  return _buildLikedSongsTile();
                }

                final artist = onLikedSongsSelected != null
                    ? artists[index - 1]
                    : artists[index];
                final isSelected = selectedArtist?.id == artist.id;
                final isPlaylist = artist.categoryLabel == 'Playlist';

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onArtistSelected(artist),
                    borderRadius: BorderRadius.circular(6.r),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF2C2C2C)
                            : const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 1.5.w,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Left image thumbnail (square) with playlist overlay
                          ClipRRect(
                            borderRadius: BorderRadius.horizontal(
                              left: Radius.circular(5.r),
                            ),
                            child: SizedBox(
                              width: 48.w,
                              height: double.infinity,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  artist.imageUrl != null &&
                                          artist.imageUrl!.isNotEmpty
                                      ? Image.network(
                                          artist.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, _) =>
                                              _buildFallbackIcon(isPlaylist),
                                          loadingBuilder:
                                              (context, child, progress) {
                                            if (progress == null) return child;
                                            return Container(
                                              color: AppColors.surfaceLight,
                                              child: const Center(
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 1.5,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<Color>(
                                                    AppColors.primary,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        )
                                      : _buildFallbackIcon(isPlaylist),
                                  // Playlist badge overlay
                                  if (isPlaylist)
                                    Positioned(
                                      bottom: 2.h,
                                      right: 2.w,
                                      child: Container(
                                        padding: EdgeInsets.all(2.w),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(3.r),
                                        ),
                                        child: Icon(
                                          CupertinoIcons.music_note_list,
                                          color: Colors.white,
                                          size: 9.sp,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          // Right artist / playlist name
                          Expanded(
                            child: Text(
                              artist.name,
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelected)
                            Padding(
                              padding: EdgeInsets.only(right: 6.w),
                              child: Icon(
                                Icons.check_circle_rounded,
                                size: 14.sp,
                                color: AppColors.primary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLikedSongsTile() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onLikedSongsSelected,
        borderRadius: BorderRadius.circular(6.r),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(5.r),
                ),
                child: Container(
                  width: 48.w,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF450AF5), Color(0xFFC4EFD9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      CupertinoIcons.heart_fill,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Liked Songs',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackIcon(bool isPlaylist) {
    return Container(
      color: AppColors.surfaceLight,
      child: Icon(
        isPlaylist ? CupertinoIcons.music_note_list : Icons.person_rounded,
        size: 20.sp,
        color: AppColors.textSecondary,
      ),
    );
  }
}
