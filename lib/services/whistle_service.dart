import 'package:audioplayers/audioplayers.dart';

/// Plays referee whistle sound for half-time and full-time events.
class WhistleService {
  static final AudioPlayer _player = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);

  static Future<void> playWhistle() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('music/referee_witsel.mp3'));
    } catch (_) {
      // Silently fail — whistle is non-critical UX feedback
    }
  }

  static Future<void> dispose() async {
    await _player.dispose();
  }
}