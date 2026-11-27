import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_constants.dart';
import '../models/artist_category_model.dart';
import '../models/audio_verification_model.dart';
import '../models/playlist_model.dart';
import '../models/track_model.dart';
import '../repositories/music_repository.dart';
import '../services/local_database_service.dart';

enum ViewState {
  initial,
  loading,
  success,
  empty,
  error,
}

class MusicController extends GetxController {
  final IMusicRepository _repository;
  final ILocalDatabaseService _databaseService;

  MusicController(
    this._repository, {
    ILocalDatabaseService? databaseService,
  }) : _databaseService = databaseService ?? LocalDatabaseService();

  // Observable state
  final Rx<ViewState> state = ViewState.initial.obs;
  final RxList<TrackModel> tracks = <TrackModel>[].obs;
  final RxString errorMessage = ''.obs;

  // Selected Category / Genre
  final RxString selectedCategory = 'All'.obs;
  final List<String> categories = AppConstants.musicCategories;

  // Selected Spotify-style Artist / Regional category
  final Rx<ArtistCategoryModel?> selectedArtist = Rx<ArtistCategoryModel?>(null);
  final List<ArtistCategoryModel> featuredArtists = AppConstants.featuredArtists;

  // Track audio verification map: trackId -> AudioVerificationModel
  final RxMap<String, AudioVerificationModel> audioVerifications =
      <String, AudioVerificationModel>{}.obs;

  // TrackIds currently being actively verified
  final RxSet<String> verifyingTrackIds = <String>{}.obs;

  // Optional TabController attached by the view for native TabBar and TabBarView direct transitions
  TabController? tabController;

  // Bottom Navigation Active Tab (0: Home, 1: Search, 2: Your Library)
  final RxInt currentTabIndex = 0.obs;

  // PageController for smooth tab navigation
  late final PageController pageController = PageController(initialPage: currentTabIndex.value);

  // In Library tab: viewing liked songs detail playlist
  final RxBool isViewingLikedSongs = false.obs;

  // Double-tap back timestamp for home screen exit debounce
  DateTime? lastBackPressTime;

  /// Handles back navigation stack within MusicCatalogueScreen:
  /// 1. If viewing liked songs detail -> close it and return to Library (returns true).
  /// 2. If viewing a custom playlist detail -> close it and return to Library (returns true).
  /// 3. If on a non-Home tab (Search or Library) -> switch to Home tab (returns true).
  /// 4. If on Home tab -> requires a second back press within 2 seconds to exit (returns true on first press, false to allow exit on second press).
  bool handleBackPress() {
    if (isViewingLikedSongs.value) {
      closeLikedSongs();
      lastBackPressTime = null;
      return true;
    }
    if (activeCustomPlaylist.value != null) {
      closeCustomPlaylist();
      lastBackPressTime = null;
      return true;
    }
    if (currentTabIndex.value != 0) {
      changeTab(0);
      lastBackPressTime = null;
      return true;
    }
    final now = DateTime.now();
    if (lastBackPressTime == null ||
        now.difference(lastBackPressTime!) > const Duration(seconds: 2)) {
      lastBackPressTime = now;
      return true;
    }
    return false;
  }

  void openLikedSongs() {
    isViewingLikedSongs.value = true;
  }

  void closeLikedSongs() {
    isViewingLikedSongs.value = false;
  }

  // Library tab filter: 'Playlists' | 'Artists'
  final RxString selectedLibraryFilter = 'Playlists'.obs;

  void selectLibraryFilter(String filter) {
    selectedLibraryFilter.value = filter;
  }

  // Followed artists collection
  final RxList<ArtistCategoryModel> followedArtists = <ArtistCategoryModel>[].obs;
  final RxSet<String> followedArtistIds = <String>{}.obs;

  bool isArtistFollowed(String artistId) => followedArtistIds.contains(artistId);

