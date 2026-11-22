import 'dart:ui';
import 'package:flutter/material.dart';

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
        scaffoldBackgroundColor: const Color(0xFF120E1D),
      ),
      home: const MainScreen(),
    );
  }
}

class Track {
  final String title;
  final String artist;
  final String time;
  final String imageUrl;
  final String platform;

  Track(this.title, this.artist, this.time, this.imageUrl, this.platform);
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  // Надежные ссылки на картинки
  final List<Track> _tracks = [
    Track('Её парень', 'Shluzov', '1:12', 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=200&q=80', 'YT'),
    Track('заново', 'dabbackwood', '1:26', 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=200&q=80', 'SC'),
    Track('гуль', 'dabbackwood', '1:34', 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=200&q=80', 'YT'),
    Track('назад в кресты', 'curdest', '1:29', 'https://images.unsplash.com/photo-1493225457124-a1a2a5f5646f?w=200&q=80', 'YT'),
    Track('хирург', 'curdest', '2:05', 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=200&q=80', 'SC'),
    Track('ФРУКТОВЫЙ', 'Unknown', '1:45', 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=200&q=80', 'YT'),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final List<Widget> _screens = const [
    HomeScreen(),
    BrowseScreen(),
    LibraryScreen(),
    FavoritesScreen(),
    SearchScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. СВАЙПАБЕЛЬНЫЕ ЭКРАНЫ
          Positioned.fill(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              children: _screens,
            ),
          ),

          // 2. НИЖНЯЯ ПАНЕЛЬ (Liquid Glass)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16 + MediaQuery.of(context).padding.bottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Мини-плеер (теперь КЛИКАБЕЛЬНЫЙ!)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PlayerScreen()),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
                      child: Container(
                        height: 65,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(_tracks[0].imageUrl, width: 45, height: 45, fit: BoxFit.cover),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('распять (folk remix)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  Text('stellla и plateexx', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                ],
                              ),
                            ),
                            const Icon(Icons.play_arrow_rounded, size: 35, color: Colors.white),
                            const SizedBox(width: 8),
                            const Icon(Icons.skip_next_rounded, size: 35, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Навигация (Liquid Glass)
                ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
                    child: Container(
                      height: 65,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                      ),
                      child: Stack(
                        children: [
                          AnimatedAlign(
                            alignment: Alignment(((_currentIndex / 2) - 1).clamp(-1.0, 1.0), 0),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutQuart,
                            child: Container(
                              width: 55, height: 55,
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                            ),
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
      onTap: () {
        _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      },
      child: Container(
        width: 55, alignment: Alignment.center,
        child: Icon(icon, color: _currentIndex == index ? Colors.white : Colors.white38, size: 26),
      ),
    );
  }
}

// ==========================================
// 1. ГЛАВНЫЙ ЭКРАН (Копия RX Playa)
// ==========================================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Track> tracks = [
      Track('гуль', 'dabbackwood', '', 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=200&q=80', 'YT'),
      Track('dabbackwood - наза...', 'dabbackwood', '', 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=200&q=80', 'YT'),
      Track('хирург', 'curdest', '', 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=200&q=80', 'SC'),
      Track('Её парень', 'Shluzov', '', 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=200&q=80', 'YT'),
      Track('назад в кресты', 'curdest', '', 'https://images.unsplash.com/photo-1493225457124-a1a2a5f5646f?w=200&q=80', 'YT'),
      Track('ФРУКТОВЫЙ', 'Unknown', '', 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=200&q=80', 'YT'),
    ];

    return Stack(
      children: [
        // Цветное свечение на фоне (чтобы было видно стекло)
        Positioned(top: -100, left: -100, child: Container(width: 400, height: 400, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.deepPurple.withOpacity(0.3), boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.3), blurRadius: 100)]))),
        Positioned(bottom: 0, right: -50, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blueAccent.withOpacity(0.2), boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.2), blurRadius: 100)]))),
        
        SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 180),
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    const Icon(Icons.waves_rounded, color: Colors.white, size: 35), 
                    const SizedBox(width: 10),
                    const Text('Storix', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                  ],
                ),
              ),
              // Текст под приветствием
              const Padding(
                padding: EdgeInsets.only(left: 20, right: 20, bottom: 20),
                child: Text('SoundCloud и аддоны: импорт и действия в RX Playa; лайки аккаунта недоступны.', style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.4)),
              ),
              
              // Баннер
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(colors: [Color(0xFF5CB8E6), Color(0xFF9A81D7)]),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('RX Wave', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        Container(width: 50, height: 50, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.3)), child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Кнопки фильтров
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildFilterChip('Все площадки', true),
                    const SizedBox(width: 8),
                    _buildFilterChip('Музыка', false),
                    const SizedBox(width: 8),
                    _buildFilterChip('Плейлисты', false),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Сетка карточек (КАК В RX)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 2.4,
                  ),
                  itemCount: tracks.length,
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(color: const Color(0xFF231C33), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
                            child: Image.network(tracks[index].imageUrl, width: 75, height: double.infinity, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tracks[index].title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(tracks[index].platform == 'YT' ? Icons.play_circle_fill_rounded : Icons.cloud, size: 14, color: tracks[index].platform == 'YT' ? Colors.redAccent : Colors.orangeAccent),
                                    const SizedBox(width: 4),
                                    Text(tracks[index].platform, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: tracks[index].platform == 'YT' ? Colors.redAccent : Colors.orangeAccent)),
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String text, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: isActive ? const Color(0xFF3EB1E8) : const Color(0xFF231C33), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: isActive ? Colors.white : Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }
}

