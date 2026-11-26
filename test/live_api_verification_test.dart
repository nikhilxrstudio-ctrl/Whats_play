// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';
import 'package:whats_play/models/track_model.dart';
import 'package:whats_play/services/audius_service.dart';
import 'package:whats_play/services/saavn_service.dart';
import 'package:whats_play/repositories/music_repository.dart';

void main() {
  test('Live Network Integration Test - Fetch Rich Hits (Diljit, Honey, Gujarati) with 100% Matching Art & Audio', () async {
    final audiusService = AudiusService();
    final saavnService = SaavnService();
    final repository = MusicRepository(
      audiusService: audiusService,
      saavnService: saavnService,
    );

    // 1. Fetch rich songs for "Diljit Dosanjh"
    final diljitTracks = await repository.searchTracks('Diljit Dosanjh', limit: 3);
    expect(diljitTracks, isNotEmpty);
    print('\n================ DILJIT DOSANJH REAL HITS (${diljitTracks.length}) ================');
    for (final t in diljitTracks) {
      print('• "${t.title}" from Album: [${t.albumName}] by ${t.artistName} (${t.formattedDuration})');
      print('  Artwork (500x500): ${t.artworkUrl}');
      print('  Audio Stream: ${t.audioUrl}');
    }

    // 2. Fetch rich songs for "Honey Singh"
    final honeyTracks = await repository.searchTracks('Honey Singh', limit: 3);
    expect(honeyTracks, isNotEmpty);
    print('\n================ HONEY SINGH REAL HITS (${honeyTracks.length}) ================');
    for (final t in honeyTracks) {
      print('• "${t.title}" from Album: [${t.albumName}] by ${t.artistName} (${t.formattedDuration})');
      print('  Artwork (500x500): ${t.artworkUrl}');
      print('  Audio Stream: ${t.audioUrl}');
    }

    // 3. Fetch rich songs for "Gujarati"
    final gujaratiTracks = await repository.searchTracks('Gujarati', limit: 3);
    expect(gujaratiTracks, isNotEmpty);
    print('\n================ GUJARATI REAL HITS (${gujaratiTracks.length}) ================');
    for (final t in gujaratiTracks) {
      print('• "${t.title}" from Album: [${t.albumName}] by ${t.artistName} (${t.formattedDuration})');
      print('  Artwork (500x500): ${t.artworkUrl}');
      print('  Audio Stream: ${t.audioUrl}');
    }

    // 4. Verify live audio stream of the first Diljit track
    final firstTrack = diljitTracks.first;
    print('\nTesting live audio stream for: "${firstTrack.title}" (${firstTrack.audioUrl})');
    final verification = await repository.verifyTrackAudio(firstTrack);
    print('Audio Verification Result:');
    print('  - HTTP Status: ${verification.statusCode}');
    print('  - Content-Type: ${verification.contentType}');
    print('  - Accessible: ${verification.isAccessible}');
    print('  - Full Track Playable: ${verification.isFullTrack}');
    print('  - Details: ${verification.details}');
    print('==============================================================\n');

    expect(verification.isAccessible, isTrue);
    expect(verification.statusCode, 200);
    expect(verification.isFullTrack, isTrue);

    // 5. Fetch real official Trending chart tracks
    final trendingChart = await repository.getTrendingChartTracks(limit: 5);
    expect(trendingChart, isNotEmpty);
    print('\n================ REAL TRENDING CHART HITS (${trendingChart.length}) ================');
    for (int i = 0; i < trendingChart.length; i++) {
      final t = trendingChart[i];
      print('• #${i + 1}: "${t.title}" by ${t.artistName} (${t.formattedDuration})');
      print('  Artwork: ${t.artworkUrl}');
      print('  Audio Stream: ${t.audioUrl}');
    }
    print('====================================================================\n');
  });

  test('Inspect JioSaavn Trending and Top Charts APIs', () async {
    final client = http.Client();
    final headers = {
      'Accept': 'application/json',
      'User-Agent':
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    };

    // Test 1: content.getTrending
    final trendingUri = Uri.parse(
      'https://www.jiosaavn.com/api.php?__call=content.getTrending&_format=json&_marker=0&api_version=4&ctx=web6dot0',
    );
    final res1 = await client.get(trendingUri, headers: headers);
    print('content.getTrending status: ${res1.statusCode}');
    if (res1.statusCode == 200) {
      try {
        final data = jsonDecode(res1.body);
        if (data is List) {
          final types = data.map((e) => e['type']).toSet();
          print('content.getTrending types: $types');
          for (final item in data) {
            if (item['type'] == 'song') {
              print('  Trending Song: ${item['title']} - ${item['more_info']?['singers']}');
            }
          }
        }
      } catch (e) {
        print('Error parsing getTrending: $e');
      }
    }

    // Test playlist.getDetails for "Trending Today" (listid: 110858205)
    final playlistUri = Uri.parse(
      'https://www.jiosaavn.com/api.php?__call=playlist.getDetails&listid=110858205&_format=json&_marker=0&api_version=4&ctx=web6dot0',
    );
    final resPl = await client.get(playlistUri, headers: headers);
    print('Trending Today playlist status: ${resPl.statusCode}');
    if (resPl.statusCode == 200) {
      final plData = jsonDecode(resPl.body);
      print('Playlist keys: ${plData is Map ? plData.keys.toList() : plData.runtimeType}');
      if (plData is Map) {
        final list = plData['list'] ?? plData['songs'];
        print('Playlist list count: ${list is List ? list.length : list?.runtimeType}');
        if (list is List && list.isNotEmpty) {
          for (int i = 0; i < 5; i++) {
            final t = TrackModel.fromSaavnJson(list[i] as Map<String, dynamic>);
            print('  #${i + 1}: "${t.title}" by "${t.artistName}" (${t.formattedDuration})');
            print('     audioUrl: ${t.audioUrl}');
            print('     artworkUrl: ${t.artworkUrl}');
            print('     streamable: ${t.isStreamable}');
          }
        }
      }
    }

    // Test 2: content.getCharts
    final chartsUri = Uri.parse(
      'https://www.jiosaavn.com/api.php?__call=content.getCharts&_format=json&_marker=0&api_version=4&ctx=web6dot0',
    );
    final res2 = await client.get(chartsUri, headers: headers);
    print('content.getCharts status: ${res2.statusCode}');
    if (res2.statusCode == 200) {
      try {
        final data = jsonDecode(res2.body);
        if (data is List) {
          print('content.getCharts items: ${data.length}');
          for (final item in data.take(5)) {
            if (item is Map) {
              print('  Chart: ${item['title']} (listid: ${item['listid'] ?? item['id']})');
            }
          }
        }
      } catch (e) {
        print('Error parsing getCharts: $e');
      }
    }

    // Test 3: New Releases endpoints
    final newReleasesUri = Uri.parse(
      'https://www.jiosaavn.com/api.php?__call=search.getPlaylistResults&q=New+Releases&_format=json&_marker=0&api_version=4&ctx=web6dot0&n=5',
    );
    final resNR = await client.get(newReleasesUri, headers: headers);
    print('search.getPlaylistResults New Releases: ${resNR.statusCode}');
    if (resNR.statusCode == 200) {
      final plData = jsonDecode(resNR.body);
      final results = plData['results'] as List?;
      print('  playlists found: ${results?.length}');
      if (results != null) {
        for (final p in results.take(3)) {
          print('    Playlist: "${p['title']}" (listid: ${p['listid'] ?? p['id']})');
        }
      }
    }

    // Test Taaza Tunes (listid: 6689255) - Official New Releases playlist!
    final taazaUri = Uri.parse(
      'https://www.jiosaavn.com/api.php?__call=playlist.getDetails&listid=6689255&_format=json&_marker=0&api_version=4&ctx=web6dot0',
    );
    final resTT = await client.get(taazaUri, headers: headers);
    print('Taaza Tunes status: ${resTT.statusCode}');
    if (resTT.statusCode == 200) {
      final data = jsonDecode(resTT.body);
      print('Taaza Tunes title: ${data['title']}');
      final list = data['list'] ?? data['songs'];
      print('Taaza Tunes songs count: ${list is List ? list.length : 0}');
      if (list is List) {
        for (int i = 0; i < (list.length < 5 ? list.length : 5); i++) {
          final t = TrackModel.fromSaavnJson(list[i] as Map<String, dynamic>);
          print('  #${i + 1}: "${t.title}" by ${t.artistName} (${t.formattedDuration}) - ${t.albumName}');
        }
      }
    }
  });
}
