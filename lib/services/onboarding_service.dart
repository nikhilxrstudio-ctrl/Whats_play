import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the user has completed onboarding and stores their
/// display name + preferred genre categories for personalised Home content.
class OnboardingService {
  static const _kDone = 'onboarding_done';
  static const _kName = 'onboarding_display_name';
  static const _kGenres = 'onboarding_genres';

  // ── singleton ──────────────────────────────────────────────────────────────
  static final OnboardingService _i = OnboardingService._();
  OnboardingService._();
  factory OnboardingService() => _i;

  SharedPreferences? _prefs;

  Future<void> _ensure() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ── queries ────────────────────────────────────────────────────────────────

  /// Returns true when the user has already seen and completed onboarding.
  Future<bool> isOnboardingDone() async {
    await _ensure();
    return _prefs!.getBool(_kDone) ?? false;
  }

  /// The display name the user chose during onboarding (may be empty for logged-in
  /// users who skipped the name step because we use their Google display name).
  Future<String> getSavedName() async {
    await _ensure();
    return _prefs!.getString(_kName) ?? '';
  }

  /// The list of genre/category ids the user selected (e.g. ['Bollywood', 'Punjabi']).
  /// Empty list means "All" (default).
  Future<List<String>> getSavedGenres() async {
    await _ensure();
    return _prefs!.getStringList(_kGenres) ?? [];
  }

  // ── mutations ──────────────────────────────────────────────────────────────

  Future<void> saveName(String name) async {
    await _ensure();
    await _prefs!.setString(_kName, name.trim());
  }

  Future<void> saveGenres(List<String> genres) async {
    await _ensure();
    await _prefs!.setStringList(_kGenres, genres);
  }

  /// Mark onboarding as complete.  Call this after the user taps "Done".
  Future<void> completeOnboarding({
    required String name,
    required List<String> genres,
  }) async {
    await _ensure();
    if (name.trim().isNotEmpty) await _prefs!.setString(_kName, name.trim());
    await _prefs!.setStringList(_kGenres, genres);
    await _prefs!.setBool(_kDone, true);
  }

  /// Reset onboarding (dev / logout helper).
  Future<void> reset() async {
    await _ensure();
    await _prefs!.remove(_kDone);
    await _prefs!.remove(_kName);
    await _prefs!.remove(_kGenres);
  }
}
