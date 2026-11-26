import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/artist_category_model.dart';
import '../models/playlist_model.dart';
import '../models/track_model.dart';

abstract class ILocalDatabaseService {
  Future<List<TrackModel>> getLikedSongs();
  Future<void> saveLikedSong(TrackModel track);
  Future<void> removeLikedSong(String trackId);
  Future<bool> isSongLiked(String trackId);
  Future<void> clearAllLikedSongs();

  Future<List<ArtistCategoryModel>> getFollowedArtists();
  Future<void> saveFollowedArtist(ArtistCategoryModel artist);
  Future<void> removeFollowedArtist(String artistId);
  Future<bool> isArtistFollowed(String artistId);

  Future<List<PlaylistModel>> getCustomPlaylists();
  Future<void> saveCustomPlaylist(PlaylistModel playlist);
  Future<void> removeCustomPlaylist(String playlistId);

  Future<List<TrackModel>> getTracksForPlaylist(String playlistId);
  Future<void> addTrackToPlaylist(String playlistId, TrackModel track);
  Future<void> removeTrackFromPlaylist(String playlistId, String trackId);
  Future<bool> isTrackInPlaylist(String playlistId, String trackId);
  Future<int> getPlaylistSongCount(String playlistId);

  Future<void> recordTrackPlay(TrackModel track);
  Future<List<TrackModel>> getTopPlayedTracks({int limit = 30});
  Future<List<TrackModel>> getListeningHistory({int limit = 30});
  Future<int> getTrackPlayCount(String trackId);

  Future<List<TrackModel>> getDownloadedSongs();
  Future<void> saveDownloadedSong(TrackModel track, {String? localPath});
  Future<void> removeDownloadedSong(String trackId);
  Future<bool> isSongDownloaded(String trackId);
  Future<int> getDownloadedSongsCount();
}

