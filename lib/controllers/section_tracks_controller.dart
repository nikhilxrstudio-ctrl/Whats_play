import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/music_controller.dart';
import '../controllers/player_controller.dart';
import '../models/track_model.dart';

class SectionTracksArgs {
  final String title;
  final String? subtitle;
  final List<TrackModel>? tracks;
  final String? sectionType; // e.g. 'suggested', 'category', 'genre', 'custom', 'trending'
  final bool showRank;
  final String? imageUrl;

  const SectionTracksArgs({
    required this.title,
    this.subtitle,
    this.tracks,
    this.sectionType,
    this.showRank = false,
    this.imageUrl,
  });
}

class SectionTracksController extends GetxController {
  final RxString title = 'Section'.obs;
  final RxString subtitle = ''.obs;
  final RxString sectionType = ''.obs;
  final RxBool showRank = false.obs;
  final RxString imageUrl = ''.obs;
  final RxList<TrackModel> tracks = <TrackModel>[].obs;
  final RxString searchQuery = ''.obs;
  final RxBool isSearchActive = false.obs;
  final TextEditingController searchTextController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  final ScrollController scrollController = ScrollController();
  final RxDouble scrollOffset = 0.0.obs;

  String get resolvedImageUrl {
    if (imageUrl.value.isNotEmpty) return imageUrl.value;
    if (tracks.isNotEmpty && (tracks.first.artworkUrl ?? '').isNotEmpty) {
      return tracks.first.artworkUrl!;
    }
    // Contextual fallback based on title / type
    final lower = title.value.toLowerCase();
    if (lower.contains('romantic') || lower.contains('love')) {
      return 'https://c.saavncdn.com/editorial/BollywoodLoveSongs_20231129150319_500x500.jpg';
    }
    if (lower.contains('party') || lower.contains('dance')) {
      return 'https://c.saavncdn.com/editorial/NonStopParty_20261113052024_500x500.jpg';
    }
    if (lower.contains('punjabi')) {
      return 'https://c.saavncdn.com/editorial/PunjabiHitSongs_20261027063731_500x500.jpg';
    }
    return 'https://c.saavncdn.com/editorial/Hindi-IndiaSuperhitsTop50_20261113063216_500x500.jpg';
  }

  List<TrackModel> get filteredTracks {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return tracks;
    return tracks.where((t) {
      return t.title.toLowerCase().contains(query) ||
          t.artistName.toLowerCase().contains(query) ||
          t.albumName.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(() {
      scrollOffset.value = scrollController.offset;
    });
    _parseArguments();
  }

  void _parseArguments() {
    final dynamic args = Get.arguments;
    if (args is SectionTracksArgs) {
      title.value = args.title;
      subtitle.value = args.subtitle ?? '';
      sectionType.value = args.sectionType ?? '';
      showRank.value = args.showRank || (args.sectionType == 'trending');
      if (args.imageUrl != null && args.imageUrl!.isNotEmpty) {
        imageUrl.value = args.imageUrl!;
      }
      if (args.tracks != null) {
        tracks.assignAll(args.tracks!);
      }
    } else if (args is Map) {
      title.value = (args['title'] ?? 'Section').toString();
      subtitle.value = (args['subtitle'] ?? '').toString();
      sectionType.value = (args['sectionType'] ?? '').toString();
      showRank.value = args['showRank'] == true || sectionType.value == 'trending';
      if (args['imageUrl'] != null) {
        imageUrl.value = args['imageUrl'].toString();
      }
      if (args['tracks'] is List<TrackModel>) {
        tracks.assignAll(args['tracks'] as List<TrackModel>);
      }
    }

    // If sectionType is 'suggested', keep reactively synced with MusicController
    if (sectionType.value == 'suggested' && Get.isRegistered<MusicController>()) {
      final musicCtrl = Get.find<MusicController>();
      if (tracks.isEmpty) {
        tracks.assignAll(musicCtrl.suggestedTracks);
      }
      if (subtitle.isEmpty) {
        subtitle.value = musicCtrl.suggestionSubtitle.value;
      }
      ever(musicCtrl.suggestedTracks, (List<TrackModel> updated) {
        tracks.assignAll(updated);
      });
      ever(musicCtrl.suggestionSubtitle, (String updatedSub) {
        subtitle.value = updatedSub;
      });
    }
  }

  void toggleSearch() {
    isSearchActive.toggle();
    if (isSearchActive.value) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!searchFocusNode.hasFocus) {
          searchFocusNode.requestFocus();
        }
      });
    } else {
      searchFocusNode.unfocus();
      clearSearch();
    }
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
  }

  void clearSearch() {
    searchTextController.clear();
    searchQuery.value = '';
  }

  void playAll({bool shuffle = false}) {
    final list = filteredTracks;
    if (list.isEmpty) return;

    if (Get.isRegistered<PlayerController>()) {
      final playerCtrl = Get.find<PlayerController>();
      if (shuffle) {
        playerCtrl.isShuffle.value = true;
        final shuffled = List<TrackModel>.from(list)..shuffle();
        playerCtrl.playTrack(shuffled.first, queue: shuffled);
      } else {
        playerCtrl.playTrack(list.first, queue: list);
      }
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    searchFocusNode.dispose();
    searchTextController.dispose();
    super.onClose();
  }
}
