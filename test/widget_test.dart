import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:whats_play/constants/app_constants.dart';
import 'package:whats_play/controllers/artist_detail_controller.dart';
import 'package:whats_play/controllers/music_controller.dart';
import 'package:whats_play/controllers/player_controller.dart';
import 'package:whats_play/models/track_model.dart';
import 'package:whats_play/repositories/music_repository.dart';
import 'package:whats_play/routes/app_routes.dart';
import 'package:whats_play/screens/artist_detail_screen.dart';
import 'package:whats_play/screens/music_catalogue_screen.dart';
import 'package:whats_play/screens/music_player_screen.dart';
import 'package:whats_play/services/local_database_service.dart';
import 'package:whats_play/widgets/mini_player_bar.dart';
import 'package:whats_play/widgets/spotify_back_button.dart';

import 'controllers/music_controller_test.dart';
import 'controllers/player_controller_test.dart';

void main() {
  testWidgets('MusicCatalogueScreen navigates to MusicPlayerScreen on track tap', (tester) async {
    // Provide standard phone dimensions
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.0;

    final mockTracks = [
      const TrackModel(
        trackId: '101',
        title: 'Cyberpunk Odyssey',
        artistName: 'Neon Wave',
        albumName: 'Nightdrive EP',
        genre: 'Electronic',
        durationSeconds: 215,
        audioUrl: 'https://api.audius.co/v1/tracks/101/stream',
        musicSource: 'Audius',
        licenseInfo: 'Open Stream',
        isStreamable: true,
        isDownloadable: false,
      ),
    ];

    final repo = MockMusicRepository(mockTracks: mockTracks);
    final db = MemoryLocalDatabaseService();
    final musicController = MusicController(repo, databaseService: db);
    final mockHandler = MockAudioPlayerHandler();
    final playerController = PlayerController(
      mockHandler,
      databaseService: db,
    );

    Get.put<IMusicRepository>(repo);
    Get.put<MusicController>(musicController);
    Get.put<PlayerController>(playerController);
    Get.put<ArtistDetailController>(ArtistDetailController(repo));

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        builder: (context, child) {
          return GetMaterialApp(
            initialRoute: AppRoutes.catalogue,
            getPages: [
              GetPage(
                name: AppRoutes.catalogue,
                page: () => const MusicCatalogueScreen(),
              ),
              GetPage(
                name: AppRoutes.player,
                page: () => const MusicPlayerScreen(),
              ),
              GetPage(
                name: AppRoutes.artist,
                page: () => const ArtistDetailScreen(),
              ),
            ],
          );
        },
      ),
    );

    // Initial pump
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify App Title and Header
    expect(find.text(AppConstants.appTitle), findsOneWidget);

    // Verify Spotify-style Artist avatars
    expect(find.text('Featured Artists & Playlists'), findsOneWidget);
    expect(find.text('Diljit Dosanjh'), findsOneWidget);
    expect(find.text('Honey Singh'), findsOneWidget);
    expect(find.text('Gujarati Hits'), findsOneWidget);

    // Verify Track details rendered
    expect(find.text('Cyberpunk Odyssey'), findsAtLeastNWidgets(1));
    expect(find.text('Neon Wave'), findsAtLeastNWidgets(1));
    expect(find.text('Nightdrive EP'), findsOneWidget);

    // Tap the track to play and navigate to Player Screen
    await tester.tap(find.text('Nightdrive EP'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400)); // wait for navigation transition

    // Verify Player Screen is displayed with playback controls & notification status
    expect(find.text('PLAYING FROM CATALOGUE'), findsOneWidget);
    expect(find.text('Media Notification Active'), findsOneWidget);
    expect(find.byIcon(Icons.skip_previous_rounded), findsOneWidget);
    expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);

    addTearDown(() {
      Get.reset();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  testWidgets('SpotifyBackButton renders circular icon and triggers callback', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) => MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              leading: SpotifyBackButton(
                onPressed: () => tapped = true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(SpotifyBackButton), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.chevron_left), findsOneWidget);

    await tester.tap(find.byType(SpotifyBackButton));
    expect(tapped, true);
  });

  testWidgets('Tapping on a featured artist in Home navigates to ArtistDetailScreen', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.0;

    final repo = MockMusicRepository();
    final db = MemoryLocalDatabaseService();
    final musicController = MusicController(repo, databaseService: db);
    final mockHandler = MockAudioPlayerHandler();
    final playerController = PlayerController(
      mockHandler,
      databaseService: db,
    );

    Get.put<IMusicRepository>(repo);
    Get.put<MusicController>(musicController);
    Get.put<PlayerController>(playerController);
    Get.put<ArtistDetailController>(ArtistDetailController(repo));

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        builder: (context, child) {
          return GetMaterialApp(
            initialRoute: AppRoutes.catalogue,
            getPages: [
              GetPage(
                name: AppRoutes.catalogue,
                page: () => const MusicCatalogueScreen(),
              ),
              GetPage(
                name: AppRoutes.player,
                page: () => const MusicPlayerScreen(),
              ),
              GetPage(
                name: AppRoutes.artist,
                page: () => const ArtistDetailScreen(),
              ),
            ],
          );
        },
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Tap Diljit Dosanjh in the Featured grid
    expect(find.text('Diljit Dosanjh'), findsOneWidget);
    await tester.tap(find.text('Diljit Dosanjh'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400)); // wait for navigation transition

    // Verify ArtistDetailScreen is opened
    expect(find.byType(ArtistDetailScreen), findsOneWidget);
    expect(find.text('Verified Artist'), findsOneWidget);

    addTearDown(() {
      Get.reset();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  testWidgets('MiniPlayerBar renders previous/next buttons and supports swipe to change tracks', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.0;

    const track1 = TrackModel(
      trackId: '1',
      title: 'First Track',
      artistName: 'Artist 1',
      albumName: 'Album 1',
      genre: 'Pop',
      durationSeconds: 180,
      audioUrl: 'https://example.com/1.mp3',
      musicSource: 'JioSaavn',
      licenseInfo: 'Licensed',
      isStreamable: true,
      isDownloadable: false,
    );

    const track2 = TrackModel(
      trackId: '2',
      title: 'Second Track',
      artistName: 'Artist 2',
      albumName: 'Album 2',
      genre: 'Pop',
      durationSeconds: 200,
      audioUrl: 'https://example.com/2.mp3',
      musicSource: 'JioSaavn',
      licenseInfo: 'Licensed',
      isStreamable: true,
      isDownloadable: false,
    );

    final repo = MockMusicRepository(mockTracks: [track1, track2]);
    final db = MemoryLocalDatabaseService();
    final musicController = MusicController(repo, databaseService: db);
    final mockHandler = MockAudioPlayerHandler();
    final playerController = PlayerController(
      mockHandler,
      databaseService: db,
    );

    Get.put<IMusicRepository>(repo);
    Get.put<MusicController>(musicController);
    Get.put<PlayerController>(playerController);

    // Play track1 with queue [track1, track2]
    await playerController.playTrack(track1, queue: [track1, track2]);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        builder: (context, child) {
          return const GetMaterialApp(
            home: Scaffold(
              body: Center(child: Text('Test Body')),
              bottomNavigationBar: MiniPlayerBar(),
            ),
          );
        },
      ),
    );

    await tester.pump();

    // Verify MiniPlayerBar displays track1
    expect(find.text('First Track'), findsOneWidget);
    expect(find.byIcon(Icons.skip_previous_rounded), findsOneWidget);
    expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);

    // Tap next button -> changes to track2
    await tester.tap(find.byIcon(Icons.skip_next_rounded));
    await tester.pump();
    expect(playerController.currentTrack.value?.title, 'Second Track');

    // Swipe left (right-to-left drag) -> advances to next track in queue
    await tester.drag(find.text('Second Track'), const Offset(-200, 0),
        warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(playerController.currentTrack.value?.title, 'First Track');

    // Swipe right (left-to-right drag) -> moves to previous track
    await tester.drag(find.text('First Track'), const Offset(200, 0),
        warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(playerController.currentTrack.value?.title, 'Second Track');

    addTearDown(() {
      Get.reset();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  testWidgets('MusicPlayerScreen updates track title and artwork when tapping skip next', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.0;

    const track1 = TrackModel(
      trackId: '1',
      title: 'First Song',
      artistName: 'First Artist',
      albumName: 'First Album',
      genre: 'Pop',
      durationSeconds: 180,
      audioUrl: 'https://example.com/1.mp3',
      artworkUrl: 'https://example.com/art1.jpg',
      musicSource: 'JioSaavn',
      licenseInfo: 'Licensed',
      isStreamable: true,
      isDownloadable: false,
    );

    const track2 = TrackModel(
      trackId: '2',
      title: 'Second Song',
      artistName: 'Second Artist',
      albumName: 'Second Album',
      genre: 'Pop',
      durationSeconds: 200,
      audioUrl: 'https://example.com/2.mp3',
      artworkUrl: 'https://example.com/art2.jpg',
      musicSource: 'JioSaavn',
      licenseInfo: 'Licensed',
      isStreamable: true,
      isDownloadable: false,
    );

    final mockHandler = MockAudioPlayerHandler();
    final db = MemoryLocalDatabaseService();
    final playerController = PlayerController(mockHandler, databaseService: db);
    Get.put<PlayerController>(playerController);

    await playerController.playTrack(track1, queue: [track1, track2]);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        builder: (context, child) {
          return const GetMaterialApp(
            home: MusicPlayerScreen(),
          );
        },
      ),
    );

    await tester.pump();

    // Initially displays track 1 info
    expect(tester.widget<Text>(find.byKey(const Key('player_current_title'))).data, 'First Song');
    expect(tester.widget<Text>(find.byKey(const Key('player_current_artist'))).data, 'First Artist');

    // Tap Next button
    await tester.tap(find.byIcon(Icons.skip_next_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify track info updated to track 2
    expect(tester.widget<Text>(find.byKey(const Key('player_current_title'))).data, 'Second Song');
    expect(tester.widget<Text>(find.byKey(const Key('player_current_artist'))).data, 'Second Artist');

    addTearDown(() {
      Get.reset();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  testWidgets('MusicPlayerScreen swiping song artwork changes to next and previous track', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.0;

    const track1 = TrackModel(
      trackId: '10',
      title: 'Track Alpha',
      artistName: 'Artist Alpha',
      albumName: 'Album Alpha',
      genre: 'Pop',
      durationSeconds: 180,
      audioUrl: 'https://example.com/10.mp3',
      artworkUrl: 'https://example.com/art10.jpg',
      musicSource: 'JioSaavn',
      licenseInfo: 'Licensed',
      isStreamable: true,
      isDownloadable: false,
    );

    const track2 = TrackModel(
      trackId: '20',
      title: 'Track Beta',
      artistName: 'Artist Beta',
      albumName: 'Album Beta',
      genre: 'Pop',
      durationSeconds: 200,
      audioUrl: 'https://example.com/20.mp3',
      artworkUrl: 'https://example.com/art20.jpg',
      musicSource: 'JioSaavn',
      licenseInfo: 'Licensed',
      isStreamable: true,
      isDownloadable: false,
    );

    final mockHandler = MockAudioPlayerHandler();
    final db = MemoryLocalDatabaseService();
    final playerController = PlayerController(mockHandler, databaseService: db);
    Get.put<PlayerController>(playerController);

    await playerController.playTrack(track1, queue: [track1, track2]);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        builder: (context, child) {
          return const GetMaterialApp(
            home: MusicPlayerScreen(),
          );
        },
      ),
    );

    await tester.pump();

    // Verify initial Track Alpha
    expect(tester.widget<Text>(find.byKey(const Key('player_current_title'))).data, 'Track Alpha');
    expect(tester.widget<Text>(find.byKey(const Key('player_current_artist'))).data, 'Artist Alpha');

    // Swipe left on the artwork PageView to go to next song
    final pageViewFinder = find.byType(PageView);
    expect(pageViewFinder, findsOneWidget);

    await tester.fling(pageViewFinder, const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();

    // Verify now playing Track Beta
    expect(tester.widget<Text>(find.byKey(const Key('player_current_title'))).data, 'Track Beta');
    expect(tester.widget<Text>(find.byKey(const Key('player_current_artist'))).data, 'Artist Beta');

    // Swipe right on the artwork PageView to go back to Track Alpha
    await tester.fling(pageViewFinder, const Offset(400, 0), 1000);
    await tester.pumpAndSettle();

    // Verify back to Track Alpha
    expect(tester.widget<Text>(find.byKey(const Key('player_current_title'))).data, 'Track Alpha');
    expect(tester.widget<Text>(find.byKey(const Key('player_current_artist'))).data, 'Artist Alpha');

    addTearDown(() {
      Get.reset();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
