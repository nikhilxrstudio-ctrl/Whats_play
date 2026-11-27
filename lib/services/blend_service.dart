import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/blend_model.dart';
import '../models/track_model.dart';
import 'auth_service.dart';

class BlendService extends GetxService {
  static BlendService get to => Get.find<BlendService>();

  final RxList<BlendModel> userBlends = <BlendModel>[].obs;
  final RxBool isLoading = false.obs;

  StreamSubscription<QuerySnapshot>? _blendsSubscription;
  Worker? _authWorker;

  @override
  void onInit() {
    super.onInit();
    final auth = Get.isRegistered<AuthService>() ? AuthService.to : null;
    if (auth != null) {
      _authWorker = ever(auth.effectiveUid, (uid) {
        if (uid.isNotEmpty) {
          _listenToUserBlends(uid);
        } else {
          _blendsSubscription?.cancel();
          userBlends.clear();
        }
      });

      if (auth.effectiveUid.value.isNotEmpty) {
        _listenToUserBlends(auth.effectiveUid.value);
      }
    }
  }

  @override
  void onClose() {
    _authWorker?.dispose();
    _blendsSubscription?.cancel();
    super.onClose();
  }

  void _listenToUserBlends(String uid) {
    _blendsSubscription?.cancel();
    try {
      _blendsSubscription = FirebaseFirestore.instance
          .collection('blends')
          .where('memberUids', arrayContains: uid)
          .snapshots()
          .listen(
        (snapshot) {
          final list = snapshot.docs
              .map((doc) => BlendModel.fromFirestore(doc))
              .toList();
          // Sort by updatedAt descending
          list.sort((a, b) {
            final aTime = a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });
          userBlends.value = list;
        },
        onError: (err) {
          debugPrint('[BlendService] Error listening to user blends: $err');
        },
      );
    } catch (e) {
      debugPrint('[BlendService] Firestore listen init error: $e');
    }
  }

