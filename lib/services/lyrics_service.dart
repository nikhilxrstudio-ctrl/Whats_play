import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/secrets/api_secrets.dart';
import '../models/track_model.dart';

abstract class ILyricsService {
  Future<String?> getLyrics(TrackModel track);
}

class LyricsService implements ILyricsService {
  final http.Client _client;
  static final Map<String, String> _cache = {};

  LyricsService({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<String?> getLyrics(TrackModel track) async {
    final cacheKey = '${track.trackId}_${track.title}'.toLowerCase();
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    // 1. Try JioSaavn Official Lyrics using trackId
    if (track.trackId.isNotEmpty) {
      try {
        final jioLyrics = await _fetchJioSaavnLyrics(track.trackId);
        if (jioLyrics != null && jioLyrics.trim().isNotEmpty) {
          _cache[cacheKey] = jioLyrics;
          return jioLyrics;
        }
      } catch (e) {
        debugPrint('[LyricsService] JioSaavn lyrics error: $e');
      }
    }

    // 2. Try LRCLIB API with Track Title and Artist Name
    try {
      final lrclibLyrics = await _fetchLrclibLyrics(track.title, track.artistName);
      if (lrclibLyrics != null && lrclibLyrics.trim().isNotEmpty) {
        _cache[cacheKey] = lrclibLyrics;
        return lrclibLyrics;
      }
    } catch (e) {
      debugPrint('[LyricsService] LRCLIB lyrics error: $e');
    }

    // 3. Try fallback with cleaned title (remove brackets e.g. "(From ...)", "[Remix]")
    final cleanedTitle = _cleanTitle(track.title);
    if (cleanedTitle != track.title) {
      try {
        final fallbackLyrics = await _fetchLrclibLyrics(cleanedTitle, track.artistName);
        if (fallbackLyrics != null && fallbackLyrics.trim().isNotEmpty) {
          _cache[cacheKey] = fallbackLyrics;
          return fallbackLyrics;
        }
      } catch (_) {}
    }

    return null;
  }

  Future<String?> _fetchJioSaavnLyrics(String trackId) async {
    if (!ApiSecrets.isMusicApiConfigured) return null;
    final uri = ApiSecrets.buildSaavnLyricsUri(trackId);
    final res = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)',
      },
    ).timeout(const Duration(seconds: 8));

    if (res.statusCode == 200 && res.body.isNotEmpty) {
      final data = jsonDecode(res.body);
      if (data is Map && data.containsKey('lyrics')) {
        final rawLyrics = data['lyrics'] as String?;
        if (rawLyrics != null && rawLyrics.isNotEmpty) {
          return _cleanHtml(rawLyrics);
        }
      }
    }
    return null;
  }

  Future<String?> _fetchLrclibLyrics(String trackName, String artistName) async {
    final queryParams = {
      'track_name': trackName.trim(),
      'artist_name': artistName.split(',').first.trim(),
    };
    final uri = Uri.https('lrclib.net', '/api/get', queryParams);
    final res = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'WhatsPlay-Music-App/1.0',
      },
    ).timeout(const Duration(seconds: 8));

    if (res.statusCode == 200 && res.body.isNotEmpty) {
      final data = jsonDecode(res.body);
      if (data is Map) {
        final plain = data['plainLyrics'] as String?;
        if (plain != null && plain.trim().isNotEmpty) {
          return plain.trim();
        }
      }
    }
    return null;
  }

  String _cleanTitle(String title) {
    return title
        .replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _cleanHtml(String html) {
    return html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<.*?>'), '')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&#039;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }
}
