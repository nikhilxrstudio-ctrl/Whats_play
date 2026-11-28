// ==============================================================================
// WhatsPlay Music - Secret Vault (Public Template)
//
// All sensitive endpoints, keys, and credentials are kept blank here so they
// remain hidden when the repository is cloned by any user.
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
