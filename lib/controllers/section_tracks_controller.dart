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

  const SectionTracksArgs({
    required this.title,
    this.subtitle,
    this.tracks,
    this.sectionType,
    this.showRank = false,
  });
}

class SectionTracksController extends GetxController {
  final RxString title = 'Section'.obs;
  final RxString subtitle = ''.obs;
  final RxString sectionType = ''.obs;
  final RxBool showRank = false.obs;
  final RxList<TrackModel> tracks = <TrackModel>[].obs;
  final RxString searchQuery = ''.obs;
  final RxBool isSearchActive = false.obs;
  final TextEditingController searchTextController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

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
    _parseArguments();
  }

  void _parseArguments() {
    final dynamic args = Get.arguments;
    if (args is SectionTracksArgs) {
      title.value = args.title;
      subtitle.value = args.subtitle ?? '';
      sectionType.value = args.sectionType ?? '';
      showRank.value = args.showRank || (args.sectionType == 'trending');
      if (args.tracks != null) {
        tracks.assignAll(args.tracks!);
      }
    } else if (args is Map) {
      title.value = (args['title'] ?? 'Section').toString();
      subtitle.value = (args['subtitle'] ?? '').toString();
      sectionType.value = (args['sectionType'] ?? '').toString();
      showRank.value = args['showRank'] == true || sectionType.value == 'trending';
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
    searchFocusNode.dispose();
    searchTextController.dispose();
    super.onClose();
  }
}
