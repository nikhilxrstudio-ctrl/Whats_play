// ==============================================================================
// WhatsPlay Music - Secret Vault Configuration (Public Template)
//
// NOTICE FOR CLONED REPOSITORIES:
// This is the public template file. All secret API keys, endpoints, and credentials
// are intentionally kept empty for security in the public repository.
//
// To configure your own credentials for custom development:
// 1. Copy this file or set environment variables via --dart-define
// 2. Supply your own API endpoints and credentials below.
// ==============================================================================

class ApiSecretsVault {
  // ---------------------------------------------------------------------------
  // 1. Music Streaming Provider Endpoints (Empty by default in public clone)
  // ---------------------------------------------------------------------------
  static const String saavnBaseUrl = '';
  static const String audiusBaseUrl = '';
  static const String lyricsBaseUrl = '';

  // JioSaavn Playlist Chart IDs
  static const String saavnTrendingTodayListId = '';
  static const String saavnSuperhitsListId = '';
  static const String saavnTaazaTunesListId = '';
  static const String saavnNewHitsHindiListId = '';

  // ---------------------------------------------------------------------------
  // 2. Brevo Email Service Configuration (Empty by default in public clone)
  // ---------------------------------------------------------------------------
  static const String brevoApiKey = '';
  static const String brevoSmtpHost = '';
  static const int brevoSmtpPort = 587;
  static const String brevoUsername = '';
  static const String brevoPassword = '';
  static const String brevoSenderEmail = '';
  static const String brevoSenderName = '';
}
