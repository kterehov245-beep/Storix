import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

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

// --- МОДЕЛИ ДАННЫХ ---
class Track {
  final int id;
  final String title;
  final String artist;
  final String time;
  final String imageUrl;
  final String platform; // 'YT', 'SC'
  final String previewUrl;

  Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.time,
    required this.imageUrl,
    required this.platform,
    required this.previewUrl,
  });

  factory Track.fromDeezer(Map<String, dynamic> json) {
    return Track(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Unknown',
      artist: json['artist']?['name'] ?? 'Unknown Artist',
      time: '0:30', 
      imageUrl: json['album']?['cover_medium'] ?? 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=200&q=80',
      platform: 'SC',
      previewUrl: json['preview'] ?? '',
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late PageController _pageController;
  
  // Аудио-плеер и текущий трек
  final AudioPlayer _player = AudioPlayer();
  Track? _currentTrack;

  // Фейковые данные для красоты главной
  final List<Track> _fakeTracks = [
    Track(id: 1, title: 'гуль', artist: 'dabbackwood', time: '', imageUrl: 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=200&q=80', platform: 'YT', previewUrl: ''),
    Track(id: 2, title: 'dabbackwood - наза...', artist: 'dabbackwood', time: '', imageUrl: 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=200&q=80', platform: 'YT', previewUrl: ''),
    Track(id: 3, title: 'хирург', artist: 'curdest', time: '', imageUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=200&q=80', platform: 'SC', previewUrl: ''),
    Track(id: 4, title: 'Её парень', artist: 'Shluzov', time: '', imageUrl: 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=200&q=80', platform: 'YT', previewUrl: ''),
    Track(id: 5, title: 'назад в кресты', artist: 'curdest', time: '', imageUrl: 'https://images.unsplash.com/photo-1493225457124-a1a2a5f5646f?w=200&q=80', platform: 'YT', previewUrl: ''),
    Track(id: 6, title: 'ФРУКТОВЫЙ', artist: 'Unknown', time: '', imageUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=200&q=80', platform: 'YT', previewUrl: ''),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _player.dispose();
    super.dispose();
  }

  void _playTrack(Track track) {
    if (track.previewUrl.isEmpty) return;
    setState(() => _currentTrack = track);
    _player.setUrl(track.previewUrl);
    _player.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AppBackground(),
          
          // СВАЙПАБЕЛЬНЫЕ ЭКРАНЫ
          Positioned.fill(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              children: [
                HomeScreen(tracks: _fakeTracks, onPlay: _playTrack),
                const BrowseScreen(),
                const LibraryScreen(),
                const FavoritesScreen(),
                SearchScreen(onPlay: _playTrack),
              ],
            ),
          ),

          // ПАРЯЩАЯ НИЖНЯЯ ПАНЕЛЬ
          Positioned(
            left: 16, right: 16,
            bottom: 16 + MediaQuery.of(context).padding.bottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Мини-плеер
                if (_currentTrack != null)
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(track: _currentTrack!, player: _player))),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                        child: Container(
                          height: 65,
                          margin: const EdgeInsets.only(bottom: 12),
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
                                child: Image.network(_currentTrack!.imageUrl, width: 45, height: 45, fit: BoxFit.cover),
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
                              const Icon(Icons.play_arrow_rounded, size: 35, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                
                // Навигация (Синхронизация с пальцем)
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
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final double itemWidth = constraints.maxWidth / 5;
                          const double circleSize = 55.0;

                          return Stack(
                            children: [
                              AnimatedBuilder(
                                animation: _pageController,
                                builder: (context, child) {
                                  double currentPage = _currentIndex.toDouble();
                                  if (_pageController.hasClients && _pageController.position.haveDimensions) {
                                    currentPage = _pageController.page ?? _currentIndex.toDouble();
                                  }
                                  double leftOffset = (itemWidth * currentPage) + (itemWidth / 2) - (circleSize / 2);
                                  return Positioned(
                                    left: leftOffset,
                                    top: (70 - circleSize) / 2,
                                    child: Container(
                                      width: circleSize,
                                      height: circleSize,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        shape: BoxShape.circle,
                                        boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildNavIcon(Icons.home_filled, 0),
                                  _buildNavIcon(Icons.grid_view_rounded, 1),
                                  _buildNavIcon(Icons.folder_rounded, 2),
                                  _buildNavIcon(Icons.star_rounded, 3),
                                  _buildNavIcon(Icons.search_rounded, 4),
                                ],
                              ),
                            ],
                          );
                        }
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

  Widget _buildNavIcon(IconData icon, int index) {
    return GestureDetector(
      onTap: () => _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeOutQuart),
      child: Container(
        width: 55, alignment: Alignment.center,
        child: Icon(icon, color: _currentIndex == index ? Colors.white : Colors.white38, size: 26),
      ),
    );
  }
}

// --- ФОН (Свечение для стекла) ---
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

// --- 1. ГЛАВНАЯ ---
class HomeScreen extends StatelessWidget {
  final List<Track> tracks;
  final Function(Track) onPlay;
  const HomeScreen({super.key, required this.tracks, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 180),
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(children: const [Icon(Icons.waves_rounded, color: Colors.white, size: 35), SizedBox(width: 10), Text('Storix', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white))]),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: Text('SoundCloud и аддоны: импорт и действия в RX Playa.', style: TextStyle(color: Colors.white54, fontSize: 11)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 100,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(colors: [Color(0xFF5CB8E6), Color(0xFF9A81D7)])),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('RX Wave', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)), Container(width: 50, height: 50, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.3)), child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30))]),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 2.4),
              itemCount: tracks.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    if (tracks[index].previewUrl.isNotEmpty) onPlay(tracks[index]);
                  },
                  child: Container(
                    decoration: BoxDecoration(color: const Color(0xFF231C33).withOpacity(0.8), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.05))),
                    child: Row(
                      children: [
                        ClipRRect(borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)), child: Image.network(tracks[index].imageUrl, width: 75, height: double.infinity, fit: BoxFit.cover)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tracks[index].title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 6),
                              Row(children: [Icon(tracks[index].platform == 'YT' ? Icons.play_circle_fill_rounded : Icons.cloud, size: 14, color: tracks[index].platform == 'YT' ? Colors.redAccent : Colors.orangeAccent), const SizedBox(width: 4), Text(tracks[index].platform, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: tracks[index].platform == 'YT' ? Colors.redAccent : Colors.orangeAccent))]),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- 2. ОБЗОР ---
