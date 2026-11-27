import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';
import 'package:get/get.dart';
import '../models/blend_model.dart';
import '../routes/app_routes.dart';
import 'blend_service.dart';

class DeepLinkService extends GetxService {
  static DeepLinkService get to => Get.find<DeepLinkService>();

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _sub;

  @override
  void onInit() {
    super.onInit();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Check if app was launched via deep link
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleUri(initialUri);
      }
    } catch (e) {
      debugPrint('[DeepLinkService] Error reading initial link: $e');
    }

    // Listen for incoming deep links while app is running / in foreground
    _sub = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleUri(uri);
      },
      onError: (err) {
        debugPrint('[DeepLinkService] Error in link stream: $err');
      },
    );
  }

  void _handleUri(Uri uri) {
    debugPrint('[DeepLinkService] Deep link received: $uri');
    // formats supported:
    // whatsplay://blend?code=XXXXXX
    // https://nikhilxrstudio-ctrl.github.io/Whats_play/blend.html?code=XXXXXX
    // https://nikhilxrstudio-ctrl.github.io/Whats_play/blend?code=XXXXXX
    final code = uri.queryParameters['code']?.trim().toUpperCase();
    if (code != null && code.length == 6) {
      _joinBlendFromCode(code);
    }
  }

  Future<void> _joinBlendFromCode(String code) async {
    // Slight pause to ensure GetX router is mounted
    await Future.delayed(const Duration(milliseconds: 600));

    final blendService = Get.isRegistered<BlendService>()
        ? BlendService.to
        : Get.put(BlendService());

    final result = await blendService.joinBlendWithCode(code);
    if (result['success'] == true) {
      final blend = result['blend'] as BlendModel?;
      if (blend != null) {
        Get.toNamed(AppRoutes.blendDetail, arguments: blend);
      }
    } else {
      Get.snackbar(
        'Could Not Join Blend',
        result['message']?.toString() ?? 'Invalid or expired code.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