// ==========================================
// ПОЛНОЭКРАННЫЙ ПЛЕЕР (ТОЧЬ-В-ТОЧЬ КАК В RX)
// ==========================================
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool _isPlaying = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Фоновая картинка (на весь экран)
          Image.network(
            'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=800&q=80',
            fit: BoxFit.cover,
          ),
          // 2. Градиент поверх картинки, чтобы текст читался
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.8),
                  Colors.black,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          
          // 3. Интерфейс плеера
          SafeArea(
            child: Column(
              children: [
                // Шапка
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(icon: const Icon(Icons.keyboard_arrow_down, size: 35, color: Colors.white), onPressed: () => Navigator.pop(context)),
                      const Column(
                        children: [
                          Text('Playing from SoundCloud', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          SizedBox(height: 4),
                          Icon(Icons.expand_more, color: Colors.white70, size: 18),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.more_horiz, size: 30, color: Colors.white), onPressed: () {}),
                    ],
                  ),
                ),

                const Spacer(), // Отталкивает контент вниз

                // Блок с названием и кнопками справа
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Её парень (folk remix)', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                            SizedBox(height: 6),
                            Text('stellla и plateexx', style: TextStyle(fontSize: 16, color: Colors.white70)),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.15)),
                            child: const Icon(Icons.thumb_down_alt_outlined, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.15)),
                            child: const Icon(Icons.star_border_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.15)),
                            child: const Icon(Icons.more_horiz, color: Colors.white, size: 22),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Полоса прогресса
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4.0,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.white,
                    ),
                    child: Slider(value: 0.2, onChanged: (val) {}),
                  ),
                ),
                // Время
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('0:53', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      Text('-0:18', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Кнопки управления
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(icon: const Icon(Icons.skip_previous_rounded, size: 50, color: Colors.white), onPressed: () {}),
                    GestureDetector(
                      onTap: () => setState(() => _isPlaying = !_isPlaying),
                      child: Icon(_isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded, size: 80, color: Colors.white),
                    ),
                    IconButton(icon: const Icon(Icons.skip_next_rounded, size: 50, color: Colors.white), onPressed: () {}),
                  ],
                ),

                const SizedBox(height: 30),

                // Нижние иконки
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.comment_outlined, color: Colors.white70, size: 26),
                      const Icon(Icons.headphones_outlined, color: Colors.white70, size: 26),
                      const Icon(Icons.format_list_bulleted, color: Colors.white70, size: 26),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Кирилл\'s Phone', style: TextStyle(color: Colors.white30, fontSize: 12)),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// ОСТАЛЬНЫЕ ЭКРАНЫ (Оставил как есть, чтобы не ломать)
// ==========================================
class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Обзор', style: TextStyle(fontSize: 24, color: Colors.white54))));
  }
}
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Библиотека', style: TextStyle(fontSize: 24, color: Colors.white54))));
  }
}
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Избранное', style: TextStyle(fontSize: 24, color: Colors.white54))));
  }
}
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Поиск', style: TextStyle(fontSize: 24, color: Colors.white54))));
  }
}
