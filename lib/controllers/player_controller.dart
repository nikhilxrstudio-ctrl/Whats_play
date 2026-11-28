import 'dart:async';
import 'dart:io' as io;
import 'package:audio_service/audio_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/track_model.dart';
import '../services/audio_player_handler.dart';
import '../services/auth_service.dart';
import '../services/local_database_service.dart';
import 'music_controller.dart';

class PlayerController extends GetxController {
  final AudioPlayerHandler _audioHandler;
  final ILocalDatabaseService _databaseService;

  PlayerController(
    this._audioHandler, {
    ILocalDatabaseService? databaseService,
  }) : _databaseService = databaseService ?? LocalDatabaseService();

  // Observables
  final Rx<TrackModel?> currentTrack = Rx<TrackModel?>(null);
  final RxList<TrackModel> playlist = <TrackModel>[].obs;
  final RxInt currentIndex = 0.obs;

  final RxBool isPlaying = false.obs;
  final RxBool isBuffering = false.obs;
  final Rx<Duration> position = Duration.zero.obs;
  final Rx<Duration> duration = Duration.zero.obs;
  final RxBool isShuffle = false.obs;
  final RxBool isRepeat = false.obs;

  // Liked tracks collection
  final RxSet<String> likedTrackIds = <String>{}.obs;
  final RxList<TrackModel> likedTracks = <TrackModel>[].obs;

  // Downloaded tracks collection
  final RxSet<String> downloadedTrackIds = <String>{}.obs;
  final RxList<TrackModel> downloadedTracks = <TrackModel>[].obs;
  final RxSet<String> downloadingTrackIds = <String>{}.obs;

  bool isTrackLiked(String trackId) {
    return likedTrackIds.contains(trackId);
  }

  bool isTrackDownloaded(String trackId) {
    return downloadedTrackIds.contains(trackId);
  }

  bool isDownloading(String trackId) {
    return downloadingTrackIds.contains(trackId);
  }

