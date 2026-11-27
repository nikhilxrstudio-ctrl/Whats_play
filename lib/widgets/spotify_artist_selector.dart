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
  final List<String> favoriteCategories;
  final ValueChanged<String>? onCategorySelected;
  final String? selectedCategory;

  const SpotifyArtistSelector({
    super.key,
    required this.artists,
    required this.selectedArtist,
    required this.onArtistSelected,
    this.onLikedSongsSelected,
    this.favoriteCategories = const [],
    this.onCategorySelected,
    this.selectedCategory,
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
              itemCount: (onLikedSongsSelected != null ? 1 : 0) +
                  favoriteCategories.length +
                  artists.length,
              itemBuilder: (context, index) {
                if (index == 0 && onLikedSongsSelected != null) {
                  return _buildLikedSongsTile();
                }

                final catIndex = onLikedSongsSelected != null ? index - 1 : index;
                if (catIndex < favoriteCategories.length) {
                  return _buildCategoryTile(favoriteCategories[catIndex]);
                }

                final artistIndex = catIndex - favoriteCategories.length;
                final artist = artists[artistIndex];
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

  Widget _buildCategoryTile(String category) {
    final isSelected =
        selectedCategory?.toLowerCase() == category.toLowerCase();
    final gradient = _getCategoryGradient(category);
    final icon = _getCategoryIcon(category);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onCategorySelected?.call(category),
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
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 1.5.w,
            ),
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
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
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
  }

  List<Color> _getCategoryGradient(String category) {
    switch (category.toLowerCase()) {
      case 'bollywood':
        return [const Color(0xFFE91E63), const Color(0xFFFF9800)];
      case 'punjabi':
        return [const Color(0xFFFF5722), const Color(0xFFFFEB3B)];
      case 'gujarati':
        return [const Color(0xFF009688), const Color(0xFF4CAF50)];
      case 'romantic':
        return [const Color(0xFFE040FB), const Color(0xFFFF4081)];
      case 'party':
        return [const Color(0xFF7C4DFF), const Color(0xFF00E5FF)];
      case 'pop':
        return [const Color(0xFFFF4081), const Color(0xFFFFD54F)];
      case 'lo-fi':
      case 'chill':
        return [const Color(0xFF3F51B5), const Color(0xFF00BCD4)];
      case 'hip-hop/rap':
        return [const Color(0xFFFF9800), const Color(0xFFF44336)];
      case 'rock':
        return [const Color(0xFF37474F), const Color(0xFFD32F2F)];
      case 'electronic':
        return [const Color(0xFF00E676), const Color(0xFF00B0FF)];
      case 'classical':
        return [const Color(0xFF795548), const Color(0xFFFFB74D)];
      default:
        return [const Color(0xFF1DB954), const Color(0xFF00897B)];
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'bollywood':
        return CupertinoIcons.film;
      case 'punjabi':
        return CupertinoIcons.music_mic;
      case 'gujarati':
        return CupertinoIcons.sparkles;
      case 'romantic':
        return CupertinoIcons.heart_fill;
      case 'party':
        return CupertinoIcons.bolt_fill;
      case 'pop':
        return CupertinoIcons.star_fill;
      case 'lo-fi':
      case 'chill':
        return CupertinoIcons.headphones;
      default:
        return CupertinoIcons.music_note_2;
    }
  }
}
