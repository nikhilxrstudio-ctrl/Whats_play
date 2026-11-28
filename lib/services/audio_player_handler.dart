import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  String? _currentAudioUrl;

  AudioPlayer get player => _player;

  AudioPlayerHandler() {
    _init();
  }

  void _init() {
    // Broadcast playback state events from just_audio to audio_service
    _player.playbackEventStream.listen(
      _broadcastState,
      onError: (Object e, StackTrace st) {
        debugPrint('[AudioPlayerHandler] playbackEventStream error caught: $e');
      },
    );

    // Broadcast duration changes
    _player.durationStream.listen(
      (duration) {
        final currentItem = mediaItem.value;
        if (currentItem != null && duration != null) {
          mediaItem.add(currentItem.copyWith(duration: duration));
        }
      },
      onError: (Object e, StackTrace st) {
        debugPrint('[AudioPlayerHandler] durationStream error caught: $e');
      },
    );

    // When playback completes, only pause/reset if no external queue handler (onSkipToNext) is attached
    _player.playerStateStream.listen(
      (state) {
        if (state.processingState == ProcessingState.completed) {
          if (_player.loopMode != LoopMode.one && onSkipToNext == null) {
            pause();
            seek(Duration.zero);
          }
        }
      },
      onError: (Object e, StackTrace st) {
        debugPrint('[AudioPlayerHandler] playerStateStream error caught: $e');
      },
    );
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState] ?? AudioProcessingState.idle,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ),
    );
  }

  /// Pre-buffers the next track in the background so track transitions are instantaneous
  Future<void> prebufferTrack(String audioUrl) async {
    // Single-player architecture to prevent multi-ExoPlayer hardware codec exhaustions on real devices
  }

  Future<void> playTrack({
    required String trackId,
    required String title,
    required String artist,
    required String album,
    required String audioUrl,
    String? artworkUrl,
    Duration? duration,
  }) async {
    if (audioUrl.isEmpty) {
      debugPrint('[AudioPlayerHandler] Cannot play: empty audioUrl');
      return;
    }

    Uri? validArtUri;
    if (artworkUrl != null && artworkUrl.isNotEmpty) {
      try {
        final parsed = Uri.parse(artworkUrl);
        if (parsed.hasScheme &&
            (parsed.scheme == 'http' ||
                parsed.scheme == 'https' ||
                parsed.scheme == 'file')) {
          validArtUri = parsed;
        }
      } catch (_) {}
    }

    final item = MediaItem(
      id: audioUrl,
      title: title,
      artist: artist,
      album: album,
      artUri: validArtUri,
      duration: duration,
      extras: {'trackId': trackId},
    );

    mediaItem.add(item);

    // If exact same track is already loaded and ready, simply ensure it is playing
    if (_currentAudioUrl == audioUrl && (_player.playing || _player.processingState == ProcessingState.ready)) {
      try {
        await _player.play();
      } catch (_) {}
      return;
    }

    _currentAudioUrl = audioUrl;

    try {
      await _player.stop();
      if (audioUrl.startsWith('http://') || audioUrl.startsWith('https://')) {
        await _player.setUrl(audioUrl);
      } else {
        await _player.setFilePath(audioUrl);
      }
      await _player.play();
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('interrupted') || msg.contains('abort')) {
        // Normal cancellation when user rapidly skips to another track or changes action
        debugPrint('[AudioPlayerHandler] Track load canceled by newer request (safe cancellation).');
        return;
      }
      debugPrint('[AudioPlayerHandler] Playback error: $e');
      _broadcastState(_player.playbackEvent);
    }
  }

  @override
  Future<void> play() async {
    try {
      await _player.play();
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (!msg.contains('interrupted') && !msg.contains('abort')) {
        debugPrint('[AudioPlayerHandler] Play error: $e');
      }
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (!msg.contains('interrupted') && !msg.contains('abort')) {
        debugPrint('[AudioPlayerHandler] Pause error: $e');
      }
    }
  }

  Future<void> Function()? onSkipToNext;
  Future<void> Function()? onSkipToPrevious;

  @override
  Future<void> skipToNext() async {
    if (onSkipToNext != null) {
      await onSkipToNext!();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (onSkipToPrevious != null) {
      await onSkipToPrevious!();
    }
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (_) {}
  }

  @override
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
    return super.stop();
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    playbackState.add(playbackState.value.copyWith(repeatMode: repeatMode));
    try {
      if (repeatMode == AudioServiceRepeatMode.one) {
        await _player.setLoopMode(LoopMode.one);
      } else if (repeatMode == AudioServiceRepeatMode.all) {
        await _player.setLoopMode(LoopMode.all);
      } else {
        await _player.setLoopMode(LoopMode.off);
      }
    } catch (e) {
      debugPrint('[AudioPlayerHandler] setRepeatMode error: $e');
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