class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const SafeArea(child: Center(child: Text('Обзор (в разработке)', style: TextStyle(color: Colors.white54))));
  }
}

// --- 3. БИБЛИОТЕКА ---
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const SafeArea(child: Center(child: Text('Библиотека (в разработке)', style: TextStyle(color: Colors.white54))));
  }
}

// --- 4. ИЗБРАННОЕ ---
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const SafeArea(child: Center(child: Text('Избранное (в разработке)', style: TextStyle(color: Colors.white54))));
  }
}

// --- 5. ПОИСК (РЕАЛЬНЫЙ) ---
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
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('https://api.deezer.com/search?q=$query'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() => _results = (data['data'] as List).map((json) => Track.fromDeezer(json)).toList());
      }
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      setState(() => _isLoading = false);
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
                  hintText: 'Поиск реальных треков...',
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
                    leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(track.imageUrl, width: 50, height: 50, fit: BoxFit.cover)),
                    title: Text(track.title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(track.artist, style: const TextStyle(color: Colors.white54)),
                    trailing: IconButton(icon: const Icon(Icons.play_circle_fill, color: Colors.blueAccent, size: 35), onPressed: () => widget.onPlay(track)),
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
          Image.network(widget.track.imageUrl, fit: BoxFit.cover),
          Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.2), Colors.black.withOpacity(0.9)]))),
          SafeArea(
            child: Column(
              children: [
                Align(alignment: Alignment.topLeft, child: IconButton(icon: const Icon(Icons.keyboard_arrow_down, size: 35), onPressed: () => Navigator.pop(context))),
                const Spacer(),
                Text(widget.track.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text(widget.track.artist, style: const TextStyle(fontSize: 16, color: Colors.white70)),
                const SizedBox(height: 30),
                StreamBuilder<Duration>(
                  stream: widget.player.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final duration = widget.player.duration ?? const Duration(seconds: 30);
                    final max = duration.inMilliseconds.toDouble();
                    final value = position.inMilliseconds.toDouble().clamp(0.0, max);
                    return Slider(
                      value: value,
                      max: max == 0 ? 1.0 : max,
                      onChanged: (v) => widget.player.seek(Duration(milliseconds: v.toInt())),
                    );
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(icon: const Icon(Icons.skip_previous_rounded, size: 45), onPressed: () {}),
                    StreamBuilder<PlayerState>(
                      stream: widget.player.playerStateStream,
                      builder: (context, snapshot) {
                        final playing = snapshot.data?.playing ?? false;
                        return IconButton(
                          icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 80, color: Colors.white),
                          onPressed: () => playing ? widget.player.pause() : widget.player.play(),
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
}
