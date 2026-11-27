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
import '../models/blend_model.dart';
import '../models/playlist_model.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';
import '../services/blend_service.dart';
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

class MusicCatalogueScreen extends StatefulWidget {
  const MusicCatalogueScreen({super.key});

  @override
  State<MusicCatalogueScreen> createState() => _MusicCatalogueScreenState();
}

class _MusicCatalogueScreenState extends State<MusicCatalogueScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final MusicController controller;
  Worker? _tabWorker;

  @override
  void initState() {
    super.initState();
    controller = Get.find<MusicController>();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: controller.currentTabIndex.value.clamp(0, 2),
    );
    controller.tabController = _tabController;

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        if (controller.currentTabIndex.value != _tabController.index) {
          controller.currentTabIndex.value = _tabController.index;
        }
      }
    });

    _tabWorker = ever<int>(controller.currentTabIndex, (newIndex) {
      if (mounted && _tabController.index != newIndex) {
        _tabController.animateTo(newIndex);
      }
    });
  }

  @override
  void dispose() {
    _tabWorker?.dispose();
    if (controller.tabController == _tabController) {
      controller.tabController = null;
    }
    _tabController.dispose();
    super.dispose();
  }

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
          body: TabBarView(
            controller: _tabController,
            physics: const BouncingScrollPhysics(),
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
                    tabController: _tabController,
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
          // 1. Sticky Horizontal Genre / Category Filter Bar (Pins to top right after App Bar!)
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

          // 2. Spotify-Style Featured Artist & Liked Songs Quick-Access Grid (Shown on 'All')
          Obx(() {
            if (controller.selectedCategory.value != 'All') {
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }
            return SliverToBoxAdapter(
              child: SpotifyArtistSelector(
                artists: controller.featuredArtists,
                selectedArtist: controller.selectedArtist.value,
                onArtistSelected: (artist) {
                  Get.toNamed(AppRoutes.artist, arguments: artist);
                },
                onLikedSongsSelected: () {
                  controller.changeTab(2);
                  controller.openLikedSongs();
                },
              ),
            );
          }),

          // Suggested for You Shelf (Built from repeat listening & user history, shown on 'All')
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
            final isFilteringCategory = controller.selectedCategory.value != 'All';
            final displayCount = (isFilteringCategory || isExpanded || allTracks.length <= 10)
                ? allTracks.length
                : 10;

            return SliverMainAxisGroup(
              slivers: [
                // Category / All Songs Section Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 6.h),
                    child: Row(
                      children: [
                        Text(
                          isFilteringCategory
                              ? '${controller.selectedCategory.value} Songs'
                              : 'All Songs',
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

                // Songs List (max 10 initially on All, expands when See more is clicked; all shown when filtering)
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

                // See more / Show less toggle button if more than 10 tracks on All view
                if (allTracks.length > 10 && !isFilteringCategory)
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



  Widget _buildUserProfileTile() {
    final auth = Get.isRegistered<AuthService>()
        ? Get.find<AuthService>()
        : Get.put(AuthService());

    return Obx(() {
      final isLoggedIn = auth.isLoggedIn.value;
      final userName = auth.userName.value;
      final userEmail = auth.userEmail.value;
      final userPhoto = auth.userPhotoUrl.value;

      return Container(
        margin: EdgeInsets.only(bottom: 14.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1DB954).withValues(alpha: isLoggedIn ? 0.22 : 0.16),
              const Color(0xFF242424),
              const Color(0xFF181818),
            ],
          ),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isLoggedIn
                ? const Color(0xFF1DB954).withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.12),
            width: 1.2.w,
          ),
          boxShadow: [
            BoxShadow(
              color: isLoggedIn
                  ? const Color(0xFF1DB954).withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14.r),
            onTap: () {
              if (isLoggedIn) {
                _showAccountBottomSheet(context, auth);
              } else {
                _showGoogleSignInBottomSheet(context);
              }
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withValues(alpha: 0.4),
                        ],
                      ),
                    ),
                    child: ClipOval(
                      child: userPhoto.isNotEmpty
                          ? Image.network(
                              userPhoto,
                              width: 38.w,
                              height: 38.w,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildAvatarFallback(isLoggedIn, userName),
                            )
                          : _buildAvatarFallback(isLoggedIn, userName),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                isLoggedIn
                                    ? (userName.isNotEmpty ? userName : 'Music Lover')
                                    : 'Sign in to WhatsPlay',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14.5.sp,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isLoggedIn) ...[
                              SizedBox(width: 4.w),
                              Icon(
                                Icons.verified_rounded,
                                color: AppColors.primary,
                                size: 14.sp,
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          isLoggedIn
                              ? (userEmail.isNotEmpty ? userEmail : 'Google Account Connected')
                              : 'Sync your liked songs & playlists with Google',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  if (!isLoggedIn)
                    InkWell(
                      borderRadius: BorderRadius.circular(18.r),
                      onTap: () => _showGoogleSignInBottomSheet(context),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(18.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.login_rounded, size: 13.sp, color: Colors.black),
                            SizedBox(width: 4.w),
                            Text(
                              'Sign In',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    InkWell(
                      borderRadius: BorderRadius.circular(14.r),
                      onTap: () => _showSignOutDialog(context, auth),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              color: Colors.white70,
                              size: 13.sp,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'Sign out',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildAvatarFallback(bool isLoggedIn, String name) {
    if (isLoggedIn && name.trim().isNotEmpty) {
      final initial = name.trim()[0].toUpperCase();
      return Container(
        width: 38.w,
        height: 38.w,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.black,
            fontSize: 16.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }
    return Container(
      width: 38.w,
      height: 38.w,
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        shape: BoxShape.circle,
      ),
      child: Icon(
        CupertinoIcons.person_crop_circle_fill,
        color: AppColors.primary,
        size: 24.sp,
      ),
    );
  }

  void _showGoogleSignInBottomSheet(
    BuildContext context, {
    String? subtitle,
    VoidCallback? onSuccess,
  }) {
    final auth = Get.isRegistered<AuthService>() ? AuthService.to : null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            systemNavigationBarColor: Color(0xFF191919),
            systemNavigationBarIconBrightness: Brightness.light,
            systemNavigationBarDividerColor: Colors.transparent,
          ),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 18.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF242424), Color(0xFF141414)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(height: 22.h),
                  Container(
                    width: 58.w,
                    height: 58.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.25),
                          AppColors.primary.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.group_add_rounded,
                        color: AppColors.primary,
                        size: 28.sp,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Sign in with Google',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    subtitle ??
                        'Connect your Google account to sync playlists, liked songs, and create shared Blends with friends.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13.sp,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildSignInBenefit(
                          Icons.merge_type_rounded,
                          'Create & share Blend playlists with friends',
                        ),
                        SizedBox(height: 8.h),
                        _buildSignInBenefit(
                          Icons.cloud_sync_rounded,
                          'Sync liked songs & history across devices',
                        ),
                        SizedBox(height: 8.h),
                        _buildSignInBenefit(
                          Icons.backup_rounded,
                          'Securely back up your custom playlists',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 22.h),
                  if (auth != null)
                    Obx(() {
                      final isLoading = auth.isLoading.value;
                      return SizedBox(
                        width: double.infinity,
                        height: 48.h,
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  final success = await auth.signInWithGoogle();
                                  if (success && sheetContext.mounted) {
                                    Navigator.pop(sheetContext);
                                    Get.snackbar(
                                      'Welcome back!',
                                      'Signed in as ${auth.userName.value}',
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor: AppColors.surfaceLight,
                                      colorText: AppColors.textPrimary,
                                      duration: const Duration(seconds: 2),
                                    );
                                    onSuccess?.call();
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24.r),
                            ),
                          ),
                          child: isLoading
                              ? SizedBox(
                                  width: 20.w,
                                  height: 20.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 20.w,
                                      height: 20.w,
                                      alignment: Alignment.center,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        'G',
                                        style: TextStyle(
                                          color: const Color(0xFF4285F4),
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10.w),
                                    Text(
                                      'Continue with Google',
                                      style: TextStyle(
                                        fontSize: 14.5.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      );
                    }),
                  SizedBox(height: 10.h),
                  TextButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                    child: Text(
                      'Not Now',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSignInBenefit(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: AppColors.primary),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: AppColors.textPrimary.withValues(alpha: 0.9),
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _showAccountBottomSheet(BuildContext context, AuthService auth) {
    final playerCtrl = Get.isRegistered<PlayerController>()
        ? Get.find<PlayerController>()
        : null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            systemNavigationBarColor: Color(0xFF191919),
            systemNavigationBarIconBrightness: Brightness.light,
            systemNavigationBarDividerColor: Colors.transparent,
          ),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 18.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF242424), Color(0xFF141414)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: SafeArea(
              top: false,
              child: Obx(() {
                final userName = auth.userName.value;
                final userEmail = auth.userEmail.value;
                final userPhoto = auth.userPhotoUrl.value;
                final likedCount = playerCtrl?.likedTracks.length ?? 0;
                final playlistCount = controller.customPlaylists.length;
                final downloadCount = playerCtrl?.downloadedTracks.length ?? 0;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withValues(alpha: 0.3),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: userPhoto.isNotEmpty
                            ? Image.network(
                                userPhoto,
                                width: 56.w,
                                height: 56.w,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildAvatarFallback(true, userName),
                              )
                            : _buildAvatarFallback(true, userName),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            userName.isNotEmpty ? userName : 'Music Lover',
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
                      userEmail.isNotEmpty ? userEmail : 'Google Account Connected',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickStatTile(
                            'Liked',
                            likedCount.toString(),
                            Icons.favorite_rounded,
                            const Color(0xFFE91E63),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: _buildQuickStatTile(
                            'Playlists',
                            playlistCount.toString(),
                            Icons.playlist_play_rounded,
                            AppColors.primary,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: _buildQuickStatTile(
                            'Downloads',
                            downloadCount.toString(),
                            Icons.download_done_rounded,
                            const Color(0xFF00E5FF),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    SizedBox(
                      width: double.infinity,
                      height: 46.h,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _showSignOutDialog(context, auth);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFF5252),
                          side: BorderSide(
                            color: const Color(0xFFFF5252).withValues(alpha: 0.35),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(23.r),
                          ),
                        ),
                        icon: Icon(Icons.logout_rounded, size: 16.sp),
                        label: Text(
                          'Sign Out of Google',
                          style: TextStyle(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                      ),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickStatTile(
    String label,
    String value,
    IconData icon,
    Color accentColor,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18.sp, color: accentColor),
          SizedBox(height: 6.h),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, AuthService auth) {
    Get.defaultDialog(
      title: 'Sign Out',
      titleStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 17.sp,
        fontWeight: FontWeight.w800,
      ),
      middleText: 'Are you sure you want to sign out of your Google account?',
      middleTextStyle: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13.sp,
      ),
      backgroundColor: const Color(0xFF222222),
      radius: 16.r,
      textCancel: 'Cancel',
      cancelTextColor: AppColors.textSecondary,
      textConfirm: 'Sign Out',
      confirmTextColor: Colors.white,
      buttonColor: const Color(0xFFFF5252),
      onConfirm: () async {
        Get.back();
        await auth.signOut();
        Get.snackbar(
          'Signed Out',
          'You have signed out of Google.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.surfaceLight,
          colorText: AppColors.textPrimary,
          duration: const Duration(seconds: 2),
        );
      },
    );
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
            // User Profile Tile right after App Bar
            _buildUserProfileTile(),

            // Category Pills: Blends, Playlists, History, Downloaded, Artists
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildLibraryPill(
                    'Blends',
                    isSelected: currentFilter == 'Blends',
                    onTap: () => controller.selectLibraryFilter('Blends'),
                  ),
                  SizedBox(width: 8.w),
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
              child: currentFilter == 'Blends'
                  ? _buildBlendsSection()
                  : currentFilter == 'Artists'
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
                    // Option 2: Create Blend
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
                          Icons.auto_awesome_rounded,
                          color: AppColors.primary,
                          size: 22.sp,
                        ),
                      ),
                      title: Text(
                        'Create Blend',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Generate unique code & blend music with friends',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.sp,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(bottomSheetContext);
                        final auth = Get.isRegistered<AuthService>() ? AuthService.to : null;
                        if (auth != null && !auth.isLoggedIn.value) {
                          _showGoogleSignInBottomSheet(
                            context,
                            subtitle: 'Sign in with Google to create and host a Blend playlist with friends.',
                            onSuccess: () => _showCreateBlendSheet(context),
                          );
                          return;
                        }
                        _showCreateBlendSheet(context);
                      },
                    ),
                    SizedBox(height: 8.h),
                    // Option 3: Join Blend with Code
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
                          Icons.tag_rounded,
                          color: const Color(0xFF00E5FF),
                          size: 22.sp,
                        ),
                      ),
                      title: Text(
                        'Join with Code',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Enter a friend\'s 6-character code to join their Blend',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.sp,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(bottomSheetContext);
                        _showJoinBlendSheet(context);
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

  void _showCreateBlendSheet(BuildContext context) {
    final textController = TextEditingController(text: 'Our Blend');
    final blendService = Get.isRegistered<BlendService>() ? BlendService.to : Get.put(BlendService());
    final isCreating = false.obs;
    final selectedPreset = kBlendPresets.first.obs;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            systemNavigationBarColor: Color(0xFF191919),
            systemNavigationBarIconBrightness: Brightness.light,
            systemNavigationBarDividerColor: Colors.transparent,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 18.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF242424), Color(0xFF141414)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                    SizedBox(height: 18.h),
                    Text(
                      'Create a Shared Blend',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 19.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'A unique 6-character code will be generated. Share it with friends to blend music in real-time!',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5.sp,
                        height: 1.35,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20.h),
                    TextField(
                      controller: textController,
                      autofocus: true,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Blend Name',
                        labelStyle: TextStyle(
                          color: AppColors.primary,
                          fontSize: 14.sp,
                        ),
                        hintText: 'e.g. Weekend Vibes',
                        hintStyle: TextStyle(color: Colors.white30, fontSize: 14.sp),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          borderSide: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                        prefixIcon: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Choose Blend Emoji & Color Mood',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    SizedBox(
                      height: 48.h,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: kBlendPresets.length,
                        separatorBuilder: (context, index) => SizedBox(width: 8.w),
                        itemBuilder: (context, index) {
                          final preset = kBlendPresets[index];
                          final color = Color(int.parse('FF${preset.colorHex.replaceAll('#', '')}', radix: 16));
                          return Obx(() {
                            final isSelected = selectedPreset.value.icon == preset.icon;
                            return GestureDetector(
                              onTap: () => selectedPreset.value = preset,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: EdgeInsets.symmetric(horizontal: 12.w),
                                decoration: BoxDecoration(
                                  color: isSelected ? color.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(14.r),
                                  border: Border.all(
                                    color: isSelected ? color : Colors.white.withValues(alpha: 0.1),
                                    width: isSelected ? 1.8 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: color.withValues(alpha: 0.4),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          )
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(preset.icon, style: TextStyle(fontSize: 18.sp)),
                                    SizedBox(width: 6.w),
                                    Text(
                                      preset.label,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.white60,
                                        fontSize: 12.sp,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 22.h),
                    Obx(() {
                      final activePreset = selectedPreset.value;
                      final activeColor = Color(int.parse('FF${activePreset.colorHex.replaceAll('#', '')}', radix: 16));
                      return SizedBox(
                        width: double.infinity,
                        height: 48.h,
                        child: ElevatedButton(
                          onPressed: isCreating.value
                              ? null
                              : () async {
                                  final name = textController.text.trim();
                                  if (name.isEmpty) return;
                                  isCreating.value = true;
                                  final newBlend = await blendService.createBlend(
                                    name: name,
                                    icon: activePreset.icon,
                                    colorHex: activePreset.colorHex,
                                  );
                                  isCreating.value = false;
                                  if (newBlend != null && sheetContext.mounted) {
                                    Navigator.pop(sheetContext);
                                    Get.toNamed(AppRoutes.blendDetail, arguments: newBlend);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: activeColor,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24.r),
                            ),
                            elevation: 0,
                          ),
                          child: isCreating.value
                              ? SizedBox(
                                  width: 20.w,
                                  height: 20.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : Text(
                                  'Create & Get Code',
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black,
                                  ),
                                ),
                        ),
                      );
                    }),
                    SizedBox(height: 10.h),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showJoinBlendSheet(BuildContext context) {
    final codeController = TextEditingController();
    final blendService = Get.isRegistered<BlendService>() ? BlendService.to : Get.put(BlendService());
    final auth = Get.isRegistered<AuthService>() ? AuthService.to : null;
    final isJoining = false.obs;
    final errorMessage = ''.obs;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            systemNavigationBarColor: Color(0xFF191919),
            systemNavigationBarIconBrightness: Brightness.light,
            systemNavigationBarDividerColor: Colors.transparent,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 18.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF242424), Color(0xFF141414)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                    SizedBox(height: 18.h),
                    Text(
                      'Join a Friend\'s Blend',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 19.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Enter the 6-character code shared by your friend to blend your music together in real-time.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5.sp,
                        height: 1.35,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_rounded, size: 14, color: AppColors.primary),
                        SizedBox(width: 5.w),
                        Text(
                          'Joining as ${auth?.effectiveUserName ?? "Music Lover"}',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    TextField(
                      controller: codeController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.characters,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 8,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'CODE',
                        hintStyle: TextStyle(
                          color: Colors.white24,
                          fontSize: 24.sp,
                          letterSpacing: 8,
                          fontWeight: FontWeight.w700,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.r),
                          borderSide: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.r),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                      onChanged: (val) {
                        errorMessage.value = '';
                      },
                    ),
                    Obx(() {
                      if (errorMessage.value.isNotEmpty) {
                        return Padding(
                          padding: EdgeInsets.only(top: 8.h),
                          child: Text(
                            errorMessage.value,
                            style: TextStyle(
                              color: const Color(0xFFFF5252),
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                    SizedBox(height: 22.h),
                    Obx(() {
                      return SizedBox(
                        width: double.infinity,
                        height: 48.h,
                        child: ElevatedButton(
                          onPressed: isJoining.value
                              ? null
                              : () async {
                                  final code = codeController.text.trim();
                                  if (code.length != 6) {
                                    errorMessage.value = 'Please enter a valid 6-character code.';
                                    return;
                                  }
                                  isJoining.value = true;
                                  final result = await blendService.joinBlendWithCode(
                                    code,
                                    guestName: (auth != null && !auth.isLoggedIn.value)
                                        ? auth.effectiveUserName
                                        : null,
                                  );
                                  isJoining.value = false;

                                  if (result['success'] == true && sheetContext.mounted) {
                                    Navigator.pop(sheetContext);
                                    final blend = result['blend'] as BlendModel?;
                                    if (blend != null) {
                                      Get.toNamed(AppRoutes.blendDetail, arguments: blend);
                                    }
                                  } else {
                                    errorMessage.value = result['message']?.toString() ?? 'Failed to join Blend';
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24.r),
                            ),
                            elevation: 0,
                          ),
                          child: isJoining.value
                              ? SizedBox(
                                  width: 20.w,
                                  height: 20.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : Text(
                                  'Join Blend',
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black,
                                  ),
                                ),
                        ),
                      );
                    }),
                    SizedBox(height: 10.h),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBlendsSection() {
    final blendService = Get.isRegistered<BlendService>()
        ? BlendService.to
        : Get.put(BlendService());

    return Obx(() {
      final blends = blendService.userBlends;

      return ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final auth = Get.isRegistered<AuthService>() ? AuthService.to : null;
                      if (auth != null && !auth.isLoggedIn.value) {
                        _showGoogleSignInBottomSheet(
                          context,
                          subtitle: 'Sign in with Google to create and host a Blend playlist with friends.',
                          onSuccess: () => _showCreateBlendSheet(context),
                        );
                        return;
                      }
                      _showCreateBlendSheet(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      elevation: 0,
                    ),
                    icon: Icon(Icons.add_rounded, size: 18.sp, color: Colors.black),
                    label: Text(
                      'Create Blend',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showJoinBlendSheet(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                    ),
                    icon: Icon(Icons.tag_rounded, size: 16.sp, color: AppColors.primary),
                    label: Text(
                      'Join with Code',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),

          if (blends.isEmpty)
            _buildBlendEmptyStateCard()
          else
            ...blends.map((blend) => _buildBlendCard(blend)),
        ],
      );
    });
  }

  Widget _buildBlendCard(BlendModel blend) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () {
            Get.toNamed(AppRoutes.blendDetail, arguments: blend);
          },
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                Container(
                  width: 52.w,
                  height: 52.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14.r),
                    gradient: LinearGradient(
                      colors: blend.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: blend.themeColor.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      blend.icon,
                      style: TextStyle(fontSize: 24.sp),
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        blend.name,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${blend.tracksCount} ${blend.tracksCount == 1 ? 'song' : 'songs'} • ${blend.members.length} ${blend.members.length == 1 ? 'member' : 'members'}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15.sp,
                  color: Colors.white38,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlendEmptyStateCard() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.auto_awesome_rounded, size: 40.sp, color: AppColors.primary),
          SizedBox(height: 12.h),
          Text(
            'No Blends Yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Tap "Create Blend" to get a unique 6-character code, or tap "Join with Code" to connect with a friend\'s Blend.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5.sp,
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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

