import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:whats_play/controllers/category_detail_controller.dart';
import 'package:whats_play/controllers/player_controller.dart';
import 'package:whats_play/models/audio_verification_model.dart';
import 'package:whats_play/models/track_model.dart';
import 'package:whats_play/repositories/music_repository.dart';
import 'package:whats_play/services/local_database_service.dart';

import 'player_controller_test.dart';

class MockCategoryRepo implements IMusicRepository {
  final List<TrackModel> mockTracks;
  final bool shouldThrow;

  MockCategoryRepo({this.mockTracks = const [], this.shouldThrow = false});

  @override
  Future<List<TrackModel>> getTracks({int limit = 25, String? genre}) async {
    if (shouldThrow) throw Exception('GetTracks failed');
    return mockTracks;
  }

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

  group('CategoryDetailController Tests', () {
    const testTrack1 = TrackModel(
      trackId: '1',
      title: 'Proper Patola',
      artistName: 'Diljit Dosanjh',
      albumName: 'Proper Patola',
      genre: 'Punjabi',
      durationSeconds: 210,
      audioUrl: 'https://example.com/1.mp3',
      musicSource: 'JioSaavn',
      licenseInfo: 'Licensed',
      isStreamable: true,
      isDownloadable: false,
    );

    const testTrack2 = TrackModel(
      trackId: '2',
      title: 'Lover',
      artistName: 'Diljit Dosanjh',
      albumName: 'MoonChild Era',
      genre: 'Punjabi',
      durationSeconds: 195,
      audioUrl: 'https://example.com/2.mp3',
      musicSource: 'JioSaavn',
      licenseInfo: 'Licensed',
      isStreamable: true,
      isDownloadable: false,
    );

    tearDown(() {
      Get.reset();
    });

    test('loadCategoryTracks loads tracks into controller successfully', () async {
      final repo = MockCategoryRepo(mockTracks: [testTrack1, testTrack2]);
      final controller = CategoryDetailController(repo);

      await controller.loadCategoryTracks('Punjabi');

      expect(controller.isLoading.value, false);
      expect(controller.tracks.length, 2);
      expect(controller.tracks.first.title, 'Proper Patola');
      expect(controller.errorMessage.value, isEmpty);
    });

    test('loadCategoryTracks transitions to error message on failure', () async {
      final repo = MockCategoryRepo(shouldThrow: true);
      final controller = CategoryDetailController(repo);

      await controller.loadCategoryTracks('Punjabi');

      expect(controller.isLoading.value, false);
      expect(controller.tracks, isEmpty);
      expect(controller.errorMessage.value, contains('Failed to load tracks'));
    });

    test('playAll delegates to PlayerController with queue and shuffle options', () {
      final repo = MockCategoryRepo(mockTracks: [testTrack1, testTrack2]);
      final controller = CategoryDetailController(repo);
      final mockHandler = MockAudioPlayerHandler();
      final playerController = PlayerController(
        mockHandler,
        databaseService: MemoryLocalDatabaseService(),
      );

      Get.put<PlayerController>(playerController);

      controller.tracks.assignAll([testTrack1, testTrack2]);

      // Regular play
      controller.playAll(shuffle: false);
      expect(playerController.currentTrack.value?.title, 'Proper Patola');
      expect(playerController.playlist.length, 2);
      expect(playerController.isShuffle.value, false);

      // Shuffle play
      controller.playAll(shuffle: true);
      expect(playerController.playlist.length, 2);
      expect(playerController.isShuffle.value, true);
    });

    test('CategoryDetailArgs parses title, color, imageUrl and initial tracks', () {
      final args = const CategoryDetailArgs(
        title: 'Bollywood',
        query: 'Bollywood',
        color: Color(0xFF8D67AB),
        imageUrl: 'https://example.com/bollywood.jpg',
        initialTracks: [testTrack1],
      );

      expect(args.title, 'Bollywood');
      expect(args.query, 'Bollywood');
      expect(args.color, const Color(0xFF8D67AB));
      expect(args.imageUrl, 'https://example.com/bollywood.jpg');
      expect(args.initialTracks?.length, 1);
    });
  });
}
