import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../controllers/music_controller.dart';
import '../models/blend_model.dart';
import '../models/track_model.dart';
import '../services/blend_service.dart';
import '../services/saavn_service.dart';

class AddSongToBlendSheet extends StatefulWidget {
  final BlendModel blend;
  final List<BlendTrack> existingTracks;

  const AddSongToBlendSheet({
    super.key,
    required this.blend,
    required this.existingTracks,
  });

  static Future<void> show(
    BuildContext context,
    BlendModel blend,
    List<BlendTrack> existingTracks,
  ) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: Color(0xFF191919),
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarIconBrightness: Brightness.light,
          ),
          child: AddSongToBlendSheet(
            blend: blend,
            existingTracks: existingTracks,
          ),
        );
      },
    );
  }

  @override
  State<AddSongToBlendSheet> createState() => _AddSongToBlendSheetState();
}

class _AddSongToBlendSheetState extends State<AddSongToBlendSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;

  // Search state
  final List<TrackModel> _searchResults = [];
  bool _isSearching = false;
  String _activeSearchQuery = '';

  // Suggestions state
  final Map<String, List<TrackModel>> _categoryCache = {};
  final List<String> _categoryTabs = [];
  int _selectedCategoryIndex = 0;
  bool _isLoadingSuggestions = true;

  // Added tracks tracking (to reflect instant "Added" state)
  final Set<String> _addedAudioUrls = {};
  final Set<String> _addedTitles = {};
  final Set<String> _inFlightTrackIds = {};

  SaavnService? _saavn;

  @override
  void initState() {
    super.initState();
    _saavn = Get.isRegistered<SaavnService>()
        ? Get.find<SaavnService>()
        : Get.put(SaavnService());

    // Initialize set of already added songs
    for (final track in widget.existingTracks) {
      if (track.audioUrl.isNotEmpty) {
        _addedAudioUrls.add(track.audioUrl);
      }
      if (track.title.isNotEmpty) {
        _addedTitles.add(track.title.toLowerCase().trim());
      }
    }

    _setupCategoriesAndLoad();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Detects music category from a BlendTrack (Hindi, Gujarati, Punjabi, etc.)
  String _detectCategoryFromBlendTrack(BlendTrack track) {
    final a = track.artist.toLowerCase();
    final t = track.title.toLowerCase();

    // Gujarati detection
    if (a.contains('jignesh') ||
        a.contains('geeta rabari') ||
        a.contains('kinjal') ||
        a.contains('kirtidan') ||
        a.contains('aditya gadhvi') ||
        a.contains('osman mir') ||
        a.contains('vijay suvada') ||
        a.contains('umesh barot') ||
        a.contains('arvind vegda') ||
        a.contains('falguni pathak') ||
        a.contains('atul purohit') ||
        a.contains('bhoomi trivedi') ||
        t.contains('gujarati') ||
        t.contains('garba') ||
        t.contains('dandiya') ||
        t.contains('dayro') ||
        t.contains('sanedo') ||
        t.contains('khalasi')) {
      return 'Gujarati';
    }

    // Punjabi detection
    if (a.contains('diljit') ||
        a.contains('sidhu') ||
        a.contains('karan aujla') ||
        a.contains('ap dhillon') ||
        a.contains('ammy') ||
        a.contains('shubh') ||
        a.contains('guru randhawa') ||
        a.contains('harrdy') ||
        a.contains('jass manak') ||
        a.contains('parmish') ||
        t.contains('punjabi') ||
        t.contains('jatt') ||
        t.contains('gabru')) {
      return 'Punjabi';
    }

    // Hindi / Bollywood detection
    if (a.contains('arijit') ||
        a.contains('shreya') ||
        a.contains('jubin') ||
        a.contains('neha') ||
        a.contains('badshah') ||
        a.contains('honey singh') ||
        a.contains('pritam') ||
        a.contains('sachin') ||
        a.contains('atif') ||
        a.contains('sonu') ||
        a.contains('kumar sanu') ||
        a.contains('alka') ||
        a.contains('udit') ||
        a.contains('darshan raval') ||
        a.contains('armaan malik') ||
        a.contains('anuv jain') ||
        t.contains('hindi') ||
        t.contains('bollywood') ||
        t.contains('tum ') ||
        t.contains('pyaar') ||
        t.contains('ishq') ||
        t.contains('dil ')) {
      return 'Hindi';
    }

    return '';
  }

  /// Sets up categories based on existing songs in the blend + user taste
  Future<void> _setupCategoriesAndLoad() async {
    setState(() => _isLoadingSuggestions = true);

    final Map<String, int> counts = {};
    for (final t in widget.existingTracks) {
      final cat = _detectCategoryFromBlendTrack(t);
      if (cat.isNotEmpty) {
        counts[cat] = (counts[cat] ?? 0) + 1;
      }
    }

    // Check user listening history if blend has few or no categorized songs
    if (counts.isEmpty && Get.isRegistered<MusicController>()) {
      final musicCtrl = Get.find<MusicController>();
      for (final t in musicCtrl.suggestedTracks) {
        final g = t.genre.toLowerCase();
        final a = t.artistName.toLowerCase();
        if (g.contains('gujarati') || a.contains('jignesh') || a.contains('geeta')) {
          counts['Gujarati'] = (counts['Gujarati'] ?? 0) + 1;
        } else if (g.contains('hindi') || a.contains('arijit') || a.contains('shreya')) {
          counts['Hindi'] = (counts['Hindi'] ?? 0) + 1;
        } else if (g.contains('punjabi') || a.contains('diljit')) {
          counts['Punjabi'] = (counts['Punjabi'] ?? 0) + 1;
        }
      }
    }

    // Build the ordered tab list
    _categoryTabs.clear();

    final detected = counts.keys.toList()
      ..sort((a, b) => (counts[b] ?? 0).compareTo(counts[a] ?? 0));

    if (detected.contains('Hindi') && detected.contains('Gujarati')) {
      // Both Hindi and Gujarati present
      _categoryTabs.add('✨ Blend Mix');
      _categoryTabs.add('Hindi Hits');
      _categoryTabs.add('Gujarati Hits');
      _categoryTabs.add('🔥 Trending');
      if (detected.contains('Punjabi')) _categoryTabs.add('Punjabi Hits');
    } else if (detected.contains('Gujarati')) {
      _categoryTabs.add('✨ Blend Mix');
      _categoryTabs.add('Gujarati Hits');
      _categoryTabs.add('Hindi Hits');
      _categoryTabs.add('🔥 Trending');
      if (detected.contains('Punjabi')) _categoryTabs.add('Punjabi Hits');
    } else if (detected.contains('Hindi')) {
      _categoryTabs.add('✨ Blend Mix');
      _categoryTabs.add('Hindi Hits');
      _categoryTabs.add('Gujarati Hits');
      _categoryTabs.add('🔥 Trending');
      if (detected.contains('Punjabi')) _categoryTabs.add('Punjabi Hits');
    } else {
      // Default recommended setup
      _categoryTabs.add('🔥 Trending');
      _categoryTabs.add('Hindi Hits');
      _categoryTabs.add('Gujarati Hits');
      _categoryTabs.add('Punjabi Hits');
    }

    if (mounted) setState(() {});

    // Fetch the active tab's tracks
    await _loadCategoryTracks(_categoryTabs.first);
  }

  /// Loads tracks for a specific category tab
  Future<void> _loadCategoryTracks(String tab) async {
    if (_categoryCache.containsKey(tab) && _categoryCache[tab]!.isNotEmpty) {
      if (mounted) setState(() => _isLoadingSuggestions = false);
      return;
    }

    if (mounted) setState(() => _isLoadingSuggestions = true);
    final saavn = _saavn;
    if (saavn == null) {
      if (mounted) setState(() => _isLoadingSuggestions = false);
      return;
    }

    try {
      List<TrackModel> tracks = [];

      if (tab == '✨ Blend Mix') {
        // Interleave popular Hindi and Gujarati tracks (or whatever blend categories exist)
        final results = await Future.wait([
          saavn.searchTracks(query: 'Top Hindi Hits', limit: 12),
          saavn.searchTracks(query: 'Gujarati Hits', limit: 12),
          saavn.getRealTrendingTracks(limit: 8),
        ]);

        final hindiList = results[0];
        final gujaratiList = results[1];
        final trendingList = results[2];

        final interleaved = <TrackModel>[];
        final maxLen = [hindiList.length, gujaratiList.length].reduce((a, b) => a > b ? a : b);
        final seen = <String>{};

        for (int i = 0; i < maxLen; i++) {
          if (i < hindiList.length && seen.add(hindiList[i].trackId)) {
            interleaved.add(hindiList[i]);
          }
          if (i < gujaratiList.length && seen.add(gujaratiList[i].trackId)) {
            interleaved.add(gujaratiList[i]);
          }
        }

        // Fill in extra trending if needed
        for (final t in trendingList) {
          if (seen.add(t.trackId)) interleaved.add(t);
        }

        tracks = interleaved;
      } else if (tab == '🔥 Trending') {
        tracks = await saavn.getRealTrendingTracks(limit: 25);
      } else if (tab == 'Hindi Hits') {
        tracks = await saavn.searchTracks(query: 'Top Hindi Hits', limit: 25);
      } else if (tab == 'Gujarati Hits') {
        tracks = await saavn.searchTracks(query: 'Gujarati Hits', limit: 25);
      } else if (tab == 'Punjabi Hits') {
        tracks = await saavn.searchTracks(query: 'Top Punjabi Hits', limit: 25);
      } else {
        tracks = await saavn.searchTracks(query: tab, limit: 25);
      }

      if (tracks.isNotEmpty) {
        _categoryCache[tab] = tracks;
      }
    } catch (e) {
      debugPrint('[AddSongToBlendSheet] Error loading $tab: $e');
    }

    if (mounted) {
      setState(() => _isLoadingSuggestions = false);
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    final cleanQuery = query.trim();

    if (cleanQuery.isEmpty) {
      setState(() {
        _activeSearchQuery = '';
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _activeSearchQuery = cleanQuery;
      _isSearching = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      await _executeSearch(cleanQuery);
    });
  }

  Future<void> _executeSearch(String query) async {
    final saavn = _saavn;
    if (saavn == null || query.isEmpty) return;

    try {
      final results = await saavn.searchTracks(query: query, limit: 30);
      if (mounted && _activeSearchQuery == query) {
        setState(() {
          _searchResults
            ..clear()
            ..addAll(results);
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('[AddSongToBlendSheet] Search error: $e');
      if (mounted) setState(() => _isSearching = false);
    }
  }

  bool _isTrackAdded(TrackModel track) {
    if (track.audioUrl.isNotEmpty && _addedAudioUrls.contains(track.audioUrl)) {
      return true;
    }
    if (_addedTitles.contains(track.title.toLowerCase().trim())) {
      return true;
    }
    return false;
  }

  Future<void> _handleAddTrack(TrackModel track) async {
    if (_isTrackAdded(track)) return;
    if (_inFlightTrackIds.contains(track.trackId)) return;

    HapticFeedback.lightImpact();

    // Optimistically mark as added immediately
    setState(() {
      _inFlightTrackIds.add(track.trackId);
      if (track.audioUrl.isNotEmpty) _addedAudioUrls.add(track.audioUrl);
      _addedTitles.add(track.title.toLowerCase().trim());
    });

    final blendService = BlendService.to;
    final success = await blendService.addTrackToBlend(widget.blend.id, track);

    if (mounted) {
      setState(() {
        _inFlightTrackIds.remove(track.trackId);
        if (!success) {
          // Revert if failed
          if (track.audioUrl.isNotEmpty) _addedAudioUrls.remove(track.audioUrl);
          _addedTitles.remove(track.title.toLowerCase().trim());
        }
      });

      if (success) {
        Get.snackbar(
          'Added to Blend',
          '"${track.title}" was added to ${widget.blend.name}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF2C2C2C),
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle_rounded, color: AppColors.primary),
          duration: const Duration(seconds: 2),
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          borderRadius: 12.r,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: const Color(0xFF191919),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Drag Handle & Title Row
              SizedBox(height: 12.h),
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
              SizedBox(height: 12.h),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 18.w),
                child: Row(
                  children: [
                    Container(
                      width: 32.w,
                      height: 32.w,
                      decoration: BoxDecoration(
                        color: widget.blend.themeColor.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.blend.themeColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          widget.blend.icon,
                          style: TextStyle(fontSize: 15.sp),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Songs to ${widget.blend.name}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Suggestions & live search',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11.5.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),

              // Search Bar with instant debounce
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 18.w),
                child: TextField(
                  controller: _searchCtrl,
                  focusNode: _searchFocusNode,
                  style: TextStyle(color: Colors.white, fontSize: 13.5.sp),
                  decoration: InputDecoration(
                    hintText: 'Search songs, artists, or genres...',
                    hintStyle: TextStyle(color: Colors.white54, fontSize: 13.sp),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                    suffixIcon: _activeSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Colors.white54),
                            onPressed: () {
                              _debounceTimer?.cancel();
                              _searchCtrl.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              SizedBox(height: 12.h),

              // Body: Search Results OR Suggested Categories
              Expanded(
                child: _activeSearchQuery.isNotEmpty
                    ? _buildSearchResults()
                    : _buildSuggestedSection(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Search results view
  Widget _buildSearchResults() {
    if (_isSearching) {
      return Center(
        child: CircularProgressIndicator(
          color: widget.blend.themeColor,
          strokeWidth: 2.5,
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 40.sp, color: Colors.white30),
            SizedBox(height: 10.h),
            Text(
              'No songs found for "$_activeSearchQuery"',
              style: TextStyle(color: Colors.white60, fontSize: 13.5.sp),
            ),
            SizedBox(height: 4.h),
            Text(
              'Try searching with a different artist or song title.',
              style: TextStyle(color: Colors.white38, fontSize: 11.5.sp),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 4.h),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final track = _searchResults[index];
        return _buildTrackTile(track);
      },
    );
  }

  /// Suggested songs with category tabs
  Widget _buildSuggestedSection() {
    final currentTab = _categoryTabs.isNotEmpty && _selectedCategoryIndex < _categoryTabs.length
        ? _categoryTabs[_selectedCategoryIndex]
        : '';
    final tracks = _categoryCache[currentTab] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Filter Chips
        if (_categoryTabs.isNotEmpty)
          SizedBox(
            height: 36.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              itemCount: _categoryTabs.length,
              separatorBuilder: (context, index) => SizedBox(width: 8.w),
              itemBuilder: (context, index) {
                final tab = _categoryTabs[index];
                final isSelected = index == _selectedCategoryIndex;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedCategoryIndex = index);
                    _loadCategoryTracks(tab);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? widget.blend.themeColor.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(
                        color: isSelected
                            ? widget.blend.themeColor
                            : Colors.white.withValues(alpha: 0.12),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Text(
                      tab,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 12.sp,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        SizedBox(height: 10.h),

        // Section header note
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.w),
          child: Row(
            children: [
              Text(
                'Suggested for this Blend',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${tracks.length} songs',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 6.h),

        // Track list
        Expanded(
          child: _isLoadingSuggestions
              ? Center(
                  child: CircularProgressIndicator(
                    color: widget.blend.themeColor,
                    strokeWidth: 2.5,
                  ),
                )
              : tracks.isEmpty
                  ? Center(
                      child: Text(
                        'No suggestions available right now.',
                        style: TextStyle(color: Colors.white54, fontSize: 13.sp),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 4.h),
                      itemCount: tracks.length,
                      itemBuilder: (context, index) {
                        final track = tracks[index];
                        return _buildTrackTile(track);
                      },
                    ),
        ),
      ],
    );
  }

  /// Single Track Tile with real-time "Add" / "Added" state
  Widget _buildTrackTile(TrackModel track) {
    final isAdded = _isTrackAdded(track);
    final isInFlight = _inFlightTrackIds.contains(track.trackId);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          // 44x44 Artwork
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: SizedBox(
              width: 44.w,
              height: 44.w,
              child: track.artworkUrl != null && track.artworkUrl!.isNotEmpty
                  ? Image.network(
                      track.artworkUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.surfaceLight,
                        child: const Icon(Icons.music_note_rounded, color: Colors.white38),
                      ),
                    )
                  : Container(
                      color: AppColors.surfaceLight,
                      child: const Icon(Icons.music_note_rounded, color: Colors.white38),
                    ),
            ),
          ),
          SizedBox(width: 12.w),

          // Title & Artist
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  style: TextStyle(
                    color: isAdded ? Colors.white60 : Colors.white,
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 3.h),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        track.artistName,
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11.5.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (track.genre.isNotEmpty &&
                        track.genre.toLowerCase() != 'general' &&
                        track.genre.toLowerCase() != 'all') ...[
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          track.genre,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),

          // Action Button: "Added" checkmark or "+" Add Button
          if (isInFlight)
            SizedBox(
              width: 24.w,
              height: 24.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: widget.blend.themeColor,
              ),
            )
          else if (isAdded)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: const Color(0xFF1DB954).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: const Color(0xFF1DB954).withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded, color: const Color(0xFF1DB954), size: 14.sp),
                  SizedBox(width: 3.w),
                  Text(
                    'Added',
                    style: TextStyle(
                      color: const Color(0xFF1DB954),
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          else
            IconButton(
              icon: Icon(
                Icons.add_circle_rounded,
                color: widget.blend.themeColor,
                size: 26.sp,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Add to Blend',
              onPressed: () => _handleAddTrack(track),
            ),
        ],
      ),
    );
  }
}
