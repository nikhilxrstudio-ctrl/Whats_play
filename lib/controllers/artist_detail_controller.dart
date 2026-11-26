import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/music_controller.dart';
import '../controllers/player_controller.dart';
import '../models/artist_category_model.dart';
import '../models/track_model.dart';
import '../repositories/music_repository.dart';

class ArtistDetailController extends GetxController {
  final IMusicRepository _repository;

  ArtistDetailController(this._repository);

  final ScrollController scrollController = ScrollController();
  final RxDouble scrollOffset = 0.0.obs;

  final Rx<ArtistCategoryModel?> artist = Rx<ArtistCategoryModel?>(null);
  final RxList<TrackModel> tracks = <TrackModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isFollowing = false.obs;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    final args = Get.arguments;
    if (args is ArtistCategoryModel) {
      artist.value = args;
      if (Get.isRegistered<MusicController>()) {
        isFollowing.value = Get.find<MusicController>().isArtistFollowed(args.id);
      }
      loadArtistTracks(args);
    }
  }

  void _onScroll() {
    if (scrollController.hasClients) {
      scrollOffset.value = scrollController.offset;
    }
  }

  @override
  void onClose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.onClose();
  }

  Future<void> loadArtistTracks(ArtistCategoryModel artistModel) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final results = await _repository.searchTracks(artistModel.query, limit: 30);
      tracks.assignAll(results);
    } catch (e) {
      errorMessage.value = 'Failed to load tracks for ${artistModel.name}.';
    } finally {
      isLoading.value = false;
    }
  }

  void toggleFollow() {
    final a = artist.value;
    if (a == null) {
      isFollowing.value = !isFollowing.value;
      return;
    }
    if (Get.isRegistered<MusicController>()) {
      Get.find<MusicController>().toggleFollowArtist(a);
      isFollowing.value = Get.find<MusicController>().isArtistFollowed(a.id);
    } else {
      isFollowing.value = !isFollowing.value;
    }
  }

  void playAll({bool shuffle = false}) {
    if (tracks.isEmpty) return;
    if (!Get.isRegistered<PlayerController>()) return;
    final playerCtrl = Get.find<PlayerController>();

    final queue = List<TrackModel>.from(tracks);
    if (shuffle) {
      queue.shuffle();
    }
    playerCtrl.playTrack(queue.first, queue: queue);
  }
}
