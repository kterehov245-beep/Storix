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
        scaffoldBackgroundColor: const Color(0xFF0F0C1B),
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

  final List<Track> _tracks = [
    Track('Её парень', 'Shluzov', '1:12', 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=200&q=80', 'YT'),
    Track('заново', 'dabbackwood', '1:26', 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=200&q=80', 'SC'),
    Track('гуль', 'dabbackwood', '1:34', 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=200&q=80', 'YT'),
    Track('назад в кресты', 'curdest', '1:29', 'https://images.unsplash.com/photo-1493225457124-a1a2a5f5646f?w=200&q=80', 'YT'),
    Track('хирург', 'curdest', '2:05', 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=200&q=80', 'SC'),
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
          // Красивый фон для эффекта стекла
          const AppBackground(),

          // Экраны
          Positioned.fill(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              children: _screens,
            ),
          ),

          // НИЖНЯЯ ПАНЕЛЬ (Следит за пальцем)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16 + MediaQuery.of(context).padding.bottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Мини-плеер
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const PlayerScreen()));
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
                      child: Container(
                        height: 65,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5), // Яркий блик
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(_tracks[0].imageUrl, width: 45, height: 45, fit: BoxFit.cover),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('распять (folk remix)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  Text('stellla и plateexx', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
                
                // Навигация (Магия синхронизации)
                ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
                    child: Container(
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Вычисляем ширину одной ячейки
                          final double itemWidth = constraints.maxWidth / 5;
                          const double circleSize = 55.0;

                          return Stack(
                            children: [
                              // Анимируем позицию капсулы в реальном времени
                              AnimatedBuilder(
                                animation: _pageController,
                                builder: (context, child) {
                                  // Получаем текущую страницу (например, 1.5 если свайпаем между 1 и 2)
                                  double currentPage = _currentIndex.toDouble();
                                  if (_pageController.hasClients && _pageController.position.haveDimensions) {
                                    currentPage = _pageController.page ?? _currentIndex.toDouble();
                                  }
                                  
                                  // Считаем позицию X для капсулы
                                  double leftOffset = (itemWidth * currentPage) + (itemWidth / 2) - (circleSize / 2);

                                  return Positioned(
                                    left: leftOffset,
                                    top: (70 - circleSize) / 2,
                                    child: Container(
                                      width: circleSize,
                                      height: circleSize,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15), // Само стекло
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // Иконки
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
      onTap: () {
        _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeOutQuart);
      },
      child: Container(
        width: 55, alignment: Alignment.center,
        child: Icon(icon, color: _currentIndex == index ? Colors.white : Colors.white38, size: 26),
      ),
    );
  }
}

// ==========================================
// ФОНОВОЕ СВЕЧЕНИЕ (Основа для Liquid Glass)
// ==========================================
class AppBackground extends StatelessWidget {
  const AppBackground({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F0C1B),
      child: Stack(
        children: [
          Positioned(
            top: -100, left: -100,
            child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [Colors.deepPurpleAccent.withOpacity(0.35), Colors.transparent]),
              ),
            ),
          ),
          Positioned(
            bottom: 50, right: -100,
            child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [Colors.blueAccent.withOpacity(0.25), Colors.transparent]),
              ),
            ),
          ),
          Positioned(
            top: 300, left: 50,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [Colors.pinkAccent.withOpacity(0.15), Colors.transparent]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 1. ГЛАВНЫЙ ЭКРАН
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

    return SafeArea(
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
          
          // Сетка карточек
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
                  decoration: BoxDecoration(
                    color: const Color(0xFF231C33).withOpacity(0.8), 
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.05)), // Легкий блик
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
                        child: Image.network(tracks[index].imageUrl, width: 75, height: double.infinity, fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(width: 75, color: Colors.deepPurple)),
                      ),
                      const SizedBox(width: 10),
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
    );
  }
}

// ==========================================
// 2. ОБЗОР
// ==========================================
class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> categories = [
      {'title': 'В дороге', 'img': 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=200&q=80'},
      {'title': 'Вечеринка', 'img': 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=200&q=80'},
      {'title': 'Грустная', 'img': 'https://images.unsplash.com/photo-1493225457124-a1a2a5f5646f?w=200&q=80'},
      {'title': 'Заряд энергии', 'img': 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=200&q=80'},
      {'title': 'Концентрация', 'img': 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=200&q=80'},
      {'title': 'Отдых', 'img': 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=200&q=80'},
    ];

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 180),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Обзор', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.6,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  return Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.1))),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(cat['img'], fit: BoxFit.cover),
                        Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.8)]))),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(cat['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ],
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

// ==========================================
// 3. БИБЛИОТЕКА
// ==========================================
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 180),
        children: [
          const Text('Библиотека', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20), 
              color: const Color(0xFF231C33).withOpacity(0.8),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [Text('ВАШ ОПЫТ ПРОСЛУШИВАНИЯ', style: TextStyle(fontSize: 10, color: Colors.white70, letterSpacing: 1.2)), Icon(Icons.wifi, color: Colors.white54)]),
                const SizedBox(height: 20),
                const Text('19', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                const Text('МИНУТ ПРОСЛУШАНО', style: TextStyle(fontSize: 12, color: Colors.white54)),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('КИРИЛЛ', style: TextStyle(fontWeight: FontWeight.bold)), Text('12 прослушиваний · 2026', style: TextStyle(fontSize: 10, color: Colors.white54))]),
                  Text('11/26', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ListTile(leading: const Icon(Icons.download_rounded, color: Colors.blueAccent), title: const Text('Загрузки'), trailing: const Icon(Icons.chevron_right, color: Colors.white54), onTap: () {}),
          ListTile(leading: const Icon(Icons.folder_rounded, color: Colors.blueAccent), title: const Text('Локальная музыка'), trailing: const Icon(Icons.chevron_right, color: Colors.white54), onTap: () {}),
          const SizedBox(height: 20),
          const Text('Плейлисты', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Container(height: 120, decoration: BoxDecoration(color: const Color(0xFF231C33).withOpacity(0.8), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.add, size: 40, color: Colors.blueAccent))),
              const SizedBox(width: 12),
              Expanded(child: Container(height: 120, decoration: BoxDecoration(color: const Color(0xFF231C33).withOpacity(0.8), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.music_note, size: 40, color: Colors.white))),
            ],
          )
        ],
      ),
    );
  }
}

