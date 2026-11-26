import 'package:flutter/cupertino.dart';

class PlaylistIconHelper {
  static const Map<String, IconData> icons = {
    'music_note': CupertinoIcons.music_note_2,
    'headphones': CupertinoIcons.headphones,
    'heart': CupertinoIcons.heart_fill,
    'flame': CupertinoIcons.flame_fill,
    'star': CupertinoIcons.star_fill,
    'bolt': CupertinoIcons.bolt_fill,
    'moon': CupertinoIcons.moon_fill,
    'guitar': CupertinoIcons.guitars,
    'car': CupertinoIcons.car_fill,
    'sparkles': CupertinoIcons.sparkles,
    'waveform': CupertinoIcons.waveform,
    'party': CupertinoIcons.gift_fill,
  };

  static const Map<String, List<Color>> gradients = {
    'music_note': [Color(0xFF1DB954), Color(0xFF0D5C2A)],
    'headphones': [Color(0xFF2E77D0), Color(0xFF143B66)],
    'heart': [Color(0xFFE91429), Color(0xFF7D000E)],
    'flame': [Color(0xFFBA5D07), Color(0xFFE13300)],
    'star': [Color(0xFFE5A00D), Color(0xFF7A4E00)],
    'bolt': [Color(0xFFAF2896), Color(0xFF503750)],
    'moon': [Color(0xFF65399E), Color(0xFF291544)],
    'guitar': [Color(0xFFB82845), Color(0xFF500F1D)],
    'car': [Color(0xFF007A60), Color(0xFF063B30)],
    'sparkles': [Color(0xFFE66B00), Color(0xFF6B3100)],
    'waveform': [Color(0xFF385587), Color(0xFF13223B)],
    'party': [Color(0xFFE8115B), Color(0xFF7A042B)],
  };

  static IconData getIcon(String key) =>
      icons[key] ?? CupertinoIcons.music_note_2;

  static List<Color> getGradient(String key) =>
      gradients[key] ?? const [Color(0xFF1DB954), Color(0xFF0D5C2A)];
}
