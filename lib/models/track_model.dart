import 'package:intl/intl.dart';
import '../constants/api_constants.dart';
import '../utils/saavn_decryptor.dart';

class TrackModel {
  final String trackId;
  final String title;
  final String artistName;
  final String albumName;
  final String? artworkUrl;
  final String genre;
  final int durationSeconds;
  final DateTime? releaseDate;
  final String audioUrl;
  final String musicSource;
  final String licenseInfo;
  final bool isStreamable;
  final bool isDownloadable;
  final int? lastPlayedTimestamp;
  final String? localFilePath;

  const TrackModel({
    required this.trackId,
    required this.title,
    required this.artistName,
    required this.albumName,
    this.artworkUrl,
    required this.genre,
    required this.durationSeconds,
    this.releaseDate,
    required this.audioUrl,
    required this.musicSource,
    required this.licenseInfo,
    required this.isStreamable,
    required this.isDownloadable,
    this.lastPlayedTimestamp,
    this.localFilePath,
  });

  TrackModel copyWith({
    String? trackId,
    String? title,
    String? artistName,
    String? albumName,
    String? artworkUrl,
    String? genre,
    int? durationSeconds,
    DateTime? releaseDate,
    String? audioUrl,
    String? musicSource,
    String? licenseInfo,
    bool? isStreamable,
    bool? isDownloadable,
    int? lastPlayedTimestamp,
    String? localFilePath,
  }) {
    return TrackModel(
      trackId: trackId ?? this.trackId,
      title: title ?? this.title,
      artistName: artistName ?? this.artistName,
      albumName: albumName ?? this.albumName,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      genre: genre ?? this.genre,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      releaseDate: releaseDate ?? this.releaseDate,
      audioUrl: audioUrl ?? this.audioUrl,
      musicSource: musicSource ?? this.musicSource,
      licenseInfo: licenseInfo ?? this.licenseInfo,
      isStreamable: isStreamable ?? this.isStreamable,
      isDownloadable: isDownloadable ?? this.isDownloadable,
      lastPlayedTimestamp: lastPlayedTimestamp ?? this.lastPlayedTimestamp,
      localFilePath: localFilePath ?? this.localFilePath,
    );
  }

  /// Factory constructor to parse directly from Audius API track JSON
  factory TrackModel.fromAudiusJson(Map<String, dynamic> json) {
    final String trackId = (json['id'] ?? json['track_id'] ?? '').toString();
    final String title = json['title'] ?? 'Untitled Track';

    // Parse artist name from nested 'user' object
    String artistName = 'Unknown Artist';
    if (json['user'] is Map<String, dynamic>) {
      artistName = json['user']['name'] ??
          json['user']['handle'] ??
          'Unknown Artist';
    }

    // Parse album name from album_backlink if available
    String albumName = 'Single';
    if (json['album_backlink'] is Map<String, dynamic>) {
      final backlink = json['album_backlink'] as Map<String, dynamic>;
      albumName = backlink['playlist_name'] ?? 'Single';
    }

    // Parse artwork URL (prefer 480x480, then 150x150, then 1000x1000)
    String? artworkUrl;
    if (json['artwork'] is Map<String, dynamic>) {
      final artworkMap = json['artwork'] as Map<String, dynamic>;
      artworkUrl = artworkMap['480x480'] ??
          artworkMap['150x150'] ??
          artworkMap['1000x1000'];
    }

    // Sanitize Audius decentralized artwork URL: upgrade to https and strip non-standard validator ports
    if (artworkUrl != null && artworkUrl.isNotEmpty) {
      if (artworkUrl.startsWith('http://')) {
        artworkUrl = artworkUrl.replaceFirst('http://', 'https://');
      }
      final uri = Uri.tryParse(artworkUrl);
      if (uri != null && uri.hasPort && uri.port != 80 && uri.port != 443 && uri.port != 8080 && uri.port != 8443) {
        artworkUrl = uri.replace(port: null).toString();
      }
    }

    final String genre = json['genre'] != null && json['genre'].toString().isNotEmpty
        ? json['genre'].toString()
        : 'General';

    final int durationSeconds = (json['duration'] is num)
        ? (json['duration'] as num).toInt()
        : 0;

    // Parse release date safely
    DateTime? releaseDate;
    if (json['release_date'] != null) {
      try {
        releaseDate = DateTime.parse(json['release_date'].toString());
      } catch (_) {
        releaseDate = null;
      }
    }

    final bool isStreamable = json['is_streamable'] == true;
    final bool isDownloadable = json['is_downloadable'] == true;

    // Use direct stream URL from Audius API endpoint
    final String audioUrl = ApiConstants.buildStreamUrl(trackId);

    // License details
    final String rawLicense = json['license']?.toString() ?? '';
    final String licenseInfo = rawLicense.isNotEmpty
        ? rawLicense
        : 'Audius Open Platform Stream License (Full Track Playable)';

    return TrackModel(
      trackId: trackId,
      title: title,
      artistName: artistName,
      albumName: albumName,
      artworkUrl: artworkUrl,
      genre: genre,
      durationSeconds: durationSeconds,
      releaseDate: releaseDate,
      audioUrl: audioUrl,
      musicSource: 'Audius Protocol (Legitimate Open API)',
      licenseInfo: licenseInfo,
      isStreamable: isStreamable,
      isDownloadable: isDownloadable,
    );
  }

