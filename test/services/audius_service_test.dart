import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:whats_play/services/audius_service.dart';

void main() {
  group('AudiusService Tests', () {
    test('getTrendingTracks returns parsed tracks on HTTP 200', () async {
      final mockJson = {
        'data': [
          {
            'id': 'track_1',
            'title': 'Test Song One',
            'genre': 'Electronic',
            'duration': 210,
            'is_streamable': true,
            'user': {'name': 'DJ Tester'},
          },
          {
            'id': 'track_2',
            'title': 'Test Song Two',
            'genre': 'Synthwave',
            'duration': 180,
            'is_streamable': false,
            'user': {'name': 'Retro Wave'},
          }
        ]
      };

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode(mockJson),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AudiusService(client: mockClient);
      final tracks = await service.getTrendingTracks(limit: 2);

      expect(tracks.length, 2);
      expect(tracks[0].title, 'Test Song One');
      expect(tracks[0].artistName, 'DJ Tester');
      expect(tracks[0].isStreamable, true);
      expect(tracks[1].title, 'Test Song Two');
      expect(tracks[1].isStreamable, false);
    });

    test('getTrendingTracks appends genre query parameter when genre is provided', () async {
      Uri? capturedUri;
      final mockClient = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(
          jsonEncode({'data': []}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AudiusService(client: mockClient);
      await service.getTrendingTracks(genre: 'Pop');

      expect(capturedUri, isNotNull);
      expect(capturedUri!.queryParameters['genre'], 'Pop');
    });

    test('searchTracks queries search endpoint and returns tracks', () async {
      Uri? capturedUri;
      final mockJson = {
        'data': [
          {
            'id': 'diljit_1',
            'title': 'G.O.A.T.',
            'genre': 'Punjabi',
            'duration': 223,
            'is_streamable': true,
            'user': {'name': 'Diljit Dosanjh'},
          }
        ]
      };

      final mockClient = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(
          jsonEncode(mockJson),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AudiusService(client: mockClient);
      final results = await service.searchTracks(query: 'Diljit');

      expect(capturedUri, isNotNull);
      expect(capturedUri!.path, contains('/v1/tracks/search'));
      expect(capturedUri!.queryParameters['query'], 'Diljit');
      expect(results.length, 1);
      expect(results.first.title, 'G.O.A.T.');
      expect(results.first.artistName, 'Diljit Dosanjh');
    });

    test('getTrendingTracks throws on non-200 HTTP response', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Service Unavailable', 503);
      });

      final service = AudiusService(client: mockClient);

      expect(() => service.getTrendingTracks(), throwsException);
    });

    test('verifyAudioStream reports success when stream returns 200 with audio/mpeg', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '',
          200,
          headers: {'content-type': 'audio/mpeg'},
        );
      });

      final service = AudiusService(client: mockClient);
      final result = await service.verifyAudioStream('https://api.audius.co/v1/tracks/123/stream');

      expect(result.isAccessible, true);
      expect(result.isFullTrack, true);
      expect(result.statusCode, 200);
      expect(result.contentType, 'audio/mpeg');
    });
  });
}
