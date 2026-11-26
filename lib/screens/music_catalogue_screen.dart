import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../controllers/music_controller.dart';
import '../controllers/player_controller.dart';
import '../controllers/section_tracks_controller.dart';
import '../controllers/category_detail_controller.dart';
import '../models/playlist_model.dart';
import '../routes/app_routes.dart';
import '../widgets/category_selector_bar.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/mini_player_bar.dart';
import '../widgets/music_track_card.dart';
import '../widgets/playlist_icon_helper.dart';
import '../widgets/spotify_artist_selector.dart';
import '../widgets/spotify_back_button.dart';
import '../widgets/spotify_bottom_navigation_bar.dart';
import '../widgets/track_options_sheet.dart';

class MusicCatalogueScreen extends GetView<MusicController> {
  const MusicCatalogueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final wasOnHome = controller.currentTabIndex.value == 0 &&
            !controller.isViewingLikedSongs.value &&
            controller.activeCustomPlaylist.value == null;

        final handled = controller.handleBackPress();
        if (handled) {
          // Only show "Press back again to exit" when user was ALREADY on the root Home tab
          if (wasOnHome) {
            ScaffoldMessenger.of(context).removeCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Press back again to exit',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                backgroundColor: const Color(0xFF282828),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.only(bottom: 80.h, left: 32.w, right: 32.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            );
          } else {
            // Dismiss any existing snackbar when navigating back to Home
            ScaffoldMessenger.of(context).removeCurrentSnackBar();
          }
          return;
        }
        SystemNavigator.pop();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: AppColors.bottomBar,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(56.h),
            child: Obx(() {
              final isViewingCustom = controller.activeCustomPlaylist.value != null;
              final isViewingLiked = controller.isViewingLikedSongs.value;
              final isDetail = controller.currentTabIndex.value == 2 &&
                  (isViewingLiked || isViewingCustom);

              if (controller.currentTabIndex.value == 0) {
                return AppBar(
                  backgroundColor: AppColors.background,
                  elevation: 0,
                  centerTitle: false,
                  titleSpacing: 16.w,
                  toolbarHeight: 56.h,
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6.r),
                        child: Image.asset(
                          'assets/icons/app_logo.png',
                          width: 24.w,
                          height: 24.w,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.play_circle_fill_rounded,
                            color: AppColors.primary,
                            size: 24.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          AppConstants.appTitle,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              } else if (controller.currentTabIndex.value == 1) {
                return AppBar(
                  backgroundColor: AppColors.background,
                  elevation: 0,
                  centerTitle: false,
                  titleSpacing: 16.w,
                  toolbarHeight: 56.h,
                  title: Text(
                    'Search',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                );
              } else {
                return AppBar(
                  backgroundColor: AppColors.background,
                  elevation: 0,
                  centerTitle: false,
                  titleSpacing: 16.w,
                  toolbarHeight: 56.h,
                  leading: isDetail
                      ? SpotifyBackButton(
                          onPressed: () {
                            if (controller.isViewingLikedSongs.value) {
                              controller.closeLikedSongs();
                            } else {
                              controller.closeCustomPlaylist();
                            }
                          },
                        )
                      : null,
                  title: Text(
                    controller.isViewingLikedSongs.value
                        ? 'Liked Songs'
                        : controller.activeCustomPlaylist.value != null
                            ? controller.activeCustomPlaylist.value!.name
                            : 'Your Library',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  actions: [
                    if (!isDetail) ...[
                      IconButton(
                        icon: Icon(
                          CupertinoIcons.search,
                          color: AppColors.textPrimary,
                          size: 20.sp,
                        ),
                        onPressed: () => controller.changeTab(1),
                      ),
                      IconButton(
                        icon: Icon(
                          CupertinoIcons.plus,
                          color: AppColors.textPrimary,
                          size: 22.sp,
                        ),
                        onPressed: () => _showCreateOptionsBottomSheet(context),
                      ),
                    ],
                  ],
                );
              }
            }),
          ),
          body: PageView(
            controller: controller.pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              controller.currentTabIndex.value = index;
            },
            children: [
              _KeepAliveTab(child: _buildHomeView(context)),
              _KeepAliveTab(child: _buildSearchView(context)),
              _KeepAliveTab(child: _buildLibraryView(context)),
            ],
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            bottom: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Docked Mini Player Bar directly above bottom navigation bar
                if (Get.isRegistered<PlayerController>())
                  const MiniPlayerBar(),
                // Spotify-Style Cupertino Bottom Navigation Bar with isolated Obx
                Obx(() {
                  final isViewingCustom = controller.activeCustomPlaylist.value != null;
                  final isViewingLiked = controller.isViewingLikedSongs.value;
                  final isDetail = controller.currentTabIndex.value == 2 &&
                      (isViewingLiked || isViewingCustom);
                  return SpotifyBottomNavigationBar(
                    currentIndex: controller.currentTabIndex.value,
                    onTabSelected: (index) {
                      if (isDetail) {
                        controller.closeLikedSongs();
                        controller.closeCustomPlaylist();
                      }
                      controller.changeTab(index);
                    },
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Tab 0: Home Music Catalogue View
  /// Tab 0: Home Music Catalogue View (Full Page Scrolling with Sticky Category Bar)
  Widget _buildHomeView(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceLight,
      onRefresh: () => controller.refreshCatalogue(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          // 1. Spotify-Style Featured Artist & Liked Songs Quick-Access Grid (Scrolls away)
          SliverToBoxAdapter(
            child: Obx(() => SpotifyArtistSelector(
                  artists: controller.featuredArtists,
                  selectedArtist: controller.selectedArtist.value,
                  onArtistSelected: (artist) {
                    Get.toNamed(AppRoutes.artist, arguments: artist);
                  },
                  onLikedSongsSelected: () {
                    controller.changeTab(2);
                    controller.openLikedSongs();
                  },
                )),
          ),

          // 2. Sticky Horizontal Genre / Category Filter Bar (Pins to top on scroll)
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyCategoryHeaderDelegate(
              height: 46.h,
              child: Obx(() => CategorySelectorBar(
                    categories: controller.categories,
                    selectedCategory: controller.selectedCategory.value,
                    onCategorySelected: (category) =>
                        controller.selectCategory(category),
                  )),
            ),
          ),

          // Suggested for You Shelf (Built from repeat listening & user history)
          Obx(() {
            if (controller.selectedCategory.value != 'All' ||
                controller.suggestedTracks.isEmpty) {
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }
            return SliverToBoxAdapter(
              child: _buildSuggestedShelf(),
            );
          }),

          // 3. Main Body Content (Loading / Error / Empty / SliverList)
          Obx(() {
            if (controller.isLoading) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: LoadingView(
                  message:
                      'Loading ${controller.selectedCategory.value} tracks...',
                ),
              );
            }

            if (controller.isError) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorView(
                  message: controller.errorMessage.value,
                  onRetry: () => controller.fetchTracks(forceRefresh: true),
                ),
              );
            }

            if (controller.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyView(
                  onRefresh: () => controller.fetchTracks(forceRefresh: true),
                ),
              );
            }

            final allTracks = controller.tracks;
            final isExpanded = controller.isAllSongsExpanded.value;
            final displayCount = (isExpanded || allTracks.length <= 10)
                ? allTracks.length
                : 10;

            return SliverMainAxisGroup(
              slivers: [
                // All Songs Section Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 6.h),
                    child: Row(
                      children: [
                        Text(
                          'All Songs',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '• ${allTracks.length}',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Songs List (max 10 initially, expands when See more is clicked)
                SliverPadding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final track = allTracks[index];
                        return Obx(() {
                          final verification =
                              controller.audioVerifications[track.trackId];
                          final isVerifying =
                              controller.verifyingTrackIds.contains(track.trackId);

                          return MusicTrackCard(
                            track: track,
                            verification: verification,
                            isVerifying: isVerifying,
                            onVerifyPressed: () => controller.verifyAudio(track),
                            onTap: () {
                              if (Get.isRegistered<PlayerController>()) {
                                final playerCtrl = Get.find<PlayerController>();
                                playerCtrl.playTrack(
                                  track,
                                  queue: allTracks,
                                );
                              }
                              Get.toNamed(AppRoutes.player, arguments: track);
                            },
                          );
                        });
                      },
                      childCount: displayCount,
                    ),
                  ),
                ),

                // See more / Show less toggle button if more than 10 tracks
                if (allTracks.length > 10)
                  SliverToBoxAdapter(
                    child: Center(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: controller.toggleExpandAllSongs,
                        child: Container(
                          margin: EdgeInsets.only(top: 8.h, bottom: 12.h),
                          padding: EdgeInsets.symmetric(
                            horizontal: 18.w,
                            vertical: 7.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isExpanded
                                    ? 'Show less'
                                    : 'See more (${allTracks.length - 10} more songs)',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12.5.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Icon(
                                isExpanded
                                    ? CupertinoIcons.chevron_up
                                    : CupertinoIcons.chevron_down,
                                color: AppColors.primary,
                                size: 13.sp,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Trending Songs Shelf (placed right after All Songs section!)
                if (controller.selectedCategory.value == 'All' &&
                    controller.trendingTracks.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildTrendingShelf(),
                  ),

                // New Releases Shelf (Brand new drops & fresh arrivals)
                if (controller.selectedCategory.value == 'All' &&
                    controller.newReleases.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildNewReleasesShelf(),
                  ),

                // Top Charts: India Top 50 Ranked List Section
                if (controller.selectedCategory.value == 'All' &&
                    controller.topCharts.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildTopChartsRankedSection(),
                  ),

                // Romantic Melodies Shelf (Love & Soul Hits)
                if (controller.selectedCategory.value == 'All' &&
                    controller.romanticTracks.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildRomanticShelf(),
                  ),

                // Party & Dance Anthems Shelf (Club bangers & high energy hits)
                if (controller.selectedCategory.value == 'All' &&
                    controller.partyTracks.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildPartyShelf(),
                  ),

                SliverToBoxAdapter(
                  child: SizedBox(height: 16.h),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  /// Horizontal Shelf displaying dynamically suggested songs based on listening history
  Widget _buildSuggestedShelf() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suggested for You',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Obx(() => Text(
                          controller.suggestionSubtitle.value,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.5.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Get.toNamed(
                    AppRoutes.sectionTracks,
                    arguments: SectionTracksArgs(
                      title: 'Suggested for You',
                      subtitle: controller.suggestionSubtitle.value,
                      tracks: controller.suggestedTracks.toList(),
                      sectionType: 'suggested',
                      imageUrl: controller.suggestedTracks.isNotEmpty
                          ? controller.suggestedTracks.first.artworkUrl
                          : 'https://c.saavncdn.com/editorial/Hindi-IndiaSuperhitsTop50_20261113063216_500x500.jpg',
                    ),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                  child: Text(
                    'See all',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 165.h,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: controller.suggestedTracks.length,
            separatorBuilder: (context, index) => SizedBox(width: 12.w),
            itemBuilder: (context, index) {
              final track = controller.suggestedTracks[index];
              return GestureDetector(
                onTap: () {
                  if (Get.isRegistered<PlayerController>()) {
                    final playerCtrl = Get.find<PlayerController>();
                    playerCtrl.playTrack(track, queue: controller.suggestedTracks);
                  }
                  Get.toNamed(AppRoutes.player, arguments: track);
                },
                child: SizedBox(
                  width: 114.w,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6.r),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              track.artworkUrl != null &&
                                      track.artworkUrl!.isNotEmpty
                                  ? Image.network(
                                      track.artworkUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        color: AppColors.surfaceLight,
                                        child: const Icon(
                                          Icons.music_note_rounded,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: AppColors.surfaceLight,
                                      child: const Icon(
                                        Icons.music_note_rounded,
                                        color: AppColors.primary,
                                      ),
                                    ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 24.h,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.7),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        track.title,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        track.artistName,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Horizontal Shelf displaying Trending Songs with ranking badges (#1, #2, etc.)
  Widget _buildTrendingShelf() {
    return Obx(() {
      final list = controller.trendingTracks;
      if (list.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 10.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.flame_fill,
                            color: const Color(0xFFFF5722),
                            size: 18.sp,
                          ),
                          SizedBox(width: 6.w),
                          Flexible(
                            child: Text(
                              'Trending Songs',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Top chartbusters and trending hits right now',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Get.toNamed(
                      AppRoutes.sectionTracks,
                      arguments: SectionTracksArgs(
                        title: 'Trending Songs',
                        subtitle: 'Top chartbusters and trending hits right now',
                        tracks: list.toList(),
                        sectionType: 'trending',
                        showRank: true,
                        imageUrl: 'https://c.saavncdn.com/editorial/Hindi-IndiaSuperhitsTop50_20261113063216_500x500.jpg',
                      ),
                    );
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                    child: Text(
                      'See all',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 165.h,
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, _) => SizedBox(width: 12.w),
              itemBuilder: (context, index) {
                final track = list[index];
                final rank = index + 1;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (Get.isRegistered<PlayerController>()) {
                      Get.find<PlayerController>().playTrack(track, queue: list);
                    }
                    Get.toNamed(AppRoutes.player, arguments: track);
                  },
                  child: SizedBox(
                    width: 114.w,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card with Artwork & Ranking Badge (#1, #2, #3, ...)
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6.r),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Container(
                                  color: AppColors.surfaceLight,
                                  child: track.artworkUrl != null &&
                                          track.artworkUrl!.isNotEmpty
                                      ? Image.network(
                                          track.artworkUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (ctx, err, stack) =>
                                              Container(
                                            color: AppColors.surfaceLight,
                                            child: const Icon(
                                              Icons.music_note_rounded,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.music_note_rounded,
                                          color: AppColors.primary,
                                        ),
                                ),
                                // Gradient shade at bottom
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 24.h,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.7),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                // Ranking badge (#1, #2, #3, ...)
                                Positioned(
                                  top: 6.h,
                                  left: 6.w,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6.w,
                                      vertical: 2.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.82),
                                      borderRadius: BorderRadius.circular(4.r),
                                      border: Border.all(
                                        color: rank <= 3
                                            ? AppColors.primary
                                            : Colors.white24,
                                        width: 1.w,
                                      ),
                                    ),
                                    child: Text(
                                      '#$rank',
                                      style: TextStyle(
                                        color: rank <= 3
                                            ? AppColors.primary
                                            : Colors.white,
                                        fontSize: 10.5.sp,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          track.title,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          track.artistName,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 12.h),
        ],
      );
    });
  }

  /// Horizontal Shelf displaying brand new music drops and fresh hits ("Taaza Tunes")
  Widget _buildNewReleasesShelf() {
    return Obx(() {
      final list = controller.newReleases;
      if (list.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 10.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.sparkles,
                            color: const Color(0xFF00E5FF),
                            size: 18.sp,
                          ),
                          SizedBox(width: 6.w),
                          Flexible(
                            child: Text(
                              'New Releases',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Fresh music drops and latest arrivals',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Get.toNamed(
                      AppRoutes.sectionTracks,
                      arguments: SectionTracksArgs(
                        title: 'New Releases',
                        subtitle: 'Fresh music drops and latest arrivals',
                        tracks: list.toList(),
                        sectionType: 'new_releases',
                        imageUrl: list.isNotEmpty
                            ? list.first.artworkUrl
                            : 'https://c.saavncdn.com/editorial/Hindi-IndiaSuperhitsTop50_20261113063216_500x500.jpg',
                      ),
                    );
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                    child: Text(
                      'See all',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 165.h,
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, _) => SizedBox(width: 12.w),
              itemBuilder: (context, index) {
                final track = list[index];
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (Get.isRegistered<PlayerController>()) {
                      Get.find<PlayerController>().playTrack(track, queue: list);
                    }
                    Get.toNamed(AppRoutes.player, arguments: track);
                  },
                  child: SizedBox(
                    width: 114.w,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card with Artwork & "NEW" Badge
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6.r),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Container(
                                  color: AppColors.surfaceLight,
                                  child: track.artworkUrl != null &&
                                          track.artworkUrl!.isNotEmpty
                                      ? Image.network(
                                          track.artworkUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (ctx, err, stack) =>
                                              Container(
                                            color: AppColors.surfaceLight,
                                            child: const Icon(
                                              Icons.music_note_rounded,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.music_note_rounded,
                                          color: AppColors.primary,
                                        ),
                                ),
                                // Gradient shade at bottom
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 24.h,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.7),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                // "NEW" Badge
                                Positioned(
                                  top: 6.h,
                                  left: 6.w,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6.w,
                                      vertical: 2.h,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF00E5FF), Color(0xFF1DB954)],
                                      ),
                                      borderRadius: BorderRadius.circular(4.r),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.4),
                                          blurRadius: 4.r,
                                          offset: Offset(0, 1.h),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      'NEW',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 9.sp,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          track.title,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          track.artistName,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 12.h),
        ],
      );
    });
  }

  /// Ranked Vertical List displaying Top Charts (India Top 50) with numbered ranks (#1, #2, etc.)
  Widget _buildTopChartsRankedSection() {
    return Obx(() {
      final list = controller.topCharts;
      if (list.isEmpty) return const SizedBox.shrink();

      final topDisplayTracks = list.take(5).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 10.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.chart_bar_alt_fill,
                            color: const Color(0xFFFFD700),
                            size: 18.sp,
                          ),
                          SizedBox(width: 6.w),
                          Flexible(
                            child: Text(
                              'Top Charts • India Top 50',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'The most streamed songs across the nation right now',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Get.toNamed(
                      AppRoutes.sectionTracks,
                      arguments: SectionTracksArgs(
                        title: 'India Superhits Top 50',
                        subtitle: 'The most streamed songs across the nation right now',
                        tracks: list.toList(),
                        sectionType: 'trending',
                        showRank: true,
                        imageUrl: 'https://c.saavncdn.com/editorial/Hindi-IndiaSuperhitsTop50_20261113063216_500x500.jpg',
                      ),
                    );
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                    child: Text(
                      'See all',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Top 5 Ranked Song Cards
          for (int i = 0; i < topDisplayTracks.length; i++)
            MusicTrackCard(
              track: topDisplayTracks[i],
              rank: i + 1,
              onTap: () {
                if (Get.isRegistered<PlayerController>()) {
                  Get.find<PlayerController>().playTrack(
                    topDisplayTracks[i],
                    queue: list,
                  );
                }
                Get.toNamed(AppRoutes.player, arguments: topDisplayTracks[i]);
              },
              onMoreTap: () => TrackOptionsSheet.show(
                Get.overlayContext ?? Get.context,
                topDisplayTracks[i],
              ),
            ),
          // Button to view all 50 chart songs
          if (list.length > 5)
            Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Get.toNamed(
                    AppRoutes.sectionTracks,
                    arguments: SectionTracksArgs(
                      title: 'India Superhits Top 50',
                      subtitle: 'The most streamed songs across the nation right now',
                      tracks: list.toList(),
                      sectionType: 'trending',
                      showRank: true,
                      imageUrl: 'https://c.saavncdn.com/editorial/Hindi-IndiaSuperhitsTop50_20261113063216_500x500.jpg',
                    ),
                  );
                },
                child: Container(
                  margin: EdgeInsets.only(top: 8.h, bottom: 8.h),
                  padding: EdgeInsets.symmetric(
                    horizontal: 18.w,
                    vertical: 7.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'See all ${list.length} chartbusters',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Icon(
                        CupertinoIcons.arrow_right,
                        color: AppColors.primary,
                        size: 13.sp,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          SizedBox(height: 8.h),
        ],
      );
    });
  }

  /// Horizontal Shelf displaying Romantic Melodies & love ballads
  Widget _buildRomanticShelf() {
    return Obx(() {
      final list = controller.romanticTracks;
      if (list.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 10.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.heart_fill,
                            color: const Color(0xFFFF2D55),
                            size: 18.sp,
                          ),
                          SizedBox(width: 6.w),
                          Flexible(
                            child: Text(
                              'Romantic Melodies',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Heart-touching acoustic & love ballads',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Get.toNamed(
                      AppRoutes.sectionTracks,
                      arguments: SectionTracksArgs(
                        title: 'Romantic Melodies',
                        subtitle: 'Heart-touching acoustic & love ballads',
                        tracks: list.toList(),
                        sectionType: 'category',
                        imageUrl: 'https://c.saavncdn.com/editorial/BollywoodLoveSongs_20231129150319_500x500.jpg',
                      ),
                    );
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                    child: Text(
                      'See all',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 165.h,
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, _) => SizedBox(width: 12.w),
              itemBuilder: (context, index) {
                final track = list[index];
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (Get.isRegistered<PlayerController>()) {
                      Get.find<PlayerController>().playTrack(track, queue: list);
                    }
                    Get.toNamed(AppRoutes.player, arguments: track);
                  },
                  child: SizedBox(
                    width: 114.w,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6.r),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Container(
                                  color: AppColors.surfaceLight,
                                  child: track.artworkUrl != null &&
                                          track.artworkUrl!.isNotEmpty
                                      ? Image.network(
                                          track.artworkUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (ctx, err, stack) =>
                                              Container(
                                            color: AppColors.surfaceLight,
                                            child: const Icon(
                                              Icons.music_note_rounded,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.music_note_rounded,
                                          color: AppColors.primary,
                                        ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 24.h,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.7),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          track.title,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          track.artistName,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 12.h),
        ],
      );
    });
  }

  /// Horizontal Shelf displaying Party & Dance Anthems
  Widget _buildPartyShelf() {
    return Obx(() {
      final list = controller.partyTracks;
      if (list.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 10.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.bolt_fill,
                            color: const Color(0xFFFFB800),
                            size: 18.sp,
                          ),
                          SizedBox(width: 6.w),
                          Flexible(
                            child: Text(
                              'Party & Dance Anthems',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'High-voltage club bangers to turn up the mood',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Get.toNamed(
                      AppRoutes.sectionTracks,
                      arguments: SectionTracksArgs(
                        title: 'Party & Dance Anthems',
                        subtitle: 'High-voltage club bangers to turn up the mood',
                        tracks: list.toList(),
                        sectionType: 'category',
                        imageUrl: 'https://c.saavncdn.com/editorial/NonStopParty_20261113052024_500x500.jpg',
                      ),
                    );
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                    child: Text(
                      'See all',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 165.h,
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, _) => SizedBox(width: 12.w),
              itemBuilder: (context, index) {
                final track = list[index];
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (Get.isRegistered<PlayerController>()) {
                      Get.find<PlayerController>().playTrack(track, queue: list);
                    }
                    Get.toNamed(AppRoutes.player, arguments: track);
                  },
                  child: SizedBox(
                    width: 114.w,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6.r),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Container(
                                  color: AppColors.surfaceLight,
                                  child: track.artworkUrl != null &&
                                          track.artworkUrl!.isNotEmpty
                                      ? Image.network(
                                          track.artworkUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (ctx, err, stack) =>
                                              Container(
                                            color: AppColors.surfaceLight,
                                            child: const Icon(
                                              Icons.music_note_rounded,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.music_note_rounded,
                                          color: AppColors.primary,
                                        ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 24.h,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.7),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          track.title,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          track.artistName,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 12.h),
        ],
      );
    });
  }

  /// Tab 1: Search View (Instant Music Search + Browse Categories)
  Widget _buildSearchView(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 10.h, left: 16.w, right: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed Height Cupertino-Styled Search Input Bar (No Height Jumps)
          Container(
            height: 46.h,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.search,
                  color: AppColors.textPrimary,
                  size: 20.sp,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: TextField(
                    controller: controller.searchTextController,
                    onChanged: (val) => controller.onSearchQueryChanged(val),
                    onSubmitted: (val) => controller.performSearch(val),
                    textAlignVertical: TextAlignVertical.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14.sp,
                    ),
                    decoration: InputDecoration(
                      hintText: 'What do you want to listen to?',
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13.5.sp,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                Obx(() => controller.searchQuery.value.isNotEmpty
                    ? GestureDetector(
                        onTap: () => controller.clearSearch(),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
                          child: Icon(
                            CupertinoIcons.clear_circled_solid,
                            color: AppColors.textSecondary,
                            size: 18.sp,
                          ),
                        ),
                      )
                    : const SizedBox.shrink()),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          // Content: Search Results or Browse Categories
          Expanded(
            child: Obx(() {
              if (controller.isSearching.value) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                );
              }

              if (controller.searchQuery.value.isNotEmpty) {
                if (controller.searchResults.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.search,
                          size: 48.sp,
                          color: AppColors.textMuted,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'No results found for "${controller.searchQuery.value}"',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14.sp,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: controller.searchResults.length,
                  itemBuilder: (context, index) {
                    final track = controller.searchResults[index];
                    return MusicTrackCard(
                      track: track,
                      onTap: () {
                        if (Get.isRegistered<PlayerController>()) {
                          final playerCtrl = Get.find<PlayerController>();
                          playerCtrl.playTrack(
                            track,
                            queue: controller.searchResults,
                          );
                        }
                        Get.toNamed(AppRoutes.player, arguments: track);
                      },
                    );
                  },
                );
              }

              // Default Search Home: Browse All Categories
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Browse all',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10.w,
                      mainAxisSpacing: 10.h,
                      childAspectRatio: 1.75,
                      children: [
                        _buildBrowseCard(
                          title: 'Punjabi',
                          color: const Color(0xFFBA5D07),
                          query: 'Punjabi',
                          imageUrl:
                              'https://c.saavncdn.com/editorial/PunjabiHitSongs_20261027063731_500x500.jpg',
                        ),
                        _buildBrowseCard(
                          title: 'Bollywood',
                          color: const Color(0xFF8D67AB),
                          query: 'Bollywood',
                          imageUrl:
                              'https://c.saavncdn.com/editorial/BollywoodLoveSongs_20231129150319_500x500.jpg',
                        ),
                        _buildBrowseCard(
                          title: 'Gujarati',
                          color: const Color(0xFFE8115B),
                          query: 'Gujarati',
                          imageUrl:
                              'https://c.saavncdn.com/editorial/Gujarati-IndiaSuperhitsTop50_20260904074620_500x500.jpg',
                        ),
                        _buildBrowseCard(
                          title: 'Pop',
                          color: const Color(0xFF148A08),
                          query: 'Pop',
                          imageUrl:
                              'https://c.saavncdn.com/245/Hass-Hass-English-2023-20231026170517-500x500.jpg',
                        ),
                        _buildBrowseCard(
                          title: 'Hip-Hop',
                          color: const Color(0xFFBC5900),
                          query: 'Hip-Hop',
                          imageUrl:
                              'https://c.saavncdn.com/artists/Yo_Yo_Honey_Singh_004_20260811095253_500x500.jpg',
                        ),
                        _buildBrowseCard(
                          title: 'Dance / EDM',
                          color: const Color(0xFF0D73EC),
                          query: 'Electronic',
                          imageUrl:
                              'https://c.saavncdn.com/editorial/PartyTop50_20240405105214_500x500.jpg',
                        ),
                        _buildBrowseCard(
                          title: 'Romantic',
                          color: const Color(0xFFE91429),
                          query: 'Romantic',
                          imageUrl:
                              'https://c.saavncdn.com/artists/Arijit_Singh_004_20241118063717_500x500.jpg',
                        ),
                        _buildBrowseCard(
                          title: 'Rock & Hits',
                          color: const Color(0xFF608108),
                          query: 'Rock',
                          imageUrl:
                              'https://c.saavncdn.com/artists/Sidhu_Moose_Wala_004_20250617183705_500x500.jpg',
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBrowseCard({
    required String title,
    required Color color,
    required String query,
    required String imageUrl,
  }) {
    return InkWell(
      onTap: () {
        Get.toNamed(
          AppRoutes.category,
          arguments: CategoryDetailArgs(
            title: title,
            query: query,
            color: color,
            imageUrl: imageUrl,
          ),
        );
      },
      borderRadius: BorderRadius.circular(6.r),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6.r),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Stack(
            children: [
              // Category Title
              Padding(
                padding: EdgeInsets.all(12.w),
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              // Spotify-Style Rotated Artwork in Bottom-Right Corner
              Positioned(
                bottom: -5.h,
                right: -14.w,
                child: Transform.rotate(
                  angle: 25 * 3.1415926535 / 180, // 25 degree tilt
                  child: Container(
                    width: 66.w,
                    height: 66.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 8.r,
                          offset: Offset(0, 4.h),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4.r),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, _) => Container(
                          color: Colors.black26,
                          child: Icon(
                            Icons.music_note_rounded,
                            color: Colors.white54,
                            size: 24.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tab 2: Your Library View
  Widget _buildLibraryView(BuildContext context) {
    return Obx(() {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final isDetailView = child.key == const ValueKey('liked_songs_detail') ||
              (child.key is ValueKey<String> &&
                  (child.key as ValueKey<String>).value.startsWith('custom_playlist'));
          return SlideTransition(
            position: Tween<Offset>(
              begin: isDetailView ? const Offset(1.0, 0.0) : const Offset(-0.3, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: controller.isViewingLikedSongs.value
            ? KeyedSubtree(
                key: const ValueKey('liked_songs_detail'),
                child: _buildLikedSongsDetailView(),
              )
            : controller.activeCustomPlaylist.value != null
                ? KeyedSubtree(
                    key: ValueKey(
                        'custom_playlist_${controller.activeCustomPlaylist.value!.id}'),
                    child: _buildCustomPlaylistDetailView(
                        controller.activeCustomPlaylist.value!),
                  )
                : KeyedSubtree(
                    key: const ValueKey('library_overview'),
                    child: _buildLibraryOverview(),
                  ),
      );
    });
  }



  Widget _buildLikedSongsDetailView() {
    if (!Get.isRegistered<PlayerController>()) {
      return const SizedBox.shrink();
    }
    final playerCtrl = Get.find<PlayerController>();

    return Obx(() {
      final likedTracks = playerCtrl.likedTracks;

      return Column(
        children: [
          // Large Spotify Liked Songs Playlist Header
          Padding(
            padding: EdgeInsets.only(top: 10.h, left: 16.w, right: 16.w, bottom: 10.h),
            child: Row(
              children: [
                Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF450AF5), Color(0xFFC4EFD9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(6.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF450AF5).withValues(alpha: 0.35),
                        blurRadius: 12.r,
                        offset: Offset(0, 4.h),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      CupertinoIcons.heart_fill,
                      color: Colors.white,
                      size: 38.sp,
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Liked Songs',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${likedTracks.length} ${likedTracks.length == 1 ? 'song' : 'songs'}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (likedTracks.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      playerCtrl.playTrack(
                        likedTracks.first,
                        queue: likedTracks,
                      );
                    },
                    child: Container(
                      width: 48.w,
                      height: 48.w,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.black,
                        size: 32.sp,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF1E1E1E), height: 1),
          // Liked Tracks List or Empty State
          Expanded(
            child: likedTracks.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.heart,
                            size: 48.sp,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'Songs you like will appear here',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            'Save songs by tapping the heart icon while playing or browsing.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.5.sp,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 4.h),
                    itemCount: likedTracks.length,
                    itemBuilder: (context, index) {
                      final track = likedTracks[index];
                      return MusicTrackCard(
                        track: track,
                        onTap: () {
                          playerCtrl.playTrack(
                            track,
                            queue: likedTracks,
                          );
                          Get.toNamed(AppRoutes.player, arguments: track);
                        },
                      );
                    },
                  ),
          ),
        ],
      );
    });
  }



  Widget _buildCustomPlaylistDetailView(PlaylistModel playlist) {
    final playerCtrl = Get.isRegistered<PlayerController>()
        ? Get.find<PlayerController>()
        : null;

    final gradient = PlaylistIconHelper.getGradient(playlist.iconKey);
    final icon = PlaylistIconHelper.getIcon(playlist.iconKey);

    return Obx(() {
      final tracks = controller.activePlaylistTracks;
      final currentPlaylist =
          controller.activeCustomPlaylist.value ?? playlist;

      return Column(
        children: [
          // Large Custom Playlist Header
          Padding(
            padding: EdgeInsets.only(top: 10.h, left: 16.w, right: 16.w, bottom: 10.h),
            child: Row(
              children: [
                Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.first.withValues(alpha: 0.35),
                        blurRadius: 12.r,
                        offset: Offset(0, 4.h),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 38.sp,
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentPlaylist.name,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${tracks.length} ${tracks.length == 1 ? 'song' : 'songs'}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (tracks.isNotEmpty && playerCtrl != null)
                  GestureDetector(
                    onTap: () {
                      playerCtrl.playTrack(
                        tracks.first,
                        queue: tracks,
                      );
                      Get.toNamed(AppRoutes.player, arguments: tracks.first);
                    },
                    child: Container(
                      width: 48.w,
                      height: 48.w,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          CupertinoIcons.play_fill,
                          color: Colors.black,
                          size: 24.sp,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          // Custom Playlist Tracks List or Empty Placeholder
          Expanded(
            child: controller.isLoadingPlaylistTracks.value
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                : tracks.isEmpty
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32.w),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                icon,
                                size: 52.sp,
                                color: AppColors.textMuted,
                              ),
                              SizedBox(height: 14.h),
                              Text(
                                'No songs in this collection yet',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                'Add songs by tapping ⋮ on any track in Liked Songs, Search, or long-pressing in the music player screen.',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12.5.sp,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(vertical: 4.h),
                        itemCount: tracks.length,
                        itemBuilder: (context, index) {
                          final track = tracks[index];
                          return MusicTrackCard(
                            track: track,
                            onTap: () {
                              if (playerCtrl != null) {
                                playerCtrl.playTrack(
                                  track,
                                  queue: tracks,
                                );
                              }
                              Get.toNamed(AppRoutes.player, arguments: track);
                            },
                            onMoreTap: () => TrackOptionsSheet.show(
                              context,
                              track,
                              currentPlaylistId: currentPlaylist.id,
                              onOpenCreatePlaylist: () =>
                                  _showCreatePlaylistSheet(context),
                            ),
                          );
                        },
                      ),
          ),
        ],
      );
    });
  }



  Widget _buildLibraryOverview() {
    final playerCtrl = Get.isRegistered<PlayerController>()
        ? Get.find<PlayerController>()
        : null;

    return Obx(() {
      final currentFilter = controller.selectedLibraryFilter.value;

      return Padding(
        padding: EdgeInsets.only(top: 10.h, left: 16.w, right: 16.w, bottom: 8.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Pills: Playlists, History, Downloaded, Artists
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildLibraryPill(
                    'Playlists',
                    isSelected: currentFilter == 'Playlists',
                    onTap: () => controller.selectLibraryFilter('Playlists'),
                  ),
                  SizedBox(width: 8.w),
                  _buildLibraryPill(
                    'History',
                    isSelected: currentFilter == 'History',
                    onTap: () => controller.selectLibraryFilter('History'),
                  ),
                  SizedBox(width: 8.w),
                  _buildLibraryPill(
                    'Downloaded',
                    isSelected: currentFilter == 'Downloaded',
                    onTap: () => controller.selectLibraryFilter('Downloaded'),
                  ),
                  SizedBox(width: 8.w),
                  _buildLibraryPill(
                    'Artists',
                    isSelected: currentFilter == 'Artists',
                    onTap: () => controller.selectLibraryFilter('Artists'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Content based on selected Library Pill
            Expanded(
              child: currentFilter == 'Artists'
                  ? _buildFollowedArtistsSection()
                  : currentFilter == 'History'
                      ? _buildHistorySection(playerCtrl)
                      : currentFilter == 'Downloaded'
                          ? _buildDownloadedSection(playerCtrl)
                          : _buildPlaylistsSection(playerCtrl),
            ),
          ],
        ),
      );
    });
  }



  Widget _buildPlaylistsSection(PlayerController? playerCtrl) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Liked Songs Item (Real-time count + Tap to view)
        if (playerCtrl != null)
          Obx(() {
            final count = playerCtrl.likedTracks.length;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              splashColor: Colors.transparent,
              hoverColor: Colors.transparent,
              focusColor: Colors.transparent,
              leading: Container(
                width: 52.w,
                height: 52.w,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF450AF5), Color(0xFFC4EFD9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Icon(
                  CupertinoIcons.heart_fill,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              title: Text(
                'Liked Songs',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14.5.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Playlist • $count ${count == 1 ? 'song' : 'songs'}',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.sp,
                ),
              ),
              trailing: Icon(
                CupertinoIcons.pin_fill,
                color: AppColors.primary,
                size: 16.sp,
              ),
              onTap: () => controller.openLikedSongs(),
            );
          }),
        SizedBox(height: 8.h),
        // Downloaded Songs Item
        if (playerCtrl != null)
          Obx(() {
            final count = playerCtrl.downloadedTracks.length;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              splashColor: Colors.transparent,
              hoverColor: Colors.transparent,
              focusColor: Colors.transparent,
              leading: Container(
                width: 52.w,
                height: 52.w,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF009688), Color(0xFF1DB954)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Icon(
                  CupertinoIcons.arrow_down_circle_fill,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              title: Text(
                'Downloaded Songs',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14.5.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Playlist • $count ${count == 1 ? 'song' : 'songs'}',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.sp,
                ),
              ),
              trailing: Icon(
                CupertinoIcons.chevron_right,
                color: AppColors.textMuted,
                size: 16.sp,
              ),
              onTap: () => controller.selectLibraryFilter('Downloaded'),
            );
          }),
        SizedBox(height: 8.h),
        // Listening History Item
        Obx(() {
          final count = controller.listeningHistory.length;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            splashColor: Colors.transparent,
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            leading: Container(
              width: 52.w,
              height: 52.w,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Icon(
                CupertinoIcons.clock_fill,
                color: Colors.white,
                size: 24.sp,
              ),
            ),
            title: Text(
              'Listening History',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14.5.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'History • $count ${count == 1 ? 'song played' : 'songs played'}',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.sp,
              ),
            ),
            trailing: Icon(
              CupertinoIcons.chevron_right,
              color: AppColors.textMuted,
              size: 16.sp,
            ),
            onTap: () => controller.selectLibraryFilter('History'),
          );
        }),
        SizedBox(height: 8.h),
        // Custom User Collections / Playlists
        Obx(() {
          final customList = controller.customPlaylists;
          if (customList.isEmpty) return const SizedBox.shrink();

          return Column(
            children: [
              for (final pl in customList)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  splashColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  leading: Container(
                    width: 52.w,
                    height: 52.w,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: PlaylistIconHelper.getGradient(pl.iconKey),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Icon(
                      PlaylistIconHelper.getIcon(pl.iconKey),
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  ),
                  title: Text(
                    pl.name,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14.5.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Playlist • ${pl.songCount} ${pl.songCount == 1 ? 'song' : 'songs'}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.sp,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      CupertinoIcons.ellipsis_vertical,
                      color: AppColors.textMuted,
                      size: 16.sp,
                    ),
                    onPressed: () {
                      final ctx = Get.overlayContext ?? Get.context;
                      if (ctx != null) _showPlaylistOptions(ctx, pl);
                    },
                  ),
                  onTap: () => controller.openCustomPlaylist(pl),
                ),
              SizedBox(height: 8.h),
            ],
          );
        }),
        // Featured Artist Playlists
        for (final artist in controller.featuredArtists.take(4))
          ListTile(
            contentPadding: EdgeInsets.zero,
            splashColor: Colors.transparent,
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(4.r),
              child: SizedBox(
                width: 52.w,
                height: 52.w,
                child: artist.imageUrl != null
                    ? Image.network(artist.imageUrl!, fit: BoxFit.cover)
                    : Container(color: AppColors.surfaceLight),
              ),
            ),
            title: Text(
              '${artist.name} Hits',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14.5.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Artist • Official Mix',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.sp,
              ),
            ),
            onTap: () {
              Get.toNamed(AppRoutes.artist, arguments: artist);
            },
          ),
      ],
    );
  }

  Widget _buildFollowedArtistsSection() {
    return Obx(() {
      final followed = controller.followedArtists;

      if (followed.isEmpty) {
        return Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.person_crop_circle_badge_plus,
                  size: 56.sp,
                  color: AppColors.textMuted,
                ),
                SizedBox(height: 16.h),
                Text(
                  'No artists followed yet',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Follow your favorite artists from their details page to see them here.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      return ListView(
        padding: EdgeInsets.zero,
        children: [
          for (final artist in followed)
            ListTile(
              contentPadding: EdgeInsets.symmetric(vertical: 4.h),
              splashColor: Colors.transparent,
              hoverColor: Colors.transparent,
              focusColor: Colors.transparent,
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(26.r), // Circular avatar for artists
                child: SizedBox(
                  width: 52.w,
                  height: 52.w,
                  child: artist.imageUrl != null && artist.imageUrl!.isNotEmpty
                      ? Image.network(artist.imageUrl!, fit: BoxFit.cover)
                      : Container(
                          color: AppColors.surfaceLight,
                          child: const Icon(CupertinoIcons.person_fill, color: AppColors.textMuted),
                        ),
                ),
              ),
              title: Text(
                artist.name,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Artist',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.sp,
                ),
              ),
              trailing: Icon(
                CupertinoIcons.chevron_right,
                color: AppColors.textMuted,
                size: 16.sp,
              ),
              onTap: () {
                Get.toNamed(AppRoutes.artist, arguments: artist);
              },
            ),
        ],
      );
    });
  }



  Widget _buildHistorySection(PlayerController? playerCtrl) {
    return Obx(() {
      final grouped = controller.groupedListeningHistory;
      if (grouped.isEmpty) {
        return Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.clock,
                  size: 56.sp,
                  color: AppColors.textMuted,
                ),
                SizedBox(height: 16.h),
                Text(
                  'No listening history yet',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Songs you listen to will automatically be recorded and organized here by day.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      return ListView(
        padding: EdgeInsets.zero,
        children: [
          for (final entry in grouped.entries) ...[
            Padding(
              padding: EdgeInsets.only(top: 14.h, bottom: 6.h, left: 4.w, right: 4.w),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.calendar,
                    size: 14.sp,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    entry.key,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${entry.value.length} ${entry.value.length == 1 ? 'song' : 'songs'}',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11.5.sp,
                    ),
                  ),
                ],
              ),
            ),
            for (final track in entry.value)
              MusicTrackCard(
                track: track,
                onTap: () {
                  if (playerCtrl != null) {
                    playerCtrl.playTrack(track, queue: entry.value);
                  }
                  Get.toNamed(AppRoutes.player, arguments: track);
                },
                onMoreTap: () => TrackOptionsSheet.show(
                  Get.overlayContext ?? Get.context,
                  track,
                ),
              ),
          ],
          SizedBox(height: 20.h),
        ],
      );
    });
  }

  Widget _buildDownloadedSection(PlayerController? playerCtrl) {
    if (playerCtrl == null) return const SizedBox.shrink();

    return Obx(() {
      final downloaded = playerCtrl.downloadedTracks;
      if (downloaded.isEmpty) {
        return Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.arrow_down_circle,
                  size: 56.sp,
                  color: AppColors.textMuted,
                ),
                SizedBox(height: 16.h),
                Text(
                  'No downloaded songs yet',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Tap the download icon in the player or song options to listen offline anytime.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      return ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.arrow_down_circle_fill,
                  size: 14.sp,
                  color: AppColors.primary,
                ),
                SizedBox(width: 6.w),
                Text(
                  '${downloaded.length} ${downloaded.length == 1 ? 'Song' : 'Songs'} Offline',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    playerCtrl.toggleShuffle();
                    playerCtrl.playTrack(downloaded.first, queue: downloaded);
                  },
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.shuffle,
                        size: 14.sp,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Shuffle',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          for (final track in downloaded)
            MusicTrackCard(
              track: track,
              onTap: () {
                playerCtrl.playTrack(track, queue: downloaded);
                Get.toNamed(AppRoutes.player, arguments: track);
              },
              onMoreTap: () => TrackOptionsSheet.show(
                Get.overlayContext ?? Get.context,
                track,
              ),
            ),
          SizedBox(height: 20.h),
        ],
      );
    });
  }

  Widget _buildLibraryPill(
    String title, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.black : AppColors.textPrimary,
            fontSize: 12.sp,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _showCreateOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            systemNavigationBarColor: Color(0xFF1F1F1F),
            systemNavigationBarIconBrightness: Brightness.light,
            systemNavigationBarDividerColor: Colors.transparent,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
            ),
            child: SafeArea(
              top: false,
              bottom: true,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pull Handle
                    Container(
                      width: 38.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Create',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    // Option 1: Playlist
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 48.w,
                        height: 48.w,
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceLight,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.music_note_list,
                          color: Colors.white,
                          size: 24.sp,
                        ),
                      ),
                      title: Text(
                        'Playlist',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Build a playlist with custom songs & icon',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.sp,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(bottomSheetContext);
                        _showCreatePlaylistSheet(context);
                      },
                    ),
                    SizedBox(height: 8.h),
                    // Option 2: Blend
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 48.w,
                        height: 48.w,
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceLight,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.person_2_fill,
                          color: Colors.white,
                          size: 22.sp,
                        ),
                      ),
                      title: Text(
                        'Blend',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Combine tastes in a shared playlist with friends',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.sp,
                        ),
                      ),
                      onTap: () async {
                        Navigator.pop(bottomSheetContext);
                        await controller.createCustomPlaylist('Friends Blend', 'party');
                        Get.snackbar(
                          'Blend Created',
                          'Your blend playlist is ready in Your Library!',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppColors.surfaceLight,
                          colorText: AppColors.textPrimary,
                          duration: const Duration(seconds: 2),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCreatePlaylistSheet(BuildContext context) {
    final textController = TextEditingController();
    final selectedIcon = 'music_note'.obs;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            systemNavigationBarColor: Color(0xFF191919),
            systemNavigationBarIconBrightness: Brightness.light,
            systemNavigationBarDividerColor: Colors.transparent,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF191919),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              child: SafeArea(
                top: false,
                bottom: true,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 16.h),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 38.w,
                            height: 4.h,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(2.r),
                            ),
                          ),
                        ),
                        SizedBox(height: 18.h),
                        Text(
                          'Create Playlist',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 18.h),
                        // Live Icon Preview
                        Center(
                          child: Obx(() {
                            final iconKey = selectedIcon.value;
                            return Container(
                              width: 72.w,
                              height: 72.w,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: PlaylistIconHelper.getGradient(iconKey),
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: PlaylistIconHelper.getGradient(iconKey)
                                        .first
                                        .withValues(alpha: 0.4),
                                    blurRadius: 16.r,
                                    offset: Offset(0, 6.h),
                                  ),
                                ],
                              ),
                              child: Icon(
                                PlaylistIconHelper.getIcon(iconKey),
                                color: Colors.white,
                                size: 36.sp,
                              ),
                            );
                          }),
                        ),
                        SizedBox(height: 20.h),
                        // Name TextField
                        TextField(
                          controller: textController,
                          autofocus: true,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          cursorColor: AppColors.primary,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.surfaceLight,
                            hintText:
                                'My Playlist #${controller.customPlaylists.length + 1}',
                            hintStyle: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14.5.sp,
                              fontWeight: FontWeight.w400,
                            ),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(
                                CupertinoIcons.clear_circled_solid,
                                color: AppColors.textMuted,
                              ),
                              onPressed: () => textController.clear(),
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),
                        Text(
                          'Choose an icon',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        // Icon Selection Row
                        SizedBox(
                          height: 58.h,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: PlaylistIconHelper.icons.keys.length,
                            separatorBuilder: (context, index) =>
                                SizedBox(width: 10.w),
                            itemBuilder: (context, index) {
                              final key =
                                  PlaylistIconHelper.icons.keys.elementAt(index);
                              return Obx(() {
                                final isSelected = selectedIcon.value == key;
                                final gradient =
                                    PlaylistIconHelper.getGradient(key);

                                return GestureDetector(
                                  onTap: () => selectedIcon.value = key,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: 52.w,
                                    height: 52.w,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: gradient,
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(10.r),
                                      border: isSelected
                                          ? Border.all(
                                              color: Colors.white, width: 2.5)
                                          : null,
                                    ),
                                    child: Icon(
                                      PlaylistIconHelper.getIcon(key),
                                      color: Colors.white,
                                      size: 24.sp,
                                    ),
                                  ),
                                );
                              });
                            },
                          ),
                        ),
                        SizedBox(height: 28.h),
                        // Action buttons: Cancel and Create
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(bottomSheetContext),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 13.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24.r),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14.5.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  final name = textController.text.trim();
                                  Navigator.pop(bottomSheetContext);
                                  await controller.createCustomPlaylist(
                                    name,
                                    selectedIcon.value,
                                  );
                                  Get.snackbar(
                                    'Playlist Created',
                                    'Added to Your Library',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: AppColors.surfaceLight,
                                    colorText: AppColors.textPrimary,
                                    duration: const Duration(seconds: 2),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: EdgeInsets.symmetric(vertical: 13.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24.r),
                                  ),
                                ),
                                child: Text(
                                  'Create',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14.5.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPlaylistOptions(BuildContext context, PlaylistModel playlist) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            systemNavigationBarColor: Color(0xFF1F1F1F),
            systemNavigationBarIconBrightness: Brightness.light,
            systemNavigationBarDividerColor: Colors.transparent,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
            ),
            child: SafeArea(
              top: false,
              bottom: true,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 38.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      playlist.name,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    ListTile(
                      leading:
                          const Icon(CupertinoIcons.trash, color: Colors.redAccent),
                      title: const Text('Delete Playlist',
                          style: TextStyle(color: Colors.redAccent)),
                      onTap: () async {
                        Navigator.pop(bottomSheetContext);
                        await controller.deleteCustomPlaylist(playlist.id);
                        Get.snackbar(
                          'Deleted',
                          'Playlist "${playlist.name}" removed',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppColors.surfaceLight,
                          colorText: AppColors.textPrimary,
                          duration: const Duration(seconds: 2),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Pinned sticky header delegate for CategorySelectorBar on the Home screen
class _StickyCategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _StickyCategoryHeaderDelegate({
    required this.child,
    required this.height,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      height: height,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _StickyCategoryHeaderDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}

class _KeepAliveTab extends StatefulWidget {
  final Widget child;
  const _KeepAliveTab({required this.child});

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

