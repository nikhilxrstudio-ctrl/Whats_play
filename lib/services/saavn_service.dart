import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/audio_verification_model.dart';
import '../models/track_model.dart';
import 'api_service.dart';

class SaavnService implements IApiService {
  final http.Client _client;

  SaavnService({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<List<TrackModel>> getTrendingTracks({
    int limit = 25,
    String? genre,
  }) async {
    if (genre == null ||
        genre.isEmpty ||
        genre.toLowerCase() == 'all' ||
        genre.toLowerCase() == 'trending') {
      return await getRealTrendingTracks(limit: limit);
    }
    return await searchTracks(query: genre, limit: limit);
  }

  /// Fetches authentic real-time trending tracks from JioSaavn's official charts:
  /// 1. "Trending Today" official chart playlist (listid: 110858205)
  /// 2. "India Superhits Top 50" (listid: 1134548194)
  /// 3. JioSaavn real-time trending songs feed (__call=content.getTrending)
  Future<List<TrackModel>> getRealTrendingTracks({int limit = 25}) async {
    final headers = {
      'Accept': 'application/json',
      'User-Agent':
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    };

    // 1. Try official "Trending Today" playlist (listid: 110858205)
    try {
      final trendingUri = Uri.parse(
        'https://www.jiosaavn.com/api.php?__call=playlist.getDetails&listid=110858205&_format=json&_marker=0&api_version=4&ctx=web6dot0',
      );
      final res = await _client.get(trendingUri, headers: headers).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map) {
          final list = data['list'] ?? data['songs'];
          if (list is List && list.isNotEmpty) {
            final tracks = <TrackModel>[];
            for (final item in list) {
              if (item is Map<String, dynamic>) {
                final track = TrackModel.fromSaavnJson(item);
                if (track.isStreamable) tracks.add(track);
              }
            }
            if (tracks.isNotEmpty) {
              debugPrint('[SaavnService] Loaded ${tracks.length} real trending tracks from "Trending Today" chart.');
              return tracks.take(limit).toList();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[SaavnService] Error fetching "Trending Today" chart: $e');
    }

    // 2. Try official "India Superhits Top 50" chart (listid: 1134548194)
    try {
      final superhitsUri = Uri.parse(
        'https://www.jiosaavn.com/api.php?__call=playlist.getDetails&listid=1134548194&_format=json&_marker=0&api_version=4&ctx=web6dot0',
      );
      final res = await _client.get(superhitsUri, headers: headers).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map) {
          final list = data['list'] ?? data['songs'];
          if (list is List && list.isNotEmpty) {
            final tracks = <TrackModel>[];
            for (final item in list) {
              if (item is Map<String, dynamic>) {
                final track = TrackModel.fromSaavnJson(item);
                if (track.isStreamable) tracks.add(track);
              }
            }
            if (tracks.isNotEmpty) {
              debugPrint('[SaavnService] Loaded ${tracks.length} real trending tracks from "India Superhits Top 50".');
              return tracks.take(limit).toList();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[SaavnService] Error fetching "India Superhits Top 50": $e');
    }

    // 3. Fallback: query content.getTrending
    try {
      final feedUri = Uri.parse(
        'https://www.jiosaavn.com/api.php?__call=content.getTrending&_format=json&_marker=0&api_version=4&ctx=web6dot0',
      );
      final res = await _client.get(feedUri, headers: headers).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List && data.isNotEmpty) {
          final tracks = <TrackModel>[];
          for (final item in data) {
            if (item is Map<String, dynamic> && item['type'] == 'song') {
              final track = TrackModel.fromSaavnJson(item);
              if (track.isStreamable) tracks.add(track);
            }
          }
          if (tracks.isNotEmpty) {
            debugPrint('[SaavnService] Loaded ${tracks.length} real trending songs from content.getTrending.');
            return tracks.take(limit).toList();
          }
        }
      }
    } catch (e) {
      debugPrint('[SaavnService] Error fetching content.getTrending: $e');
    }

    // Fallback: search popular Hindi hits
    return await searchTracks(query: 'Top Bollywood', limit: limit);
  }

  /// Fetches authentic real-time new release tracks from JioSaavn:
  /// 1. "Taaza Tunes" official new releases flagship playlist (listid: 6689255)
  /// 2. "New Hits Hindi" playlist (listid: 1300709425)
  /// 3. Fallback search for latest hits
  Future<List<TrackModel>> getNewReleases({int limit = 25}) async {
    final headers = {
      'Accept': 'application/json',
      'User-Agent':
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    };

    // 1. Try official "Taaza Tunes" playlist (listid: 6689255)
    try {
      final taazaUri = Uri.parse(
        'https://www.jiosaavn.com/api.php?__call=playlist.getDetails&listid=6689255&_format=json&_marker=0&api_version=4&ctx=web6dot0',
      );
      final res = await _client.get(taazaUri, headers: headers).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map) {
          final list = data['list'] ?? data['songs'];
          if (list is List && list.isNotEmpty) {
            final tracks = <TrackModel>[];
            for (final item in list) {
              if (item is Map<String, dynamic>) {
                final track = TrackModel.fromSaavnJson(item);
                if (track.isStreamable) tracks.add(track);
              }
            }
            if (tracks.isNotEmpty) {
              debugPrint('[SaavnService] Loaded ${tracks.length} tracks from "Taaza Tunes" New Releases.');
              return tracks.take(limit).toList();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[SaavnService] Error fetching "Taaza Tunes" New Releases: $e');
    }

    // 2. Try "New Hits Hindi" playlist (listid: 1300709425)
    try {
      final newHitsUri = Uri.parse(
        'https://www.jiosaavn.com/api.php?__call=playlist.getDetails&listid=1300709425&_format=json&_marker=0&api_version=4&ctx=web6dot0',
      );
      final res = await _client.get(newHitsUri, headers: headers).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map) {
          final list = data['list'] ?? data['songs'];
          if (list is List && list.isNotEmpty) {
            final tracks = <TrackModel>[];
            for (final item in list) {
              if (item is Map<String, dynamic>) {
                final track = TrackModel.fromSaavnJson(item);
                if (track.isStreamable) tracks.add(track);
              }
            }
            if (tracks.isNotEmpty) {
              debugPrint('[SaavnService] Loaded ${tracks.length} tracks from "New Hits Hindi".');
              return tracks.take(limit).toList();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[SaavnService] Error fetching "New Hits Hindi": $e');
    }

    // 3. Fallback: search Latest Hindi Hits
    return await searchTracks(query: 'Latest Hindi Hits', limit: limit);
  }

  /// Fetches tracks from a specific JioSaavn playlist by its listid
  Future<List<TrackModel>> getPlaylistDetails(
    String listId, {
    int limit = 25,
    String? fallbackQuery,
  }) async {
    final headers = {
      'Accept': 'application/json',
      'User-Agent':
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    };
    try {
      final uri = Uri.parse(
        'https://www.jiosaavn.com/api.php?__call=playlist.getDetails&listid=$listId&_format=json&_marker=0&api_version=4&ctx=web6dot0',
      );
      final res = await _client.get(uri, headers: headers).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map) {
          final list = data['list'] ?? data['songs'];
          if (list is List && list.isNotEmpty) {
            final tracks = <TrackModel>[];
            for (final item in list) {
              if (item is Map<String, dynamic>) {
                final track = TrackModel.fromSaavnJson(item);
                if (track.isStreamable) tracks.add(track);
              }
            }
            if (tracks.isNotEmpty) {
              return tracks.take(limit).toList();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[SaavnService] Error fetching playlist $listId: $e');
    }

    if (fallbackQuery != null && fallbackQuery.isNotEmpty) {
      return await searchTracks(query: fallbackQuery, limit: limit);
    }
    return [];
  }

  @override
  Future<List<TrackModel>> searchTracks({
    required String query,
    int limit = 25,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    final cleanQueryLower = cleanQuery.toLowerCase();

    final songUri = Uri.parse(
      'https://www.jiosaavn.com/api.php?__call=search.getResults&q=${Uri.encodeComponent(cleanQuery)}&_format=json&_marker=0&api_version=4&ctx=web6dot0&n=$limit',
    );
    final artistUri = Uri.parse(
      'https://www.jiosaavn.com/api.php?__call=search.getArtistResults&q=${Uri.encodeComponent(cleanQuery)}&_format=json&_marker=0&api_version=4&ctx=web6dot0&n=5',
    );

    debugPrint('[SaavnService] Searching tracks and artists for: "$cleanQuery"');

    final headers = {
      'Accept': 'application/json',
      'User-Agent':
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    };

    try {
      // Query both song search and artist search in parallel
      final responses = await Future.wait([
        _client.get(songUri, headers: headers).timeout(const Duration(seconds: 12)),
        _client.get(artistUri, headers: headers).timeout(const Duration(seconds: 12)),
      ]);

      final songResponse = responses[0];
      final artistResponse = responses[1];

      final List<TrackModel> songTracks = [];
      if (songResponse.statusCode == 200) {
        try {
          final Map<String, dynamic> body = jsonDecode(songResponse.body);
          final List<dynamic>? results = body['results'];
          if (results != null) {
            for (final item in results) {
              if (item is Map<String, dynamic>) {
                final track = TrackModel.fromSaavnJson(item);
                if (track.isStreamable) songTracks.add(track);
              }
            }
          }
        } catch (e) {
          debugPrint('[SaavnService] Error parsing song search results: $e');
        }
      }

      final List<TrackModel> artistTracks = [];
      bool isStrongArtistMatch = false;

      if (artistResponse.statusCode == 200) {
        try {
          final Map<String, dynamic> body = jsonDecode(artistResponse.body);
          final List<dynamic>? artists = body['results'];
          if (artists != null && artists.isNotEmpty) {
            Map<String, dynamic>? bestArtist;
            for (final a in artists) {
              if (a is Map<String, dynamic>) {
                final name = (a['name'] ?? '').toString().trim().toLowerCase();
                if (name == cleanQueryLower ||
                    name.startsWith(cleanQueryLower) ||
                    cleanQueryLower.startsWith(name) ||
                    name.split(' ').any((p) => p.isNotEmpty && cleanQueryLower.split(' ').contains(p))) {
                  bestArtist = a;
                  break;
                }
              }
            }

            bestArtist ??= artists.first as Map<String, dynamic>;

            final artistName = (bestArtist['name'] ?? '').toString().trim().toLowerCase();
            final artistId = bestArtist['artistid'] ?? bestArtist['id'];

            final queryTokens = cleanQueryLower.split(' ').where((s) => s.isNotEmpty).toList();
            isStrongArtistMatch = artistName == cleanQueryLower ||
                artistName.startsWith(cleanQueryLower) ||
                cleanQueryLower.startsWith(artistName) ||
                (queryTokens.length > 1 && queryTokens.every((w) => artistName.contains(w)));

            if (artistId != null && (isStrongArtistMatch || songTracks.isEmpty)) {
              final artistPageUri = Uri.parse(
                'https://www.jiosaavn.com/api.php?__call=artist.getArtistPageDetails&artistId=$artistId&_format=json&_marker=0&api_version=4&ctx=web6dot0&n_song=$limit',
              );
              final pageRes = await _client.get(artistPageUri, headers: headers).timeout(const Duration(seconds: 12));
              if (pageRes.statusCode == 200) {
                final pageBody = jsonDecode(pageRes.body);
                final List<dynamic>? topSongs = pageBody['topSongs'];
                if (topSongs != null) {
                  for (final item in topSongs) {
                    if (item is Map<String, dynamic>) {
                      final track = TrackModel.fromSaavnJson(item);
                      if (track.isStreamable) artistTracks.add(track);
                    }
                  }
                }
              }
            }
          }
        } catch (e) {
          debugPrint('[SaavnService] Error fetching artist top songs: $e');
        }
      }

      // Merge & Deduplicate
      final Map<String, TrackModel> deduplicated = {};

      if (isStrongArtistMatch) {
        // User searched for an artist: prioritize artist's top hit songs first
        for (final t in artistTracks) {
          deduplicated[t.trackId] = t;
        }
        for (final t in songTracks) {
          deduplicated.putIfAbsent(t.trackId, () => t);
        }
      } else {
        // User searched for song title or genre: prioritize song results first
        for (final t in songTracks) {
          deduplicated[t.trackId] = t;
        }
        for (final t in artistTracks) {
          deduplicated.putIfAbsent(t.trackId, () => t);
        }
      }

      final results = deduplicated.values.take(limit).toList();
      debugPrint('[SaavnService] Successfully returned ${results.length} tracks for "$query".');
      return results;
    } on SocketException catch (e) {
      debugPrint('[SaavnService] Network error: $e');
      throw Exception('Network connection failed. Please check your internet connection.');
    } on TimeoutException catch (e) {
      debugPrint('[SaavnService] Timeout error: $e');
      throw Exception('Request timed out. Music API server took too long to respond.');
    } catch (e) {
      debugPrint('[SaavnService] Unexpected search error: $e');
      rethrow;
    }
  }

  @override
  Future<AudioVerificationModel> verifyAudioStream(String streamUrl) async {
    final stopwatch = Stopwatch()..start();
    debugPrint('[SaavnService] Verifying audio stream URL: $streamUrl');

    try {
      final uri = Uri.parse(streamUrl);
      final request = http.Request('GET', uri)
        ..followRedirects = true
        ..maxRedirects = 5
        ..headers['User-Agent'] =
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36';

      final streamedResponse = await _client.send(request).timeout(
        const Duration(seconds: 10),
      );
      stopwatch.stop();

      final statusCode = streamedResponse.statusCode;
      final contentType = streamedResponse.headers['content-type'] ?? 'unknown';
      final isAudioType = contentType.toLowerCase().contains('audio') ||
          contentType.toLowerCase().contains('mpeg') ||
          contentType.toLowerCase().contains('mp3') ||
          contentType.toLowerCase().contains('mp4') ||
          contentType.toLowerCase().contains('octet-stream');

      final isSuccess = statusCode >= 200 && statusCode < 300;

      // Close stream early
      streamedResponse.stream.listen((_) {}).cancel();

      return AudioVerificationModel(
        url: streamUrl,
        statusCode: statusCode,
        contentType: contentType,
        isAccessible: isSuccess,
        isFullTrack: isAudioType,
        verificationTime: DateTime.now(),
        details: isSuccess
            ? 'Verified HTTP $statusCode ($contentType) in ${stopwatch.elapsedMilliseconds}ms'
            : 'Server returned HTTP $statusCode',
      );
    } catch (e) {
      stopwatch.stop();
      debugPrint('[SaavnService] Stream verification error: $e');
      return AudioVerificationModel.failed(
        url: streamUrl,
        error: e.toString(),
      );
    }
  }
}
