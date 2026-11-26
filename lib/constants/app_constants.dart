import '../models/artist_category_model.dart';

class AppConstants {
  static const String appTitle = 'WhatsPlay Music';
  static const String catalogueSubtitle = 'Legitimate Music Provider Integration';
  static const String providerName = 'JioSaavn & Audius Open Music Protocols';
  static const String licensingNotice =
      'Tracks are streamed legitimately with matching artwork and verified audio URLs.';

  // Design sizes for ScreenUtil (Mobile reference)
  static const double designWidth = 375.0;
  static const double designHeight = 812.0;

  // Pagination / fetch limits
  static const int defaultFetchLimit = 25;

  // Music Categories / Genres available for selection
  static const List<String> musicCategories = [
    'All',
    'Suggested',
    'Electronic',
    'Hip-Hop/Rap',
    'Pop',
    'Rock',
    'Alternative',
    'Ambient',
    'Bass',
    'House',
    'Techno',
    'Lo-Fi',
    'Chill',
    'Acoustic',
    'Classical',
    'Jazz',
    'R&B / Soul',
    'Trap',
  ];

  // Spotify-style featured artist & regional categories with 100% verified authentic photos
  static const List<ArtistCategoryModel> featuredArtists = [
    ArtistCategoryModel(
      id: 'diljit',
      name: 'Diljit Dosanjh',
      query: 'Diljit Dosanjh',
      categoryLabel: 'Artist',
      imageUrl:
          'https://c.saavncdn.com/artists/Diljit_Dosanjh_005_20231025073054_500x500.jpg',
    ),
    ArtistCategoryModel(
      id: 'honey_singh',
      name: 'Honey Singh',
      query: 'Honey Singh',
      categoryLabel: 'Artist',
      imageUrl:
          'https://c.saavncdn.com/artists/Yo_Yo_Honey_Singh_004_20260811095253_500x500.jpg',
    ),
    ArtistCategoryModel(
      id: 'gujarati',
      name: 'Gujarati Hits',
      query: 'Gujarati',
      categoryLabel: 'Regional',
      imageUrl:
          'https://c.saavncdn.com/editorial/Gujarati-IndiaSuperhitsTop50_20260904074620_500x500.jpg',
    ),
    ArtistCategoryModel(
      id: 'arijit',
      name: 'Arijit Singh',
      query: 'Arijit Singh',
      categoryLabel: 'Artist',
      imageUrl:
          'https://c.saavncdn.com/artists/Arijit_Singh_004_20241118063717_500x500.jpg',
    ),
    ArtistCategoryModel(
      id: 'sidhu',
      name: 'Sidhu Moose Wala',
      query: 'Sidhu Moose Wala',
      categoryLabel: 'Artist',
      imageUrl:
          'https://c.saavncdn.com/artists/Sidhu_Moose_Wala_004_20250617183705_500x500.jpg',
    ),
    ArtistCategoryModel(
      id: 'bollywood',
      name: 'Bollywood Hits',
      query: 'Bollywood',
      categoryLabel: 'Genre',
      imageUrl:
          'https://c.saavncdn.com/editorial/BollywoodLoveSongs_20231129150319_500x500.jpg',
    ),
    ArtistCategoryModel(
      id: 'punjabi',
      name: 'Punjabi Hits',
      query: 'Punjabi',
      categoryLabel: 'Regional',
      imageUrl:
          'https://c.saavncdn.com/editorial/PunjabiHitSongs_20261027063731_500x500.jpg',
    ),
    ArtistCategoryModel(
      id: 'badshah',
      name: 'Badshah Hits',
      query: 'Badshah',
      categoryLabel: 'Artist',
      imageUrl:
          'https://c.saavncdn.com/artists/Badshah_006_20241118064015_500x500.jpg',
    ),
    // ── Hit Playlists ──
    ArtistCategoryModel(
      id: 'playlist_top50_bollywood',
      name: 'Top 50 Bollywood',
      query: 'Top Bollywood hits',
      categoryLabel: 'Playlist',
      imageUrl:
          'https://c.saavncdn.com/editorial/Hindi-IndiaSuperhitsTop50_20261113063216_500x500.jpg',
    ),
    ArtistCategoryModel(
      id: 'playlist_party_mix',
      name: 'Party Mix',
      query: 'Party dance hits',
      categoryLabel: 'Playlist',
      imageUrl:
          'https://c.saavncdn.com/editorial/NonStopParty_20261113052024_500x500.jpg',
    ),
    ArtistCategoryModel(
      id: 'playlist_romantic',
      name: 'Romantic Hits',
      query: 'Romantic Hindi songs',
      categoryLabel: 'Playlist',
      imageUrl:
          'https://c.saavncdn.com/editorial/BollywoodLoveSongs_20231129150319_500x500.jpg',
    ),
    ArtistCategoryModel(
      id: 'playlist_punjabi_top',
      name: 'Punjabi Top Hits',
      query: 'Punjabi top hits',
      categoryLabel: 'Playlist',
      imageUrl:
          'https://c.saavncdn.com/editorial/PunjabiHitSongs_20261027063731_500x500.jpg',
    ),
    ArtistCategoryModel(
      id: 'playlist_chill_vibes',
      name: 'Chill Vibes',
      query: 'Chill lofi relax',
      categoryLabel: 'Playlist',
      imageUrl:
          'https://c.saavncdn.com/editorial/ChillMaaro-LoFiMix_20260403095103_500x500.jpg',
    ),
    ArtistCategoryModel(
      id: 'playlist_90s_retro',
      name: '90s Retro Hits',
      query: '90s Hindi retro',
      categoryLabel: 'Playlist',
      imageUrl:
          'https://c.saavncdn.com/editorial/BestOf90sHindi_20251125041813_500x500.jpg',
    ),
  ];
}
