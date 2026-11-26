import 'package:flutter_test/flutter_test.dart';
import 'package:whats_play/constants/app_constants.dart';
import 'package:whats_play/controllers/music_controller.dart';
import 'package:whats_play/models/artist_category_model.dart';
import 'package:whats_play/models/audio_verification_model.dart';
import 'package:whats_play/models/track_model.dart';
import 'package:whats_play/repositories/music_repository.dart';
import 'package:whats_play/services/local_database_service.dart';

class MockMusicRepository implements IMusicRepository {
  final bool shouldFail;
  final List<TrackModel> mockTracks;
  String? lastRequestedGenre;
  String? lastSearchQuery;
  final List<String> allSearchQueries = [];

  MockMusicRepository({
    this.shouldFail = false,
    this.mockTracks = const [],
  });

  int getTracksCount = 0;

  @override
  Future<List<TrackModel>> getTracks({int limit = 25, String? genre}) async {
    getTracksCount++;
    lastRequestedGenre = genre;
    if (shouldFail) {
      throw Exception('Mock network failure');
    }
    return mockTracks;
  }

  @override
  Future<List<TrackModel>> searchTracks(String query, {int limit = 25}) async {
    lastSearchQuery = query;
    allSearchQueries.add(query);
    if (shouldFail) {
      throw Exception('Mock network failure');
    }
    return mockTracks;
  }

  @override
  Future<List<TrackModel>> getTrendingChartTracks({int limit = 25}) async {
    if (shouldFail) {
      throw Exception('Mock network failure');
    }
    return mockTracks;
  }

  @override
  Future<List<TrackModel>> getNewReleases({int limit = 25}) async {
    if (shouldFail) {
      throw Exception('Mock network failure');
    }
    return mockTracks;
  }

  @override
  Future<List<TrackModel>> getTopCharts({int limit = 25}) async {
    if (shouldFail) {
      throw Exception('Mock network failure');
    }
    return mockTracks;
  }

  @override
  Future<List<TrackModel>> getRomanticTracks({int limit = 25}) async {
    if (shouldFail) {
      throw Exception('Mock network failure');
    }
    return mockTracks;
  }

  @override
  Future<List<TrackModel>> getPartyTracks({int limit = 25}) async {
    if (shouldFail) {
      throw Exception('Mock network failure');
    }
    return mockTracks;
  }

  @override
  Future<AudioVerificationModel> verifyTrackAudio(TrackModel track) async {
    return AudioVerificationModel(
      url: track.audioUrl,
      statusCode: 200,
      contentType: 'audio/mpeg',
      isAccessible: true,
      isFullTrack: true,
      verificationTime: DateTime.now(),
      details: 'Mock verified',
    );
  }
}

