import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'main.dart' show Track;

/// Общее хранилище треков для всех разделов.
/// Пока живёт только в памяти: после перезапуска приложения список пустой.
class LibraryStore extends ChangeNotifier {
  LibraryStore._();
  static final LibraryStore instance = LibraryStore._();

  final List<Track> _tracks = [];
  final Set<String> _favorites = {}; // ключ — путь к файлу

  List<Track> get tracks => List.unmodifiable(_tracks);

  List<Track> get favoriteTracks =>
      _tracks.where((t) => _favorites.contains(t.streamUrl)).toList();

  bool isFavorite(Track track) => _favorites.contains(track.streamUrl);

  void addTracks(List<Track> newTracks) {
    for (final track in newTracks) {
      final exists = _tracks.any((t) => t.streamUrl == track.streamUrl);
      if (!exists) _tracks.add(track);
    }
    notifyListeners();
  }

  void removeTrack(Track track) {
    _tracks.removeWhere((t) => t.streamUrl == track.streamUrl);
    _favorites.remove(track.streamUrl);
    notifyListeners();
  }

  void toggleFavorite(Track track) {
    if (!_favorites.remove(track.streamUrl)) {
      _favorites.add(track.streamUrl);
    }
    notifyListeners();
  }
}

// --- БИБЛИОТЕКА: ЛОКАЛЬНАЯ МУЗЫКА ---
class LocalLibraryScreen extends StatelessWidget {
  final Function(Track) onPlay;
  const LocalLibraryScreen({super.key, required this.onPlay});

  String _titleFromFileName(String name) {
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  Future<void> _pickFiles(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );
      if (result == null) return; // окно выбора закрыли без выбора

      final tracks = <Track>[];
      for (final file in result.files) {
        final path = file.path;
        if (path == null) continue;
        tracks.add(
          Track(
            title: _titleFromFileName(file.name),
            artist: 'Локальный файл',
            thumbnail: '',
            streamUrl: path,
            duration: Duration.zero,
          ),
        );
      }
      LibraryStore.instance.addTracks(tracks);
    } catch (e) {
      debugPrint('Library pick error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось добавить музыку: $e')),
        );
      }
    }
  }

  Widget _buildTile(Track track) {
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
        style: const TextStyle(color: Colors.white54),
      ),
      onTap: () => onPlay(track),
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
          final tracks = LibraryStore.instance.tracks;
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
                child: tracks.isEmpty
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
                            _buildTile(tracks[index]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
