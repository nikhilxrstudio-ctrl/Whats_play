import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'track_model.dart';

class BlendThemePreset {
  final String icon;
  final String colorHex;
  final String label;

  const BlendThemePreset({
    required this.icon,
    required this.colorHex,
    required this.label,
  });
}

const List<BlendThemePreset> kBlendPresets = [
  BlendThemePreset(icon: '🎵', colorHex: '#1DB954', label: 'Classic'),
  BlendThemePreset(icon: '🔥', colorHex: '#FF5722', label: 'Vibes'),
  BlendThemePreset(icon: '💜', colorHex: '#9C27B0', label: 'Chill'),
  BlendThemePreset(icon: '🎧', colorHex: '#00E5FF', label: 'Electro'),
  BlendThemePreset(icon: '💖', colorHex: '#E91E63', label: 'Romance'),
  BlendThemePreset(icon: '⚡', colorHex: '#FFC107', label: 'Party'),
  BlendThemePreset(icon: '🌊', colorHex: '#0091EA', label: 'Waves'),
  BlendThemePreset(icon: '☕', colorHex: '#8D6E63', label: 'Acoustic'),
  BlendThemePreset(icon: '🌟', colorHex: '#FFB300', label: 'Stars'),
  BlendThemePreset(icon: '🎸', colorHex: '#E64A19', label: 'Rock'),
  BlendThemePreset(icon: '🌴', colorHex: '#26A69A', label: 'Tropics'),
  BlendThemePreset(icon: '🎉', colorHex: '#7C4DFF', label: 'Fiesta'),
];

class BlendMember {
  final String uid;
  final String name;
  final String photoUrl;
  final String email;
  final DateTime? joinedAt;

  BlendMember({
    required this.uid,
    required this.name,
    this.photoUrl = '',
    this.email = '',
    this.joinedAt,
  });

  factory BlendMember.fromMap(Map<String, dynamic> map) {
    DateTime? joined;
    if (map['joinedAt'] is Timestamp) {
      joined = (map['joinedAt'] as Timestamp).toDate();
    }
    return BlendMember(
      uid: map['uid'] as String? ?? '',
      name: map['name'] as String? ?? 'Member',
      photoUrl: map['photoUrl'] as String? ?? '',
      email: map['email'] as String? ?? '',
      joinedAt: joined,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'photoUrl': photoUrl,
      'email': email,
      'joinedAt': joinedAt != null ? Timestamp.fromDate(joinedAt!) : FieldValue.serverTimestamp(),
    };
  }
}