  Future<void> toggleFollowArtist(ArtistCategoryModel artist) async {
    if (followedArtistIds.contains(artist.id)) {
      followedArtistIds.remove(artist.id);
      followedArtists.removeWhere((a) => a.id == artist.id);
      try {
        await _databaseService.removeFollowedArtist(artist.id);
        debugPrint('[MusicController] Unfollowed artist: ${artist.name}');
      } catch (e) {
        debugPrint('[MusicController] Error unfollowing artist: $e');
      }
    } else {
      followedArtistIds.add(artist.id);
      if (!followedArtists.any((a) => a.id == artist.id)) {
        followedArtists.insert(0, artist);
      }
      try {
        await _databaseService.saveFollowedArtist(artist);
        debugPrint('[MusicController] Followed artist: ${artist.name}');
      } catch (e) {
        debugPrint('[MusicController] Error saving followed artist: $e');
      }
    }
  }

  Future<void> loadFollowedArtists() async {
    try {
      final savedArtists = await _databaseService.getFollowedArtists();
      followedArtists.assignAll(savedArtists);
      followedArtistIds.assignAll(savedArtists.map((a) => a.id));
      debugPrint('[MusicController] Loaded ${savedArtists.length} followed artists from SQLite.');
    } catch (e) {
      debugPrint('[MusicController] Error loading followed artists: $e');
    }
  }

  // Custom user playlists / collections
  final RxList<PlaylistModel> customPlaylists = <PlaylistModel>[].obs;

  Future<void> loadCustomPlaylists() async {
    try {
      final list = await _databaseService.getCustomPlaylists();
      customPlaylists.assignAll(list);
      debugPrint('[MusicController] Loaded ${list.length} custom playlists from SQLite.');
    } catch (e) {
      debugPrint('[MusicController] Error loading custom playlists: $e');
    }
  }

  Future<PlaylistModel> createCustomPlaylist(String name, String iconKey) async {
    final playlist = PlaylistModel(
      id: 'pl_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim().isEmpty ? 'My Playlist #${customPlaylists.length + 1}' : name.trim(),
      iconKey: iconKey,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      songCount: 0,
    );
    customPlaylists.insert(0, playlist);
    try {
      await _databaseService.saveCustomPlaylist(playlist);
      debugPrint('[MusicController] Saved custom playlist: "${playlist.name}" to SQLite.');
    } catch (e) {
      debugPrint('[MusicController] Error saving custom playlist: $e');
    }
    return playlist;
  }

  Future<void> deleteCustomPlaylist(String playlistId) async {
    customPlaylists.removeWhere((p) => p.id == playlistId);
    if (activeCustomPlaylist.value?.id == playlistId) {
      closeCustomPlaylist();
    }
    try {
      await _databaseService.removeCustomPlaylist(playlistId);
      debugPrint('[MusicController] Removed custom playlist ($playlistId) from SQLite.');
    } catch (e) {
      debugPrint('[MusicController] Error removing custom playlist: $e');
    }
  }

  // Active custom playlist viewing in Your Library
  final Rx<PlaylistModel?> activeCustomPlaylist = Rx<PlaylistModel?>(null);
  final RxList<TrackModel> activePlaylistTracks = <TrackModel>[].obs;
  final RxBool isLoadingPlaylistTracks = false.obs;

  Future<void> openCustomPlaylist(PlaylistModel playlist) async {
    activeCustomPlaylist.value = playlist;
    isLoadingPlaylistTracks.value = true;
    try {
      final list = await _databaseService.getTracksForPlaylist(playlist.id);
      activePlaylistTracks.assignAll(list);
      debugPrint('[MusicController] Loaded ${list.length} tracks for playlist "${playlist.name}".');
    } catch (e) {
      debugPrint('[MusicController] Error loading playlist tracks: $e');
    } finally {
      isLoadingPlaylistTracks.value = false;
    }
  }

  void closeCustomPlaylist() {
    activeCustomPlaylist.value = null;
    activePlaylistTracks.clear();
  }

  Future<void> addTrackToPlaylist(String playlistId, TrackModel track) async {
    try {
      await _databaseService.addTrackToPlaylist(playlistId, track);
      final newCount = await _databaseService.getPlaylistSongCount(playlistId);

      final idx = customPlaylists.indexWhere((p) => p.id == playlistId);
      if (idx != -1) {
        customPlaylists[idx] = customPlaylists[idx].copyWith(songCount: newCount);
      }

      if (activeCustomPlaylist.value?.id == playlistId) {
        activeCustomPlaylist.value = activeCustomPlaylist.value!.copyWith(songCount: newCount);
        if (!activePlaylistTracks.any((t) => t.trackId == track.trackId)) {
          activePlaylistTracks.insert(0, track);
        }
      }
      debugPrint('[MusicController] Added track "${track.title}" to playlist $playlistId.');
    } catch (e) {
      debugPrint('[MusicController] Error adding track to playlist: $e');
    }
  }

