import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:whats_play/services/saavn_service.dart';

void main() {
  group('SaavnService Tests', () {
    test('searchTracks returns empty list for empty query', () async {
      final service = SaavnService();
      final tracks = await service.searchTracks(query: '   ');
      expect(tracks, isEmpty);
    });

    test('searchTracks returns song search results', () async {
      final mockClient = MockClient((request) async {
        final url = request.url.toString();
        if (url.contains('search.getResults')) {
          return http.Response(
            jsonEncode({
              'results': [
                {
                  'id': 'track_song_1',
                  'title': 'Khamma Ramdevpir',
                  'subtitle': 'Hitesh Prajapati - Album',
                  'language': 'gujarati',
                  'image': 'https://c.saavncdn.com/150x150.jpg',
                  'more_info': {
                    'vlink': 'https://media.saavncdn.com/preview.mp3',
                    'duration': '389',
                  }
                }
              ]
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (url.contains('search.getArtistResults')) {
          return http.Response(
            jsonEncode({'results': []}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = SaavnService(client: mockClient);
      final tracks = await service.searchTracks(query: 'Khamma Ramdevpir');

      expect(tracks.length, 1);
      expect(tracks[0].title, 'Khamma Ramdevpir');
      expect(tracks[0].artistName, 'Hitesh Prajapati');
      expect(tracks[0].isStreamable, true);
    });

    test('searchTracks detects artist query and retrieves artist top songs', () async {
      final mockClient = MockClient((request) async {
        final url = request.url.toString();
        if (url.contains('search.getArtistResults')) {
          return http.Response(
            jsonEncode({
              'results': [
                {
                  'name': 'Hitesh Prajapati',
                  'artistid': '843306',
                }
              ]
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (url.contains('artist.getArtistPageDetails')) {
          return http.Response(
            jsonEncode({
              'topSongs': [
                {
                  'id': 'artist_song_1',
                  'title': 'Pragat Piranu Navkhand Neje Punjanu',
                  'subtitle': 'Hitesh Prajapati - Bhakti',
                  'language': 'gujarati',
                  'image': 'https://c.saavncdn.com/150x150.jpg',
                  'more_info': {
                    'vlink': 'https://media.saavncdn.com/hitesh1.mp3',
                    'duration': '252',
                  }
                },
                {
                  'id': 'artist_song_2',
                  'title': 'Khamma Ramdevpir',
                  'subtitle': 'Hitesh Prajapati - Bhakti',
                  'language': 'gujarati',
                  'image': 'https://c.saavncdn.com/150x150.jpg',
                  'more_info': {
                    'vlink': 'https://media.saavncdn.com/hitesh2.mp3',
                    'duration': '389',
                  }
                }
              ]
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (url.contains('search.getResults')) {
          return http.Response(
            jsonEncode({'results': []}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = SaavnService(client: mockClient);
      final tracks = await service.searchTracks(query: 'Hitesh Prajapati');

      expect(tracks.length, 2);
      expect(tracks[0].title, 'Pragat Piranu Navkhand Neje Punjanu');
      expect(tracks[0].artistName, 'Hitesh Prajapati');
      expect(tracks[1].title, 'Khamma Ramdevpir');
    });

    test('getTrendingTracks falls back to Top Bollywood if genre is null or empty', () async {
      String? capturedQuery;
      final mockClient = MockClient((request) async {
        final url = request.url.toString();
        if (url.contains('search.getResults')) {
          capturedQuery = request.url.queryParameters['q'];
          return http.Response(
            jsonEncode({'results': []}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({'results': []}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = SaavnService(client: mockClient);
      await service.getTrendingTracks();

      expect(capturedQuery, 'Top Bollywood');
    });
  });
}
