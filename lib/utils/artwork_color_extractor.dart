import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Extracts the dominant and vibrant color from a track's album artwork image.
/// Caches results in memory to avoid redundant processing.
class ArtworkColorExtractor {
  static final Map<String, Color> _cache = {};

  /// Synchronously gets cached color if already extracted
  static Color? getCachedColor(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    return _cache[imageUrl];
  }

  /// Extracts dominant color from an image URL, or returns a deterministic palette
  static Future<Color> extractDominantColor(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const Color(0xFF282828);
    }

    if (_cache.containsKey(imageUrl)) {
      return _cache[imageUrl]!;
    }

    try {
      final ImageProvider provider = ResizeImage(
        NetworkImage(imageUrl),
        width: 32,
        height: 32,
      );
      final Completer<ui.Image> completer = Completer<ui.Image>();
      final ImageStream stream = provider.resolve(ImageConfiguration.empty);
      late ImageStreamListener listener;
      listener = ImageStreamListener(
        (ImageInfo info, bool _) {
          completer.complete(info.image);
          stream.removeListener(listener);
        },
        onError: (dynamic error, StackTrace? _) {
          completer.completeError(error);
          stream.removeListener(listener);
        },
      );
      stream.addListener(listener);

      final ui.Image image = await completer.future.timeout(
        const Duration(milliseconds: 1500),
      );
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );

      if (byteData == null) {
        return _fallbackColor(imageUrl);
      }

      final buffer = byteData.buffer.asUint8List();
      int totalR = 0, totalG = 0, totalB = 0;
      int colorfulPixels = 0;

      // Track the most vibrant, saturated color
      int bestR = 40, bestG = 40, bestB = 40;
      double maxSaturation = -1;

      for (int i = 0; i < buffer.length; i += 4) {
        final r = buffer[i];
        final g = buffer[i + 1];
        final b = buffer[i + 2];
        final a = buffer[i + 3];

        if (a < 128) continue; // Ignore transparent pixels

        final maxC = max(r, max(g, b));
        final minC = min(r, min(g, b));
        final brightness = (r + g + b) / 3.0;

        // Skip pure blacks, pure whites, and muddy greys
        if (brightness < 25 || brightness > 235) continue;

        final saturation = maxC > 0 ? (maxC - minC) / maxC.toDouble() : 0.0;

        if (saturation > 0.15) {
          totalR += r;
          totalG += g;
          totalB += b;
          colorfulPixels++;

          if (saturation > maxSaturation &&
              brightness >= 40 &&
              brightness <= 210) {
            maxSaturation = saturation;
            bestR = r;
            bestG = g;
            bestB = b;
          }
        }
      }

      Color finalColor;
      if (maxSaturation > 0.25) {
        finalColor = Color.fromARGB(255, bestR, bestG, bestB);
      } else if (colorfulPixels > 0) {
        finalColor = Color.fromARGB(
          255,
          totalR ~/ colorfulPixels,
          totalG ~/ colorfulPixels,
          totalB ~/ colorfulPixels,
        );
      } else {
        finalColor = _fallbackColor(imageUrl);
      }

      _cache[imageUrl] = finalColor;
      return finalColor;
    } catch (_) {
      // Offline, test environment, or network error fallback (deterministic, not random)
      return _fallbackColor(imageUrl);
    }
  }

  /// Generates a deterministic, consistent color from the URL string so it is never random
  static Color _fallbackColor(String imageUrl) {
    final hash = imageUrl.hashCode.abs();
    final r = 38 + (hash % 50);
    final g = 38 + ((hash ~/ 50) % 50);
    final b = 38 + ((hash ~/ 2500) % 50);
    return Color.fromARGB(255, r, g, b);
  }
}
