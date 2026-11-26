# WhatsPlay – Flutter Music Catalogue App

A lightweight Flutter application built from scratch to integrate with legitimate music APIs, fetch live music data, and display the catalogue on a clean, responsive single screen.

---

## 1. Architecture: MVVM + Repository Pattern

The project strictly follows the clean data flow requested:

```
Music API (Audius REST)
         │
         ▼
Service Layer (`AudiusService` implements `IApiService`)
         │
         ▼
Repository Layer (`MusicRepository` implements `IMusicRepository`)
         │
         ▼
Controller Layer (`MusicController` GetxController)
         │
         ▼
UI Layer (`MusicCatalogueScreen` + Reusable Widgets)
```

### Folder Structure

```
lib/
├── constants/
│   ├── api_constants.dart      # Endpoints and environment configurations
│   ├── app_colors.dart         # Theme palette (dark theme, badges, status)
│   └── app_constants.dart      # Design dimensions, limits, and app metadata
├── models/
│   ├── audio_verification_model.dart # Audio HTTP stream verification response
│   └── track_model.dart        # Strongly-typed Dart model for music tracks
├── services/
│   ├── api_service.dart        # IApiService abstraction
│   └── audius_service.dart     # Audius REST API & stream verifier implementation
├── repositories/
│   └── music_repository.dart   # IMusicRepository & concrete implementation
├── controllers/
│   └── music_controller.dart   # GetX controller managing ViewState & reactive data
├── screens/
│   └── music_catalogue_screen.dart # Single clean screen displaying catalogue
├── widgets/
│   ├── audio_status_badge.dart # Status badge for audio availability
│   ├── music_track_card.dart   # Responsive track card
│   ├── loading_view.dart       # Centered loading state
│   ├── error_view.dart         # Error state with retry action
│   └── empty_view.dart         # Empty state handler
├── routes/
│   ├── app_routes.dart         # Route names
│   └── app_pages.dart          # GetPage routes with dependency injection bindings
└── main.dart                   # ScreenUtilInit & GetMaterialApp entry point
```

---

## 2. Music Provider Research & Comparison

| Provider | Free API Access | Auth Requirement | Playable Audio URL | Preview vs Full Track | Commercial / Licensing Rights | Rate Limits / Reliability | Verdict |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Audius** | **Yes (100% Free)** | **None** (Only standard `app_name`) | **Yes (Direct MP3 Stream)** | **Full Track (192-320 kbps)** | **Legitimate artist streaming distribution** | **High** (Decentralized host nodes & CDN) | **SELECTED (Best Overall)** |
| **Jamendo** | Yes (Free Dev Tier) | `client_id` (Requires developer registration) | Yes (Direct MP3) | Full Track | Creative Commons (CC BY-NC, CC BY-SA) | Moderate (Demo keys subject to suspension) | Strong alternative with developer account |
| **Free Music Archive (FMA)** | Restrictive | API key required | Discontinued public API | N/A | Variable CC | Deprecated public v1 API | Not viable for open integration |
| **Internet Archive** | Yes | None | Yes (Raw file storage) | Inconsistent | Public Domain / CC | Unstructured metadata, variable bitrates | Inconsistent track schema |
| **MusicBrainz** | Yes | None | **No** (Metadata only) | None | Open Data (CC0) | 1 req/sec | **No audio streaming available** |
| **Spotify / Apple Music** | Paid / Restricted | OAuth 2.0 / JWT Client Secrets | **No direct stream URLs** (Spotify removed previews; requires Premium SDK) | 30s preview (deprecated) | Proprietary DRM / Paid Subscription | Strict commercial API terms | Ineligible for direct playback |

### Why Audius Was Chosen

1. **Legitimate Playable Audio**: Direct `/v1/tracks/{id}/stream` endpoint provides full playable `audio/mpeg` streams without artificial 30-second truncations.
2. **Zero Barrier to Integration**: No secret server keys required; can be configured seamlessly using standard `app_name`.
3. **Rich Metadata**: Complete song title, artist name, album name, high-resolution artwork (`150x150`, `480x480`, `1000x1000`), duration, genre, and release date.
4. **Legitimate Licensing**: Artists distribute tracks directly through the Audius protocol under platform streaming terms.

---