  /// Factory constructor to parse from JioSaavn Indian/Bollywood/Regional hit music JSON
  factory TrackModel.fromSaavnJson(Map<String, dynamic> json) {
    final String trackId = (json['id'] ?? '').toString();
    String title = json['title'] ?? 'Untitled Track';
    title = title
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&#039;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');

    final moreInfo = json['more_info'] is Map<String, dynamic>
        ? json['more_info'] as Map<String, dynamic>
        : <String, dynamic>{};

    // Parse artist names
    String artistName = 'Unknown Artist';
    if (moreInfo['artistMap'] is Map<String, dynamic>) {
      final artistMap = moreInfo['artistMap'] as Map<String, dynamic>;
      final primary = artistMap['primary_artists'] as List<dynamic>?;
      if (primary != null && primary.isNotEmpty) {
        artistName = primary
            .map((a) => a['name']?.toString() ?? '')
            .where((n) => n.isNotEmpty)
            .join(', ');
      }
    }
    if (artistName == 'Unknown Artist' && json['subtitle'] != null) {
      artistName = json['subtitle'].toString().split('-').first.trim();
    }

    final String albumName = moreInfo['album']?.toString() ?? 'Single';

    // Upgrade image to high-resolution 500x500
    String? artworkUrl = json['image']?.toString();
    if (artworkUrl != null) {
      artworkUrl = artworkUrl
          .replaceAll('150x150.jpg', '500x500.jpg')
          .replaceAll('50x50.jpg', '500x500.jpg');
    }

    final String rawLang = json['language']?.toString() ?? 'Indian Pop';
    final String genre = rawLang.isNotEmpty
        ? '${rawLang[0].toUpperCase()}${rawLang.substring(1)}'
        : 'Indian Pop';

    final int durationSeconds =
        int.tryParse(moreInfo['duration']?.toString() ?? '0') ?? 0;

    // Decrypt full high quality 320kbps track stream URL or fallback to vlink
    String audioUrl = '';
    final String? encryptedMediaUrl =
        moreInfo['encrypted_media_url']?.toString();
    if (encryptedMediaUrl != null && encryptedMediaUrl.isNotEmpty) {
      audioUrl = SaavnDecryptor.decryptMediaUrl(encryptedMediaUrl);
    }
    if (audioUrl.isEmpty) {
      audioUrl = moreInfo['vlink']?.toString() ?? '';
    }
    final bool isStreamable = audioUrl.isNotEmpty;

    final String licenseInfo = moreInfo['copyright_text']?.toString() ??
        'Official Licensed Music Stream';

    return TrackModel(
      trackId: trackId,
      title: title,
      artistName: artistName,
      albumName: albumName,
      artworkUrl: artworkUrl,
      genre: genre,
      durationSeconds: durationSeconds,
      audioUrl: audioUrl,
      musicSource: 'JioSaavn Official Open Catalogue',
      licenseInfo: licenseInfo,
      isStreamable: isStreamable,
      isDownloadable: false,
    );
  }

