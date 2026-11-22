import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

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
  final String videoId;

  Track({required this.title, required this.artist, required this.thumbnail, required this.videoId});
}

// --- ГЛАВНЫЙ ЭКРАН ---
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final AudioPlayer _player = AudioPlayer();
  int _currentIndex = 0;
  Track? _currentTrack;
  bool _isLoadingTrack = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  // ПЛЕЙ ТРЕКА (Извлекаем аудио с YouTube)
  Future<void> _playTrack(Track track) async {
    setState(() {
      _currentTrack = track;
      _isLoadingTrack = true;
    });

    try {
      final yt = YoutubeExplode();
      // Получаем манифест всех потоков видео
      final streamManifest = await yt.videos.streams.getManifest(track.videoId);
      // Берем только аудио (наивысшее качество)
      final audioStreamInfo = streamManifest.audioOnly.withHighestBitrate();
      
      await _player.setUrl(audioStreamInfo.url.toString());
      _player.play();
      
      yt.close();
    } catch (e) {
      debugPrint('Playback error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingTrack = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AppBackground(),
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                const Center(child: Text('Добро пожаловать в Storix!\nПерейди во вкладку поиска (лупа).', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54))),
                const Center(child: Text('Обзор', style: TextStyle(color: Colors.white54))),
                const Center(child: Text('Библиотека', style: TextStyle(color: Colors.white54))),
                const Center(child: Text('Избранное', style: TextStyle(color: Colors.white54))),
                SearchScreen(onPlay: _playTrack),
              ],
            ),
          ),
          
          // Мини-плеер и Навигация
          Positioned(
            left: 16, right: 16,
            bottom: 16 + MediaQuery.of(context).padding.bottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_currentTrack != null)
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(track: _currentTrack!, player: _player))),
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
                const SizedBox(height: 12),
                
                // Навигация
                ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child: Container(
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _navIcon(Icons.home_filled, 0),
                          _navIcon(Icons.grid_view_rounded, 1),
                          _navIcon(Icons.folder_rounded, 2),
                          _navIcon(Icons.star_rounded, 3),
                          _navIcon(Icons.search_rounded, 4),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navIcon(IconData icon, int index) {
    final active = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Icon(icon, color: active ? Colors.white : Colors.white38, size: 26),
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

// --- ПОИСК (ВСТРОЕННЫЙ YOUTUBE) ---
class SearchScreen extends StatefulWidget {
  final Function(Track) onPlay;
  const SearchScreen({super.key, required this.onPlay});
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
      final yt = YoutubeExplode();
      // Ищем видео по запросу
      final searchList = await yt.search.search(query);
      
      setState(() {
        _results = searchList.take(10).map((video) => Track(
          title: video.title,
          artist: video.author,
          thumbnail: video.thumbnails.mediumResUrl,
          videoId: video.id.value,
        )).toList();
      });
      yt.close();
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
                  hintText: 'Поиск полных треков...',
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
                    final duration = widget.player.duration ?? const Duration(minutes: 1);
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
