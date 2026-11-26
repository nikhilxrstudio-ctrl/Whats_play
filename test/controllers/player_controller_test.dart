import 'package:flutter_test/flutter_test.dart';
import 'package:whats_play/controllers/player_controller.dart';
import 'package:whats_play/models/track_model.dart';
import 'package:whats_play/services/audio_player_handler.dart';
import 'package:whats_play/services/local_database_service.dart';

class MockAudioPlayerHandler extends AudioPlayerHandler {
  bool isPlayingMock = false;
  Duration? lastSeekPosition;
  String? lastPlayedUrl;

  @override
  Future<void> playTrack({
    required String trackId,
    required String title,
    required String artist,
    required String album,
    required String audioUrl,
    String? artworkUrl,
    Duration? duration,
  }) async {
    lastPlayedUrl = audioUrl;
    isPlayingMock = true;
  }

  @override
  Future<void> play() async {
    isPlayingMock = true;
  }

  @override
  Future<void> pause() async {
    isPlayingMock = false;
  }

  @override
  Future<void> prebufferTrack(String audioUrl) async {}

  @override
  Future<void> seek(Duration position) async {
    lastSeekPosition = position;
  }
}

void main() {
  group('PlayerController Tests', () {
    testWidgets('playTrack loads track and initializes playback state', (tester) async {
      final mockHandler = MockAudioPlayerHandler();
      final controller = PlayerController(mockHandler);

      const track = TrackModel(
        trackId: '101',
        title: 'Born To Shine',
        artistName: 'Diljit Dosanjh',
        albumName: 'G.O.A.T.',
        genre: 'Punjabi',
        durationSeconds: 214,
        audioUrl: 'https://example.com/stream.mp3',
        musicSource: 'JioSaavn',
        licenseInfo: 'Licensed',
        isStreamable: true,
        isDownloadable: false,
      );

      await controller.playTrack(track);

      expect(controller.currentTrack.value?.trackId, '101');
      expect(controller.duration.value.inSeconds, 214);
      expect(mockHandler.lastPlayedUrl, 'https://example.com/stream.mp3');
      expect(controller.formatDuration(const Duration(minutes: 3, seconds: 34)), '3:34');
    });

    testWidgets('playNext and playPrevious traverse playlist', (tester) async {
      final mockHandler = MockAudioPlayerHandler();
      final controller = PlayerController(mockHandler);

      final queue = [
        const TrackModel(
          trackId: '1',
          title: 'Track 1',
          artistName: 'Artist 1',
          albumName: 'Album 1',
          genre: 'Pop',
          durationSeconds: 180,
          audioUrl: 'https://example.com/1.mp3',
          musicSource: 'Source',
          licenseInfo: 'License',
          isStreamable: true,
          isDownloadable: false,
        ),
        const TrackModel(
          trackId: '2',
          title: 'Track 2',
          artistName: 'Artist 2',
          albumName: 'Album 2',
          genre: 'Pop',
          durationSeconds: 200,
          audioUrl: 'https://example.com/2.mp3',
          musicSource: 'Source',
          licenseInfo: 'License',
          isStreamable: true,
          isDownloadable: false,
        ),
      ];

      await controller.playTrack(queue[0], queue: queue);
      expect(controller.currentIndex.value, 0);

      await controller.playNext();
      expect(controller.currentIndex.value, 1);
      expect(controller.currentTrack.value?.title, 'Track 2');

      await controller.playPrevious();
      expect(controller.currentIndex.value, 0);
      expect(controller.currentTrack.value?.title, 'Track 1');
    });

    testWidgets('toggleShuffle and toggleRepeat toggle reactive flags', (tester) async {
      final mockHandler = MockAudioPlayerHandler();
      final controller = PlayerController(mockHandler);

      expect(controller.isShuffle.value, false);
      controller.toggleShuffle();
      expect(controller.isShuffle.value, true);

      expect(controller.isRepeat.value, false);
      controller.toggleRepeat();
      expect(controller.isRepeat.value, true);
    });

    test('toggleLike adds, removes and persists track across restarts', () async {
      final mockHandler = MockAudioPlayerHandler();
      final databaseService = MemoryLocalDatabaseService();
      final controller = PlayerController(mockHandler, databaseService: databaseService);

      const track = TrackModel(
        trackId: '101',
        title: 'Born To Shine',
        artistName: 'Diljit Dosanjh',
        albumName: 'G.O.A.T.',
        genre: 'Punjabi',
        durationSeconds: 214,
        audioUrl: 'https://example.com/stream.mp3',
        musicSource: 'JioSaavn',
        licenseInfo: 'Licensed',
        isStreamable: true,
        isDownloadable: false,
      );

      expect(controller.isTrackLiked('101'), false);
      expect(controller.likedTracks.length, 0);

      // Like track
      await controller.toggleLike(track);
      expect(controller.isTrackLiked('101'), true);
      expect(controller.likedTracks.length, 1);
      expect(controller.likedTracks.first.title, 'Born To Shine');

      // Verify it was persisted to storage
      final storedSongs = await databaseService.getLikedSongs();
      expect(storedSongs.length, 1);
      expect(storedSongs.first.trackId, '101');

      // Simulate app restart by initializing a new PlayerController with the same database
      final restartedController = PlayerController(mockHandler, databaseService: databaseService);
      restartedController.onInit();
      // Wait microtask for async storage load
      await Future.delayed(const Duration(milliseconds: 50));

      expect(restartedController.isTrackLiked('101'), true);
      expect(restartedController.likedTracks.length, 1);
      expect(restartedController.likedTracks.first.title, 'Born To Shine');

      // Unlike track
      await restartedController.toggleLike(track);
      expect(restartedController.isTrackLiked('101'), false);
      expect(restartedController.likedTracks.length, 0);
      expect(await databaseService.getLikedSongs(), isEmpty);
    });

    test('toggleDownload saves track for offline listening and removes on second toggle', () async {
      final mockHandler = MockAudioPlayerHandler();
      final databaseService = MemoryLocalDatabaseService();
      final controller = PlayerController(mockHandler, databaseService: databaseService);
      controller.onInit();

      const track = TrackModel(
        trackId: 'dl_202',
        title: 'Proper Patola',
        artistName: 'Diljit Dosanjh',
        albumName: 'Proper Patola',
        genre: 'Punjabi',
        durationSeconds: 180,
        audioUrl: 'https://example.com/proper_patola.mp3',
        musicSource: 'JioSaavn',
        licenseInfo: 'Licensed',
        isStreamable: true,
        isDownloadable: true,
      );

      expect(controller.isTrackDownloaded('dl_202'), false);
      expect(controller.downloadedTracks.length, 0);

      // Download track
      await controller.toggleDownload(track);
      expect(controller.isTrackDownloaded('dl_202'), true);
      expect(controller.downloadedTracks.length, 1);
      expect(controller.downloadedTracks.first.title, 'Proper Patola');

      // Verify DB persistence
      final storedDownloads = await databaseService.getDownloadedSongs();
      expect(storedDownloads.length, 1);
      expect(storedDownloads.first.trackId, 'dl_202');

      // Simulate app restart: new PlayerController instance with same database
      final restartedController = PlayerController(mockHandler, databaseService: databaseService);
      restartedController.onInit();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(restartedController.isTrackDownloaded('dl_202'), true);
      expect(restartedController.downloadedTracks.length, 1);
      expect(restartedController.downloadedTracks.first.title, 'Proper Patola');

      // Second toggle removes download
      await restartedController.toggleDownload(track);
      expect(restartedController.isTrackDownloaded('dl_202'), false);
      expect(restartedController.downloadedTracks.length, 0);
      expect(await databaseService.getDownloadedSongs(), isEmpty);
    });

    testWidgets('Listening to a track for 10 seconds records it to listening history', (tester) async {
      final mockHandler = MockAudioPlayerHandler();
      final databaseService = MemoryLocalDatabaseService();
      final controller = PlayerController(mockHandler, databaseService: databaseService);

      const track = TrackModel(
        trackId: '10s_track',
        title: 'Ten Seconds Track',
        artistName: 'Test Artist',
        albumName: 'Test Album',
        genre: 'Pop',
        durationSeconds: 200,
        audioUrl: 'https://example.com/10s.mp3',
        musicSource: 'JioSaavn',
        licenseInfo: 'Licensed',
        isStreamable: true,
        isDownloadable: false,
      );

      await controller.playTrack(track);

      // Before 10 seconds, not in history
      expect(await databaseService.getListeningHistory(), isEmpty);

      // Trigger 10-second history record
      await controller.recordListeningHistoryForTest(track);
      final history = await databaseService.getListeningHistory();
      expect(history.length, 1);
      expect(history.first.title, 'Ten Seconds Track');
    });
  });
}
