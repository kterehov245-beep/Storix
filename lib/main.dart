import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:soundcloud_explode_dart/soundcloud_explode_dart.dart';
import 'package:glass_liquid_navbar/glass_liquid_navbar.dart'; // Импорт навигации
import 'services/storix_audio_engine.dart';
import 'library_screen.dart';
import 'player_screen.dart';
void main() {
  runApp(const MyMusicApp());
}

class MyMusicApp extends StatelessWidget {
  const MyMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Storix',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0C1B),
      ),
      home: const MainScreen(),
    );
  }
}

// --- МОДЕЛИ ---
class Track {
  final String title;
  final String artist;
  final String thumbnail;
  final String streamUrl;
  final Duration duration;

  Track({
    required this.title,
    required this.artist,
    required this.thumbnail,
    required this.streamUrl,
    required this.duration,
  });
}

// --- ГЛАВНЫЙ ЭКРАН ---
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final StorixAudioEngine _audio = StorixAudioEngine();

AudioPlayer get _player => _audio.player;
  final SoundcloudClient _scClient = SoundcloudClient();
  
  int _currentIndex = 0;
  late PageController _pageController;
  
  Track? _currentTrack;
  bool _isLoadingTrack = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _audio.dispose();
    super.dispose();
  }

  Future<void> _playTrack(Track track) async {
      PlaybackController.instance.onTrackStarted(track, _player, _playTrack);
  setState(() {
    _currentTrack = track;
    _isLoadingTrack = true;
  });

  try {
    if (track.streamUrl.trim().isEmpty) {
      throw Exception(
        'Для этого трека нет доступного аудиопотока'
      );
    }

    if (track.streamUrl.startsWith('http')) {
  await _audio.playUrl(track.streamUrl);
} else {
  await _player.setFilePath(track.streamUrl);
  _player.play();
    }

  } catch (e) {
    debugPrint('Storix playback error: $e');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка воспроизведения: $e'),
          backgroundColor: Colors.deepPurple,
        ),
      );
    }

  } finally {
    if (mounted) {
      setState(() {
        _isLoadingTrack = false;
      });
    }
  }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // ВАЖНО для работы Liquid Glass навигации
      body: Stack(
        children: [
          const AppBackground(),
          
          Positioned.fill(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              children: [
                HomeScreen(onPlay: _playTrack),
                const BrowseScreen(),
                LocalLibraryScreen(onPlay: _playTrack),
                const FavoritesScreen(),
                SearchScreen(onPlay: _playTrack, scClient: _scClient),
              ],
            ),
          ),
          
          // Мини-плеер
          if (_currentTrack != null)
            Positioned(
              left: 16, right: 16,
              bottom: 90 + MediaQuery.of(context).padding.bottom,
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NowPlayingScreen(track: _currentTrack!, player: _player))),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child: Container(
                      height: 65,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(_currentTrack!.thumbnail, width: 45, height: 45, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(width: 45, height: 45, color: Colors.deepPurple)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_currentTrack!.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text(_currentTrack!.artist, style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          if (_isLoadingTrack)
                            const SizedBox(width: 30, height: 30, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          else
                            StreamBuilder<PlayerState>(
                              stream: _player.playerStateStream,
                              builder: (context, snapshot) {
                                final playing = snapshot.data?.playing ?? false;
                                return IconButton(
                                  icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 35, color: Colors.white),
                                  onPressed: () => playing ? _player.pause() : _player.play(),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      
      // НОВАЯ LIQUID GLASS НАВИГАЦИЯ
      bottomNavigationBar: LiquidGlassNavbar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          _pageController.jumpToPage(index); // jumpToPage для мгновенного переключения
        },
        items: const [
          LiquidNavItem(icon: Icons.home_rounded, label: 'Главная'),
          LiquidNavItem(icon: Icons.grid_view_rounded, label: 'Обзор'),
          LiquidNavItem(icon: Icons.folder_rounded, label: 'Библиотека'),
          LiquidNavItem(icon: Icons.star_rounded, label: 'Избранное'),
          LiquidNavItem(icon: Icons.search_rounded, label: 'Поиск'),
        ],
      ),
    );
  }
}

// --- ФОН ---
class AppBackground extends StatelessWidget {
  const AppBackground({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F0C1B),
      child: Stack(
        children: [
          Positioned(top: -100, left: -100, child: Container(width: 400, height: 400, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Colors.deepPurpleAccent.withOpacity(0.35), Colors.transparent])))),
          Positioned(bottom: 50, right: -100, child: Container(width: 400, height: 400, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Colors.blueAccent.withOpacity(0.25), Colors.transparent])))),
        ],
      ),
    );
  }
}

