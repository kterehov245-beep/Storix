import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import 'main.dart' show Track;

/// "Исполнитель - Название_12345678.mp3" -> ["Исполнитель", "Название"]
List<String> _splitName(String fileName) {
  var name = fileName;
  final dot = name.lastIndexOf('.');
  if (dot > 0) name = name.substring(0, dot);
  name = name.replaceAll('_', ' ');
  name = name.replaceAll(RegExp(r'\s*\d{6,}$'), ''); // хвост из цифр (id с сайта)
  name = name.replaceAll(RegExp(r'\s+'), ' ').trim();

  final sep = name.indexOf(' - ');
  if (sep > 0 && sep + 3 < name.length) {
    return [name.substring(0, sep).trim(), name.substring(sep + 3).trim()];
  }
  return ['Неизвестный исполнитель', name.isEmpty ? fileName : name];
}

/// Хранилище: библиотека, избранное и история.
/// Всё сохраняется в файл, поэтому не пропадает после перезапуска.
class LibraryStore extends ChangeNotifier {
  LibraryStore._() {
    unawaited(_load());
  }
  static final LibraryStore instance = LibraryStore._();

  final List<Track> _tracks = [];
  final Set<String> _favorites = {};
  final List<String> _history = [];
  Directory? _root;

  /// false, пока список читается с диска.
  bool loaded = false;

  List<Track> get tracks => List.unmodifiable(_tracks);

  List<Track> get favoriteTracks =>
      _tracks.where((t) => _favorites.contains(t.streamUrl)).toList();

  /// Недавно проигранные, самые свежие первыми.
  List<Track> get recentTracks {
    final result = <Track>[];
    for (final path in _history) {
      final i = _tracks.indexWhere((t) => t.streamUrl == path);
      if (i >= 0) result.add(_tracks[i]);
    }
    return result;
  }

  bool isFavorite(Track track) => _favorites.contains(track.streamUrl);

  Future<Directory> _storageDir() async {
    final existing = _root;
    if (existing != null) return existing;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/storix');
    if (!await dir.exists()) await dir.create(recursive: true);
    _root = dir;
    return dir;
  }

  Future<void> _load() async {
    try {
      final dir = await _storageDir();
      final file = File('${dir.path}/library.json');
      if (await file.exists()) {
        final data =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;

        final items = (data['tracks'] as List<dynamic>?) ?? [];
        for (final item in items) {
          final map = item as Map<String, dynamic>;
          final path = map['path'] as String;
          if (!await File(path).exists()) continue; // файл пропал — пропускаем
          _tracks.add(
            Track(
              title: map['title'] as String,
              artist: map['artist'] as String,
              thumbnail: '',
              streamUrl: path,
              duration: Duration.zero,
            ),
          );
        }

        _favorites.addAll(
          ((data['favorites'] as List<dynamic>?) ?? []).cast<String>(),
        );
        _history.addAll(
          ((data['history'] as List<dynamic>?) ?? []).cast<String>(),
        );
        _favorites.removeWhere((p) => !_tracks.any((t) => t.streamUrl == p));
        _history.removeWhere((p) => !_tracks.any((t) => t.streamUrl == p));
      }
    } catch (e) {
      debugPrint('Library load error: $e');
    }
    loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final dir = await _storageDir();
      final data = <String, dynamic>{
        'tracks': _tracks
            .map((t) => {
                  'title': t.title,
                  'artist': t.artist,
                  'path': t.streamUrl,
                })
            .toList(),
        'favorites': _favorites.toList(),
        'history': _history,
      };
      await File('${dir.path}/library.json').writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('Library save error: $e');
    }
  }

  /// Копирует выбранные файлы в память приложения и добавляет в библиотеку.
  /// Возвращает, сколько новых треков добавлено.
  Future<int> addFiles(List<PlatformFile> files) async {
    final root = await _storageDir();
    final musicDir = Directory('${root.path}/music');
    if (!await musicDir.exists()) await musicDir.create(recursive: true);

    var added = 0;
    for (final file in files) {
      final source = file.path;
      if (source == null) continue;

      final target = '${musicDir.path}/${file.size}_${file.name}';
      if (_tracks.any((t) => t.streamUrl == target)) continue; // уже есть

      try {
        await File(source).copy(target);
      } catch (e) {
        debugPrint('Copy error: $e');
        continue;
      }

      final parts = _splitName(file.name);
      _tracks.add(
        Track(
          title: parts[1],
          artist: parts[0],
          thumbnail: '',
          streamUrl: target,
          duration: Duration.zero,
        ),
      );
      added++;
    }

    // Убираем временные копии, которые создал выбор файлов.
    try {
      await FilePicker.platform.clearTemporaryFiles();
    } catch (_) {}

    if (added > 0) {
      notifyListeners();
      unawaited(_save());
    }
    return added;
  }

  Future<void> _deleteFile(String path) async {
    try {
      await File(path).delete();
    } catch (_) {}
  }

  void removeTrack(Track track) {
    _tracks.removeWhere((t) => t.streamUrl == track.streamUrl);
    _favorites.remove(track.streamUrl);
    _history.remove(track.streamUrl);
    if (track.streamUrl.contains('/storix/music/')) {
      unawaited(_deleteFile(track.streamUrl));
    }
    notifyListeners();
    unawaited(_save());
  }

  void toggleFavorite(Track track) {
    if (!_favorites.remove(track.streamUrl)) {
      _favorites.add(track.streamUrl);
    }
    notifyListeners();
    unawaited(_save());
  }

  void recordPlayed(Track track) {
    if (!_tracks.any((t) => t.streamUrl == track.streamUrl)) return;
    _history.remove(track.streamUrl);
    _history.insert(0, track.streamUrl);
    if (_history.length > 30) _history.removeRange(30, _history.length);
    notifyListeners();
    unawaited(_save());
  }
}

