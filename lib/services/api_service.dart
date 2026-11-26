import '../models/track_model.dart';
import '../models/audio_verification_model.dart';

abstract class IApiService {
  /// Fetches trending tracks from the music provider API, optionally filtered by genre/category
  Future<List<TrackModel>> getTrendingTracks({
    int limit = 25,
    String? genre,
  });

  /// Searches tracks by artist name, track title, or regional query (e.g. Diljit, Honey Singh, Gujarati)
  Future<List<TrackModel>> searchTracks({
    required String query,
    int limit = 25,
  });

  /// Verifies whether an audio stream URL is live, reachable, and returns valid audio headers
  Future<AudioVerificationModel> verifyAudioStream(String streamUrl);
}
