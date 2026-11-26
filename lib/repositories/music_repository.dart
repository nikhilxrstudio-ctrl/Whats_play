import '../models/audio_verification_model.dart';
import '../models/track_model.dart';
import '../services/api_service.dart';
import '../services/saavn_service.dart';

abstract class IMusicRepository {
  Future<List<TrackModel>> getTracks({int limit = 25, String? genre});
  Future<List<TrackModel>> searchTracks(String query, {int limit = 25});
  Future<List<TrackModel>> getTrendingChartTracks({int limit = 25});
  Future<List<TrackModel>> getNewReleases({int limit = 25});
  Future<List<TrackModel>> getTopCharts({int limit = 25}) => searchTracks('India Superhits Top 50', limit: limit);
  Future<List<TrackModel>> getRomanticTracks({int limit = 25}) => searchTracks('Romantic Hindi Hits', limit: limit);
  Future<List<TrackModel>> getPartyTracks({int limit = 25}) => searchTracks('Bollywood Party Dance Hits', limit: limit);
  Future<AudioVerificationModel> verifyTrackAudio(TrackModel track);
}

class MusicRepository implements IMusicRepository {
  final IApiService _audiusService;
  final IApiService _saavnService;

  MusicRepository({
    required IApiService audiusService,
    required IApiService saavnService,
  })  : _audiusService = audiusService,
        _saavnService = saavnService;

  @override
  Future<List<TrackModel>> getNewReleases({int limit = 25}) async {
    try {
      final saavn = _saavnService;
      if (saavn is SaavnService) {
        final releases = await saavn.getNewReleases(limit: limit);
        if (releases.isNotEmpty) return releases;
      }
      final fallback = await _saavnService.searchTracks(query: 'Latest Hindi Hits', limit: limit);
      if (fallback.isNotEmpty) return fallback;
    } catch (_) {}

    try {
      final audiusTracks = await _audiusService.getTrendingTracks(limit: limit);
      if (audiusTracks.isNotEmpty) return audiusTracks;
    } catch (_) {}

    return [];
  }

  @override
  Future<List<TrackModel>> getTrendingChartTracks({int limit = 25}) async {
    // 1. Fetch real official Trending chart from JioSaavn
    try {
      final trending = await _saavnService.getTrendingTracks(
        limit: limit,
        genre: 'Trending',
      );
      if (trending.isNotEmpty) return trending;
    } catch (_) {}

    // 2. Fallback to Audius trending tracks
    try {
      final audiusTrending = await _audiusService.getTrendingTracks(limit: limit);
      if (audiusTrending.isNotEmpty) return audiusTrending;
    } catch (_) {}

    return [];
  }

  @override
  Future<List<TrackModel>> getTracks({int limit = 25, String? genre}) async {
    // If the genre is Indian/Regional, use Saavn for authentic rich catalogue
    if (_isRegionalOrIndian(genre)) {
      try {
        final tracks = await _saavnService.getTrendingTracks(
          limit: limit,
          genre: genre,
        );
        if (tracks.isNotEmpty) return tracks;
      } catch (_) {}
    }

    // Default to Audius for global/electronic/trending tracks
    return await _audiusService.getTrendingTracks(limit: limit, genre: genre);
  }

  @override
  Future<List<TrackModel>> searchTracks(String query, {int limit = 25}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    // Prioritize JioSaavn for real tracks (Artists, Bollywood, Punjabi, Gujarati, Hit Songs)
    try {
      final saavnTracks = await _saavnService.searchTracks(query: cleanQuery, limit: limit);
      if (saavnTracks.isNotEmpty) {
        return saavnTracks;
      }
    } catch (_) {}

    // Fall back to Audius for global/indie/electronic search
    try {
      final audiusTracks = await _audiusService.searchTracks(query: cleanQuery, limit: limit);
      if (audiusTracks.isNotEmpty) {
        return audiusTracks;
      }
    } catch (_) {}

    return [];
  }

  @override
  Future<List<TrackModel>> getTopCharts({int limit = 25}) async {
    try {
      final saavn = _saavnService;
      if (saavn is SaavnService) {
        final tracks = await saavn.getPlaylistDetails(
          '1134548194',
          limit: limit,
          fallbackQuery: 'India Superhits Top 50',
        );
        if (tracks.isNotEmpty) return tracks;
      }
      return await _saavnService.searchTracks(query: 'India Superhits Top 50', limit: limit);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<TrackModel>> getRomanticTracks({int limit = 25}) async {
    try {
      final saavn = _saavnService;
      if (saavn is SaavnService) {
        final tracks = await saavn.getPlaylistDetails(
          '1302033575',
          limit: limit,
          fallbackQuery: 'Romantic Hindi Hits',
        );
        if (tracks.isNotEmpty) return tracks;
      }
      return await _saavnService.searchTracks(query: 'Romantic Hindi Hits', limit: limit);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<TrackModel>> getPartyTracks({int limit = 25}) async {
    try {
      final saavn = _saavnService;
      if (saavn is SaavnService) {
        final tracks = await saavn.getPlaylistDetails(
          '79653434',
          limit: limit,
          fallbackQuery: 'Bollywood Party Dance',
        );
        if (tracks.isNotEmpty) return tracks;
      }
      return await _saavnService.searchTracks(query: 'Bollywood Party Dance', limit: limit);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<AudioVerificationModel> verifyTrackAudio(TrackModel track) async {
    if (track.audioUrl.contains('jio.com') ||
        track.audioUrl.contains('saavn')) {
      return await _saavnService.verifyAudioStream(track.audioUrl);
    }
    return await _audiusService.verifyAudioStream(track.audioUrl);
  }

  bool _isRegionalOrIndian(String? query) {
    if (query == null) return false;
    final q = query.toLowerCase();
    return q.contains('gujarati') ||
        q.contains('punjabi') ||
        q.contains('bollywood') ||
        q.contains('hindi') ||
        q.contains('indian');
  }
}