  Future<void> removeTrackFromPlaylist(String playlistId, String trackId) async {
    try {
      await _databaseService.removeTrackFromPlaylist(playlistId, trackId);
      final newCount = await _databaseService.getPlaylistSongCount(playlistId);

      final idx = customPlaylists.indexWhere((p) => p.id == playlistId);
      if (idx != -1) {
        customPlaylists[idx] = customPlaylists[idx].copyWith(songCount: newCount);
      }

      if (activeCustomPlaylist.value?.id == playlistId) {
        activeCustomPlaylist.value = activeCustomPlaylist.value!.copyWith(songCount: newCount);
        activePlaylistTracks.removeWhere((t) => t.trackId == trackId);
      }
      debugPrint('[MusicController] Removed track $trackId from playlist $playlistId.');
    } catch (e) {
      debugPrint('[MusicController] Error removing track from playlist: $e');
    }
  }

  Future<bool> isTrackInPlaylist(String playlistId, String trackId) async {
    return await _databaseService.isTrackInPlaylist(playlistId, trackId);
  }

  // Search tab state
  final RxString searchQuery = ''.obs;
  final RxList<TrackModel> searchResults = <TrackModel>[].obs;
  final RxBool isSearching = false.obs;
  final TextEditingController searchTextController = TextEditingController();
  Timer? _searchDebounceTimer;

  void onSearchQueryChanged(String query) {
    searchQuery.value = query;
    _searchDebounceTimer?.cancel();

    if (query.trim().isEmpty) {
      searchResults.clear();
      isSearching.value = false;
      return;
    }

    isSearching.value = true;
    _searchDebounceTimer = Timer(const Duration(milliseconds: 350), () {
      performSearch(query.trim());
    });
  }

  Future<void> performSearch(String query) async {
    final cleanQuery = query.trim();
    searchQuery.value = cleanQuery;
    _searchDebounceTimer?.cancel();

    if (cleanQuery.isEmpty) {
      searchResults.clear();
      isSearching.value = false;
      return;
    }

    isSearching.value = true;
    try {
      final results = await _repository.searchTracks(cleanQuery);
      if (searchQuery.value == cleanQuery) {
        searchResults.assignAll(results);
      }
    } catch (e) {
      debugPrint('[MusicController] Search error: $e');
    } finally {
      if (searchQuery.value == cleanQuery) {
        isSearching.value = false;
      }
    }
  }

  void clearSearch() {
    _searchDebounceTimer?.cancel();
    searchTextController.clear();
    searchQuery.value = '';
    searchResults.clear();
    isSearching.value = false;
  }

  @override
  void onClose() {
    _searchDebounceTimer?.cancel();
    searchTextController.dispose();
    pageController.dispose();
    super.onClose();
  }

