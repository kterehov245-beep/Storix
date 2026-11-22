import 'dart:async';
import 'package:just_audio/just_audio.dart';

class StorixAudioEngine {
  final AudioPlayer player = AudioPlayer();

  bool _disposed = false;

  Future<void> playUrl(String url) async {
    if (_disposed) {
      throw StateError('Audio engine is disposed');
    }

    final uri = Uri.tryParse(url.trim());

    if (uri == null ||
        !uri.hasScheme ||
        !['https', 'http'].contains(uri.scheme)) {
      throw ArgumentError('Некорректная ссылка на аудио');
    }

    await player.setUrl(uri.toString());

    if (_disposed) return;

    unawaited(player.play());
  }

  Future<void> playFile(String path) async {
    if (_disposed) {
      throw StateError('Audio engine is disposed');
    }

    if (path.trim().isEmpty) {
      throw ArgumentError('Путь к файлу пуст');
    }

    await player.setFilePath(path);

    if (_disposed) return;

    unawaited(player.play());
  }

  Future<void> pause() => player.pause();

  Future<void> resume() => player.play();

  Future<void> seek(Duration position) {
    return player.seek(position);
  }

  Future<void> stop() => player.stop();

  Future<void> setVolume(double volume) {
    return player.setVolume(volume.clamp(0.0, 1.0));
  }

  Future<void> dispose() async {
    if (_disposed) return;

    _disposed = true;
    await player.dispose();
  }
}
