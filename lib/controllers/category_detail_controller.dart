import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/music_controller.dart';
import '../controllers/player_controller.dart';
import '../models/track_model.dart';
import '../repositories/music_repository.dart';

class CategoryDetailArgs {
  final String title;
  final String query;
  final Color color;
  final String imageUrl;
  final List<TrackModel>? initialTracks;

  const CategoryDetailArgs({
    required this.title,
    required this.query,
    required this.color,
    required this.imageUrl,
    this.initialTracks,
  });
}

class CategoryDetailController extends GetxController {
  final IMusicRepository _repository;

  CategoryDetailController(this._repository);

  final ScrollController scrollController = ScrollController();
  final RxDouble scrollOffset = 0.0.obs;

  final RxString title = 'Category'.obs;
  final RxString query = ''.obs;
  final Rx<Color> color = const Color(0xFF1DB954).obs;
  final RxString imageUrl = ''.obs;

  final RxList<TrackModel> tracks = <TrackModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    _parseArguments();
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

  void _parseArguments() {
    final dynamic args = Get.arguments;
    if (args is CategoryDetailArgs) {
      title.value = args.title;
      query.value = args.query;
      color.value = args.color;
      imageUrl.value = args.imageUrl;
      if (args.initialTracks != null && args.initialTracks!.isNotEmpty) {
        tracks.assignAll(args.initialTracks!);
        isLoading.value = false;
      }
    } else if (args is Map) {
      title.value = (args['title'] ?? 'Category').toString();
      query.value = (args['query'] ?? title.value).toString();
      if (args['color'] is Color) {
        color.value = args['color'] as Color;
      }
      imageUrl.value = (args['imageUrl'] ?? '').toString();
      if (args['tracks'] is List<TrackModel>) {
        tracks.assignAll(args['tracks'] as List<TrackModel>);
        isLoading.value = false;
      }
    }

    // Check if MusicController already has cached tracks for this category/query
    if (tracks.isEmpty && Get.isRegistered<MusicController>()) {
      final musicCtrl = Get.find<MusicController>();
      final cached = musicCtrl.getCachedTracksForCategory(query.value);
      if (cached != null && cached.isNotEmpty) {
        tracks.assignAll(cached);
        isLoading.value = false;
      }
    }

    // Fetch fresh tracks from repository
    loadCategoryTracks(query.value);
  }

  Future<void> loadCategoryTracks(String genreQuery) async {
    if (genreQuery.isEmpty) return;

    if (tracks.isEmpty) {
      isLoading.value = true;
    }
    errorMessage.value = '';

    try {
      List<TrackModel> results = await _repository.getTracks(
        genre: genreQuery,
        limit: 30,
      );
      if (results.isEmpty) {
        results = await _repository.searchTracks(genreQuery, limit: 30);
      }
      if (results.isNotEmpty) {
        tracks.assignAll(results);
      } else if (tracks.isEmpty) {
        errorMessage.value = 'No songs found for ${title.value}.';
      }
    } catch (e) {
      if (tracks.isEmpty) {
        errorMessage.value = 'Failed to load tracks for ${title.value}.';
      }
    } finally {
      isLoading.value = false;
    }
  }

  void playAll({bool shuffle = false}) {
    if (tracks.isEmpty) return;
    if (!Get.isRegistered<PlayerController>()) return;
    final playerCtrl = Get.find<PlayerController>();

    final queue = List<TrackModel>.from(tracks);
    if (shuffle) {
      playerCtrl.isShuffle.value = true;
      queue.shuffle();
    } else {
      playerCtrl.isShuffle.value = false;
    }
    playerCtrl.playTrack(queue.first, queue: queue);
  }
}
