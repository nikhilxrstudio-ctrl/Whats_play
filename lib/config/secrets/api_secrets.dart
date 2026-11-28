import 'dart:convert';
import 'api_secrets_vault.dart';

/// Centralized Secrets & API Configuration for WhatsPlay.
///
/// Supports:
/// 1. `--dart-define` command-line flags (e.g. CI/CD or custom builds)
/// 2. Local `ApiSecretsVault` values (kept secure locally and hidden in public clones)
/// 3. Graceful fallback if endpoints are unconfigured
class ApiSecrets {
  // ---------------------------------------------------------------------------
  // 1. Music Provider Endpoints
  // ---------------------------------------------------------------------------

  /// JioSaavn Gateway Base URL
  static const String saavnBaseUrl = String.fromEnvironment(
    'SAAVN_BASE_URL',
    defaultValue: ApiSecretsVault.saavnBaseUrl,
  );

  /// Audius Discovery Gateway Base URL
  static const String audiusBaseUrl = String.fromEnvironment(
    'AUDIUS_BASE_URL',
    defaultValue: ApiSecretsVault.audiusBaseUrl,
  );

  /// Lyrics Gateway Base URL (falls back to saavnBaseUrl if unset)
  static String get lyricsBaseUrl {
    const fromEnv = String.fromEnvironment('LYRICS_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (ApiSecretsVault.lyricsBaseUrl.isNotEmpty) {
      return ApiSecretsVault.lyricsBaseUrl;
    }
    return saavnBaseUrl;
  }

  /// Whether the primary music API has been configured
  static bool get isMusicApiConfigured => saavnBaseUrl.isNotEmpty;

  // ---------------------------------------------------------------------------
  // 2. JioSaavn Playlist Chart IDs
  // ---------------------------------------------------------------------------

  static const String saavnTrendingTodayListId = String.fromEnvironment(
    'SAAVN_TRENDING_TODAY_LIST_ID',
    defaultValue: ApiSecretsVault.saavnTrendingTodayListId,
  );

  static const String saavnSuperhitsListId = String.fromEnvironment(
    'SAAVN_SUPERHITS_LIST_ID',
    defaultValue: ApiSecretsVault.saavnSuperhitsListId,
  );

  static const String saavnTaazaTunesListId = String.fromEnvironment(
    'SAAVN_TAAZA_TUNES_LIST_ID',
    defaultValue: ApiSecretsVault.saavnTaazaTunesListId,
  );

  static const String saavnNewHitsHindiListId = String.fromEnvironment(
    'SAAVN_NEW_HITS_HINDI_LIST_ID',
    defaultValue: ApiSecretsVault.saavnNewHitsHindiListId,
  );

  // ---------------------------------------------------------------------------
  // 3. JioSaavn URI Builders
  // ---------------------------------------------------------------------------

  /// Builds a Uri for playlist details
  static Uri buildSaavnPlaylistUri(String listId) {
    return Uri.parse(
      '$saavnBaseUrl?__call=playlist.getDetails&listid=$listId&_format=json&_marker=0&api_version=4&ctx=web6dot0',
    );
  }

  /// Builds a Uri for real-time trending feed
  static Uri buildSaavnTrendingFeedUri() {
    return Uri.parse(
      '$saavnBaseUrl?__call=content.getTrending&_format=json&_marker=0&api_version=4&ctx=web6dot0',
    );
  }

  /// Builds a Uri for track search
  static Uri buildSaavnSearchUri(String query, {int limit = 25}) {
    return Uri.parse(
      '$saavnBaseUrl?__call=search.getResults&q=${Uri.encodeComponent(query)}&_format=json&_marker=0&api_version=4&ctx=web6dot0&n=$limit',
    );
  }

  /// Builds a Uri for artist search
  static Uri buildSaavnArtistSearchUri(String query, {int limit = 5}) {
    return Uri.parse(
      '$saavnBaseUrl?__call=search.getArtistResults&q=${Uri.encodeComponent(query)}&_format=json&_marker=0&api_version=4&ctx=web6dot0&n=$limit',
    );
  }

  /// Builds a Uri for artist detail page
  static Uri buildSaavnArtistPageUri(String artistId, {int limit = 25}) {
    return Uri.parse(
      '$saavnBaseUrl?__call=artist.getArtistPageDetails&artistId=$artistId&_format=json&_marker=0&api_version=4&ctx=web6dot0&n_song=$limit',
    );
  }

  /// Builds a Uri for song lyrics lookup
  static Uri buildSaavnLyricsUri(String trackId) {
    return Uri.parse(
      '$lyricsBaseUrl?__call=lyrics.getLyrics&lyrics_id=$trackId&_format=json&_marker=0&api_version=4&ctx=web6dot0',
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Brevo Email Service Configuration
  // ---------------------------------------------------------------------------

  static const String brevoApiKey = String.fromEnvironment(
    'BREVO_API_KEY',
    defaultValue: ApiSecretsVault.brevoApiKey,
  );

  static const String brevoSmtpHost = String.fromEnvironment(
    'BREVO_SMTP_HOST',
    defaultValue: ApiSecretsVault.brevoSmtpHost,
  );

  static const int brevoSmtpPort = int.fromEnvironment(
    'BREVO_SMTP_PORT',
    defaultValue: ApiSecretsVault.brevoSmtpPort,
  );

  static const String brevoUsername = String.fromEnvironment(
    'BREVO_SMTP_USER',
    defaultValue: ApiSecretsVault.brevoUsername,
  );

  static String get brevoPassword {
    const fromEnv = String.fromEnvironment('BREVO_SMTP_PASSWORD');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (ApiSecretsVault.brevoPassword.isNotEmpty) {
      final raw = ApiSecretsVault.brevoPassword;
      // If base64 encoded, decode it safely
      try {
        if (!raw.startsWith('xsmtp') && RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(raw)) {
          return utf8.decode(base64.decode(raw));
        }
      } catch (_) {}
      return raw;
    }
    return '';
  }

  static const String brevoSenderEmail = String.fromEnvironment(
    'BREVO_SENDER_EMAIL',
    defaultValue: ApiSecretsVault.brevoSenderEmail,
  );

  static const String brevoSenderName = String.fromEnvironment(
    'BREVO_SENDER_NAME',
    defaultValue: ApiSecretsVault.brevoSenderName,
  );

  static bool get isBrevoConfigured =>
      brevoSmtpHost.isNotEmpty && brevoUsername.isNotEmpty && brevoPassword.isNotEmpty;
}