/// Scalable, production-grade SQLite Database service for storing user's Liked Songs
/// and library data persistently across app restarts.
class LocalDatabaseService implements ILocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  static const String _dbName = 'whats_play_music.db';
  static const int _dbVersion = 6;
  static const String tableLikedSongs = 'liked_songs';
  static const String tableFollowedArtists = 'followed_artists';
  static const String tableCustomPlaylists = 'custom_playlists';
  static const String tablePlaylistTracks = 'playlist_tracks';
  static const String tableListeningHistory = 'listening_history';
  static const String tableDownloadedSongs = 'downloaded_songs';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final fullPath = p.join(dbPath, _dbName);

    debugPrint('[LocalDatabaseService] Initializing SQLite database at: $fullPath');

    return await openDatabase(
      fullPath,
      version: _dbVersion,
      onCreate: (db, version) async {
        debugPrint('[LocalDatabaseService] Creating $tableLikedSongs table schema...');
        await db.execute('''
          CREATE TABLE $tableLikedSongs (
            track_id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            artist_name TEXT,
            album_name TEXT,
            artwork_url TEXT,
            genre TEXT,
            duration_seconds INTEGER,
            release_date TEXT,
            audio_url TEXT NOT NULL,
            music_source TEXT,
            license_info TEXT,
            is_streamable INTEGER,
            is_downloadable INTEGER,
            created_at INTEGER NOT NULL
          )
        ''');

        // Create index on created_at for fast descending queries
        await db.execute(
          'CREATE INDEX idx_liked_songs_created_at ON $tableLikedSongs (created_at DESC)',
        );

        debugPrint('[LocalDatabaseService] Creating $tableFollowedArtists table schema...');
        await db.execute('''
          CREATE TABLE $tableFollowedArtists (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            query TEXT NOT NULL,
            category_label TEXT,
            image_url TEXT,
            created_at INTEGER NOT NULL
          )
        ''');

        debugPrint('[LocalDatabaseService] Creating $tableCustomPlaylists table schema...');
        await db.execute('''
          CREATE TABLE $tableCustomPlaylists (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            icon_key TEXT NOT NULL,
            song_count INTEGER NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');

        debugPrint('[LocalDatabaseService] Creating $tablePlaylistTracks table schema...');
        await db.execute('''
          CREATE TABLE $tablePlaylistTracks (
            playlist_id TEXT NOT NULL,
            track_id TEXT NOT NULL,
            title TEXT NOT NULL,
            artist_name TEXT,
            album_name TEXT,
            artwork_url TEXT,
            genre TEXT,
            duration_seconds INTEGER,
            release_date TEXT,
            audio_url TEXT NOT NULL,
            music_source TEXT,
            license_info TEXT,
            is_streamable INTEGER,
            is_downloadable INTEGER,
            created_at INTEGER NOT NULL,
            PRIMARY KEY (playlist_id, track_id)
          )
        ''');

        await db.execute(
          'CREATE INDEX idx_playlist_tracks ON $tablePlaylistTracks (playlist_id, created_at DESC)',
        );

        debugPrint('[LocalDatabaseService] Creating $tableListeningHistory table schema...');
        await db.execute('''
          CREATE TABLE $tableListeningHistory (
            track_id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            artist_name TEXT,
            album_name TEXT,
            artwork_url TEXT,
            genre TEXT,
            duration_seconds INTEGER,
            release_date TEXT,
            audio_url TEXT NOT NULL,
            music_source TEXT,
            license_info TEXT,
            is_streamable INTEGER,
            is_downloadable INTEGER,
            play_count INTEGER NOT NULL DEFAULT 1,
            last_played_at INTEGER NOT NULL
          )
        ''');

        await db.execute(
          'CREATE INDEX idx_listening_history_plays ON $tableListeningHistory (play_count DESC, last_played_at DESC)',
        );

        debugPrint('[LocalDatabaseService] Creating $tableDownloadedSongs table schema...');
        await db.execute('''
          CREATE TABLE $tableDownloadedSongs (
            track_id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            artist_name TEXT,
            album_name TEXT,
            artwork_url TEXT,
            genre TEXT,
            duration_seconds INTEGER,
            release_date TEXT,
            audio_url TEXT NOT NULL,
            local_file_path TEXT,
            music_source TEXT,
            license_info TEXT,
            is_streamable INTEGER,
            is_downloadable INTEGER,
            downloaded_at INTEGER NOT NULL
          )
        ''');

        await db.execute(
          'CREATE INDEX idx_downloaded_songs_date ON $tableDownloadedSongs (downloaded_at DESC)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          debugPrint('[LocalDatabaseService] Upgrading schema: creating $tableFollowedArtists...');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $tableFollowedArtists (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              query TEXT NOT NULL,
              category_label TEXT,
              image_url TEXT,
              created_at INTEGER NOT NULL
            )
          ''');
        }
        if (oldVersion < 3) {
          debugPrint('[LocalDatabaseService] Upgrading schema: creating $tableCustomPlaylists...');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $tableCustomPlaylists (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              icon_key TEXT NOT NULL,
              song_count INTEGER NOT NULL,
              created_at INTEGER NOT NULL
            )
          ''');
        }
        if (oldVersion < 4) {
          debugPrint('[LocalDatabaseService] Upgrading schema: creating $tablePlaylistTracks...');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $tablePlaylistTracks (
              playlist_id TEXT NOT NULL,
              track_id TEXT NOT NULL,
              title TEXT NOT NULL,
              artist_name TEXT,
              album_name TEXT,
              artwork_url TEXT,
              genre TEXT,
              duration_seconds INTEGER,
              release_date TEXT,
              audio_url TEXT NOT NULL,
              music_source TEXT,
              license_info TEXT,
              is_streamable INTEGER,
              is_downloadable INTEGER,
              created_at INTEGER NOT NULL,
              PRIMARY KEY (playlist_id, track_id)
            )
          ''');
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_playlist_tracks ON $tablePlaylistTracks (playlist_id, created_at DESC)',
          );
        }
        if (oldVersion < 5) {
          debugPrint('[LocalDatabaseService] Upgrading schema: creating $tableListeningHistory...');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $tableListeningHistory (
              track_id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              artist_name TEXT,
              album_name TEXT,
              artwork_url TEXT,
              genre TEXT,
              duration_seconds INTEGER,
              release_date TEXT,
              audio_url TEXT NOT NULL,
              music_source TEXT,
              license_info TEXT,
              is_streamable INTEGER,
              is_downloadable INTEGER,
              play_count INTEGER NOT NULL DEFAULT 1,
              last_played_at INTEGER NOT NULL
            )
          ''');
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_listening_history_plays ON $tableListeningHistory (play_count DESC, last_played_at DESC)',
          );
        }
        if (oldVersion < 6) {
          debugPrint('[LocalDatabaseService] Upgrading schema: creating $tableDownloadedSongs...');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $tableDownloadedSongs (
              track_id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              artist_name TEXT,
              album_name TEXT,
              artwork_url TEXT,
              genre TEXT,
              duration_seconds INTEGER,
              release_date TEXT,
              audio_url TEXT NOT NULL,
              local_file_path TEXT,
              music_source TEXT,
              license_info TEXT,
              is_streamable INTEGER,
              is_downloadable INTEGER,
              downloaded_at INTEGER NOT NULL
            )
          ''');
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_downloaded_songs_date ON $tableDownloadedSongs (downloaded_at DESC)',
          );
        }
      },
    );
  }

  @override
  Future<List<TrackModel>> getLikedSongs() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> records = await db.query(
        tableLikedSongs,
        orderBy: 'created_at DESC',
      );

      final tracks = records.map((map) => TrackModel.fromMap(map)).toList();
      debugPrint('[LocalDatabaseService] Retrieved ${tracks.length} liked songs from SQLite.');
      return tracks;
    } catch (e) {
      debugPrint('[LocalDatabaseService] Error getting liked songs: $e');
      return [];
    }
  }

  @override
  Future<void> saveLikedSong(TrackModel track) async {
    try {
      final db = await database;
      final Map<String, dynamic> row = track.toMap();
      row['created_at'] = DateTime.now().millisecondsSinceEpoch;

      await db.insert(
        tableLikedSongs,
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('[LocalDatabaseService] Successfully saved "${track.title}" (ID: ${track.trackId}) to SQLite.');
    } catch (e) {
      debugPrint('[LocalDatabaseService] Error saving liked song "${track.title}": $e');
      rethrow;
    }
  }

  @override
  Future<void> removeLikedSong(String trackId) async {
    try {
      final db = await database;
      final count = await db.delete(
        tableLikedSongs,
        where: 'track_id = ?',
        whereArgs: [trackId],
      );
      debugPrint('[LocalDatabaseService] Deleted $count liked song (ID: $trackId) from SQLite.');
    } catch (e) {
      debugPrint('[LocalDatabaseService] Error removing liked song ($trackId): $e');
      rethrow;
    }
  }

  @override
  Future<bool> isSongLiked(String trackId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> records = await db.query(
        tableLikedSongs,
        columns: ['track_id'],
        where: 'track_id = ?',
        whereArgs: [trackId],
        limit: 1,
      );
      return records.isNotEmpty;
    } catch (e) {
      debugPrint('[LocalDatabaseService] Error checking isSongLiked: $e');
      return false;
    }
  }

  @override
  Future<void> clearAllLikedSongs() async {
    try {
      final db = await database;
      await db.delete(tableLikedSongs);
      debugPrint('[LocalDatabaseService] Cleared all liked songs from SQLite.');
    } catch (e) {
      debugPrint('[LocalDatabaseService] Error clearing liked songs: $e');
    }
  }

  @override
  Future<List<ArtistCategoryModel>> getFollowedArtists() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> records = await db.query(
        tableFollowedArtists,
        orderBy: 'created_at DESC',
      );
      return records.map((map) => ArtistCategoryModel.fromMap(map)).toList();
    } catch (e) {
      debugPrint('[LocalDatabaseService] Error getting followed artists: $e');
      return [];
    }
  }

  @override
  Future<void> saveFollowedArtist(ArtistCategoryModel artist) async {
    try {
      final db = await database;
      final Map<String, dynamic> row = artist.toMap();
      row['created_at'] = DateTime.now().millisecondsSinceEpoch;

      await db.insert(
        tableFollowedArtists,
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('[LocalDatabaseService] Saved followed artist "${artist.name}" to SQLite.');
    } catch (e) {
      debugPrint('[LocalDatabaseService] Error saving followed artist: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeFollowedArtist(String artistId) async {
    try {
      final db = await database;
      await db.delete(
        tableFollowedArtists,
        where: 'id = ?',
        whereArgs: [artistId],
      );
      debugPrint('[LocalDatabaseService] Removed followed artist ($artistId) from SQLite.');
    } catch (e) {
      debugPrint('[LocalDatabaseService] Error removing followed artist: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isArtistFollowed(String artistId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> records = await db.query(
        tableFollowedArtists,
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [artistId],
        limit: 1,
      );
      return records.isNotEmpty;
    } catch (e) {
      debugPrint('[LocalDatabaseService] Error checking isArtistFollowed: $e');
      return false;
    }
  }

  @override
  Future<List<PlaylistModel>> getCustomPlaylists() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> records = await db.query(
        tableCustomPlaylists,
        orderBy: 'created_at DESC',
      );
      return records.map((map) => PlaylistModel.fromMap(map)).toList();
    } catch (e) {
      debugPrint('[LocalDatabaseService] Error getting custom playlists: $e');
      return [];
    }
  }

  @override
  Future<void> saveCustomPlaylist(PlaylistModel playlist) async {
    try {
      final db = await database;
      await db.insert(
        tableCustomPlaylists,
        playlist.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('[LocalDatabaseService] Saved custom playlist "${playlist.name}".');
    } catch (e) {
      debugPrint('[LocalDatabaseService] Error saving custom playlist: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeCustomPlaylist(String playlistId) async {
    try {
      final db = await database;
      await db.delete(
        tablePlaylistTracks,
        where: 'playlist_id = ?',
        whereArgs: [playlistId],
      );
      await db.delete(
        tableCustomPlaylists,
        where: 'id = ?',
        whereArgs: [playlistId],
      );
      debugPrint('[LocalDatabaseService] Removed custom playlist ($playlistId).');
    } catch (e) {
      debugPrint('[LocalDatabaseService] Error removing custom playlist: $e');
      rethrow;
    }
  }

  @override
  Future<List<TrackModel>> getTracksForPlaylist(String playlistId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> records = await db.query(
        tablePlaylistTracks,
        where: 'playlist_id = ?',
        whereArgs: [playlistId],
        orderBy: 'created_at DESC',
      );
      return records.map((map) => TrackModel.fromMap(map)).toList();
    } catch (e) {
      debugPrint('[LocalDatabaseService] Error getting tracks for playlist $playlistId: $e');
      return [];
    }
  }

  @override
  Future<void> addTrackToPlaylist(String playlistId, TrackModel track) async {
    try {
      final db = await database;
      final Map<String, dynamic> row = track.toMap();
      row['playlist_id'] = playlistId;
      row['created_at'] = DateTime.now().millisecondsSinceEpoch;

      await db.insert(
        tablePlaylistTracks,
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Refresh song_count on tableCustomPlaylists
      await db.execute('''
        UPDATE $tableCustomPlaylists
        SET song_count = (SELECT COUNT(*) FROM $tablePlaylistTracks WHERE playlist_id = ?)
        WHERE id = ?
      ''', [playlistId, playlistId]);

      debugPrint('[LocalDatabaseService] Added track "${track.title}" to playlist $playlistId.');
    } catch (e) {
      debugPrint('[LocalDatabaseService] Error adding track to playlist: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeTrackFromPlaylist(String playlistId, String trackId) async {
    try {
      final db = await database;
      await db.delete(
        tablePlaylistTracks,
        where: 'playlist_id = ? AND track_id = ?',
        whereArgs: [playlistId, trackId],
      );

      // Refresh song_count on tableCustomPlaylists
      await db.execute('''
        UPDATE $tableCustomPlaylists
        SET song_count = (SELECT COUNT(*) FROM $tablePlaylistTracks WHERE playlist_id = ?)
        WHERE id = ?
      ''', [playlistId, playlistId]);

      debugPrint('[LocalDatabaseService] Removed track $trackId from playlist $playlistId.');
    } catch (e) {
      debugPrint('[LocalDatabaseService] Error removing track from playlist: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isTrackInPlaylist(String playlistId, String trackId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> records = await db.query(
        tablePlaylistTracks,
        columns: ['track_id'],
        where: 'playlist_id = ? AND track_id = ?',
        whereArgs: [playlistId, trackId],
        limit: 1,
      );
      return records.isNotEmpty;
    } catch (e) {
      debugPrint('[LocalDatabaseService] Error checking isTrackInPlaylist: $e');
      return false;
    }
  }

  @override
  Future<int> getPlaylistSongCount(String playlistId) async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $tablePlaylistTracks WHERE playlist_id = ?',
        [playlistId],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      debugPrint('[LocalDatabaseService] Error getting song count: $e');
      return 0;
    }
  }

  @override
  Future<void> recordTrackPlay(TrackModel track) async {
    try {
      final db = await database;
      final now = track.lastPlayedTimestamp ?? DateTime.now().millisecondsSinceEpoch;

      final existing = await db.query(
        tableListeningHistory,
        columns: ['play_count'],
        where: 'track_id = ?',
        whereArgs: [track.trackId],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        final currentCount = (existing.first['play_count'] as int?) ?? 1;
        await db.update(
          tableListeningHistory,
          {
            'play_count': currentCount + 1,
            'last_played_at': now,
            'title': track.title,
            'artist_name': track.artistName,
            'album_name': track.albumName,
            'artwork_url': track.artworkUrl,
            'audio_url': track.audioUrl,
          },
          where: 'track_id = ?',
          whereArgs: [track.trackId],
        );
        debugPrint('[LocalDatabaseService] Incremented play_count for "${track.title}" to ${currentCount + 1}');
      } else {
        final map = <String, dynamic>{
          'track_id': track.trackId,
          'title': track.title,
          'artist_name': track.artistName,
          'album_name': track.albumName,
          'artwork_url': track.artworkUrl,
          'genre': track.genre,
          'duration_seconds': track.durationSeconds,
          'release_date': track.releaseDate?.toIso8601String(),
          'audio_url': track.audioUrl,
          'music_source': track.musicSource,
          'license_info': track.licenseInfo,
          'is_streamable': track.isStreamable ? 1 : 0,
          'is_downloadable': track.isDownloadable ? 1 : 0,
          'play_count': 1,
          'last_played_at': now,
        };
        await db.insert(
          tableListeningHistory,
          map,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        debugPrint('[LocalDatabaseService] Recorded initial play for "${track.title}"');
      }
    } catch (e) {
      debugPrint('[LocalDatabaseService] Error recording track play: $e');
    }
  }

  @override
  Future<List<TrackModel>> getTopPlayedTracks({int limit = 30}) async {
    try {
      final db = await database;
      final maps = await db.query(
        tableListeningHistory,
        orderBy: 'play_count DESC, last_played_at DESC',
        limit: limit,
      );
      return maps.map((m) => TrackModel.fromMap(m)).toList();
    } catch (e) {
      debugPrint('[LocalDatabaseService] Error fetching top played tracks: $e');
      return [];
    }
  }

  @override
  Future<List<TrackModel>> getListeningHistory({int limit = 30}) async {
    try {
      final db = await database;
      final maps = await db.query(
        tableListeningHistory,
        orderBy: 'last_played_at DESC',
        limit: limit,
      );
      return maps.map((m) => TrackModel.fromMap(m)).toList();
    } catch (e) {
      debugPrint('[LocalDatabaseService] Error fetching listening history: $e');
      return [];
    }
  }

  @override
  Future<int> getTrackPlayCount(String trackId) async {
    try {
      final db = await database;
      final maps = await db.query(
        tableListeningHistory,
        columns: ['play_count'],
        where: 'track_id = ?',
        whereArgs: [trackId],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return (maps.first['play_count'] as int?) ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('[LocalDatabaseService] Error getting track play count: $e');
      return 0;
    }
  }

  @override
  Future<List<TrackModel>> getDownloadedSongs() async {
    try {
      final db = await database;
      final maps = await db.query(
        tableDownloadedSongs,
        orderBy: 'downloaded_at DESC',
      );
      return maps.map((m) => TrackModel.fromMap(m)).toList();
    } catch (e) {
      debugPrint('[LocalDatabaseService] Error getting downloaded songs: $e');
      return [];
    }
  }

  @override
  Future<void> saveDownloadedSong(TrackModel track, {String? localPath}) async {
    try {
      final db = await database;
      final map = <String, dynamic>{
        'track_id': track.trackId,
        'title': track.title,
        'artist_name': track.artistName,
        'album_name': track.albumName,
        'artwork_url': track.artworkUrl,
        'genre': track.genre,
        'duration_seconds': track.durationSeconds,
        'release_date': track.releaseDate?.toIso8601String(),
        'audio_url': track.audioUrl,
        'local_file_path': localPath ?? track.localFilePath,
        'music_source': track.musicSource,
        'license_info': track.licenseInfo,
        'is_streamable': track.isStreamable ? 1 : 0,
        'is_downloadable': track.isDownloadable ? 1 : 0,
        'downloaded_at': DateTime.now().millisecondsSinceEpoch,
      };
      await db.insert(
        tableDownloadedSongs,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('[LocalDatabaseService] Successfully saved downloaded song to SQLite: "${track.title}"');
    } catch (e) {
      debugPrint('[LocalDatabaseService] Error saving downloaded song: $e');
    }
  }

  @override
  Future<void> removeDownloadedSong(String trackId) async {
    try {
      final db = await database;
      // Get file path before deleting record
      final records = await db.query(
        tableDownloadedSongs,
        columns: ['local_file_path'],
        where: 'track_id = ?',
        whereArgs: [trackId],
        limit: 1,
      );
      if (records.isNotEmpty) {
        final filePath = records.first['local_file_path'] as String?;
        if (filePath != null && filePath.isNotEmpty) {
          final file = io.File(filePath);
          if (await file.exists()) {
            await file.delete();
            debugPrint('[LocalDatabaseService] Deleted offline audio file at: $filePath');
          }
        }
      }

      await db.delete(
        tableDownloadedSongs,
        where: 'track_id = ?',
        whereArgs: [trackId],
      );
      debugPrint('[LocalDatabaseService] Removed downloaded song: $trackId');
    } catch (e) {
      debugPrint('[LocalDatabaseService] Error removing downloaded song: $e');
    }
  }

  @override
  Future<bool> isSongDownloaded(String trackId) async {
    try {
      final db = await database;
      final count = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM $tableDownloadedSongs WHERE track_id = ?',
          [trackId],
        ),
      );
      return (count ?? 0) > 0;
    } catch (e) {
      debugPrint('[LocalDatabaseService] Error checking isSongDownloaded: $e');
      return false;
    }
  }

  @override
  Future<int> getDownloadedSongsCount() async {
    try {
      final db = await database;
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableDownloadedSongs'),
      );
      return count ?? 0;
    } catch (e) {
      return 0;
    }
  }
}

/// In-Memory implementation of ILocalDatabaseService for testing & fallbacks
class MemoryLocalDatabaseService implements ILocalDatabaseService {
  final Map<String, Map<String, dynamic>> _storage = {};
  final Map<String, Map<String, dynamic>> _artistStorage = {};
  final Map<String, Map<String, dynamic>> _playlistStorage = {};
  final Map<String, List<Map<String, dynamic>>> _playlistTracksStorage = {};
  final Map<String, Map<String, dynamic>> _listeningHistory = {};

  @override
  Future<List<TrackModel>> getLikedSongs() async {
    final list = _storage.values.toList();
    list.sort((a, b) => (b['created_at'] as int).compareTo(a['created_at'] as int));
    return list.map((map) => TrackModel.fromMap(map)).toList();
  }

  @override
  Future<void> saveLikedSong(TrackModel track) async {
    final map = track.toMap();
    map['created_at'] = DateTime.now().millisecondsSinceEpoch;
    _storage[track.trackId] = map;
  }

  @override
  Future<void> removeLikedSong(String trackId) async {
    _storage.remove(trackId);
  }

  @override
  Future<bool> isSongLiked(String trackId) async {
    return _storage.containsKey(trackId);
  }

  @override
  Future<void> clearAllLikedSongs() async {
    _storage.clear();
  }

  @override
  Future<List<ArtistCategoryModel>> getFollowedArtists() async {
    final list = _artistStorage.values.toList();
    list.sort((a, b) => (b['created_at'] as int).compareTo(a['created_at'] as int));
    return list.map((map) => ArtistCategoryModel.fromMap(map)).toList();
  }

  @override
  Future<void> saveFollowedArtist(ArtistCategoryModel artist) async {
    final map = artist.toMap();
    map['created_at'] = DateTime.now().millisecondsSinceEpoch;
    _artistStorage[artist.id] = map;
  }

  @override
  Future<void> removeFollowedArtist(String artistId) async {
    _artistStorage.remove(artistId);
  }

  @override
  Future<bool> isArtistFollowed(String artistId) async {
    return _artistStorage.containsKey(artistId);
  }

  @override
  Future<List<PlaylistModel>> getCustomPlaylists() async {
    final list = _playlistStorage.values.toList();
    list.sort((a, b) => (b['created_at'] as int).compareTo(a['created_at'] as int));
    return list.map((map) => PlaylistModel.fromMap(map)).toList();
  }

  @override
  Future<void> saveCustomPlaylist(PlaylistModel playlist) async {
    _playlistStorage[playlist.id] = playlist.toMap();
  }

  @override
  Future<void> removeCustomPlaylist(String playlistId) async {
    _playlistStorage.remove(playlistId);
    _playlistTracksStorage.remove(playlistId);
  }

  @override
  Future<List<TrackModel>> getTracksForPlaylist(String playlistId) async {
    final list = _playlistTracksStorage[playlistId] ?? [];
    return list.map((map) => TrackModel.fromMap(map)).toList();
  }

  @override
  Future<void> addTrackToPlaylist(String playlistId, TrackModel track) async {
    final tracks = _playlistTracksStorage.putIfAbsent(playlistId, () => []);
    tracks.removeWhere((t) => t['track_id'] == track.trackId);
    final map = track.toMap();
    map['created_at'] = DateTime.now().millisecondsSinceEpoch;
    tracks.insert(0, map);

    if (_playlistStorage.containsKey(playlistId)) {
      _playlistStorage[playlistId]!['song_count'] = tracks.length;
    }
  }

  @override
  Future<void> removeTrackFromPlaylist(String playlistId, String trackId) async {
    final tracks = _playlistTracksStorage[playlistId];
    if (tracks != null) {
      tracks.removeWhere((t) => t['track_id'] == trackId);
      if (_playlistStorage.containsKey(playlistId)) {
        _playlistStorage[playlistId]!['song_count'] = tracks.length;
      }
    }
  }

  @override
  Future<bool> isTrackInPlaylist(String playlistId, String trackId) async {
    final tracks = _playlistTracksStorage[playlistId];
    if (tracks == null) return false;
    return tracks.any((t) => t['track_id'] == trackId);
  }

  @override
  Future<int> getPlaylistSongCount(String playlistId) async {
    return _playlistTracksStorage[playlistId]?.length ?? 0;
  }

  @override
  Future<void> recordTrackPlay(TrackModel track) async {
    final now = track.lastPlayedTimestamp ?? DateTime.now().millisecondsSinceEpoch;
    if (_listeningHistory.containsKey(track.trackId)) {
      final current = _listeningHistory[track.trackId]!;
      current['play_count'] = ((current['play_count'] as int?) ?? 1) + 1;
      current['last_played_at'] = now;
    } else {
      final map = track.toMap();
      map['play_count'] = 1;
      map['last_played_at'] = now;
      map['created_at'] = now;
      _listeningHistory[track.trackId] = map;
    }
  }

  @override
  Future<List<TrackModel>> getTopPlayedTracks({int limit = 30}) async {
    final list = _listeningHistory.values.toList();
    list.sort((a, b) {
      final playCmp = ((b['play_count'] as int?) ?? 0).compareTo((a['play_count'] as int?) ?? 0);
      if (playCmp != 0) return playCmp;
      return ((b['last_played_at'] as int?) ?? 0).compareTo((a['last_played_at'] as int?) ?? 0);
    });
    return list.take(limit).map((m) => TrackModel.fromMap(m)).toList();
  }

  @override
  Future<List<TrackModel>> getListeningHistory({int limit = 30}) async {
    final list = _listeningHistory.values.toList();
    list.sort((a, b) => ((b['last_played_at'] as int?) ?? 0).compareTo((a['last_played_at'] as int?) ?? 0));
    return list.take(limit).map((m) => TrackModel.fromMap(m)).toList();
  }

  @override
  Future<int> getTrackPlayCount(String trackId) async {
    return (_listeningHistory[trackId]?['play_count'] as int?) ?? 0;
  }

  final Map<String, Map<String, dynamic>> _downloadedStorage = {};

  @override
  Future<List<TrackModel>> getDownloadedSongs() async {
    final list = _downloadedStorage.values.toList();
    list.sort((a, b) =>
        ((b['downloaded_at'] as int?) ?? 0).compareTo((a['downloaded_at'] as int?) ?? 0));
    return list.map((m) => TrackModel.fromMap(m)).toList();
  }

  @override
  Future<void> saveDownloadedSong(TrackModel track, {String? localPath}) async {
    final map = track.toMap();
    map['downloaded_at'] = DateTime.now().millisecondsSinceEpoch;
    if (localPath != null) map['local_file_path'] = localPath;
    _downloadedStorage[track.trackId] = map;
  }

  @override
  Future<void> removeDownloadedSong(String trackId) async {
    _downloadedStorage.remove(trackId);
  }

  @override
  Future<bool> isSongDownloaded(String trackId) async {
    return _downloadedStorage.containsKey(trackId);
  }

  @override
  Future<int> getDownloadedSongsCount() async {
    return _downloadedStorage.length;
  }
}