  Future<void> toggleDownload(TrackModel track) async {
    if (downloadedTrackIds.contains(track.trackId)) {
      downloadedTrackIds.remove(track.trackId);
      final removed = downloadedTracks.firstWhereOrNull((t) => t.trackId == track.trackId);
      downloadedTracks.removeWhere((t) => t.trackId == track.trackId);
      try {
        await _databaseService.removeDownloadedSong(track.trackId);
        if (removed?.localFilePath != null) {
          final file = io.File(removed!.localFilePath!);
          if (await file.exists()) {
            await file.delete();
          }
        }
        _syncDownloadEventToFirestore(track, isAdded: false);
        debugPrint('[PlayerController] Removed "${track.title}" from downloads.');
        if (Get.overlayContext != null) {
          Get.rawSnackbar(
            message: 'Removed from Downloads',
            duration: const Duration(seconds: 2),
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      } catch (e) {
        debugPrint('[PlayerController] Error removing downloaded song: $e');
      }
    } else {
      downloadingTrackIds.add(track.trackId);
      try {
        String? localFilePath;
        String? fileSizeString;
        if (track.audioUrl.isNotEmpty) {
          try {
            final appDir = await getApplicationDocumentsDirectory();
            final offlineDir = io.Directory(p.join(appDir.path, 'offline_music'));
            if (!await offlineDir.exists()) {
              await offlineDir.create(recursive: true);
              // Create .nomedia so files are hidden from Android Media Scanner / gallery / other players
              final noMediaFile = io.File(p.join(offlineDir.path, '.nomedia'));
              if (!await noMediaFile.exists()) {
                await noMediaFile.writeAsString('');
              }
            }
            final sanitizedId = track.trackId.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
            final destinationPath = p.join(offlineDir.path, '$sanitizedId.m4a');
            final tempPath = '$destinationPath.tmp';

            final response = await http.get(Uri.parse(track.audioUrl));
            if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
              final tempFile = io.File(tempPath);
              await tempFile.writeAsBytes(response.bodyBytes);
              await tempFile.rename(destinationPath);
              localFilePath = destinationPath;
              final sizeInMb = response.bodyBytes.length / (1024 * 1024);
              fileSizeString = '${sizeInMb.toStringAsFixed(1)} MB';
              debugPrint('[PlayerController] Saved offline audio to app sandbox: $destinationPath ($fileSizeString)');
            }
          } catch (ioErr) {
            debugPrint('[PlayerController] Offline file save error/fallback: $ioErr');
          }
        }

        final downloadedTrack = track.copyWith(
          localFilePath: localFilePath ?? 'local_storage/${track.trackId}.m4a',
        );
        await _databaseService.saveDownloadedSong(downloadedTrack, localPath: localFilePath);
        downloadingTrackIds.remove(track.trackId);
        downloadedTrackIds.add(track.trackId);
        downloadedTracks.removeWhere((t) => t.trackId == track.trackId);
        downloadedTracks.insert(0, downloadedTrack);

        _syncDownloadEventToFirestore(
          downloadedTrack,
          isAdded: true,
          fileSize: fileSizeString ?? '3.5 MB',
        );

        debugPrint('[PlayerController] Saved "${track.title}" to downloads.');
        if (Get.overlayContext != null) {
          Get.rawSnackbar(
            message: 'Downloaded "${track.title}" for offline listening',
            duration: const Duration(seconds: 2),
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      } catch (e) {
        downloadingTrackIds.remove(track.trackId);
        debugPrint('[PlayerController] Error saving downloaded song: $e');
      }
    }
  }

  void _syncDownloadEventToFirestore(
    TrackModel track, {
    required bool isAdded,
    String? fileSize,
  }) {
    Future.microtask(() async {
      try {
        final authService = Get.isRegistered<AuthService>() ? Get.find<AuthService>() : null;
        final uid = authService?.currentUser.value?.uid;
        final deviceId = authService?.currentDeviceId.value;
        final userName = authService?.effectiveUserName ?? 'WhatsPlay User';
        final userEmail = authService?.userEmail.value ?? '';

        final firestore = FirebaseFirestore.instance;

        // 1. Update user document download counters for admin dashboard
        final updateMap = <String, dynamic>{
          'totalDownloads': FieldValue.increment(isAdded ? 1 : -1),
          'downloadCount': FieldValue.increment(isAdded ? 1 : -1),
          'lastUpdated': FieldValue.serverTimestamp(),
        };

        if (isAdded) {
          updateMap['lastDownloadAt'] = FieldValue.serverTimestamp();
          updateMap['lastDownloadedSong'] = track.title;
        }

        if (uid != null && uid.isNotEmpty) {
          await firestore.collection('users').doc(uid).set(updateMap, SetOptions(merge: true));
        }

        if (deviceId != null && deviceId.isNotEmpty && deviceId != 'unknown') {
          await firestore.collection('users').doc('device_$deviceId').set(updateMap, SetOptions(merge: true));
        }

        // 2. If newly added, log individual download record into 'song_downloads'
        if (isAdded) {
          await firestore.collection('song_downloads').add({
            'songId': track.trackId,
            'songName': track.title,
            'artist': track.artistName,
            'user': userName.isNotEmpty ? userName : 'WhatsPlay User',
            'userEmail': userEmail,
            'userId': uid ?? (deviceId != null ? 'device_$deviceId' : 'anonymous'),
            'status': 'Success',
            'fileSize': fileSize ?? '3.5 MB',
            'artwork': track.artworkUrl ?? '',
            'source': 'WhatsPlay App',
            'downloadDate': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        debugPrint('[PlayerController] Download Firestore sync error: $e');
      }
    });
  }

  Future<void> toggleLike(TrackModel track) async {
    if (likedTrackIds.contains(track.trackId)) {
      likedTrackIds.remove(track.trackId);
      likedTracks.removeWhere((t) => t.trackId == track.trackId);
      try {
        await _databaseService.removeLikedSong(track.trackId);
        debugPrint('[PlayerController] Removed "${track.title}" from local storage.');
      } catch (e) {
        debugPrint('[PlayerController] Error removing liked song from storage: $e');
      }
    } else {
      likedTrackIds.add(track.trackId);
      if (!likedTracks.any((t) => t.trackId == track.trackId)) {
        likedTracks.insert(0, track);
      }
      try {
        await _databaseService.saveLikedSong(track);
        debugPrint('[PlayerController] Saved "${track.title}" to local storage.');
      } catch (e) {
        debugPrint('[PlayerController] Error saving liked song to storage: $e');
      }
    }
  }

  StreamSubscription? _playbackSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;

  @override
  void onInit() {
    super.onInit();
    _listenToPlayerStreams();
    _loadLikedSongsFromStorage();
    _loadDownloadedSongsFromStorage();
  }

  Future<void> _loadDownloadedSongsFromStorage() async {
    try {
      final savedTracks = await _databaseService.getDownloadedSongs();
      downloadedTracks.assignAll(savedTracks);
      downloadedTrackIds.assignAll(savedTracks.map((t) => t.trackId));
      debugPrint(
          '[PlayerController] Successfully loaded ${savedTracks.length} downloaded songs from local storage.');
    } catch (e) {
      debugPrint('[PlayerController] Error loading downloaded songs from storage: $e');
    }
  }

  Future<void> _loadLikedSongsFromStorage() async {
    try {
      final savedTracks = await _databaseService.getLikedSongs();
      likedTracks.assignAll(savedTracks);
      likedTrackIds.assignAll(savedTracks.map((t) => t.trackId));
      debugPrint(
          '[PlayerController] Successfully loaded ${savedTracks.length} liked songs from local storage.');
    } catch (e) {
      debugPrint('[PlayerController] Error loading liked songs from storage: $e');
    }
  }

  int _playSequenceToken = 0;
  bool _hasRecordedCurrentTrackForHistory = false;

  void _listenToPlayerStreams() {
    _audioHandler.onSkipToNext = playNext;
    _audioHandler.onSkipToPrevious = playPrevious;

    _playbackSubscription = _audioHandler.player.playerStateStream.listen(
      (state) {
        isPlaying.value = state.playing;
        isBuffering.value = state.processingState == ProcessingState.buffering ||
            state.processingState == ProcessingState.loading;

        // When current track starts playing cleanly, pre-buffer the next track!
        if (state.playing && state.processingState == ProcessingState.ready) {
          _triggerNextTrackPrebuffering();
        }

        if (state.processingState == ProcessingState.completed) {
          if (!_hasRecordedCurrentTrackForHistory && currentTrack.value != null) {
            _recordListeningHistory(currentTrack.value!);
          }
          if (isRepeat.value) {
            // Repeat mode active: immediately restart current track from beginning
            Future.microtask(() async {
              try {
                await seek(Duration.zero);
                await play();
              } catch (_) {
                if (currentTrack.value != null) {
                  await playTrack(currentTrack.value!);
                }
              }
            });
          } else {
            // Auto-advance to next track in playlist and guarantee continuous playback
            Future.microtask(() async {
              try {
                await playNext();
              } catch (e) {
                debugPrint('[PlayerController] Error auto-playing next track: $e');
              }
            });
          }
        }
      },
      onError: (Object e) {
        debugPrint('[PlayerController] playerStateStream error caught: $e');
      },
    );

    _positionSubscription = _audioHandler.player.positionStream.listen(
      (pos) {
        position.value = pos;

        // Automatically record to Listening History when user has listened for 10 seconds
        if (!_hasRecordedCurrentTrackForHistory &&
            pos.inSeconds >= 10 &&
            currentTrack.value != null) {
          _recordListeningHistory(currentTrack.value!);
        }
      },
      onError: (Object e) {},
    );

    _durationSubscription = _audioHandler.player.durationStream.listen(
      (dur) {
        if (dur != null && dur > Duration.zero) {
          duration.value = dur;
        }
      },
      onError: (Object e) {},
    );
  }

  /// Automatically records track to listening history and refreshes Library
  Future<void> _recordListeningHistory(TrackModel track) async {
    if (_hasRecordedCurrentTrackForHistory) return;
    _hasRecordedCurrentTrackForHistory = true;

    final now = DateTime.now().millisecondsSinceEpoch;
    final trackWithTimestamp = track.copyWith(lastPlayedTimestamp: now);

    debugPrint('[PlayerController] User listened >= 10s: adding "${track.title}" to Listening History');

    try {
      await _databaseService.recordTrackPlay(trackWithTimestamp);
      if (Get.isRegistered<MusicController>()) {
        final musicCtrl = Get.find<MusicController>();
        musicCtrl.onTrackPlayed(trackWithTimestamp);
        await musicCtrl.loadListeningHistory();
      }
    } catch (e) {
      debugPrint('[PlayerController] Error recording track to history: $e');
    }
  }

  @visibleForTesting
  Future<void> recordListeningHistoryForTest(TrackModel track) => _recordListeningHistory(track);

  /// Plays a selected track and optionally updates the playlist queue
  Future<void> playTrack(TrackModel track, {List<TrackModel>? queue}) async {
    final token = ++_playSequenceToken;
    currentTrack.value = track;
    _hasRecordedCurrentTrackForHistory = false;

    if (queue != null && queue.isNotEmpty) {
      playlist.assignAll(queue);
      final idx = playlist.indexWhere((t) => t.trackId == track.trackId);
      currentIndex.value = idx >= 0 ? idx : 0;
    } else if (playlist.isNotEmpty) {
      final idx = playlist.indexWhere((t) => t.trackId == track.trackId);
      if (idx >= 0) {
        currentIndex.value = idx;
      }
    }

    duration.value = Duration(seconds: track.durationSeconds);
    position.value = Duration.zero;

    // Determine effective audio URL: local offline file if available, else network URL
    String audioUrlToPlay = track.audioUrl;
    if (track.localFilePath != null && io.File(track.localFilePath!).existsSync()) {
      audioUrlToPlay = track.localFilePath!;
    } else {
      final dlMatch = downloadedTracks.firstWhereOrNull((t) => t.trackId == track.trackId);
      if (dlMatch?.localFilePath != null && io.File(dlMatch!.localFilePath!).existsSync()) {
        audioUrlToPlay = dlMatch.localFilePath!;
      }
    }

    if (audioUrlToPlay.isEmpty) {
      debugPrint('[PlayerController] Cannot play track: audioUrl is empty for "${track.title}"');
      return;
    }

    debugPrint('[PlayerController] Loading track: "${track.title}" from: $audioUrlToPlay');

    try {
      await _audioHandler.playTrack(
        trackId: track.trackId,
        title: track.title,
        artist: track.artistName,
        album: track.albumName,
        audioUrl: audioUrlToPlay,
        artworkUrl: track.artworkUrl,
        duration: Duration(seconds: track.durationSeconds),
      );

      // Pre-buffer next track in advance so next skip is instantaneous
      if (token == _playSequenceToken) {
        if (isRepeat.value) {
          _audioHandler.setRepeatMode(AudioServiceRepeatMode.one);
        }
        _triggerNextTrackPrebuffering();
      }
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (!msg.contains('interrupted') && !msg.contains('abort')) {
        debugPrint('[PlayerController] Playback error: $e');
      }
    }
  }

  /// Automatically pre-buffers the next track while current track is playing
  void _triggerNextTrackPrebuffering() {
    if (playlist.length <= 1) return;

    final nextIdx = isShuffle.value && playlist.length > 1
        ? (currentIndex.value + 1 + (playlist.length ~/ 2)) % playlist.length
        : (currentIndex.value + 1) % playlist.length;

    if (nextIdx >= 0 && nextIdx < playlist.length) {
      final nextTrack = playlist[nextIdx];
      String nextAudioUrl = nextTrack.audioUrl;
      if (nextTrack.localFilePath != null && io.File(nextTrack.localFilePath!).existsSync()) {
        nextAudioUrl = nextTrack.localFilePath!;
      } else {
        final dlMatch = downloadedTracks.firstWhereOrNull((t) => t.trackId == nextTrack.trackId);
        if (dlMatch?.localFilePath != null && io.File(dlMatch!.localFilePath!).existsSync()) {
          nextAudioUrl = dlMatch.localFilePath!;
        }
      }

      if (nextAudioUrl.isNotEmpty && nextAudioUrl != currentTrack.value?.audioUrl) {
        _audioHandler.prebufferTrack(nextAudioUrl);
      }
    }
  }

  /// Toggles Play / Pause
  Future<void> togglePlayPause() async {
    try {
      if (isPlaying.value) {
        await pause();
      } else {
        await play();
      }
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (!msg.contains('interrupted') && !msg.contains('abort')) {
        debugPrint('[PlayerController] Toggle play/pause error: $e');
      }
    }
  }

  Future<void> play() async {
    try {
      await _audioHandler.play();
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (!msg.contains('interrupted') && !msg.contains('abort')) {
        debugPrint('[PlayerController] Play error: $e');
      }
    }
  }

  Future<void> pause() async {
    try {
      await _audioHandler.pause();
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (!msg.contains('interrupted') && !msg.contains('abort')) {
        debugPrint('[PlayerController] Pause error: $e');
      }
    }
  }

  Future<void> seek(Duration newPosition) async {
    try {
      await _audioHandler.seek(newPosition);
    } catch (_) {}
  }

  Future<void> seekForward10() async {
    final target = position.value + const Duration(seconds: 10);
    final max = duration.value;
    await seek(target < max ? target : max);
  }

  Future<void> seekBackward10() async {
    final target = position.value - const Duration(seconds: 10);
    await seek(target > Duration.zero ? target : Duration.zero);
  }

  /// Plays the next track in the playlist
  Future<void> playNext() async {
    if (playlist.isEmpty) return;

    try {
      if (isShuffle.value && playlist.length > 1) {
        final nextIdx = (currentIndex.value + 1 + (playlist.length ~/ 2)) % playlist.length;
        currentIndex.value = nextIdx;
      } else {
        currentIndex.value = (currentIndex.value + 1) % playlist.length;
      }

      final nextTrack = playlist[currentIndex.value];
      await playTrack(nextTrack);
      if (!_audioHandler.player.playing) {
        await _audioHandler.play();
      }
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (!msg.contains('interrupted') && !msg.contains('abort')) {
        debugPrint('[PlayerController] playNext error: $e');
      }
    }
  }

  /// Plays the previous track in the playlist
  Future<void> playPrevious() async {
    if (playlist.isEmpty) return;

    try {
      // If more than 3 seconds in, restart track
      if (position.value.inSeconds > 3) {
        await seek(Duration.zero);
        return;
      }

      currentIndex.value = (currentIndex.value - 1 + playlist.length) % playlist.length;
      final prevTrack = playlist[currentIndex.value];
      await playTrack(prevTrack);
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (!msg.contains('interrupted') && !msg.contains('abort')) {
        debugPrint('[PlayerController] playPrevious error: $e');
      }
    }
  }

  void toggleShuffle() {
    isShuffle.toggle();
  }

  void toggleRepeat() {
    isRepeat.toggle();
    try {
      _audioHandler.setRepeatMode(
        isRepeat.value ? AudioServiceRepeatMode.one : AudioServiceRepeatMode.none,
      );
    } catch (e) {
      debugPrint('[PlayerController] Error updating repeat mode: $e');
    }
  }

  String formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void onClose() {
    _playbackSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    super.onClose();
  }
}