  void changeTab(int index) {
    if (currentTabIndex.value == index) return;
    currentTabIndex.value = index;
    if (tabController != null && tabController!.index != index) {
      tabController!.animateTo(index);
    } else if (pageController.hasClients && pageController.page?.round() != index) {
      pageController.jumpToPage(index);
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchTracks();
    loadFollowedArtists();
    loadCustomPlaylists();
    loadSuggestions();
    loadListeningHistory();
    loadTrendingTracks();
    loadNewReleases();
    loadTopCharts();
    loadRomanticTracks();
    loadPartyTracks();
  }

  // All Songs expansion state in Home (initial max 10, expandable via See more)
  final RxBool isAllSongsExpanded = false.obs;

  void toggleExpandAllSongs() {
    isAllSongsExpanded.toggle();
  }

  // Trending Songs Shelf
  final RxList<TrackModel> trendingTracks = <TrackModel>[].obs;
  final RxBool isLoadingTrending = false.obs;

  Future<void> loadTrendingTracks() async {
    isLoadingTrending.value = true;
    try {
      final results = await _repository.getTrendingChartTracks(limit: 20);
      if (results.isNotEmpty) {
        trendingTracks.assignAll(results);
      } else {
        final fallback = await _repository.getTracks(genre: 'Top Bollywood', limit: 20);
        trendingTracks.assignAll(fallback);
      }
      debugPrint('[MusicController] Loaded ${trendingTracks.length} real trending tracks.');
    } catch (e) {
      debugPrint('[MusicController] Error loading trending tracks: $e');
    } finally {
      isLoadingTrending.value = false;
    }
  }

  // New Releases Shelf (Taaza Tunes & fresh music drops)
  final RxList<TrackModel> newReleases = <TrackModel>[].obs;
  final RxBool isLoadingNewReleases = false.obs;

  Future<void> loadNewReleases() async {
    isLoadingNewReleases.value = true;
    try {
      final results = await _repository.getNewReleases(limit: 20);
      if (results.isNotEmpty) {
        newReleases.assignAll(results);
      } else {
        final fallback = await _repository.searchTracks('Latest Hindi Hits', limit: 20);
        newReleases.assignAll(fallback);
      }
      debugPrint('[MusicController] Loaded ${newReleases.length} new release tracks.');
    } catch (e) {
      debugPrint('[MusicController] Error loading new releases: $e');
    } finally {
      isLoadingNewReleases.value = false;
    }
  }

  // Top Charts (India Superhits Top 50)
  final RxList<TrackModel> topCharts = <TrackModel>[].obs;
  final RxBool isLoadingTopCharts = false.obs;

  Future<void> loadTopCharts() async {
    isLoadingTopCharts.value = true;
    try {
      final results = await _repository.getTopCharts(limit: 50);
      if (results.isNotEmpty) {
        topCharts.assignAll(results);
      } else {
        final fallback = await _repository.searchTracks('India Superhits Top 50', limit: 25);
        topCharts.assignAll(fallback);
      }
      debugPrint('[MusicController] Loaded ${topCharts.length} top charts tracks.');
    } catch (e) {
      debugPrint('[MusicController] Error loading top charts: $e');
    } finally {
      isLoadingTopCharts.value = false;
    }
  }

  // Romantic Melodies (Love & Soul Hits)
  final RxList<TrackModel> romanticTracks = <TrackModel>[].obs;
  final RxBool isLoadingRomantic = false.obs;

  Future<void> loadRomanticTracks() async {
    isLoadingRomantic.value = true;
    try {
      final results = await _repository.getRomanticTracks(limit: 25);
      if (results.isNotEmpty) {
        romanticTracks.assignAll(results);
      } else {
        final fallback = await _repository.searchTracks('Romantic Hindi Hits', limit: 20);
        romanticTracks.assignAll(fallback);
      }
      debugPrint('[MusicController] Loaded ${romanticTracks.length} romantic tracks.');
    } catch (e) {
      debugPrint('[MusicController] Error loading romantic tracks: $e');
    } finally {
      isLoadingRomantic.value = false;
    }
  }

  // Party & Dance Anthems (Club bangers & high energy hits)
  final RxList<TrackModel> partyTracks = <TrackModel>[].obs;
  final RxBool isLoadingParty = false.obs;

  Future<void> loadPartyTracks() async {
    isLoadingParty.value = true;
    try {
      final results = await _repository.getPartyTracks(limit: 25);
      if (results.isNotEmpty) {
        partyTracks.assignAll(results);
      } else {
        final fallback = await _repository.searchTracks('Bollywood Party Dance', limit: 20);
        partyTracks.assignAll(fallback);
      }
      debugPrint('[MusicController] Loaded ${partyTracks.length} party tracks.');
    } catch (e) {
      debugPrint('[MusicController] Error loading party tracks: $e');
    } finally {
      isLoadingParty.value = false;
    }
  }

  // Listening History
  final RxList<TrackModel> listeningHistory = <TrackModel>[].obs;
  final RxBool isLoadingHistory = false.obs;

  Future<void> loadListeningHistory() async {
    isLoadingHistory.value = true;
    try {
      final history = await _databaseService.getListeningHistory(limit: 100);
      listeningHistory.assignAll(history);
      debugPrint('[MusicController] Loaded ${history.length} listening history tracks.');
    } catch (e) {
      debugPrint('[MusicController] Error loading listening history: $e');
    } finally {
      isLoadingHistory.value = false;
    }
  }

  Map<String, List<TrackModel>> get groupedListeningHistory {
    final Map<String, List<TrackModel>> groups = {};
    for (final track in listeningHistory) {
      final label = track.dayLabel;
      groups.putIfAbsent(label, () => []).add(track);
    }
    return groups;
  }

  // Suggested Songs built dynamically from user's listening preferences
  final RxList<TrackModel> suggestedTracks = <TrackModel>[].obs;
  final RxBool isLoadingSuggestions = false.obs;
  final RxString suggestionSubtitle =
      'Fresh popular hits based on your listening'.obs;

  /// Called whenever a track starts playing: removes already played track from suggestions
  void onTrackPlayed(TrackModel track) {
    suggestedTracks.removeWhere((t) => t.trackId == track.trackId);
    loadListeningHistory();
    if (suggestedTracks.length < 5 && !isLoadingSuggestions.value) {
      loadSuggestions();
    }
  }

  /// Categorizes a track into high-level Indian/Global music categories (Punjabi, Hindi, Gujarati, etc.)
  String? _detectCategory(TrackModel track) {
    final g = track.genre.toLowerCase();
    if (g.contains('punjabi')) return 'Punjabi';
    if (g.contains('hindi') || g.contains('bollywood')) return 'Hindi';
    if (g.contains('gujarati')) return 'Gujarati';
    if (g.contains('pop') || g.contains('english')) return 'Pop';
    if (g.contains('hip-hop') || g.contains('rap')) return 'Hip-Hop/Rap';

    final a = track.artistName.toLowerCase();
    if (a.contains('diljit') ||
        a.contains('sidhu') ||
        a.contains('karan aujla') ||
        a.contains('ap dhillon') ||
        a.contains('ammy')) {
      return 'Punjabi';
    }
    if (a.contains('arijit') ||
        a.contains('honey singh') ||
        a.contains('badshah') ||
        a.contains('shreya') ||
        a.contains('jubin') ||
        a.contains('neha')) {
      return 'Hindi';
    }
    if (a.contains('jignesh') ||
        a.contains('geeta rabari') ||
        a.contains('kinjal dave')) {
      return 'Gujarati';
    }

    if (track.genre.isNotEmpty &&
        track.genre.toLowerCase() != 'general' &&
        track.genre.toLowerCase() != 'all') {
      return track.genre;
    }
    return null;
  }

  /// Maps category to high-volume top hits search query for authentic catalogue
  String _getPopularHitsQuery(String category) {
    switch (category) {
      case 'Punjabi':
        return 'Top Punjabi';
      case 'Hindi':
        return 'Top Hindi';
      case 'Gujarati':
        return 'Gujarati Hits';
      case 'Pop':
        return 'Pop Hits';
      case 'Hip-Hop/Rap':
        return 'Hip-Hop Hits';
      default:
        return '$category Hits';
    }
  }

  /// Loads smart suggestions:
  /// 1. Excludes ANY song the user has already played.
  /// 2. If user listens to Punjabi & Hindi, fetches popular hits from BOTH Punjabi & Hindi and blends them.
  Future<void> loadSuggestions() async {
    isLoadingSuggestions.value = true;
    try {
      // 1. Collect all tracks the user has already played
      final history = await _databaseService.getListeningHistory(limit: 100);
      final Set<String> playedTrackIds = history.map((t) => t.trackId).toSet();

      // 2. Aggregate category and artist affinity from listening history
      final Map<String, int> categoryWeights = {};
      final Map<String, int> artistWeights = {};

      for (final track in history) {
        final playCount = await _databaseService.getTrackPlayCount(track.trackId);
        final weight = playCount > 0 ? playCount : 1;

        final category = _detectCategory(track);
        if (category != null && category.isNotEmpty) {
          categoryWeights[category] = (categoryWeights[category] ?? 0) + weight;
        }

        final artist = track.artistName.trim();
        if (artist.isNotEmpty &&
            artist.toLowerCase() != 'unknown artist' &&
            !artist.toLowerCase().contains('unknown')) {
          artistWeights[artist] = (artistWeights[artist] ?? 0) + weight;
        }
      }

      // If listening history has no categories, inspect liked songs
      if (categoryWeights.isEmpty) {
        final liked = await _databaseService.getLikedSongs();
        for (final track in liked) {
          final cat = _detectCategory(track);
          if (cat != null) {
            categoryWeights[cat] = (categoryWeights[cat] ?? 0) + 1;
          }
          final artist = track.artistName.trim();
          if (artist.isNotEmpty && !artist.toLowerCase().contains('unknown')) {
            artistWeights[artist] = (artistWeights[artist] ?? 0) + 1;
          }
        }
      }

      // 3. Determine target categories (e.g. ['Punjabi', 'Hindi'])
      final List<String> targetCategories = [];
      if (categoryWeights.isNotEmpty) {
        final sorted = categoryWeights.keys.toList()
          ..sort((a, b) => categoryWeights[b]!.compareTo(categoryWeights[a]!));
        targetCategories.addAll(sorted.take(3));
      } else {
        // Fallback default: Punjabi and Hindi popular hits
        targetCategories.addAll(['Punjabi', 'Hindi']);
      }

      // Update subtitle dynamically
      if (targetCategories.length >= 2) {
        suggestionSubtitle.value =
            'Popular ${targetCategories[0]} & ${targetCategories[1]} hits for you';
      } else if (targetCategories.isNotEmpty) {
        suggestionSubtitle.value =
            'Most popular ${targetCategories[0]} hits for you';
      } else {
        suggestionSubtitle.value = 'Fresh popular hits for you';
      }

      // 4. Fetch the most popular hit songs for each category (excluding already played tracks)
      final List<List<TrackModel>> categoryResults = [];
      for (final cat in targetCategories) {
        final query = _getPopularHitsQuery(cat);
        try {
          final tracks = await _repository.searchTracks(query, limit: 15);
          final unplayed = tracks
              .where((t) => !playedTrackIds.contains(t.trackId))
              .toList();
          if (unplayed.isNotEmpty) {
            categoryResults.add(unplayed);
          }
        } catch (e) {
          debugPrint('[MusicController] Error fetching popular hits for $cat: $e');
        }
      }

      // Also if user has a top listened artist, fetch top popular songs of that artist
      if (artistWeights.isNotEmpty) {
        final topArtist = artistWeights.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
        try {
          final artistTracks =
              await _repository.searchTracks(topArtist, limit: 10);
          final unplayed = artistTracks
              .where((t) => !playedTrackIds.contains(t.trackId))
              .toList();
          if (unplayed.isNotEmpty) {
            categoryResults.add(unplayed);
          }
        } catch (_) {}
      }

      // 5. Interleave songs from each category (e.g. Punjabi and Hindi side-by-side)
      final List<TrackModel> blendedSuggestions = [];
      final Set<String> addedIds = {};

      int maxLen = 0;
      for (final list in categoryResults) {
        if (list.length > maxLen) maxLen = list.length;
      }

      for (int i = 0; i < maxLen; i++) {
        for (final list in categoryResults) {
          if (i < list.length) {
            final track = list[i];
            if (!playedTrackIds.contains(track.trackId) &&
                !addedIds.contains(track.trackId)) {
              addedIds.add(track.trackId);
              blendedSuggestions.add(track);
            }
          }
        }
      }

      // Fallback: If suggestions empty (e.g. offline/mock empty results), try trending tracks
      if (blendedSuggestions.isEmpty) {
        try {
          final fallback = await _repository.getTracks(limit: 25);
          for (final t in fallback) {
            if (!playedTrackIds.contains(t.trackId) &&
                !addedIds.contains(t.trackId)) {
              addedIds.add(t.trackId);
              blendedSuggestions.add(t);
            }
          }
        } catch (_) {}
      }

      suggestedTracks.assignAll(blendedSuggestions.take(20));
      debugPrint(
          '[MusicController] Loaded ${suggestedTracks.length} fresh unplayed suggestions across ${targetCategories.join(", ")}.');
    } catch (e) {
      debugPrint('[MusicController] Error loading suggestions: $e');
    } finally {
      isLoadingSuggestions.value = false;
    }
  }

  Future<int> getTrackPlayCount(String trackId) async {
    return await _databaseService.getTrackPlayCount(trackId);
  }

  /// Selects a genre category and fetches music specifically for this category
  Future<void> selectCategory(String category) async {
    selectedArtist.value = null; // Clear artist selection when selecting genre
    if (selectedCategory.value == category && state.value == ViewState.success) {
      return;
    }
    selectedCategory.value = category;
    await fetchTracks();
  }

  /// Selects an artist or regional category (Spotify style: Diljit, Honey Singh, Gujarati)
  Future<void> selectArtist(ArtistCategoryModel artist) async {
    if (selectedArtist.value?.id == artist.id) {
      // Tapping again deselects and returns to "All"
      selectedArtist.value = null;
      selectedCategory.value = 'All';
      await fetchTracks();
      return;
    }

    selectedArtist.value = artist;
    selectedCategory.value = artist.name;
    await fetchTracks();
  }

  // In-memory cache of fetched tracks per category/artist to prevent redundant API calls
  final Map<String, List<TrackModel>> _categoryCache = {};

  /// Retrieves cached tracks for a category if available
  List<TrackModel>? getCachedTracksForCategory(String category) {
    return _categoryCache['category_$category'];
  }

  /// Fetches real music catalogue from repository or in-memory cache
  Future<void> fetchTracks({bool forceRefresh = false}) async {
    final cacheKey = selectedArtist.value != null
        ? 'artist_${selectedArtist.value!.id}'
        : 'category_${selectedCategory.value}';

    // If already cached in memory and not forced refresh, reuse existing tracks without API call
    if (!forceRefresh &&
        _categoryCache.containsKey(cacheKey) &&
        _categoryCache[cacheKey]!.isNotEmpty) {
      debugPrint('[MusicController] Reusing cached tracks for $cacheKey (${_categoryCache[cacheKey]!.length} tracks, no API call).');
      tracks.assignAll(_categoryCache[cacheKey]!);
      state.value = ViewState.success;
      return;
    }

    state.value = ViewState.loading;
    errorMessage.value = '';

    try {
      final List<TrackModel> fetchedTracks;

      if (selectedCategory.value == 'Suggested') {
        if (suggestedTracks.isEmpty) {
          await loadSuggestions();
        }
        fetchedTracks = List.from(suggestedTracks);
      } else if (selectedArtist.value != null) {
        // Fetch via artist search query
        fetchedTracks = await _repository.searchTracks(
          selectedArtist.value!.query,
          limit: AppConstants.defaultFetchLimit,
        );
      } else {
        // Fetch via trending / genre filter
        fetchedTracks = await _repository.getTracks(
          limit: AppConstants.defaultFetchLimit,
          genre: selectedCategory.value,
        );
      }

      if (fetchedTracks.isEmpty) {
        tracks.clear();
        state.value = ViewState.empty;
      } else {
        _categoryCache[cacheKey] = fetchedTracks;
        tracks.assignAll(fetchedTracks);
        state.value = ViewState.success;

        // Automatically verify the top track audio URL as proof of playable audio stream
        if (tracks.isNotEmpty) {
          verifyAudio(tracks.first);
        }
      }
    } catch (e) {
      debugPrint('[MusicController] Error fetching tracks: $e');
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
      state.value = ViewState.error;
    }
  }

  /// Verifies the legal audio stream URL for a given track
  Future<void> verifyAudio(TrackModel track) async {
    if (verifyingTrackIds.contains(track.trackId) ||
        audioVerifications.containsKey(track.trackId)) {
      return;
    }

    verifyingTrackIds.add(track.trackId);

    try {
      final verification = await _repository.verifyTrackAudio(track);
      audioVerifications[track.trackId] = verification;
    } catch (e) {
      audioVerifications[track.trackId] = AudioVerificationModel.failed(
        url: track.audioUrl,
        error: e.toString(),
      );
    } finally {
      verifyingTrackIds.remove(track.trackId);
    }
  }

  /// Refreshes the track catalogue for the current category / artist
  Future<void> refreshCatalogue() async {
    await Future.wait([
      fetchTracks(forceRefresh: true),
      loadSuggestions(),
      loadTrendingTracks(),
      loadNewReleases(),
      loadTopCharts(),
      loadRomanticTracks(),
      loadPartyTracks(),
    ]);
  }

  /// Helper getters for UI
  bool get isLoading => state.value == ViewState.loading;
  bool get isSuccess => state.value == ViewState.success;
  bool get isEmpty => state.value == ViewState.empty;
  bool get isError => state.value == ViewState.error;
}
