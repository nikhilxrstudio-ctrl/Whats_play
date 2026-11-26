import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/audio_verification_model.dart';
import '../models/track_model.dart';
import 'api_service.dart';

class AudiusService implements IApiService {
  final http.Client _client;

  AudiusService({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<List<TrackModel>> getTrendingTracks({
    int limit = 25,
    String? genre,
  }) async {
    final Map<String, String> queryParameters = {
      'app_name': ApiConstants.appName,
      'limit': limit.toString(),
    };

    if (genre != null &&
        genre.isNotEmpty &&
        genre.toLowerCase() != 'all') {
      queryParameters['genre'] = genre;
    }

    final uri = Uri.parse('${ApiConstants.audiusBaseUrl}${ApiConstants.trendingTracksEndpoint}')
        .replace(queryParameters: queryParameters);

    debugPrint('[AudiusService] Fetching tracks from: $uri');

    try {
      final response = await _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'WhatsPlayFlutter/1.0',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic>? data = body['data'];

        if (data == null || data.isEmpty) {
          debugPrint('[AudiusService] Empty data array received for genre: $genre');
          return [];
        }

        final List<TrackModel> tracks = data
            .whereType<Map<String, dynamic>>()
            .map((item) => TrackModel.fromAudiusJson(item))
            .toList();

        debugPrint('[AudiusService] Successfully parsed ${tracks.length} tracks for genre: ${genre ?? "All"}.');
        return tracks;
      } else {
        throw HttpException(
          'API responded with status code ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } on SocketException catch (e) {
      debugPrint('[AudiusService] Network error: $e');
      throw Exception('Network connection failed. Please check your internet connection.');
    } on TimeoutException catch (e) {
      debugPrint('[AudiusService] Timeout error: $e');
      throw Exception('Request timed out. Music API server took too long to respond.');
    } on FormatException catch (e) {
      debugPrint('[AudiusService] JSON format error: $e');
      throw Exception('Failed to parse music data response format.');
    } catch (e) {
      debugPrint('[AudiusService] Unexpected error: $e');
      rethrow;
    }
  }

  @override
  Future<List<TrackModel>> searchTracks({
    required String query,
    int limit = 25,
  }) async {
    final uri = Uri.parse('${ApiConstants.audiusBaseUrl}${ApiConstants.searchTracksEndpoint}')
        .replace(queryParameters: {
      'query': query,
      'app_name': ApiConstants.appName,
      'limit': limit.toString(),
    });

    debugPrint('[AudiusService] Searching tracks with query: "$query" from: $uri');

    try {
      final response = await _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'WhatsPlayFlutter/1.0',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic>? data = body['data'];

        if (data == null || data.isEmpty) {
          debugPrint('[AudiusService] Empty search data received for query: $query');
          return [];
        }

        final List<TrackModel> tracks = data
            .whereType<Map<String, dynamic>>()
            .map((item) => TrackModel.fromAudiusJson(item))
            .toList();

        debugPrint('[AudiusService] Successfully parsed ${tracks.length} tracks for query: "$query".');
        return tracks;
      } else {
        throw HttpException(
          'API responded with status code ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } on SocketException catch (e) {
      debugPrint('[AudiusService] Network error: $e');
      throw Exception('Network connection failed. Please check your internet connection.');
    } on TimeoutException catch (e) {
      debugPrint('[AudiusService] Timeout error: $e');
      throw Exception('Request timed out. Music API server took too long to respond.');
    } on FormatException catch (e) {
      debugPrint('[AudiusService] JSON format error: $e');
      throw Exception('Failed to parse search response format.');
    } catch (e) {
      debugPrint('[AudiusService] Unexpected search error: $e');
      rethrow;
    }
  }

  @override
  Future<AudioVerificationModel> verifyAudioStream(String streamUrl) async {
    final stopwatch = Stopwatch()..start();
    debugPrint('[AudiusService] Verifying audio stream URL: $streamUrl');

    try {
      final uri = Uri.parse(streamUrl);
      // Create request that follows redirects
      final request = http.Request('GET', uri)
        ..followRedirects = true
        ..maxRedirects = 5
        ..headers['User-Agent'] = 'WhatsPlayFlutter/1.0';

      final streamedResponse = await _client.send(request).timeout(
        const Duration(seconds: 10),
      );
      stopwatch.stop();

      final statusCode = streamedResponse.statusCode;
      final contentType = streamedResponse.headers['content-type'] ?? 'unknown';
      final isAudioType = contentType.toLowerCase().contains('audio') ||
          contentType.toLowerCase().contains('mpeg') ||
          contentType.toLowerCase().contains('mp3') ||
          contentType.toLowerCase().contains('octet-stream');

      final isSuccess = statusCode >= 200 && statusCode < 300;

      // Close response stream early to not download full file
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
      debugPrint('[AudiusService] Stream verification error: $e');
      return AudioVerificationModel.failed(
        url: streamUrl,
        error: e.toString(),
      );
    }
  }
}