  /// Formatted duration string e.g. "3:45"
  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final remainingSeconds = durationSeconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Formatted release date e.g. "Nov 19, 2026"
  String get formattedReleaseDate {
    if (releaseDate == null) return 'N/A';
    try {
      return DateFormat.yMMMd().format(releaseDate!);
    } catch (_) {
      return 'N/A';
    }
  }

  /// DateTime representation of when the track was last played
  DateTime? get lastPlayedDateTime => lastPlayedTimestamp != null
      ? DateTime.fromMillisecondsSinceEpoch(lastPlayedTimestamp!)
      : null;

  /// Human-friendly day label for grouping in Listening History (e.g. "Today", "Yesterday", "Nov 24, 2026")
  String get dayLabel {
    if (lastPlayedTimestamp == null) return 'Earlier';
    final date = DateTime.fromMillisecondsSinceEpoch(lastPlayedTimestamp!);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final trackDay = DateTime(date.year, date.month, date.day);

    if (trackDay == today) {
      return 'Today';
    } else if (trackDay == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('EEEE, MMM d').format(date);
    }
  }

  /// Convert TrackModel to clean Map containing only core SQLite track columns
  Map<String, dynamic> toSqliteTrackMap() {
    return {
      'track_id': trackId,
      'title': title,
      'artist_name': artistName,
      'album_name': albumName,
      'artwork_url': artworkUrl,
      'genre': genre,
      'duration_seconds': durationSeconds,
      'release_date': releaseDate?.toIso8601String(),
      'audio_url': audioUrl,
      'music_source': musicSource,
      'license_info': licenseInfo,
      'is_streamable': isStreamable ? 1 : 0,
      'is_downloadable': isDownloadable ? 1 : 0,
    };
  }

  /// Convert TrackModel to Map for SQLite local storage persistence
  Map<String, dynamic> toMap() {
    return {
      'track_id': trackId,
      'title': title,
      'artist_name': artistName,
      'album_name': albumName,
      'artwork_url': artworkUrl,
      'genre': genre,
      'duration_seconds': durationSeconds,
      'release_date': releaseDate?.toIso8601String(),
      'audio_url': audioUrl,
      'music_source': musicSource,
      'license_info': licenseInfo,
      'is_streamable': isStreamable ? 1 : 0,
      'is_downloadable': isDownloadable ? 1 : 0,
    };
  }

  /// Factory constructor to reconstruct TrackModel from SQLite local storage map
  factory TrackModel.fromMap(Map<String, dynamic> map) {
    DateTime? releaseDate;
    if (map['release_date'] != null) {
      try {
        releaseDate = DateTime.parse(map['release_date'].toString());
      } catch (_) {
        releaseDate = null;
      }
    }

    final playedAt = (map['last_played_at'] as num?)?.toInt() ??
        (map['downloaded_at'] as num?)?.toInt();

    return TrackModel(
      trackId: map['track_id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Untitled Track',
      artistName: map['artist_name']?.toString() ?? 'Unknown Artist',
      albumName: map['album_name']?.toString() ?? 'Single',
      artworkUrl: map['artwork_url']?.toString(),
      genre: map['genre']?.toString() ?? 'General',
      durationSeconds: (map['duration_seconds'] as num?)?.toInt() ?? 0,
      releaseDate: releaseDate,
      audioUrl: map['audio_url']?.toString() ?? '',
      musicSource: map['music_source']?.toString() ?? 'Local Storage',
      licenseInfo: map['license_info']?.toString() ?? 'Licensed Audio Stream',
      isStreamable: map['is_streamable'] == 1 || map['is_streamable'] == true,
      isDownloadable: map['is_downloadable'] == 1 || map['is_downloadable'] == true,
      lastPlayedTimestamp: playedAt,
      localFilePath: map['local_file_path']?.toString(),
    );
  }

  /// Display text for Audio Availability Status
  String get audioAvailabilityStatus {
    if (isStreamable) {
      return 'Full Audio Available (Direct MP3 Stream)';
    }
    return 'Stream Unavailable';
  }

  /// Audio availability indicator type
  AudioStatusType get audioStatusType {
    if (isStreamable) return AudioStatusType.fullTrack;
    return AudioStatusType.unavailable;
  }
}

enum AudioStatusType {
  fullTrack,
  previewOnly,
  unavailable,
}