  /// Generate a unique 6-character uppercase alphanumeric code (no confusing chars: 0/O, 1/I)
  static String _generateRawCode() {
    const chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    final rand = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  /// Generates a verified unique uppercase code in Firestore
  Future<String> generateUniqueCode() async {
    for (int i = 0; i < 5; i++) {
      final code = _generateRawCode();
      try {
        final query = await FirebaseFirestore.instance
            .collection('blends')
            .where('code', isEqualTo: code)
            .limit(1)
            .get();
        if (query.docs.isEmpty) {
          return code;
        }
      } catch (_) {
        return code;
      }
    }
    return _generateRawCode();
  }

  /// Create a new shared Blend with customizable emoji icon and color theme
  Future<BlendModel?> createBlend({
    required String name,
    String icon = '🎵',
    String colorHex = '#1DB954',
    String? guestName,
  }) async {
    final auth = Get.isRegistered<AuthService>() ? AuthService.to : null;
    final uid = auth?.effectiveUid.value ?? '';
    if (uid.isEmpty) {
      Get.snackbar(
        'Connecting Device...',
        'Please wait a moment and try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }

    if (guestName != null && guestName.trim().isNotEmpty) {
      await auth?.updateGuestName(guestName.trim());
    }

    final effectiveName = auth?.effectiveUserName ?? 'Creator';
    final photo = auth?.currentUser.value?.photoURL ?? auth?.userPhotoUrl.value ?? '';

    isLoading.value = true;
    try {
      final code = await generateUniqueCode();
      final now = DateTime.now();

      final creatorMember = BlendMember(
        uid: uid,
        name: effectiveName,
        photoUrl: photo,
        joinedAt: now,
      );

      final blendRef = FirebaseFirestore.instance.collection('blends').doc();

      final blendData = {
        'name': name.trim().isNotEmpty ? name.trim() : 'Our Blend',
        'code': code.toUpperCase(),
        'creatorUid': uid,
        'creatorName': creatorMember.name,
        'creatorPhoto': creatorMember.photoUrl,
        'memberUids': [uid],
        'members': [creatorMember.toMap()],
        'tracksCount': 0,
        'icon': icon,
        'colorHex': colorHex,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await blendRef.set(blendData);

      // Increment createdBlendsCount on users/{uid}
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'createdBlendsCount': FieldValue.increment(1),
          'lastActive': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}

      final newBlend = BlendModel(
        id: blendRef.id,
        name: blendData['name'] as String,
        code: code,
        creatorUid: uid,
        creatorName: creatorMember.name,
        creatorPhoto: creatorMember.photoUrl,
        memberUids: [uid],
        members: [creatorMember],
        tracksCount: 0,
        icon: icon,
        colorHex: colorHex,
        createdAt: now,
        updatedAt: now,
      );

      isLoading.value = false;
      return newBlend;
    } catch (e) {
      debugPrint('[BlendService] Create blend error: $e');
      isLoading.value = false;
      Get.snackbar(
        'Error Creating Blend',
        'Could not create blend. Please check your internet connection.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  /// Join an existing Blend using its unique uppercase code
  Future<Map<String, dynamic>> joinBlendWithCode(String code, {String? guestName}) async {
    final auth = Get.isRegistered<AuthService>() ? AuthService.to : null;
    final uid = auth?.effectiveUid.value ?? '';
    if (uid.isEmpty) {
      return {
        'success': false,
        'message': 'Connecting device... Please try again in a moment.',
      };
    }

    if (guestName != null && guestName.trim().isNotEmpty) {
      await auth?.updateGuestName(guestName.trim());
    }

    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.length != 6) {
      return {
        'success': false,
        'message': 'Blend code must be 6 characters.',
      };
    }

    isLoading.value = true;
    try {
      final query = await FirebaseFirestore.instance
          .collection('blends')
          .where('code', isEqualTo: cleanCode)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        isLoading.value = false;
        return {
          'success': false,
          'message': 'No Blend found with code "$cleanCode". Check and try again.',
        };
      }

      final doc = query.docs.first;
      final existingBlend = BlendModel.fromFirestore(doc);

      // Check if user is already in this blend
      if (existingBlend.memberUids.contains(uid)) {
        isLoading.value = false;
        return {
          'success': true,
          'message': 'You are already in "${existingBlend.name}"!',
          'blend': existingBlend,
        };
      }

      final effectiveName = auth?.effectiveUserName ?? 'Friend';
      final photo = auth?.currentUser.value?.photoURL ?? auth?.userPhotoUrl.value ?? '';

      final newMember = BlendMember(
        uid: uid,
        name: effectiveName,
        photoUrl: photo,
        joinedAt: DateTime.now(),
      );

      // Add user to memberUids and members list
      await doc.reference.update({
        'memberUids': FieldValue.arrayUnion([uid]),
        'members': FieldValue.arrayUnion([newMember.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Increment joinedBlendsCount on users/{uid}
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'joinedBlendsCount': FieldValue.increment(1),
          'lastActive': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}

      // Re-fetch updated blend
      final updatedDoc = await doc.reference.get();
      final updatedBlend = BlendModel.fromFirestore(updatedDoc);

      isLoading.value = false;
      return {
        'success': true,
        'message': 'Successfully joined "${updatedBlend.name}"!',
        'blend': updatedBlend,
      };
    } catch (e) {
      debugPrint('[BlendService] Join blend error: $e');
      isLoading.value = false;
      return {
        'success': false,
        'message': 'Failed to join Blend: $e',
      };
    }
  }

  /// Add a song/track to a specific Blend
  Future<bool> addTrackToBlend(String blendId, TrackModel track) async {
    final auth = Get.isRegistered<AuthService>() ? AuthService.to : null;
    final uid = auth?.effectiveUid.value ?? '';
    if (uid.isEmpty) {
      Get.snackbar(
        'Connecting Device...',
        'Please wait a moment and try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    try {
      final tracksCollection = FirebaseFirestore.instance
          .collection('blends')
          .doc(blendId)
          .collection('tracks');

      // Check if track is already added to avoid duplicates
      final existing = await tracksCollection.where('audioUrl', isEqualTo: track.audioUrl).limit(1).get();
      if (existing.docs.isNotEmpty) {
        Get.snackbar(
          'Already in Blend',
          '"${track.title}" is already in this Blend playlist.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      final effectiveName = auth?.effectiveUserName ?? 'Friend';
      final photo = auth?.currentUser.value?.photoURL ?? auth?.userPhotoUrl.value ?? '';

      final trackDoc = tracksCollection.doc();
      final trackData = {
        'title': track.title,
        'artist': track.artistName,
        'artwork': track.artworkUrl ?? '',
        'audioUrl': track.audioUrl,
        'album': track.albumName,
        'durationSeconds': track.durationSeconds,
        'addedByUid': uid,
        'addedByName': effectiveName,
        'addedByPhoto': photo,
        'addedAt': FieldValue.serverTimestamp(),
      };

      await trackDoc.set(trackData);

      // Increment tracksCount on parent blend doc
      await FirebaseFirestore.instance.collection('blends').doc(blendId).update({
        'tracksCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        'Added to Blend',
        '"${track.title}" added to Blend playlist!',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      debugPrint('[BlendService] Add track error: $e');
      Get.snackbar(
        'Error',
        'Could not add track: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Real-time stream of tracks in a specific Blend
  Stream<List<BlendTrack>> getBlendTracksStream(String blendId) {
    if (blendId.isEmpty) return Stream.value([]);
    return FirebaseFirestore.instance
        .collection('blends')
        .doc(blendId)
        .collection('tracks')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => BlendTrack.fromFirestore(doc)).toList())
        .handleError((error) {
          debugPrint('[BlendService] getBlendTracksStream handled error: $error');
          return <BlendTrack>[];
        });
  }

  /// Real-time stream of a Blend document itself for syncing theme & details
  Stream<BlendModel?> getBlendStream(String blendId) {
    if (blendId.isEmpty) return Stream.value(null);
    return FirebaseFirestore.instance
        .collection('blends')
        .doc(blendId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return BlendModel.fromFirestore(doc);
        })
        .handleError((error) {
          debugPrint('[BlendService] getBlendStream handled error: $error');
          return null;
        });
  }

  /// Update the blend's custom icon/emoji and color theme
  Future<bool> updateBlendTheme(
    String blendId, {
    required String icon,
    required String colorHex,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('blends').doc(blendId).update({
        'icon': icon,
        'colorHex': colorHex,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('[BlendService] updateBlendTheme error: $e');
      return false;
    }
  }

  /// Remove a song from a Blend
  Future<bool> removeTrackFromBlend(String blendId, String trackDocId) async {
    try {
      await FirebaseFirestore.instance
          .collection('blends')
          .doc(blendId)
          .collection('tracks')
          .doc(trackDocId)
          .delete();

      await FirebaseFirestore.instance.collection('blends').doc(blendId).update({
        'tracksCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('[BlendService] Remove track error: $e');
      return false;
    }
  }

  /// Leave a Blend
  Future<bool> leaveBlend(String blendId) async {
    final auth = Get.isRegistered<AuthService>() ? AuthService.to : null;
    final uid = auth?.effectiveUid.value ?? '';
    if (uid.isEmpty) return false;

    try {
      final docRef = FirebaseFirestore.instance.collection('blends').doc(blendId);
      final doc = await docRef.get();
      if (!doc.exists) return false;

      final blend = BlendModel.fromFirestore(doc);
      final remainingUids = List<String>.from(blend.memberUids)..remove(uid);
      final remainingMembers = blend.members.where((m) => m.uid != uid).toList();

      if (remainingUids.isEmpty) {
        // No members left, delete the blend
        await docRef.delete();
      } else {
        await docRef.update({
          'memberUids': remainingUids,
          'members': remainingMembers.map((m) => m.toMap()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      return true;
    } catch (e) {
      debugPrint('[BlendService] Leave blend error: $e');
      return false;
    }
  }
}