class BlendModel {
  final String id;
  final String name;
  final String code; // 6-character unique uppercase code
  final String creatorUid;
  final String creatorName;
  final String creatorEmail;
  final String creatorPhoto;
  final List<String> memberUids;
  final List<BlendMember> members;
  final int tracksCount;
  final String icon; // Emoji or custom icon, e.g. 🎵, 🔥, 💜
  final String colorHex; // Hex string e.g. '#1DB954'
  final bool isOfficial; // Official Blend created from Admin panel
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BlendModel({
    required this.id,
    required this.name,
    required this.code,
    required this.creatorUid,
    required this.creatorName,
    this.creatorEmail = '',
    this.creatorPhoto = '',
    required this.memberUids,
    required this.members,
    this.tracksCount = 0,
    this.icon = '🎵',
    this.colorHex = '#1DB954',
    this.isOfficial = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Official room verification helper:
  /// Returns true if marked as official by Admin or matches official creator UID / email
  bool get isOfficialBlend {
    return isOfficial == true ||
        creatorUid == 'official_whatsplay_admin' ||
        creatorEmail.trim().toLowerCase() == 'whatsplay.official@gmail.com';
  }

  /// Global static helper to check if a Blend room is official
  static bool checkIsOfficial(BlendModel blend) => blend.isOfficialBlend;

  /// Parse the colorHex into a Flutter Color
  Color get themeColor {
    try {
      final hex = colorHex.replaceAll('#', '').trim();
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
      return const Color(0xFF1DB954);
    } catch (_) {
      return const Color(0xFF1DB954);
    }
  }

  /// Two-tone gradient matching the blend theme
  List<Color> get gradientColors {
    final primary = themeColor;
    final hsl = HSLColor.fromColor(primary);
    final dark = hsl.withLightness((hsl.lightness * 0.45).clamp(0.0, 1.0)).toColor();
    return [primary, dark];
  }

  factory BlendModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime? created;
    if (data['createdAt'] is Timestamp) {
      created = (data['createdAt'] as Timestamp).toDate();
    }
    DateTime? updated;
    if (data['updatedAt'] is Timestamp) {
      updated = (data['updatedAt'] as Timestamp).toDate();
    }

    final rawMembers = data['members'] as List<dynamic>? ?? [];
    final membersList = rawMembers
        .map((m) => BlendMember.fromMap(m is Map<String, dynamic> ? m : {}))
        .toList();

    final rawMemberUids = data['memberUids'] as List<dynamic>? ?? [];
    final memberUidsList = rawMemberUids.map((u) => u.toString()).toList();

    final isOfficialRaw = data['isOfficial'] == true ||
        data['creatorUid'] == 'official_whatsplay_admin' ||
        (data['creatorEmail'] as String? ?? '').trim().toLowerCase() == 'whatsplay.official@gmail.com';

    return BlendModel(
      id: doc.id,
      name: data['name'] as String? ?? 'Our Blend',
      code: (data['code'] as String? ?? '').toUpperCase(),
      creatorUid: data['creatorUid'] as String? ?? '',
      creatorName: data['creatorName'] as String? ?? 'Friend',
      creatorEmail: data['creatorEmail'] as String? ?? '',
      creatorPhoto: data['creatorPhoto'] as String? ?? '',
      memberUids: memberUidsList,
      members: membersList,
      tracksCount: (data['tracksCount'] as num?)?.toInt() ?? 0,
      icon: data['icon'] as String? ?? '🎵',
      colorHex: data['colorHex'] as String? ?? '#1DB954',
      isOfficial: isOfficialRaw,
      createdAt: created,
      updatedAt: updated,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': code.toUpperCase(),
      'creatorUid': creatorUid,
      'creatorName': creatorName,
      'creatorEmail': creatorEmail,
      'creatorPhoto': creatorPhoto,
      'memberUids': memberUids,
      'members': members.map((m) => m.toMap()).toList(),
      'tracksCount': tracksCount,
      'icon': icon,
      'colorHex': colorHex,
      'isOfficial': isOfficial,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  BlendModel copyWith({
    String? id,
    String? name,
    String? code,
    String? creatorUid,
    String? creatorName,
    String? creatorEmail,
    String? creatorPhoto,
    List<String>? memberUids,
    List<BlendMember>? members,
    int? tracksCount,
    String? icon,
    String? colorHex,
    bool? isOfficial,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BlendModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      creatorUid: creatorUid ?? this.creatorUid,
      creatorName: creatorName ?? this.creatorName,
      creatorEmail: creatorEmail ?? this.creatorEmail,
      creatorPhoto: creatorPhoto ?? this.creatorPhoto,
      memberUids: memberUids ?? this.memberUids,
      members: members ?? this.members,
      tracksCount: tracksCount ?? this.tracksCount,
      icon: icon ?? this.icon,
      colorHex: colorHex ?? this.colorHex,
      isOfficial: isOfficial ?? this.isOfficial,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class BlendTrack {
  final String id;
  final String title;
  final String artist;
  final String artwork;
  final String audioUrl;
  final String album;
  final int durationSeconds;
  final String addedByUid;
  final String addedByName;
  final String addedByPhoto;
  final DateTime? addedAt;

  BlendTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.artwork,
    required this.audioUrl,
    required this.album,
    this.durationSeconds = 0,
    required this.addedByUid,
    required this.addedByName,
    this.addedByPhoto = '',
    this.addedAt,
  });

  factory BlendTrack.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime? added;
    if (data['addedAt'] is Timestamp) {
      added = (data['addedAt'] as Timestamp).toDate();
    }

    return BlendTrack(
      id: doc.id,
      title: data['title'] as String? ?? 'Unknown Title',
      artist: data['artist'] as String? ?? 'Unknown Artist',
      artwork: data['artwork'] as String? ?? '',
      audioUrl: data['audioUrl'] as String? ?? '',
      album: data['album'] as String? ?? '',
      durationSeconds: (data['durationSeconds'] as num?)?.toInt() ?? 0,
      addedByUid: data['addedByUid'] as String? ?? '',
      addedByName: data['addedByName'] as String? ?? 'Friend',
      addedByPhoto: data['addedByPhoto'] as String? ?? '',
      addedAt: added,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'artist': artist,
      'artwork': artwork,
      'audioUrl': audioUrl,
      'album': album,
      'durationSeconds': durationSeconds,
      'addedByUid': addedByUid,
      'addedByName': addedByName,
      'addedByPhoto': addedByPhoto,
      'addedAt': addedAt != null ? Timestamp.fromDate(addedAt!) : FieldValue.serverTimestamp(),
    };
  }

  TrackModel toTrackModel() {
    return TrackModel(
      trackId: id,
      title: title,
      artistName: artist,
      albumName: album.isNotEmpty ? album : 'Blend Playlist',
      artworkUrl: artwork.isNotEmpty ? artwork : null,
      genre: 'Blend',
      durationSeconds: durationSeconds,
      audioUrl: audioUrl,
      musicSource: 'saavn',
      licenseInfo: 'Standard',
      isStreamable: true,
      isDownloadable: true,
    );
  }
}
