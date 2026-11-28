import 'dart:ui';
import 'glass.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'yandex_auth_screen.dart';
import 'package:webview_flutter/webview_flutter.dart'; // Этот тоже нужен
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
  MiniPlayerBar(
    track: _currentTrack!,
    player: _player,
    isLoading: _isLoadingTrack,
  ),
if (false)
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
// --- ГЛАВНЫЙ ЭКРАН ---
class HomeScreen extends StatelessWidget {
  final Function(Track) onPlay;
  const HomeScreen({super.key, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 180), // Отступ под плеер
        children: [
          // Приветствие
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.waves_rounded, color: Colors.white, size: 35),
                    SizedBox(width: 10),
                    Text('Storix', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                  ],
                ),
                SizedBox(height: 20),
                Text('Добрый вечер', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                SizedBox(height: 8),
                Text('SoundCloud и аддоны: импорт и действия', style: TextStyle(fontSize: 14, color: Colors.white54)),
              ],
            ),
          ),
          
          // Большой баннер (как RX Wave)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFF4facfe), Color(0xFFb06ab3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text('Storix Wave', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Горизонтальные фильтры
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildFilterChip('Все площадки', isActive: true),
                _buildFilterChip('Музыка'),
                _buildFilterChip('Плейлисты'),
              ],
            ),
          ),
          
          // Сетка треков (2 колонки) с использованием GlassSurface
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.2,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                return GlassSurface(
                  radius: 12,
                  blur: 10,
                  fillAlpha: 40,
                  padding: EdgeInsets.zero,
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
                          color: Colors.grey, // Сюда можно потом поставить картинку
                        ),
                        child: const Icon(Icons.music_note, color: Colors.white54),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Название\nтрека', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String text, {bool isActive = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.blueAccent : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: isActive ? Colors.white : Colors.white70, fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
      ),
    );
  }
}

