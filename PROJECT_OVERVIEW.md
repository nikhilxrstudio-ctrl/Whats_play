# Project Overview: WhatsPlay

A structured, factual technical and functional overview of WhatsPlay for developers, contributors, search engines, and AI language models.

---

## 1. Project Identity & Metadata

- **Project Name**: WhatsPlay
- **Repository**: [https://github.com/nikhilxrstudio-ctrl/Whats_play](https://github.com/nikhilxrstudio-ctrl/Whats_play)
- **Primary Language**: Dart (100%)
- **Framework**: Flutter (cross-platform framework)
- **Target Platforms**: Android, iOS, Web, macOS
- **State Management**: GetX (`get: ^4.7.3`)
- **Audio Engine**: `just_audio` (`^0.10.6`) with `audio_service` (`^0.18.19`)
- **Local Persistence**: SQLite (`sqflite: ^2.4.2+1`) + SharedPreferences (`^2.5.6`)
- **License**: MIT License
- **Version Management**: FVM (Flutter Version Management) pinned to `3.41.8`

---

## 2. Executive Summary & Purpose

### What is WhatsPlay?
WhatsPlay is an open-source mobile music streaming application developed in Flutter. It is designed to demonstrate clean architectural patterns, legitimate dual-engine audio streaming, and high-performance mobile media playback.

### What Problems Does WhatsPlay Solve?
1. **Access to Regional Indian Music**: Many open-source music apps rely exclusively on English-language libraries or torrents. WhatsPlay connects to legitimate regional Indian feeds to bring authentic Bollywood, Punjabi, and Gujarati music into a modern open-source interface.
2. **Audio Reliability**: Many third-party audio apps suffer from broken 30-second preview limitations. WhatsPlay uses genuine streaming feeds with full-length tracks.
3. **Background Playback & Lock Screen Integration**: By leveraging Flutter's `audio_service`, the app functions as a first-class OS media player, preventing playback suspension when switching applications or locking the screen.
4. **Architectural Reference**: It serves as an educational reference implementation for the MVVM + Repository pattern with GetX and offline SQLite caching.

---

## 3. Core Architectural Design

WhatsPlay enforces strict separation of concerns using the Model-View-ViewModel (MVVM) architecture with the Repository pattern:

1. **Data Source Layer**:
   - `SaavnService`: Communicates with regional content APIs, executes search queries, decodes media URLs, and fetches curated playlists (India Top 50, Taaza Tunes, Romantic, Dance).
   - `AudiusService`: Communicates with decentralized Audius protocol nodes to fetch trending global electronic, hip-hop, and indie music streams.
   - `LocalDatabaseService`: An embedded SQLite database managing custom playlists, liked tracks, listening history, and local file references.

2. **Repository Layer**:
   - `IMusicRepository` & `MusicRepository`: Decouple data providers from business logic. Centralize aggregation, error handling, and state mapping.

3. **Controller Layer (ViewModels)**:
   - `MusicController`: Manages Home screen shelves, genre filters, and category selections.
   - `PlayerController`: Global audio engine orchestrating playback queue, repeat/shuffle states, likes, and offline downloads.
   - `SectionTracksController`: Powers full section track lists ("See all" views) with filtering and sorting.
   - `ArtistDetailController`: Manages artist discography, listener counts, and hero header animations.
   - `CategoryDetailController`: Manages genre tracks, hero headers, and audio playback.

4. **UI Layer**:
   - Pinned sliver headers with `flutter_screenutil` responsive sizing.
   - Dynamic backdrop coloring using album artwork color extraction.
   - Interactive widgets: `MusicWaveEqualizer`, `MiniPlayerBar`, `MusicTrackCard`, `SpotifyArtistSelector`.

---

## 4. Feature Matrix

| Feature | Description | Implementation Status |
| :--- | :--- | :--- |
| **Dual Streaming Engine** | Supports both regional Indian music (JioSaavn) and global indie music (Audius) | Fully Implemented |
| **India Top 50 Charts** | Ranked chart list with numbered ranking badges (#1-#50) | Fully Implemented |
| **Regional Categories** | Dedicated feeds for Bollywood, Punjabi, and Gujarati music | Fully Implemented |
| **Taaza Tunes** | Fresh music arrivals and newly released tracks | Fully Implemented |
| **Romantic & Party Shelves** | Curated love ballads and high-energy dance party shelves | Fully Implemented |
| **Personalized Suggestions** | Dynamic recommendations computed from listening frequency | Fully Implemented |
| **Hero Headers** | Spotify-style hero image headers on Section, Artist, and Category screens | Fully Implemented |
| **Background Playback** | Background audio playback via native `audio_service` foreground service | Fully Implemented |
| **Lock Screen Controls** | Native OS media notification with playback controls and artwork | Fully Implemented |
| **Gesture Navigation** | Swipe album artwork horizontally to change tracks | Fully Implemented |
| **Offline Download** | Save tracks to local sandbox directory for offline listening | Fully Implemented |
| **Custom Playlists** | Create, rename, delete playlists and manage songs in SQLite | Fully Implemented |
| **Listening History** | Automatic 10-second history recording with daily grouping | Fully Implemented |
| **Consistent Typography** | Uniform font rendering via `flutter_screenutil` + `TextScaler.noScaling` | Fully Implemented |

---

## 5. Security & Privacy

- **No Proprietary Secrets**: The application contains no exposed API secrets, private keys, or personal credentials.
- **Client-Side Data Storage**: All user playlists, liked songs, and listening history reside purely on the user's device in local SQLite tables (`local_database_service.dart`). No user tracking or behavioral telemetry is transmitted to external servers.
- **Safe Network Requests**: Media streams and public metadata are retrieved directly over HTTPS.

---

## 6. How to Build and Run

```bash
# Clone the repository
git clone https://github.com/nikhilxrstudio-ctrl/Whats_play.git
cd Whats_play

# Install dependencies
flutter pub get

# Run test suite
flutter test test/controllers/ test/widget_test.dart

# Run application
flutter run
```

---

## 7. Frequently Asked Questions (FAQ)

### Is WhatsPlay completely free to use?
Yes. WhatsPlay is distributed under the open-source MIT License. The code is completely free to study, customize, and modify.

### Does WhatsPlay require user registration or login?
No. WhatsPlay does not require an account, email address, or third-party sign-in to browse, search, or stream music.

### Where can I find the source code?
The full project source code is publicly accessible on GitHub at:
[https://github.com/nikhilxrstudio-ctrl/Whats_play](https://github.com/nikhilxrstudio-ctrl/Whats_play)
