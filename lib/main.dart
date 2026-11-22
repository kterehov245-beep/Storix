import 'dart:async';
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
      title: 'Storix', // Название приложения
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF120E1D), 
      ),
      home: const MainScreen(),
    );
  }
}

// --- МОДЕЛИ ДАННЫХ ---
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
    Track('Её парень', 'Shluzov', '1:12', 'https://picsum.photos/seed/track1/200/200', 'YT'),
    Track('заново', 'dabbackwood', '1:26', 'https://picsum.photos/seed/track2/200/200', 'SC'),
    Track('гуль', 'dabbackwood', '1:34', 'https://picsum.photos/seed/track3/200/200', 'YT'),
    Track('dabbackwood - назад...', 'dabbackwood', '1:29', 'https://picsum.photos/seed/track4/200/200', 'YT'),
    Track('хирург', 'curdest', '2:05', 'https://picsum.photos/seed/track5/200/200', 'SC'),
    Track('ФРУКТОВЫЙ', 'Unknown', '1:45', 'https://picsum.photos/seed/track6/200/200', 'YT'),
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
          Positioned.fill(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              children: _screens,
            ),
          ),

          // --- НИЖНЯЯ ПАНЕЛЬ И МИНИ-ПЛЕЕР ---
          Positioned(
            left: 16,
            right: 16,
            bottom: 16 + MediaQuery.of(context).padding.bottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Мини-плеер (Liquid Glass)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                    child: Container(
                      height: 65,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              _tracks[0].imageUrl, width: 45, height: 45, fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(width: 45, height: 45, color: Colors.deepPurple),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('распять (folk remix)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                const SizedBox(height: 12),
                
                // Навигация (Liquid Glass)
                ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                    child: Container(
                      height: 65,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
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
                                boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 10)],
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
// 1. ЭКРАН: ГЛАВНАЯ (STORIX)
// ==========================================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Track> tracks = [
      Track('гуль', 'dabbackwood', '', 'https://picsum.photos/seed/track3/200/200', 'YT'),
      Track('dabbackwood - наза...', 'dabbackwood', '', 'https://picsum.photos/seed/track4/200/200', 'YT'),
      Track('хирург', 'curdest', '', 'https://picsum.photos/seed/track5/200/200', 'SC'),
      Track('Её парень', 'Shluzov', '', 'https://picsum.photos/seed/track1/200/200', 'YT'),
      Track('назад в кресты', 'curdest', '', 'https://picsum.photos/seed/track2/200/200', 'YT'),
      Track('ФРУКТОВЫЙ', 'Unknown', '', 'https://picsum.photos/seed/track6/200/200', 'YT'),
    ];

    return Stack(
      children: [
        Positioned(top: -100, left: -100, child: Container(width: 400, height: 400, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.deepPurple.withOpacity(0.2), boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.2), blurRadius: 150)]))),
        Positioned(bottom: -50, right: -50, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blueAccent.withOpacity(0.1), boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.1), blurRadius: 150)]))),
        
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
                    const Text('Storix', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5)),
                  ],
                ),
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
                        Container(width: 50, height: 50, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.25)), child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30)),
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
                    crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 2.6,
                  ),
                  itemCount: tracks.length,
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(color: const Color(0xFF231C33).withOpacity(0.8), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
                            child: Image.network(tracks[index].imageUrl, width: 65, height: double.infinity, fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(width: 65, color: Colors.deepPurple.withOpacity(0.5))),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tracks[index].title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
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
}

// ==========================================
// 2. ЭКРАН: ОБЗОР
// ==========================================
class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> categories = [
      {'title': 'В дороге', 'img': 'https://picsum.photos/seed/cat1/200/200', 'color': Colors.amber},
      {'title': 'Вечеринка', 'img': 'https://picsum.photos/seed/cat2/200/200', 'color': Colors.purpleAccent},
      {'title': 'Грустная', 'img': 'https://picsum.photos/seed/cat3/200/200', 'color': Colors.blueGrey},
      {'title': 'Заряд энергии', 'img': 'https://picsum.photos/seed/cat4/200/200', 'color': Colors.orangeAccent},
      {'title': 'Концентрация', 'img': 'https://picsum.photos/seed/cat5/200/200', 'color': Colors.grey},
      {'title': 'Отдых', 'img': 'https://picsum.photos/seed/cat6/200/200', 'color': Colors.lightBlue},
    ];

    return Scaffold(
      body: SafeArea(
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
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(cat['img'], fit: BoxFit.cover, 
                            errorBuilder: (context, error, stackTrace) => Container(color: cat['color'].withOpacity(0.3))),
                          Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.7)]))),
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
      ),
    );
  }
}

// ==========================================
// 3. ЭКРАН: БИБЛИОТЕКА
// ==========================================
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 180),
          children: [
            const Text('Библиотека', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(colors: [Color(0xFF2A3B55), Color(0xFF14202E)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
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
                Expanded(child: Container(height: 120, decoration: BoxDecoration(color: const Color(0xFF231C33), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.add, size: 40, color: Colors.blueAccent))),
                const SizedBox(width: 12),
                Expanded(child: Container(height: 120, decoration: BoxDecoration(color: const Color(0xFF231C33), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.music_note, size: 40, color: Colors.white))),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 4. ЭКРАН: ЛЮБИМОЕ
// ==========================================
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Track> favs = [
      Track('Её парень', 'Shluzov', '1:12', 'https://picsum.photos/seed/track1/200/200', 'YT'),
      Track('заново', 'dabbackwood', '1:26', 'https://picsum.photos/seed/track2/200/200', 'SC'),
      Track('гуль', 'dabbackwood', '1:34', 'https://picsum.photos/seed/track3/200/200', 'YT'),
      Track('dabbackwood - назад...', 'dabbackwood', '1:29', 'https://picsum.photos/seed/track4/200/200', 'YT'),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 180),
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: const Color(0xFF2A2140)),
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
                  child: Image.network(track.imageUrl, width: 50, height: 50, fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(width: 50, height: 50, color: Colors.grey.shade800)),
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
      ),
    );
  }
}

// ==========================================
// 5. ЭКРАН: ПОИСК
// ==========================================
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
                    filled: true, fillColor: const Color(0xFF231C33),
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
      ),
    );
  }

  Widget _buildChip(String text, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: isActive ? const Color(0xFF3EB1E8) : const Color(0xFF231C33), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: isActive ? Colors.white : Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }
}