// --- ОБЗОР (Карточки настроений) ---
class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Обзор', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                ),
                itemCount: 6,
                itemBuilder: (context, index) {
                  // Временные цвета и названия для карточек
                  final colors = [
                    [Colors.amber, Colors.orange],
                    [Colors.purpleAccent, Colors.deepPurple],
                    [Colors.blueGrey, Colors.grey],
                    [Colors.lightGreen, Colors.green],
                    [Colors.redAccent, Colors.red],
                    [Colors.lightBlue, Colors.blue],
                  ];
                  final titles = ['В дороге', 'Вечеринка', 'Грустная', 'Заряд энергии', 'Романтика', 'Сон'];
                  
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: colors[index % colors.length],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      titles[index % titles.length],
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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

// --- БИБЛИОТЕКА ---
class LibraryScreen extends StatelessWidget {
  final Function(Track) onPlay;
  const LibraryScreen({super.key, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 180),
        children: [
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text('Библиотека', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          
          // Карточка статистики
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GlassSurface(
              radius: 24,
              blur: 15,
              fillAlpha: 30,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ВАШ ОПЫТ ПРОСЛУШИВАНИЯ', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  const Text('19 МИНУТ', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('КИРИЛЛ\n12 прослушиваний', style: TextStyle(color: Colors.white, fontSize: 12)),
                      Text('11/26', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Меню
          ListTile(
            leading: const Icon(Icons.download, color: Colors.blueAccent),
            title: const Text('Загрузки', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.chevron_right, color: Colors.white54),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.folder, color: Colors.blueAccent),
            title: const Text('Локальная музыка', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.chevron_right, color: Colors.white54),
            onTap: () {},
          ),
          
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('Плейлисты', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          const SizedBox(height: 10),
          // Заглушка под плейлисты
          SizedBox(
            height: 140,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                  child: const Center(child: Icon(Icons.add, color: Colors.blueAccent, size: 40)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- ИЗБРАННОЕ ---
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 180),
        children: [
          // Шапка "Любимое"
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFF2b1055), Color(0xFF7597de)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Любимое', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 10),
                  const Text('05 треков', style: TextStyle(fontSize: 18, color: Colors.white70)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Играть'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white54)),
                        child: const Text('Перемешать', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          // Список треков (заглушка)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: Text('Здесь будут ваши любимые треки', style: TextStyle(color: Colors.white54)),
            ),
          ),
        ],
      ),
    );
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
    setState(() {
      _isLoading = true;
      _results = [];
    });

    try {
      debugPrint('--- НАЧАЛО ПОИСКА: $query ---');
      
      final searchResult = await widget.scClient.search.getTracks(query).first.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('SoundCloud не ответил за 10 секунд (возможно, блокировка)');
        },
      );

      debugPrint('--- НАЙДЕНО ТРЕКОВ: ${searchResult.length} ---');

      List<Track> foundTracks = [];

      for (var track in searchResult) {
        try {
          debugPrint('Загрузка стрима для: ${track.title}');
          
          final streams = await widget.scClient.tracks.getStreams(track.id).timeout(
            const Duration(seconds: 5),
          );

          if (streams.isEmpty) continue;

          final streamInfo = streams.firstWhere(
            (s) => s.container == 'mp3',
            orElse: () => streams.first,
          );

          foundTracks.add(Track(
            title: track.title,
            artist: track.user.username,
            thumbnail: track.artworkUrl?.toString() ?? '',
            streamUrl: streamInfo.url.toString(),
            duration: Duration(milliseconds: ((track.duration ?? 0) * 1000).toInt()),
          ));

        } catch (e) {
          debugPrint('Ошибка стрима для ${track.title}: $e');
        }
      }

      setState(() {
        _results = foundTracks;
      });
      
      if (foundTracks.isEmpty) {
        throw Exception('Треки найдены, но ни один не доступен для прослушивания');
      }

    } catch (e) {
      debugPrint('!!! ОШИБКА ПОИСКА: $e !!!');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()), 
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
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
              padding: const EdgeInsets.all(20.0),
              child: TextField(
                controller: _controller,
                onSubmitted: _search,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Поиск треков в SoundCloud...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            
            if (_isLoading)
              const CircularProgressIndicator(color: Colors.blueAccent),
            
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final track = _results[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: track.thumbnail.isNotEmpty
                          ? Image.network(
                              track.thumbnail,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(color: Colors.grey, width: 50, height: 50, child: const Icon(Icons.music_note)),
                            )
                          : Container(color: Colors.grey, width: 50, height: 50, child: const Icon(Icons.music_note)),
                    ),
                    title: Text(track.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(track.artist, style: const TextStyle(color: Colors.white54), maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: const Icon(Icons.play_circle_fill, color: Colors.blueAccent, size: 36),
                      onPressed: () => widget.onPlay(track), 
                    )
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} // <--- ВОТ ЭТА СКОБКА ЗАКРЫВАЕТ ПОИСК. ЕСЛИ ЕЕ НЕТ, ВСЁ ЛОМАЕТСЯ.

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
          Image.network(widget.track.thumbnail, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.black)),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down, size: 40, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 280, height: 280,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, offset: const Offset(0, 10))],
                    image: DecorationImage(image: NetworkImage(widget.track.thumbnail), fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(widget.track.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(height: 8),
                Text(widget.track.artist, style: const TextStyle(fontSize: 16, color: Colors.white70)),
                const SizedBox(height: 30),
                StreamBuilder<Duration>(
                  stream: widget.player.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final duration = widget.track.duration;
                    final max = duration.inMilliseconds.toDouble();
                    final double value = position.inMilliseconds.toDouble().clamp(0.0, max > 0 ? max : 1.0).toDouble();
                    
                    return Column(
                      children: [
                        Slider(
                          value: value,
                          max: max == 0 ? 1.0 : max,
                          activeColor: Colors.white,
                          inactiveColor: Colors.white24,
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
                    IconButton(icon: const Icon(Icons.skip_previous_rounded, size: 45, color: Colors.white), onPressed: () {}),
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
                    IconButton(icon: const Icon(Icons.skip_next_rounded, size: 45, color: Colors.white), onPressed: () {}),
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
