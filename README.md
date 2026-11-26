# WhatsPlay 🎵 – Flutter Music Streaming & Catalogue App

A production-grade, Spotify-inspired music streaming application built in Flutter with clean MVVM architecture, dual-engine legitimate music streaming, background audio playback with system media notifications, offline download caching, and responsive UI scaling.

---

## 📸 Core Features

- 🎧 **Dual-Engine Streaming Services**:
  - **JioSaavn Official Feeds**: Seamless streaming for Bollywood, Punjabi, Gujarati, Taaza Tunes (New Releases), Top Charts (India Top 50), Romantic Melodies, and Dance Anthems.
  - **Audius Open Protocol**: High-fidelity global electronic, hip-hop, lo-fi, and independent music streaming with direct playable audio streams (`audio/mpeg`).
- 🌟 **Spotify-Inspired Home Screen**:
  - **8-Item Quick Access Grid**: Verified artists (Diljit Dosanjh, Honey Singh, Arijit Singh, Sidhu Moose Wala, Badshah) and curated Hit Playlists (Top 50 Bollywood, Party Mix, Chill Vibes, Romantic Hits) with active CDN artworks.
  - **Ranked Top Charts Section**: Numbered rank badges (`#1`, `#2`, `#3` in Spotify green) with a "See all 50 chartbusters" shortcut.
  - **Curated Horizontal Shelves**: *Taaza Tunes* (New Releases), *Romantic Melodies*, and *Party & Dance Anthems*.
  - **Personalized Recommendations**: *Suggested For You* shelf computed dynamically from user listening history.
  - **Sticky Genre Header**: Smooth pinned horizontal chip filters for instant genre filtering.
- 🎛️ **Full-Featured Audio Player (`/player`)**:
  - **Dynamic Background Gradients**: Ambient backdrop generated in real-time from the current track's album artwork.
  - **Interactive Seekbar**: Smooth scrubbing with elapsed time and total duration.
  - **Gesture Controls**: Swipe left/right on album artwork to change tracks seamlessly.
  - **Playback Modes**: Loop/repeat (Off, Repeat All, Repeat One), shuffle mode, and 10-second skip forward/backward.
  - **Live Equalizer Wave**: Animated audio wave indicator showing playback activity on album thumbnails and player views.
- 📱 **System Media Notifications & Lock Screen**:
  - Integrated via `audio_service` + `just_audio`.
  - Background audio playback with native OS notification controls (Play/Pause, Skip Next/Previous, Seekbar, Artwork).
- 💾 **Offline Library & SQLite Persistence**:
  - **Liked Songs**: Instant heart toggle persisted to local storage.
  - **Offline Downloads**: Save tracks directly to local device sandbox for seamless playback without an internet connection.
  - **Custom Playlists**: Create, rename, delete playlists and manage songs.
  - **Listening History**: Tracks automatically logged to history after 10+ seconds of playback.
- 📱 **Consistent Cross-Device Typography**:
  - Built with `flutter_screenutil` using strict non-scaling text scalers (`TextScaler.noScaling`) to ensure exact font proportions across all mobile screen densities and aspect ratios.
- 🎯 **Version Management**:
  - Managed via **FVM** (Flutter Version Management) pinned to Flutter `3.41.8`.

---

## 🏗️ Architecture: MVVM + Repository Pattern

WhatsPlay strictly follows Clean Architecture principles with unidirectional data flow:

```
┌────────────────────────────────────────────────────────┐
│                      Data Sources                      │
│        JioSaavn API Feeds   │   Audius REST Stream      │
└─────────────────────────────┬──────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────┐
│                     Service Layer                      │
│      SaavnService      │   AudiusService (IApiService) │
│      LocalDatabaseService (SQLite) │ AudioPlayerHandler │
└─────────────────────────────┬──────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────┐
│                   Repository Layer                     │
│    MusicRepository (implements IMusicRepository)       │
└─────────────────────────────┬──────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────┐
│                   Controller Layer                     │
│  MusicController │ PlayerController │ ArtistDetailCtrl │
│    SectionTracksController │ CategoryDetailController  │
└─────────────────────────────┬──────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────┐
│                       UI Layer                         │
│  MusicCatalogueScreen │ MusicPlayerScreen │ MiniPlayer │
│     SectionTracksScreen │ ArtistDetailScreen           │
└────────────────────────────────────────────────────────┘
```

### Folder Structure