/// Очередь и текущий трек. Отсюда работают «предыдущий» и «следующий».
class PlaybackController extends ChangeNotifier {
  PlaybackController._();
  static final PlaybackController instance = PlaybackController._();

  Track? current;
  List<Track> _queue = [];
  int _index = -1;
  AudioPlayer? _player;
  StreamSubscription<PlayerState>? _sub;
  Future<void> Function(Track)? _play;
  bool _advancing = false;

  bool get hasNext => _index >= 0 && _index < _queue.length - 1;
  bool get hasPrevious => _index > 0;

  /// Вызывается из библиотеки перед запуском трека: что играть дальше.
  void setQueue(List<Track> tracks) {
    _queue = List.of(tracks);
  }

  /// Вызывается из главного экрана каждый раз, когда начинает играть трек.
  void onTrackStarted(
    Track track,
    AudioPlayer player,
    Future<void> Function(Track) play,
  ) {
    _play = play;
    _advancing = false;
    current = track;

    var i = _queue.indexWhere((t) => t.streamUrl == track.streamUrl);
    if (i < 0) {
      _queue = [track]; // трек не из библиотеки (например, из поиска)
      i = 0;
    }
    _index = i;

    if (!identical(_player, player)) {
      _sub?.cancel();
      _player = player;
      _sub = player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _onCompleted();
        }
      });
    }

    LibraryStore.instance.recordPlayed(track);
    notifyListeners();
  }

  void _onCompleted() {
    if (_advancing) return;
    _advancing = true;
    if (hasNext) next();
  }

  Future<void> next() async {
    final play = _play;
    if (!hasNext || play == null) return;
    await play(_queue[_index + 1]);
  }

  Future<void> previous() async {
    final player = _player;
    if (player == null) return;
    final play = _play;
    if (player.position > const Duration(seconds: 3) ||
        !hasPrevious ||
        play == null) {
      await player.seek(Duration.zero);
      return;
    }
    await play(_queue[_index - 1]);
  }
}

// --- БИБЛИОТЕКА: ЛОКАЛЬНАЯ МУЗЫКА ---
class LocalLibraryScreen extends StatelessWidget {
  final Function(Track) onPlay;
  const LocalLibraryScreen({super.key, required this.onPlay});

  Future<void> _pickFiles(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );
      if (result == null) return; // окно выбора закрыли без выбора

      final added = await LibraryStore.instance.addFiles(result.files);
      if (added == 0 && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Эти треки уже в библиотеке')),
        );
      }
    } catch (e) {
      debugPrint('Library pick error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось добавить музыку: $e')),
        );
      }
    }
  }

  Widget _buildTile(Track track, List<Track> all) {
    final isFav = LibraryStore.instance.isFavorite(track);
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.music_note_rounded, color: Colors.white54),
      ),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        track.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white54),
      ),
      onTap: () {
        PlaybackController.instance.setQueue(all);
        onPlay(track);
      },
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFav ? Colors.pinkAccent : Colors.white54,
            ),
            onPressed: () => LibraryStore.instance.toggleFavorite(track),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white38),
            onPressed: () => LibraryStore.instance.removeTrack(track),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: LibraryStore.instance,
        builder: (context, _) {
          final store = LibraryStore.instance;
          final tracks = store.tracks;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Библиотека',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => _pickFiles(context),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Добавить'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: !store.loaded
                    ? const Center(child: CircularProgressIndicator())
                    : tracks.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 120),
                              child: Text(
                                'Здесь пока пусто.\nНажми «Добавить» и выбери музыку на телефоне.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white54),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 180),
                            itemCount: tracks.length,
                            itemBuilder: (context, index) =>
                                _buildTile(tracks[index], tracks),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}
