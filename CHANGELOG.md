# 📋 WhatsPlay Changelog

All notable changes, new features, and releases for the WhatsPlay music streaming application are documented in this file.

Version series follows: `1.0.0+1`, `1.0.1+2`, `1.0.2+3`, ... where the semantic version (`MAJOR.MINOR.PATCH`) pairs with an incrementing build number (`+BUILD`).

---

## [v1.0.8] - 2026-11-28 (Build: 1.0.8+9)

### ⚡ What's New
- Fix song change loop on track completion to cleanly advance exactly once

## [v1.0.7] - 2026-11-28 (Build: 1.0.7+8)

### ⚡ What's New
- Ensure seamless track auto-advance and continuous playback on song completion

## [v1.0.6] - 2026-11-28 (Build: 1.0.6+7)

### ⚡ What's New
- Fix repeat mode to seamlessly loop current song on track completion

## [v1.0.5] - 2026-11-28 (Build: 1.0.5+6)

### ⚡ What's New
- Secure API endpoints and credentials into protected vault with zero-leak git template

## [v1.0.4] - 2026-11-28 (Build: 1.0.4+5)

### ⚡ What's New
- Add Cloud Firestore song_downloads tracking and APK distribution telemetry

## [v1.0.3] - 2026-11-28 (Build: 1.0.3+4)

### ⚡ What's New
- Add deferred notification permission bottom sheet on dashboard arrival with settings toggle in Your Library

## [v1.0.2] - 2026-11-28 (Build: 1.0.2+3)

### ⚡ What's New
- Add Awesome Notifications for native device pop-ups, notification shade alerts, and topic-based FCM

## [v1.0.1] - 2026-11-28 (Build: 1.0.1+2)

### ⚡ What's New
- Add optional Google Login to onboarding, automated Welcome & Welcome Back emails via Brevo, and Firestore email_logs tracking

## [v1.0.0] - 2026-11-28 (Build: 1.0.0+1)

### 🎵 Core Audio & Streaming
- **Dual-Engine Audio Playback**: High-performance streaming powered by `just_audio` and `audioplayers` with automatic fallback.
- **Regional Indian Music Discovery**: Full catalogue covering Hindi, Punjabi, Gujarati, Bhojpuri, Haryanvi, and South Indian hits via JioSaavn API.
- **Search & Exploration**: Instant search across tracks, artists, albums, and playlists.
- **Full Player & Mini Player**: Gesture-controlled mini-player bar, full-screen player with lyrics view, queue reordering, and shuffle/repeat modes.
- **Offline Downloads & SQLite Cache**: Download tracks for offline listening with persistent local SQLite storage.

### 👥 Real-Time Shared Blends & Collaboration
- **Real-Time Collaborative Blends**: Cloud Firestore real-time synchronized listening rooms with attribution ("Added by [Name]").
- **Unique 6-Character Join Codes**: Shareable uppercase codes for friends to join blends instantly.
- **Smart Song Suggestions**: Category-aware song suggestions in the Add Song sheet matching the Blend's existing language and genre.
- **Web Blend Preview**: Magic link preview landing page at `docs/blend.html` with deep-linking support.

### 💌 Automated Dark-Themed Email System (Brevo SMTP Relay)
- **100% Free Transactional Email Relay**: Direct authenticated SMTP delivery via Brevo (`smtp-relay.brevo.com:587`), requiring zero credit cards or Firebase Blaze billing.
- **Creator Confirmation Card**: Automatically delivered upon Blend creation, featuring the creator's unique 6-digit Join Code (`YOUR BLEND SHARE CODE`), gradient header banner, direct Blend management link, and sharing instructions.
- **Friend Invitation Card**: Tailored invitation card with creator greeting (*"Nikhil invited you to join..."*), Join Code box (`YOUR UNIQUE JOIN CODE`), *"Open & Join Blend Now"* CTA button, and step-by-step instructions.
- **In-App Direct Email Invite Dialog**: Send HTML invite cards directly to any recipient's email address or re-send to your own email from `BlendDetailScreen`.

### 🎨 Design & Branding
- **3D Musical Mascot Companion**: Integrated transparent PNG character avatar in onboarding and branding.
- **2-Step Onboarding**: Name selection and personalized genre picker with dynamic Home category filter chips.
- **Polished Dynamic States**: High-contrast, glowing Play All buttons and smooth TabController bottom navigation.

### 🏷️ Release & Version Tagging System
- Automated release management script (`scripts/release.sh`) for versioning, APK compilation, artifact synchronization, and Git tag publication.