```
lib/
├── constants/
│   ├── api_constants.dart          # Remote endpoints & configuration
│   ├── app_colors.dart             # Spotify dark palette, status badges & neon accents
│   └── app_constants.dart          # Featured artists, hit playlists & layout limits
├── models/
│   ├── artist_category_model.dart  # Featured artists & playlist metadata model
│   ├── audio_verification_model.dart # Stream reachability and verification model
│   ├── playlist_model.dart         # Custom user playlists model
│   └── track_model.dart            # Strongly-typed audio track model
├── services/
│   ├── api_service.dart            # IApiService contract
│   ├── audius_service.dart         # Audius REST API & stream client
│   ├── audio_player_handler.dart   # AudioService background media notification handler
│   ├── local_database_service.dart # SQLite database for playlists, history & offline tracks
│   └── saavn_service.dart          # JioSaavn API service with decryptor & search
├── repositories/
│   └── music_repository.dart       # IMusicRepository interface & implementation
├── controllers/
│   ├── artist_detail_controller.dart # Artist discography & tracks
│   ├── category_detail_controller.dart # Genre detail & browsing
│   ├── music_controller.dart       # Home catalogue, categories & shelves
│   ├── player_controller.dart      # Global playback engine, queue, likes & downloads
│   └── section_tracks_controller.dart# See-all section tracks & full playlist view
├── screens/
│   ├── artist_detail_screen.dart   # Artist profile & top songs screen
│   ├── category_detail_screen.dart # Category tracklist screen
│   ├── music_catalogue_screen.dart # Home catalogue screen with tabs & shelves
│   ├── music_player_screen.dart    # Full-screen player with dynamic gradients
│   └── section_tracks_screen.dart  # Section view (e.g. India Top 50, New Releases)
├── widgets/
│   ├── add_to_collection_sheet.dart# Bottom sheet to add track to custom playlists
│   ├── audio_status_badge.dart     # Audio verification badge
│   ├── category_selector_bar.dart  # Sticky horizontal genre selector
│   ├── mini_player_bar.dart        # Docked bottom mini player
│   ├── music_track_card.dart       # Responsive track card with rank & play state
│   ├── music_wave_equalizer.dart   # Live animated equalizer bars
│   ├── spotify_artist_selector.dart# Quick-access 8-item grid
│   ├── spotify_bottom_navigation_bar.dart # Bottom navigation bar
│   └── track_options_sheet.dart    # Track context menu (Like, Download, Add)
├── routes/
│   ├── app_routes.dart             # Named routes
│   └── app_pages.dart              # Route bindings and transitions
└── main.dart                       # App entrypoint with ScreenUtil & AudioService
```

---

## 🧪 Testing & Verification

The project includes an automated test suite verifying all layers:

- **Unit Tests**:
  - `track_model_test.dart`: Serialization, duration parsing, stream resolution.
  - `audius_service_test.dart`: API response parsing, stream URL construction.
  - `saavn_service_test.dart`: Media decryption, search resolution, playlist feeds.
  - `local_database_service_test.dart`: SQLite CRUD for likes, playlists, and history.
- **Controller Tests**:
  - `player_controller_test.dart`: Play, pause, skip, seek, shuffle, repeat, like, offline caching, and 10s history tracking.
  - `music_controller_test.dart`: State transitions, category filtering, shelf loading.
  - `section_tracks_controller_test.dart`: Queue delegation and section playback.
  - `artist_detail_controller_test.dart` & `category_detail_controller_test.dart`.
- **Widget & Integration Tests**:
  - `widget_test.dart`: Navigation to player screen, mini player swipe gesture, featured artist selection, and back button behaviors.

### Run Tests & Analysis

```bash
# Using FVM
fvm flutter analyze
fvm flutter test test/controllers/ test/widget_test.dart

# Using Flutter directly
flutter analyze
flutter test
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (v3.24+ or 3.41+)
- [FVM](https://fvm.app/) (recommended): Pinned version `3.41.8` is defined in `.fvmrc`.

### Installation & Run

```bash
# 1. Clone the repository
git clone https://github.com/nikhilxrstudio-ctrl/Whats_play.git
cd Whats_play

# 2. Use FVM to install the exact Flutter SDK version
fvm install
fvm use 3.41.8

# 3. Fetch dependencies
fvm flutter pub get

# 4. Run Static Analysis & Tests
fvm flutter analyze
fvm flutter test

# 5. Run the Application
fvm flutter run
```

---

## 📄 License

This project is built for evaluation, portfolio, and educational purposes. Audio streams are loaded directly from legitimate open public APIs (Audius protocol & public content distribution services).