void main() {
  group('MusicController Tests', () {
    test('Initializes and transitions to success when tracks are found', () async {
      final tracks = [
        const TrackModel(
          trackId: '1',
          title: 'Track A',
          artistName: 'Artist A',
          albumName: 'Album A',
          genre: 'Rock',
          durationSeconds: 120,
          audioUrl: 'https://audius.co/stream/1',
          musicSource: 'Audius',
          licenseInfo: 'Standard',
          isStreamable: true,
          isDownloadable: true,
        ),
      ];

      final repo = MockMusicRepository(mockTracks: tracks);
      final controller = MusicController(repo);

      await controller.fetchTracks();

      expect(controller.state.value, ViewState.success);
      expect(controller.tracks.length, 1);
      expect(controller.tracks.first.title, 'Track A');
      expect(controller.isSuccess, true);
    });

    test('selectCategory updates selectedCategory and fetches with genre filter', () async {
      final repo = MockMusicRepository(mockTracks: []);
      final controller = MusicController(repo);

      await controller.selectCategory('Electronic');

      expect(controller.selectedCategory.value, 'Electronic');
      expect(repo.lastRequestedGenre, 'Electronic');
    });

    test('selectArtist updates selectedArtist and fetches tracks via searchTracks', () async {
      final repo = MockMusicRepository(mockTracks: []);
      final controller = MusicController(repo);

      final diljit = AppConstants.featuredArtists.firstWhere((a) => a.id == 'diljit');
      await controller.selectArtist(diljit);

      expect(controller.selectedArtist.value?.id, 'diljit');
      expect(controller.selectedCategory.value, diljit.name);
      expect(repo.lastSearchQuery, diljit.query);

      // Tapping again deselects
      await controller.selectArtist(diljit);
      expect(controller.selectedArtist.value, isNull);
      expect(controller.selectedCategory.value, 'All');
    });

    test('Transitions to empty state when no tracks are returned', () async {
      final repo = MockMusicRepository(mockTracks: []);
      final controller = MusicController(repo);

      await controller.fetchTracks();

      expect(controller.state.value, ViewState.empty);
      expect(controller.isEmpty, true);
    });

    test('Transitions to error state when repository throws', () async {
      final repo = MockMusicRepository(shouldFail: true);
      final controller = MusicController(repo);

      await controller.fetchTracks();

      expect(controller.state.value, ViewState.error);
      expect(controller.isError, true);
      expect(controller.errorMessage.value, contains('Mock network failure'));
    });

    test('toggleFollowArtist adds, removes and checks followed artists', () async {
      final repo = MockMusicRepository();
      final db = MemoryLocalDatabaseService();
      final controller = MusicController(repo, databaseService: db);

      const artist = ArtistCategoryModel(
        id: 'diljit',
        name: 'Diljit Dosanjh',
        query: 'Diljit Dosanjh',
        categoryLabel: 'Artist',
        imageUrl: 'https://example.com/diljit.jpg',
      );

      expect(controller.isArtistFollowed('diljit'), false);
      expect(controller.followedArtists, isEmpty);

      // Follow artist
      await controller.toggleFollowArtist(artist);
      expect(controller.isArtistFollowed('diljit'), true);
      expect(controller.followedArtists.length, 1);
      expect(controller.followedArtists.first.name, 'Diljit Dosanjh');

      // Unfollow artist
      await controller.toggleFollowArtist(artist);
      expect(controller.isArtistFollowed('diljit'), false);
      expect(controller.followedArtists, isEmpty);
    });

    test('selectLibraryFilter updates selected filter', () {
      final repo = MockMusicRepository();
      final controller = MusicController(repo);

      expect(controller.selectedLibraryFilter.value, 'Playlists');
      controller.selectLibraryFilter('Artists');
      expect(controller.selectedLibraryFilter.value, 'Artists');
    });

    test('createCustomPlaylist and deleteCustomPlaylist manage custom collections', () async {
      final repo = MockMusicRepository();
      final db = MemoryLocalDatabaseService();
      final controller = MusicController(repo, databaseService: db);

      expect(controller.customPlaylists, isEmpty);

      final playlist = await controller.createCustomPlaylist('Workout Bangers', 'flame');
      expect(controller.customPlaylists.length, 1);
      expect(controller.customPlaylists.first.name, 'Workout Bangers');
      expect(controller.customPlaylists.first.iconKey, 'flame');

      await controller.deleteCustomPlaylist(playlist.id);
      expect(controller.customPlaylists, isEmpty);
    });

    test('addTrackToPlaylist and removeTrackFromPlaylist update playlist counts and active view', () async {
      final repo = MockMusicRepository();
      final db = MemoryLocalDatabaseService();
      final controller = MusicController(repo, databaseService: db);

      const track = TrackModel(
        trackId: 'track_101',
        title: 'Hass Hass',
        artistName: 'Diljit Dosanjh',
        albumName: 'Hass Hass',
        genre: 'Punjabi',
        durationSeconds: 153,
        audioUrl: 'https://example.com/audio.mp3',
        musicSource: 'JioSaavn',
        licenseInfo: 'Licensed',
        isStreamable: true,
        isDownloadable: false,
      );

      final playlist = await controller.createCustomPlaylist('Chill Vibes', 'headphones');
      expect(controller.customPlaylists.first.songCount, 0);

      // Open custom playlist
      await controller.openCustomPlaylist(playlist);
      expect(controller.activeCustomPlaylist.value?.id, playlist.id);
      expect(controller.activePlaylistTracks, isEmpty);

      // Add track
      await controller.addTrackToPlaylist(playlist.id, track);
      expect(controller.customPlaylists.first.songCount, 1);
      expect(controller.activePlaylistTracks.length, 1);
      expect(controller.activePlaylistTracks.first.title, 'Hass Hass');

      // Remove track
      await controller.removeTrackFromPlaylist(playlist.id, track.trackId);
      expect(controller.customPlaylists.first.songCount, 0);
      expect(controller.activePlaylistTracks, isEmpty);

      // Close playlist
      controller.closeCustomPlaylist();
      expect(controller.activeCustomPlaylist.value, isNull);
    });

    test('Listening history stores play counts and generates suggestions excluding already played tracks', () async {
      const trackA = TrackModel(
        trackId: 'track_a',
        title: 'Played Punjabi Song',
        artistName: 'Diljit Dosanjh',
        albumName: 'Album A',
        genre: 'Punjabi',
        durationSeconds: 180,
        audioUrl: 'https://example.com/a.mp3',
        musicSource: 'JioSaavn',
        licenseInfo: 'Licensed',
        isStreamable: true,
        isDownloadable: false,
      );

      const trackB = TrackModel(
        trackId: 'track_b',
        title: 'Played Hindi Song',
        artistName: 'Honey Singh',
        albumName: 'Album B',
        genre: 'Hindi',
        durationSeconds: 200,
        audioUrl: 'https://example.com/b.mp3',
        musicSource: 'JioSaavn',
        licenseInfo: 'Licensed',
        isStreamable: true,
        isDownloadable: false,
      );

      const unplayedPunjabiHit = TrackModel(
        trackId: 'track_c',
        title: 'Fresh Punjabi Hit',
        artistName: 'Diljit Dosanjh',
        albumName: 'Album C',
        genre: 'Punjabi',
        durationSeconds: 190,
        audioUrl: 'https://example.com/c.mp3',
        musicSource: 'JioSaavn',
        licenseInfo: 'Licensed',
        isStreamable: true,
        isDownloadable: false,
      );

      const unplayedHindiHit = TrackModel(
        trackId: 'track_d',
        title: 'Fresh Hindi Hit',
        artistName: 'Arijit Singh',
        albumName: 'Album D',
        genre: 'Hindi',
        durationSeconds: 210,
        audioUrl: 'https://example.com/d.mp3',
        musicSource: 'JioSaavn',
        licenseInfo: 'Licensed',
        isStreamable: true,
        isDownloadable: false,
      );

      final repo = MockMusicRepository(
        mockTracks: [trackA, trackB, unplayedPunjabiHit, unplayedHindiHit],
      );
      final db = MemoryLocalDatabaseService();
      final controller = MusicController(repo, databaseService: db);

      // Record multiple plays for track A (3 plays) and 1 play for track B
      await db.recordTrackPlay(trackA);
      await db.recordTrackPlay(trackA);
      await db.recordTrackPlay(trackA);
      await db.recordTrackPlay(trackB);

      // Verify play counts in database
      expect(await db.getTrackPlayCount('track_a'), 3);
      expect(await db.getTrackPlayCount('track_b'), 1);

      // Verify top played order (Song A with 3 plays is first)
      final topPlayed = await db.getTopPlayedTracks();
      expect(topPlayed.length, 2);
      expect(topPlayed.first.title, 'Played Punjabi Song');

      // Load suggestions into controller
      await controller.loadSuggestions();

      // 1. Suggestions must NOT contain already played tracks (track_a or track_b)
      expect(controller.suggestedTracks.any((t) => t.trackId == 'track_a'), false);
      expect(controller.suggestedTracks.any((t) => t.trackId == 'track_b'), false);

      // 2. Suggestions must contain the unplayed hits
      expect(controller.suggestedTracks.any((t) => t.trackId == 'track_c'), true);
      expect(controller.suggestedTracks.any((t) => t.trackId == 'track_d'), true);

      // 3. User listened to Punjabi & Hindi, so queries targeted both Punjabi and Hindi
      expect(repo.allSearchQueries.any((q) => q.contains('Punjabi')), true);
      expect(repo.allSearchQueries.any((q) => q.contains('Hindi')), true);

      // 4. Subtitle dynamically reflects Punjabi & Hindi preferences
      expect(controller.suggestionSubtitle.value.contains('Punjabi'), true);
      expect(controller.suggestionSubtitle.value.contains('Hindi'), true);

      // 5. When an unplayed suggestion is played, it is instantly removed from suggestions
      controller.onTrackPlayed(unplayedPunjabiHit);
      expect(controller.suggestedTracks.any((t) => t.trackId == 'track_c'), false);
    });

    test('selectCategory caches tracks and does not make duplicate API calls when switching back to All', () async {
      const mockTrack = TrackModel(
        trackId: '1',
        title: 'Initial Track',
        artistName: 'Artist 1',
        albumName: 'Album 1',
        genre: 'All',
        durationSeconds: 180,
        audioUrl: 'https://example.com/stream.mp3',
        musicSource: 'JioSaavn',
        licenseInfo: 'Licensed',
        isStreamable: true,
        isDownloadable: false,
      );

      final repo = MockMusicRepository(mockTracks: [mockTrack]);
      final db = MemoryLocalDatabaseService();
      final controller = MusicController(repo, databaseService: db);

      // Initial fetch for 'All'
      await controller.fetchTracks();
      expect(repo.getTracksCount, 1);
      expect(controller.tracks.first.title, 'Initial Track');

      // Switch to 'Suggested'
      await controller.selectCategory('Suggested');
      // No extra getTracks API call made because suggestions use local storage
      expect(repo.getTracksCount, 1);
      expect(controller.selectedCategory.value, 'Suggested');

      // Switch back to 'All'
      await controller.selectCategory('All');
      // Still 1! In-memory cache served 'All' tracks without calling the API again
      expect(repo.getTracksCount, 1);
      expect(controller.tracks.first.title, 'Initial Track');
      expect(controller.state.value, ViewState.success);
    });

    test('Listening history is recorded, reloaded, and grouped day-wise with day labels', () async {
      final repo = MockMusicRepository();
      final db = MemoryLocalDatabaseService();
      final controller = MusicController(repo, databaseService: db);

      final now = DateTime.now();
      final todayTrack = TrackModel(
        trackId: 'hist_1',
        title: 'Today Song',
        artistName: 'Artist 1',
        albumName: 'Album 1',
        genre: 'Pop',
        durationSeconds: 200,
        audioUrl: 'https://example.com/1.mp3',
        musicSource: 'JioSaavn',
        licenseInfo: 'Licensed',
        isStreamable: true,
        isDownloadable: false,
        lastPlayedTimestamp: now.millisecondsSinceEpoch,
      );

      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayTrack = TrackModel(
        trackId: 'hist_2',
        title: 'Yesterday Song',
        artistName: 'Artist 2',
        albumName: 'Album 2',
        genre: 'Hindi',
        durationSeconds: 180,
        audioUrl: 'https://example.com/2.mp3',
        musicSource: 'JioSaavn',
        licenseInfo: 'Licensed',
        isStreamable: true,
        isDownloadable: false,
        lastPlayedTimestamp: yesterday.millisecondsSinceEpoch,
      );

      await db.recordTrackPlay(todayTrack);
      await db.recordTrackPlay(yesterdayTrack);

      await controller.loadListeningHistory();
      expect(controller.listeningHistory.length, 2);

      final grouped = controller.groupedListeningHistory;
      expect(grouped.containsKey('Today'), true);
      expect(grouped.containsKey('Yesterday'), true);
      expect(grouped['Today']!.first.title, 'Today Song');
      expect(grouped['Yesterday']!.first.title, 'Yesterday Song');
    });

    test('loadTrendingTracks populates trending tracks and toggleExpandAllSongs toggles', () async {
      const mockTrack = TrackModel(
        trackId: 'trend_1',
        title: 'Trending Hit',
        artistName: 'Trending Artist',
        albumName: 'Top Chart',
        genre: 'Punjabi',
        durationSeconds: 180,
        audioUrl: 'https://example.com/stream.mp3',
        musicSource: 'JioSaavn',
        licenseInfo: 'Licensed',
        isStreamable: true,
        isDownloadable: true,
      );

      final repo = MockMusicRepository(mockTracks: [mockTrack]);
      final db = MemoryLocalDatabaseService();
      final controller = MusicController(repo, databaseService: db);

      await controller.loadTrendingTracks();
      expect(controller.trendingTracks.length, 1);
      expect(controller.trendingTracks.first.title, 'Trending Hit');

      expect(controller.isAllSongsExpanded.value, false);
      controller.toggleExpandAllSongs();
      expect(controller.isAllSongsExpanded.value, true);
      controller.toggleExpandAllSongs();
      expect(controller.isAllSongsExpanded.value, false);

      await controller.loadNewReleases();
      expect(controller.newReleases.length, 1);
      expect(controller.newReleases.first.title, 'Trending Hit');
    });
  });
}
                                  