class ApiConstants {
  /// Base host for Audius open discovery API
  static const String audiusBaseUrl = 'https://api.audius.co';

  /// Default application identifier registered with Audius API guidelines
  static const String defaultAppName = 'WHATS_PLAY';

  /// Environment-based configuration (via --dart-define=AUDIUS_APP_NAME=...)
  static const String appName = String.fromEnvironment(
    'AUDIUS_APP_NAME',
    defaultValue: defaultAppName,
  );

  /// Trending tracks endpoint
  static const String trendingTracksEndpoint = '/v1/tracks/trending';

  /// Track search endpoint (for artists, keywords, and regional queries)
  static const String searchTracksEndpoint = '/v1/tracks/search';

  /// Helper to build direct stream URL
  static String buildStreamUrl(String trackId) {
    return '$audiusBaseUrl/v1/tracks/$trackId/stream?app_name=$appName';
  }
}
