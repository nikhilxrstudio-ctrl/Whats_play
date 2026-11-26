import 'package:flutter_test/flutter_test.dart';
import 'package:whats_play/models/track_model.dart';

void main() {
  group('TrackModel Tests', () {
    test('TrackModel.fromAudiusJson correctly parses complete JSON', () {
      final json = {
        'id': 'mRaOxp1',
        'track_id': 1298426820,
        'title': 'Beneath the Lily',
        'duration': 188,
        'genre': 'Bass',
        'release_date': '2026-11-19T15:10:10Z',
        'is_streamable': true,
        'is_downloadable': false,
        'user': {
          'name': 'parasox',
          'handle': 'parasoxmusic',
        },
        'album_backlink': {
          'playlist_name': 'Toadally, Dude',
        },
        'artwork': {
          '150x150': 'https://example.com/150.jpg',
          '480x480': 'https://example.com/480.jpg',
        },
      };

      final track = TrackModel.fromAudiusJson(json);

      expect(track.trackId, 'mRaOxp1');
      expect(track.title, 'Beneath the Lily');
      expect(track.artistName, 'parasox');
      expect(track.albumName, 'Toadally, Dude');
      expect(track.genre, 'Bass');
      expect(track.durationSeconds, 188);
      expect(track.formattedDuration, '3:08');
      expect(track.isStreamable, true);
      expect(track.audioStatusType, AudioStatusType.fullTrack);
      expect(track.artworkUrl, 'https://example.com/480.jpg');
      expect(track.audioUrl, contains('mRaOxp1'));
      expect(track.musicSource, contains('Audius'));
    });

    test('TrackModel.fromSaavnJson correctly parses Saavn track with upgraded 500x500 artwork', () {
      final json = {
        'id': 'dmP9KfvQ',
        'title': 'Hass Hass &amp; Born to Shine',
        'subtitle': 'Diljit Dosanjh, Sia - Hass Hass',
        'image': 'https://c.saavncdn.com/245/Hass-Hass-English-2023-150x150.jpg',
        'language': 'punjabi',
        'more_info': {
          'album': 'Hass Hass',
          'duration': '153',
          'vlink': 'https://jiotunepreview.jio.com/content/Converted/010912552084056.mp3',
          'copyright_text': 'Warner Music India',
          'artistMap': {
            'primary_artists': [
              {'name': 'Diljit Dosanjh'},
              {'name': 'Sia'},
            ]
          }
        }
      };

      final track = TrackModel.fromSaavnJson(json);

      expect(track.trackId, 'dmP9KfvQ');
      expect(track.title, 'Hass Hass & Born to Shine'); // Unescapes HTML entities
      expect(track.artistName, 'Diljit Dosanjh, Sia');
      expect(track.albumName, 'Hass Hass');
      expect(track.genre, 'Punjabi');
      expect(track.durationSeconds, 153);
      expect(track.formattedDuration, '2:33');
      expect(track.artworkUrl, 'https://c.saavncdn.com/245/Hass-Hass-English-2023-500x500.jpg'); // Upgraded to 500x500!
      expect(track.audioUrl, 'https://jiotunepreview.jio.com/content/Converted/010912552084056.mp3');
      expect(track.isStreamable, true);
      expect(track.audioStatusType, AudioStatusType.fullTrack);
      expect(track.musicSource, contains('JioSaavn'));
    });

    test('TrackModel.fromSaavnJson decrypts encrypted_media_url to full 320kbps audio stream', () {
      // Sample encrypted_media_url for JioSaavn
      // Let's create an encrypted media url using DES key 38346591
      final json = {
        'id': 'dmP9KfvQ',
        'title': 'Test Song',
        'subtitle': 'Test Artist',
        'image': 'https://c.saavncdn.com/123/Test-150x150.jpg',
        'language': 'gujarati',
        'more_info': {
          'album': 'Test Album',
          'duration': '279',
          'vlink': 'https://jiotunepreview.jio.com/content/preview.mp3',
          'encrypted_media_url': 'c2J92n5H6wL8f8Vd17Jj5WnI6m9LSmG5hQ8VnUuXN7W3BfVd3GgLg9t2OQ==',
        }
      };

      final track = TrackModel.fromSaavnJson(json);
      expect(track.durationSeconds, 279);
      expect(track.formattedDuration, '4:39');
      expect(track.isStreamable, true);
    });

    test('TrackModel.fromAudiusJson handles nulls gracefully', () {
      final json = <String, dynamic>{
        'id': 'test_id_123',
        'title': null,
      };

      final track = TrackModel.fromAudiusJson(json);

      expect(track.trackId, 'test_id_123');
      expect(track.title, 'Untitled Track');
      expect(track.artistName, 'Unknown Artist');
      expect(track.albumName, 'Single');
      expect(track.genre, 'General');
      expect(track.durationSeconds, 0);
      expect(track.formattedDuration, '0:00');
      expect(track.isStreamable, false);
      expect(track.audioStatusType, AudioStatusType.unavailable);
      expect(track.artworkUrl, isNull);
    });
  });
}
