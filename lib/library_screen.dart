import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart'
    show readMetadata;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import 'main.dart' show Track;

const String _unknownArtist = 'Неизвестный исполнитель';

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
  return [_unknownArtist, name.isEmpty ? fileName : name];
}

// --- ЦВЕТ И ОБЛОЖКА ТРЕКА ---

/// Оттенок зависит от названия: один и тот же трек всегда одного цвета.
double hueFor(String title) {
  var hash = 0;
  for (final unit in title.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return (hash % 360).toDouble();
}

/// Обложка: картинка из файла или из интернета, а если её нет — нарисованная.
class TrackArt extends StatelessWidget {
  final Track track;
  final double size;
  final double radius;
  final bool big;
  const TrackArt({
    super.key,
    required this.track,
    required this.size,
    this.radius = 12,
    this.big = false,
  });

  Widget _generated() {
    final hue = hueFor(track.title);
    Widget blob(double d, int alpha) => Container(
          width: d,
          height: d,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withAlpha(alpha),
          ),
        );
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HSLColor.fromAHSL(1, hue, 0.65, 0.55).toColor(),
            HSLColor.fromAHSL(1, (hue + 40) % 360, 0.70, 0.28).toColor(),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (big)
            Positioned(
              top: -size * 0.15,
              right: -size * 0.1,
              child: blob(size * 0.5, 30),
            ),
          if (big)
            Positioned(
              bottom: size * 0.1,
              left: -size * 0.15,
              child: blob(size * 0.6, 20),
            ),
          Center(
            child: Icon(
              Icons.music_note_rounded,
              size: size * (big ? 0.35 : 0.5),
              color: Colors.white.withAlpha(big ? 90 : 210),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final thumb = track.thumbnail.trim();
    final Widget child;
    if (thumb.isEmpty) {
      child = _generated();
    } else if (thumb.startsWith('http')) {
      child = Image.network(
        thumb,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _generated(),
      );
    } else {
      child = Image.file(
        File(thumb),
        fit: BoxFit.cover,
        cacheWidth: big ? 1080 : 240,
        errorBuilder: (_, __, ___) => _generated(),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(width: size, height: size, child: child),
    );
  }
}

class _Tags {
  final String? title;
  final String? artist;
  final String thumbnail;
  final int durationMs;
  const _Tags(this.title, this.artist, this.thumbnail, this.durationMs);
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

  Track _make(String title, String artist, String path, String thumb, int ms) {
    return Track(
      title: title,
      artist: artist,
      thumbnail: thumb,
      streamUrl: path,
      duration: Duration(milliseconds: ms),
    );
  }

  Future<Directory> _storageDir() async {
    final existing = _root;
    if (existing != null) return existing;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/storix');
    if (!await dir.exists()) await dir.create(recursive: true);
    _root = dir;
    return dir;
  }

  /// Читает теги файла и сохраняет обложку (если она есть) в память приложения.
  Future<_Tags> _readTags(String audioPath) async {
    try {
      final meta = readMetadata(File(audioPath), getImage: true);
      var thumb = '';
      if (meta.pictures.isNotEmpty) {
        final root = await _storageDir();
        final covers = Directory('${root.path}/covers');
        if (!await covers.exists()) await covers.create(recursive: true);
        final coverFile = File('${covers.path}/${audioPath.split('/').last}.jpg');
        await coverFile.writeAsBytes(meta.pictures.first.bytes);
        thumb = coverFile.path;
      }
      final title = meta.title?.trim();
      final artist = meta.artist?.trim();
      return _Tags(
        (title == null || title.isEmpty) ? null : title,
        (artist == null || artist.isEmpty) ? null : artist,
        thumb,
        meta.duration?.inMilliseconds ?? 0,
      );
    } catch (e) {
      debugPrint('Tags read error: $e');
      return const _Tags(null, null, '', 0);
    }
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
          var thumb = (map['thumbnail'] as String?) ?? '';
          if (thumb.isNotEmpty && !await File(thumb).exists()) thumb = '';
          _tracks.add(
            _make(
              map['title'] as String,
              map['artist'] as String,
              path,
              thumb,
              (map['durationMs'] as int?) ?? 0,
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
    unawaited(_enrichCovers());
  }

  /// Для треков без обложки пробуем достать её из тегов файла.
  Future<void> _enrichCovers() async {
    var changed = false;
    for (var i = 0; i < _tracks.length; i++) {
      final t = _tracks[i];
      if (t.thumbnail.isNotEmpty) continue;
      final tags = await _readTags(t.streamUrl);
      final gainedDuration =
          t.duration == Duration.zero && tags.durationMs > 0;
      if (tags.thumbnail.isEmpty && !gainedDuration) continue;
      if (i >= _tracks.length || _tracks[i].streamUrl != t.streamUrl) continue;

      final artist = (t.artist == _unknownArtist && tags.artist != null)
          ? tags.artist!
          : t.artist;
      _tracks[i] = _make(
        t.title,
        artist,
        t.streamUrl,
        tags.thumbnail,
        tags.durationMs > 0 ? tags.durationMs : t.duration.inMilliseconds,
      );
      changed = true;
    }
    if (changed) {
      notifyListeners();
      unawaited(_save());
    }
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
                  'thumbnail': t.thumbnail,
                  'durationMs': t.duration.inMilliseconds,
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
      final tags = await _readTags(target);
      _tracks.add(
        _make(
          tags.title ?? parts[1],
          tags.artist ?? parts[0],
          target,
          tags.thumbnail,
          tags.durationMs,
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
    if (track.thumbnail.contains('/storix/covers/')) {
      unawaited(_deleteFile(track.thumbnail));
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
  List<Track> get queue => List.unmodifiable(_queue);
  int get index => _index;

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

  Future<void> playAt(int i) async {
    final play = _play;
    if (play == null || i < 0 || i >= _queue.length) return;
    await play(_queue[i]);
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
      leading: TrackArt(track: track, size: 48, radius: 10),
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
              isFav ? Icons.star_rounded : Icons.star_border_rounded,
              color: isFav ? const Color(0xFFFFD54F) : Colors.white54,
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
