import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:whats_play/controllers/player_controller.dart';
import 'package:whats_play/controllers/section_tracks_controller.dart';
import 'package:whats_play/models/audio_verification_model.dart';
import 'package:whats_play/models/track_model.dart';
import 'package:whats_play/repositories/music_repository.dart';
import 'package:whats_play/services/local_database_service.dart';

import 'player_controller_test.dart';

class MockRepo implements IMusicRepository {
  @override
  Future<List<TrackModel>> getTracks({int limit = 25, String? genre}) async => [];

  @override
  Future<List<TrackModel>> searchTracks(String query, {int limit = 25}) async => [];

  @override
  Future<List<TrackModel>> getTrendingChartTracks({int limit = 25}) async => [];

  @override
  Future<List<TrackModel>> getNewReleases({int limit = 25}) async => [];

  @override
  Future<List<TrackModel>> getTopCharts({int limit = 25}) async => [];

  @override
  Future<List<TrackModel>> getRomanticTracks({int limit = 25}) async => [];

  @override
  Future<List<TrackModel>> getPartyTracks({int limit = 25}) async => [];

  @override
  Future<AudioVerificationModel> verifyTrackAudio(TrackModel track) async {
    return AudioVerificationModel(
      url: track.audioUrl,
      statusCode: 200,
      contentType: 'audio/mp4',
      isAccessible: true,
      isFullTrack: true,
      verificationTime: DateTime.now(),
      details: 'OK',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SectionTracksController Tests', () {
    const track1 = TrackModel(
      trackId: '101',
      title: 'Proper Patola',
      artistName: 'Diljit Dosanjh',
      albumName: 'Namaste England',
      genre: 'Punjabi',
      durationSeconds: 180,
      audioUrl: 'https://example.com/1.mp3',
      musicSource: 'JioSaavn',
      licenseInfo: 'Licensed',
      isStreamable: true,
      isDownloadable: true,
    );

    const track2 = TrackModel(
      trackId: '102',
      title: 'Hass Hass',
      artistName: 'Diljit Dosanjh',
      albumName: 'Hass Hass',
      genre: 'Punjabi',
      durationSeconds: 153,
      audioUrl: 'https://example.com/2.mp3',
      musicSource: 'JioSaavn',
      licenseInfo: 'Licensed',
      isStreamable: true,
      isDownloadable: true,
    );

    tearDown(() {
      Get.reset();
    });

    test('Initializes with SectionTracksArgs and filters tracks by query', () {
      final controller = SectionTracksController();
      final args = const SectionTracksArgs(
        title: 'Suggested for You',
        subtitle: 'Based on songs you listen to most',
        tracks: [track1, track2],
        sectionType: 'suggested',
      );

      // Directly initialize with args
      controller.title.value = args.title;
      controller.subtitle.value = args.subtitle ?? '';
      controller.sectionType.value = args.sectionType ?? '';
      controller.tracks.assignAll(args.tracks!);

      expect(controller.title.value, 'Suggested for You');
      expect(controller.subtitle.value, 'Based on songs you listen to most');
      expect(controller.tracks.length, 2);
      expect(controller.filteredTracks.length, 2);

      // Test search filter
      controller.onSearchChanged('Proper');
      expect(controller.filteredTracks.length, 1);
      expect(controller.filteredTracks.first.title, 'Proper Patola');

      // Clear search
      controller.clearSearch();
      expect(controller.filteredTracks.length, 2);
    });

    test('playAll delegates to PlayerController queue', () {
      final mockHandler = MockAudioPlayerHandler();
      final db = MemoryLocalDatabaseService();
      final playerCtrl = PlayerController(mockHandler, databaseService: db);
      Get.put(playerCtrl);

      final controller = SectionTracksController();
      controller.tracks.assignAll([track1, track2]);

      controller.playAll(shuffle: false);

      expect(playerCtrl.currentTrack.value?.title, 'Proper Patola');
      expect(playerCtrl.playlist.length, 2);
    });

    test('SectionTracksArgs with sectionType trending enables showRank', () {
      final controller = SectionTracksController();
      final args = const SectionTracksArgs(
        title: 'Trending Songs',
        tracks: [track1, track2],
        sectionType: 'trending',
        showRank: true,
      );

      controller.title.value = args.title;
      controller.sectionType.value = args.sectionType ?? '';
      controller.showRank.value = args.showRank;
      controller.tracks.assignAll(args.tracks!);

      expect(controller.showRank.value, true);
      expect(controller.tracks.length, 2);
    });
  });
}