// ==========================================
// 4. ЛЮБИМОЕ
// ==========================================
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Track> favs = [
      Track('Её парень', 'Shluzov', '1:12', 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=200&q=80', 'YT'),
      Track('заново', 'dabbackwood', '1:26', 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=200&q=80', 'SC'),
      Track('гуль', 'dabbackwood', '1:34', 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=200&q=80', 'YT'),
      Track('dabbackwood - назад...', 'dabbackwood', '1:29', 'https://images.unsplash.com/photo-1493225457124-a1a2a5f5646f?w=200&q=80', 'YT'),
    ];

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 180),
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24), 
                color: const Color(0xFF2A2140).withOpacity(0.8),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Любимое', style: TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Любимое', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
                  const Text('05', style: TextStyle(fontSize: 20, color: Colors.white54)),
                  const SizedBox(height: 20),
                  Row(children: const [Text('Играть', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)), SizedBox(width: 20), Text('Перемешать', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 20),
                  const Text('0 из 5 на устройстве', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: const Color(0xFF3EB1E8), borderRadius: BorderRadius.circular(12)),
                    child: const Center(child: Text('Скачать 5 для оффлайн', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                  )
                ],
              ),
            ),
          ),
          ...favs.map((track) {
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(track.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
              ),
              title: Text(track.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(track.artist, style: const TextStyle(color: Colors.white54)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(track.time, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(width: 12),
                  const Icon(Icons.star_rounded, color: Colors.blueAccent),
                  const SizedBox(width: 8),
                  const Icon(Icons.more_vert, color: Colors.white54),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ==========================================
// 5. ПОИСК
// ==========================================
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 180),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Исполнители, песни, тексты и м...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  filled: true, fillColor: const Color(0xFF231C33).withOpacity(0.8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [_buildChip('Все площадки', true), const SizedBox(width: 8), _buildChip('YouTube', false), const SizedBox(width: 8), _buildChip('Яндекс Музыка', false)]),
            ),
            const Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Text('Введите запрос и выберите музыкальную площадку', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String text, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: isActive ? const Color(0xFF3EB1E8) : const Color(0xFF231C33).withOpacity(0.8), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: isActive ? Colors.white : Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }
}

// ==========================================
// ПОЛНОЭКРАННЫЙ ПЛЕЕР (С ОБЛОЖКОЙ И СТЕКЛОМ)
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
          // 1. Обложка на весь экран
          Image.network(
            'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=800&q=80',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(color: Colors.deepPurple),
          ),
          // 2. Мощное затемнение
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.8),
                  Colors.black.withOpacity(0.95),
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),
          
          // 3. Интерфейс
          SafeArea(
            child: Column(
              children: [
                // Шапка (Liquid Glass)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            IconButton(icon: const Icon(Icons.keyboard_arrow_down, size: 30, color: Colors.white), onPressed: () => Navigator.pop(context)),
                            const Text('Playing from SoundCloud', style: TextStyle(color: Colors.white, fontSize: 13)),
                            IconButton(icon: const Icon(Icons.more_horiz, color: Colors.white), onPressed: () {}),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Название
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
                            Text('Её парень (folk remix)', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                            SizedBox(height: 6),
                            Text('stellla и plateexx', style: TextStyle(fontSize: 16, color: Colors.white70)),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          _buildGlassIcon(Icons.thumb_down_alt_outlined),
                          const SizedBox(width: 12),
                          _buildGlassIcon(Icons.star_border_rounded),
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
                      trackHeight: 5.0,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.0),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 15.0),
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white30,
                      thumbColor: Colors.white,
                    ),
                    child: Slider(value: 0.3, onChanged: (val) {}),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('0:53', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('-0:18', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Управление
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(icon: const Icon(Icons.skip_previous_rounded, size: 50, color: Colors.white), onPressed: () {}),
                    GestureDetector(
                      onTap: () => setState(() => _isPlaying = !_isPlaying),
                      child: Container(
                        height: 80, width: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.2), blurRadius: 20)],
                        ),
                        child: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 45, color: Colors.black),
                      ),
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

  Widget _buildGlassIcon(IconData icon) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.15),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
