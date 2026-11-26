import 'package:flutter_test/flutter_test.dart';
import 'package:whats_play/models/artist_category_model.dart';
import 'package:whats_play/models/playlist_model.dart';
import 'package:whats_play/models/track_model.dart';
import 'package:whats_play/services/local_database_service.dart';

void main() {
  group('LocalDatabaseService & MemoryLocalDatabaseService Tests', () {
    late MemoryLocalDatabaseService databaseService;

    const testTrack1 = TrackModel(
      trackId: 'track_1',
      title: 'Pragat Piranu Navkhand Neje Punjanu',
      artistName: 'Hitesh Prajapati',
      albumName: 'Ramdevpir Bhakti',
      artworkUrl: 'https://c.saavncdn.com/test1_500x500.jpg',
      genre: 'Gujarati',
      durationSeconds: 252,
      audioUrl: 'https://aac.saavncdn.com/test1_320.mp4',
      musicSource: 'JioSaavn Official Open Catalogue',
      licenseInfo: 'Official Licensed Music Stream',
      isStreamable: true,
      isDownloadable: false,
    );

    const testTrack2 = TrackModel(
      trackId: 'track_2',
      title: 'Born to Shine',
      artistName: 'Diljit Dosanjh',
      albumName: 'G.O.A.T.',
      artworkUrl: 'https://c.saavncdn.com/test2_500x500.jpg',
      genre: 'Punjabi',
      durationSeconds: 214,
      audioUrl: 'https://aac.saavncdn.com/test2_320.mp4',
      musicSource: 'JioSaavn Official Open Catalogue',
      licenseInfo: 'Official Licensed Music Stream',
      isStreamable: true,
      isDownloadable: false,
    );

    setUp(() {
      databaseService = MemoryLocalDatabaseService();
    });

    test('initial state has empty liked songs', () async {
      final songs = await databaseService.getLikedSongs();
      expect(songs, isEmpty);
    });

    test('saveLikedSong persists track correctly', () async {
      await databaseService.saveLikedSong(testTrack1);

      final songs = await databaseService.getLikedSongs();
      expect(songs.length, 1);
      expect(songs.first.trackId, 'track_1');
      expect(songs.first.title, 'Pragat Piranu Navkhand Neje Punjanu');
      expect(songs.first.artistName, 'Hitesh Prajapati');
      expect(songs.first.durationSeconds, 252);
      expect(songs.first.isStreamable, true);

      final isLiked = await databaseService.isSongLiked('track_1');
      expect(isLiked, true);
    });

    test('removeLikedSong deletes track from storage', () async {
      await databaseService.saveLikedSong(testTrack1);
      await databaseService.saveLikedSong(testTrack2);

      var songs = await databaseService.getLikedSongs();
      expect(songs.length, 2);

      await databaseService.removeLikedSong('track_1');
      songs = await databaseService.getLikedSongs();

      expect(songs.length, 1);
      expect(songs.first.trackId, 'track_2');
      expect(await databaseService.isSongLiked('track_1'), false);
      expect(await databaseService.isSongLiked('track_2'), true);
    });

    test('TrackModel toMap and fromMap serialization roundtrip', () {
      final map = testTrack1.toMap();
      final reconstructed = TrackModel.fromMap(map);

      expect(reconstructed.trackId, testTrack1.trackId);
      expect(reconstructed.title, testTrack1.title);
      expect(reconstructed.artistName, testTrack1.artistName);
      expect(reconstructed.albumName, testTrack1.albumName);
      expect(reconstructed.durationSeconds, testTrack1.durationSeconds);
      expect(reconstructed.audioUrl, testTrack1.audioUrl);
      expect(reconstructed.isStreamable, testTrack1.isStreamable);
    });

    test('saveFollowedArtist and removeFollowedArtist manage followed artists correctly', () async {
      const artist = ArtistCategoryModel(
        id: 'diljit',
        name: 'Diljit Dosanjh',
        query: 'Diljit Dosanjh',
        categoryLabel: 'Artist',
        imageUrl: 'https://example.com/diljit.jpg',
      );

      expect(await databaseService.getFollowedArtists(), isEmpty);
      expect(await databaseService.isArtistFollowed('diljit'), false);

      await databaseService.saveFollowedArtist(artist);
      final followed = await databaseService.getFollowedArtists();
      expect(followed.length, 1);
      expect(followed.first.id, 'diljit');
      expect(followed.first.name, 'Diljit Dosanjh');
      expect(await databaseService.isArtistFollowed('diljit'), true);

      await databaseService.removeFollowedArtist('diljit');
      expect(await databaseService.getFollowedArtists(), isEmpty);
      expect(await databaseService.isArtistFollowed('diljit'), false);
    });

    test('saveCustomPlaylist and removeCustomPlaylist manage custom playlists', () async {
      final playlist = PlaylistModel(
        id: 'pl_1',
        name: 'My Chill Mix',
        iconKey: 'headphones',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        songCount: 0,
      );

      expect(await databaseService.getCustomPlaylists(), isEmpty);

      await databaseService.saveCustomPlaylist(playlist);
      var playlists = await databaseService.getCustomPlaylists();
      expect(playlists.length, 1);
      expect(playlists.first.name, 'My Chill Mix');
      expect(playlists.first.iconKey, 'headphones');

      await databaseService.removeCustomPlaylist('pl_1');
      playlists = await databaseService.getCustomPlaylists();
      expect(playlists, isEmpty);
    });

    test('addTrackToPlaylist and removeTrackFromPlaylist manage playlist tracks', () async {
      final playlist = PlaylistModel(
        id: 'pl_workout',
        name: 'Workout Bangers',
        iconKey: 'flame',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        songCount: 0,
      );
      await databaseService.saveCustomPlaylist(playlist);

      expect(await databaseService.getTracksForPlaylist('pl_workout'), isEmpty);
      expect(await databaseService.isTrackInPlaylist('pl_workout', 'track_1'), false);

      await databaseService.addTrackToPlaylist('pl_workout', testTrack1);
      expect(await databaseService.isTrackInPlaylist('pl_workout', 'track_1'), true);

      var tracks = await databaseService.getTracksForPlaylist('pl_workout');
      expect(tracks.length, 1);
      expect(tracks.first.title, testTrack1.title);
      expect(await databaseService.getPlaylistSongCount('pl_workout'), 1);

      await databaseService.removeTrackFromPlaylist('pl_workout', 'track_1');
      expect(await databaseService.isTrackInPlaylist('pl_workout', 'track_1'), false);
      tracks = await databaseService.getTracksForPlaylist('pl_workout');
      expect(tracks, isEmpty);
      expect(await databaseService.getPlaylistSongCount('pl_workout'), 0);
    });

    test('toSqliteTrackMap strictly excludes transient non-schema fields', () {
      final track = testTrack1.copyWith(
        lastPlayedTimestamp: 1732600000000,
        localFilePath: '/data/user/0/com.example/test.mp3',
      );

      final map = track.toSqliteTrackMap();
      expect(map.containsKey('last_played_at'), false);
      expect(map.containsKey('local_file_path'), false);
      expect(map['track_id'], 'track_1');
      expect(map['title'], 'Pragat Piranu Navkhand Neje Punjanu');
      expect(map.length, 13);
    });

    test('saving multiple liked songs persists all songs across retrievals', () async {
      await databaseService.saveLikedSong(testTrack1);
      await databaseService.saveLikedSong(testTrack2);

      final liked = await databaseService.getLikedSongs();
      expect(liked.length, 2);
      expect(liked.map((t) => t.trackId), containsAll(['track_1', 'track_2']));
    });
  });
}