## 3. Audio URL Verification Results

Live integration verification was performed on live Audius API endpoints:

- **Target Audio URL**: `https://api.audius.co/v1/tracks/mRaOxp1/stream?app_name=WHATS_PLAY`
- **HTTP Status**: `200 OK` (following 302 redirect to creator node)
- **Content-Type**: `audio/mpeg`
- **Full Track**: Verified full audio stream
- **CORS / Access**: `access-control-allow-origin: *`
- **Verification Details**: Verified in ~1.9s with live headers.

---

## 4. Category & Spotify-Style Artist Filtering

The single catalogue screen incorporates both **Genre Filters** and a **Spotify-Style Featured Artist & Regional View**:

1. **Spotify-Style Featured Artists & Regional Carousel (`SpotifyArtistSelector`)**:
   - Circular artist avatars with Spotify-inspired glowing active gradient rings (`LinearGradient([Purple, Cyan, Spotify Green])`) and verified checkmark badges.
   - Featured categories include:
     - **Diljit Dosanjh**
     - **Yo Yo Honey Singh**
     - **Gujarati Hits**
     - **Arijit Singh**
     - **Sidhu Moose Wala**
     - **Bollywood Hits**
     - **Punjabi Hits**
   - Tapping an artist initiates a live search (`searchTracks(query)`) to retrieve and display their real tracks.
   - Tapping the active artist again deselects it and reverts to trending music.

2. **Genre Selector Bar (`CategorySelectorBar`)**:
   - Horizontal chip selector for general genres (All, Electronic, Hip-Hop/Rap, Pop, Rock, Ambient, Bass, House, Techno, etc.).

3. **Reactive State Flow**:
   - `MusicController.selectArtist(artist)` and `MusicController.selectCategory(category)` update the reactive state, triggering the appropriate API call while keeping loading, empty, and error views seamless.

---

## 5. Music Player Screen & System Media Notifications

When a user taps any track in the catalogue list, the app initiates playback and navigates to the **Dedicated Music Player Screen (`/player`)**:

1. **Music Player Screen (`MusicPlayerScreen`)**:
   - **Large High-Res Artwork**: Center-stage 500x500 album artwork with ambient drop shadow.
   - **Track Metadata**: Song title, artist name, and album name.
   - **Interactive Seekbar**: Slider showing real-time elapsed position and total duration.
   - **Playback Controls**:
     - Big circular Play/Pause toggle with buffering indicator.
     - Next & Previous track navigation through the active playlist.
     - Quick 10s Rewind (`-10s`) & 10s Fast-Forward (`+10s`).
     - Shuffle & Repeat modes.
   - **Media Notification Status Badge**: Displays `"Media Notification Active"`.

2. **System Media Notifications (`audio_service` + `just_audio`)**:
   - Plays audio in the background and posts a native media notification in the device's notification drawer & lock screen.
   - Notification displays:
     - Song Title
     - Artist Name
     - High-resolution Album Artwork
     - Interactive Play, Pause, Next, Previous, and Seek controls.

3. **Docked Mini Player Bar (`MiniPlayerBar`)**:
   - A persistent Spotify-style mini player bar docked above the bottom of the catalogue screen when a track is active.
   - Tapping anywhere on the mini player re-opens the full Player Screen.

---

## 6. API Security & AWS Readiness

- **No Secrets Hardcoded**: No sensitive credentials exist in the client app.
- **Environment Configuration**: Configured with `--dart-define=AUDIUS_APP_NAME=WHATS_PLAY`.
- **AWS S3 / CloudFront Compatibility**: The `IApiService` and `IMusicRepository` abstractions allow seamless introduction of an AWS S3/CloudFront service implementation in the future without modifying UI or Controller code.

---

## 5. How to Run the Project

### Prerequisites

- Flutter SDK (v3.24+ / 3.41+)
- FVM (optional, supported at `/Users/imac/fvm/versions/3.41.8`)

### Running with Flutter

```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run static analysis
flutter analyze

# 3. Run unit and integration tests
flutter test

# 4. Run the application
flutter run -d chrome
# or for mobile:
flutter run -d <device_id>
```

### Running with FVM (if configured)

```bash
fvm flutter pub get
fvm flutter run
```
# Whats_play