// --- НАПОЛНЕННЫЕ РАЗДЕЛЫ ---
class HomeScreen extends StatelessWidget {
  final Function(Track) onPlay;
  const HomeScreen({super.key, required this.onPlay});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 180),
        children: [
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              children: [
                Icon(Icons.waves_rounded, color: Colors.white, size: 35),
                SizedBox(width: 10),
                Text('Storix', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
              ],
            ),
          ),
          // Пример контента
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 100,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(colors: [Color(0xFF5CB8E6), Color(0xFF9A81D7)])),
              child: const Center(child: Text('Добро пожаловать в Storix!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))),
            ),
          ),
        ],
      ),
    );
  }
}

class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const SafeArea(child: Center(child: Text('Обзор (скоро здесь появятся подборки)', style: TextStyle(color: Colors.white54))));
  }
}

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const SafeArea(child: Center(child: Text('Библиотека (ваши плейлисты)', style: TextStyle(color: Colors.white54))));
  }
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const SafeArea(child: Center(child: Text('Избранное (треки, которые вам понравились)', style: TextStyle(color: Colors.white54))));
  }
}

// --- ПОИСК С ИСПРАВЛЕННЫМ SOUNDCLOUD ---
class SearchScreen extends StatefulWidget {
  final Function(Track) onPlay;
  final SoundcloudClient scClient;
  const SearchScreen({super.key, required this.onPlay, required this.scClient});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Track> _results = [];
  bool _isLoading = false;

  Future<void> _search(String query) async {
    if (query.isEmpty) return;
    setState(() { _isLoading = true; _results = []; });
    
    try {
      final stream = widget.scClient.search(query, searchFilter: SearchFilter.tracks);
      final trackResults = await stream.first;

      List<Track> foundTracks = [];
      for (var result in trackResults) {
        if (result is TrackSearchResult) {
          final track = result;
          try {
            final streams = await widget.scClient.tracks.getStreams(track.id);
            final streamInfo = streams.firstWhere(
              (s) => s.container == 'mp3' || s.container == 'audio/mpeg', 
              orElse: () => streams.first
            );

            foundTracks.add(Track(
              title: track.title,
              artist: track.user.username,
              thumbnail: track.artworkUrl?.toString() ?? '',
              streamUrl: streamInfo.url.toString(),
              duration: Duration(milliseconds: (track.duration * 1000).toInt()),
            ));
          } catch (e) {
            // Если для трека нет доступного потока (например, требуется SoundCloud Go), пропускаем его
            debugPrint('Skipping track ${track.title}: $e');
          }
        }
      }

      setState(() {
        _results = foundTracks;
      });

    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 180),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: TextField(
                controller: _controller,
                onSubmitted: _search,
                decoration: InputDecoration(
                  hintText: 'Поиск треков на SoundCloud...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  filled: true, fillColor: const Color(0xFF231C33).withOpacity(0.8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
            ),
            if (_isLoading) const CircularProgressIndicator(color: Colors.blueAccent),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final track = _results[index];
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(track.thumbnail, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(width: 60, height: 60, color: Colors.grey)),
                    ),
                    title: Text(track.title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text(track.artist, style: const TextStyle(color: Colors.white54)),
                    trailing: IconButton(
                      icon: const Icon(Icons.play_circle_fill, color: Colors.blueAccent, size: 40),
                      onPressed: () => widget.onPlay(track),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- ПОЛНОЭКРАННЫЙ ПЛЕЕР ---
class PlayerScreen extends StatefulWidget {
  final Track track;
  final AudioPlayer player;
  const PlayerScreen({super.key, required this.track, required this.player});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(widget.track.thumbnail, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: Colors.black)),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(alignment: Alignment.topLeft, child: IconButton(icon: const Icon(Icons.keyboard_arrow_down, size: 35), onPressed: () => Navigator.pop(context))),
                const Spacer(),
                Container(
                  width: 280, height: 280,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, offset: const Offset(0, 15))],
                    image: DecorationImage(image: NetworkImage(widget.track.thumbnail), fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 40),
                Text(widget.track.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Text(widget.track.artist, style: const TextStyle(fontSize: 16, color: Colors.white70)),
                const SizedBox(height: 30),
                StreamBuilder<Duration>(
                  stream: widget.player.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final duration = widget.player.duration ?? widget.track.duration;
                    final max = duration.inMilliseconds.toDouble();
                    final value = position.inMilliseconds.toDouble().clamp(0.0, max);
                    return Column(
                      children: [
                        Slider(
                          value: value,
                          max: max == 0 ? 1.0 : max,
                          onChanged: (v) => widget.player.seek(Duration(milliseconds: v.toInt())),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_format(position), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                              Text(_format(duration), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(icon: const Icon(Icons.skip_previous_rounded, size: 45), onPressed: () {}),
                    StreamBuilder<PlayerState>(
                      stream: widget.player.playerStateStream,
                      builder: (context, snapshot) {
                        final playing = snapshot.data?.playing ?? false;
                        return Container(
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: IconButton(
                            icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 45, color: Colors.black),
                            onPressed: () => playing ? widget.player.pause() : widget.player.play(),
                          ),
                        );
                      },
                    ),
                    IconButton(icon: const Icon(Icons.skip_next_rounded, size: 45), onPressed: () {}),
                  ],
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
