import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:whats_play/controllers/artist_detail_controller.dart';
import 'package:whats_play/controllers/player_controller.dart';
import 'package:whats_play/models/artist_category_model.dart';
import 'package:whats_play/models/audio_verification_model.dart';
import 'package:whats_play/models/track_model.dart';
import 'package:whats_play/repositories/music_repository.dart';
import 'package:whats_play/services/local_database_service.dart';

import 'player_controller_test.dart';

class MockArtistRepo implements IMusicRepository {
  final List<TrackModel> mockTracks;
  final bool shouldThrow;

  MockArtistRepo({this.mockTracks = const [], this.shouldThrow = false});

  @override
  Future<List<TrackModel>> getTracks({int limit = 25, String? genre}) async => mockTracks;

  @override
  Future<List<TrackModel>> searchTracks(String query, {int limit = 25}) async {
    if (shouldThrow) throw Exception('Search failed');
    return mockTracks;
  }

  @override
  Future<List<TrackModel>> getTrendingChartTracks({int limit = 25}) async => mockTracks;

  @override
  Future<List<TrackModel>> getNewReleases({int limit = 25}) async => mockTracks;

  @override
  Future<List<TrackModel>> getTopCharts({int limit = 25}) async => mockTracks;

  @override
  Future<List<TrackModel>> getRomanticTracks({int limit = 25}) async => mockTracks;

  @override
  Future<List<TrackModel>> getPartyTracks({int limit = 25}) async => mockTracks;

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

  group('ArtistDetailController Tests', () {
    const testArtist = ArtistCategoryModel(
      id: 'diljit',
      name: 'Diljit Dosanjh',
      query: 'Diljit Dosanjh',
      categoryLabel: 'Artist',
      imageUrl: 'https://example.com/diljit.jpg',
    );

    const testTrack = TrackModel(
      trackId: '1',
      title: 'Born to Shine',
      artistName: 'Diljit Dosanjh',
      albumName: 'G.O.A.T.',
      genre: 'Punjabi',
      durationSeconds: 214,
      audioUrl: 'https://example.com/stream.mp4',
      musicSource: 'JioSaavn',
      licenseInfo: 'Licensed',
      isStreamable: true,
      isDownloadable: false,
    );

    test('loadArtistTracks loads tracks into controller successfully', () async {
      final repo = MockArtistRepo(mockTracks: [testTrack]);
      final controller = ArtistDetailController(repo);

      await controller.loadArtistTracks(testArtist);

      expect(controller.isLoading.value, false);
      expect(controller.tracks.length, 1);
      expect(controller.tracks.first.title, 'Born to Shine');
      expect(controller.errorMessage.value, isEmpty);
    });

    test('loadArtistTracks transitions to error state on failure', () async {
      final repo = MockArtistRepo(shouldThrow: true);
      final controller = ArtistDetailController(repo);

      await controller.loadArtistTracks(testArtist);

      expect(controller.isLoading.value, false);
      expect(controller.tracks, isEmpty);
      expect(controller.errorMessage.value, contains('Failed to load tracks'));
    });

    test('toggleFollow toggles following state', () {
      final repo = MockArtistRepo();
      final controller = ArtistDetailController(repo);

      expect(controller.isFollowing.value, false);
      controller.toggleFollow();
      expect(controller.isFollowing.value, true);
      controller.toggleFollow();
      expect(controller.isFollowing.value, false);
    });

    test('playAll queues and plays tracks in PlayerController', () {
      final mockHandler = MockAudioPlayerHandler();
      final playerCtrl = PlayerController(
        mockHandler,
        databaseService: MemoryLocalDatabaseService(),
      );
      Get.put<PlayerController>(playerCtrl);

      final repo = MockArtistRepo(mockTracks: [testTrack]);
      final controller = ArtistDetailController(repo);
      controller.tracks.assignAll([testTrack]);

      controller.playAll();

      expect(playerCtrl.currentTrack.value?.title, 'Born to Shine');
      expect(playerCtrl.playlist.length, 1);

      Get.delete<PlayerController>();
    });
  });
}
