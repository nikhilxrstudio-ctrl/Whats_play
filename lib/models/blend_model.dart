import 'package:cloud_firestore/cloud_firestore.dart';
import 'track_model.dart';

class BlendMember {
  final String uid;
  final String name;
  final String photoUrl;
  final DateTime? joinedAt;

  BlendMember({
    required this.uid,
    required this.name,
    this.photoUrl = '',
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
      joinedAt: joined,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'photoUrl': photoUrl,
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
  final String creatorPhoto;
  final List<String> memberUids;
  final List<BlendMember> members;
  final int tracksCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BlendModel({
    required this.id,
    required this.name,
    required this.code,
    required this.creatorUid,
    required this.creatorName,
    this.creatorPhoto = '',
    required this.memberUids,
    required this.members,
    this.tracksCount = 0,
    this.createdAt,
    this.updatedAt,
  });

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

    return BlendModel(
      id: doc.id,
      name: data['name'] as String? ?? 'Our Blend',
      code: (data['code'] as String? ?? '').toUpperCase(),
      creatorUid: data['creatorUid'] as String? ?? '',
      creatorName: data['creatorName'] as String? ?? 'Friend',
      creatorPhoto: data['creatorPhoto'] as String? ?? '',
      memberUids: memberUidsList,
      members: membersList,
      tracksCount: (data['tracksCount'] as num?)?.toInt() ?? 0,
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
      'creatorPhoto': creatorPhoto,
      'memberUids': memberUids,
      'members': members.map((m) => m.toMap()).toList(),
      'tracksCount': tracksCount,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
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
