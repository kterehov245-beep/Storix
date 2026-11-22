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
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF141026),
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

  Track(this.title, this.artist, this.time, this.imageUrl);
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
    Track('Её парень', 'Shluzov', '1:12', 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=200&q=80'),
    Track('заново', 'dabbackwood', '1:26', 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=200&q=80'),
    Track('гуль', 'dabbackwood', '1:34', 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=200&q=80'),
    Track('dabbackwood - назад...', 'dabbackwood', '1:29', 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=200&q=80'),
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

  // Список экранов
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
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _screens,
      ),

      // --- ПАРЯЩАЯ НИЖНЯЯ ПАНЕЛЬ С LIQUID GLASS ---
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Мини-плеер
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
                  child: Container(
                    height: 65,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
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
                              Text('распять (folk remix)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                              Text('stellla и plateexx', style: TextStyle(color: Colors.white54, fontSize: 13)),
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
              
              // Навигация (Liquid Glass с анимацией)
              ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
                    ),
                    child: Stack(
                      children: [
                        // Плавно двигающаяся капсула (Liquid Glass)
                        AnimatedAlign(
                          alignment: Alignment(((_currentIndex / 2) - 1).clamp(-1.0, 1.0), 0),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutQuart,
                          child: Container(
                            width: 60, // Ширина капсулы
                            height: 60,
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                          ),
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
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index) {
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        width: 60, // Ширина зоны нажатия совпадает с капсулой
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: _currentIndex == index ? Colors.white : Colors.white38,
          size: 28,
        ),
      ),
    );
  }
}

// ==========================================
// 1. ЭКРАН: ГЛАВНАЯ
// ==========================================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Цветные пятна на фоне
        Positioned(
          top: -50, left: -50,
          child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.deepPurple.withOpacity(0.2), boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.2), blurRadius: 100)])),
        ),
        SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 180),
            children: [
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('Добрый вечер', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
              // Баннер
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(colors: [Color(0xFF5CB8E6), Color(0xFFB39DDB)]),
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
            ],
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 2. ЭКРАН: ОБЗОР (Сетка категорий)
// ==========================================
class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key});

  final List<Map<String, dynamic>> _categories = const [
    {'title': 'В дороге', 'color': Colors.amber, 'img': 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=200&q=80'},
    {'title': 'Вечеринка', 'color': Colors.purpleAccent, 'img': 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=200&q=80'},
    {'title': 'Грустная', 'color': Colors.blueGrey, 'img': 'https://images.unsplash.com/photo-1493225457124-a1a2a5f5646f?w=200&q=80'},
    {'title': 'Заряд энергии', 'color': Colors.orangeAccent, 'img': 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=200&q=80'},
    {'title': 'Концентрация', 'color': Colors.grey, 'img': 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=200&q=80'},
    {'title': 'Отдых', 'color': Colors.lightBlue, 'img': 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=200&q=80'},
  ];

  @override
  Widget build(BuildContext context) {
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
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.6,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: cat['color'].withOpacity(0.2),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          Positioned(
                            right: -10, bottom: -10,
                            child: Image.network(cat['img'], width: 100, height: 100, fit: BoxFit.cover),
                          ),
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
            
            // Карточка статистики
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(colors: [Color(0xFF3A2C4F), Color(0xFF231C33)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('ВАШ ОПЫТ ПРОСЛУШИВАНИЯ', style: TextStyle(fontSize: 10, color: Colors.white70, letterSpacing: 1.2)),
                      Icon(Icons.wifi, color: Colors.white54),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('19', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                  const Text('МИНУТ ПРОСЛУШАНО', style: TextStyle(fontSize: 12, color: Colors.white54)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Список
            ListTile(
              leading: const Icon(Icons.download_rounded, color: Colors.blueAccent),
              title: const Text('Загрузки'),
              trailing: const Icon(Icons.chevron_right, color: Colors.white54),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.folder_rounded, color: Colors.blueAccent),
              title: const Text('Локальная музыка'),
              trailing: const Icon(Icons.chevron_right, color: Colors.white54),
              onTap: () {},
            ),
            
            const SizedBox(height: 20),
            const Text('Плейлисты', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            // Сетка плейлистов
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(color: const Color(0xFF231C33), borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.add, size: 40, color: Colors.blueAccent),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(color: const Color(0xFF231C33), borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.music_note, size: 40, color: Colors.white),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 4. ЭКРАН: ЛЮБИМОЕ (Скрин 1)
// ==========================================
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 180),
          children: [
            // Большая шапка
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: const Color(0xFF2A2140),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Любимое', style: TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Любимое', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
                    const Text('05', style: TextStyle(fontSize: 20, color: Colors.white54)),
                    const SizedBox(height: 20),
                    Row(
                      children: const [
                        Text('Играть', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                        SizedBox(width: 20),
                        Text('Перемешать', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('0 из 5 на устройстве', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(color: const Color(0xFF3EB1E8), borderRadius: BorderRadius.circular(12)),
                      child: const Center(child: Text('Скачать 5 для оффлайн', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                    )
                  ],
                ),
              ),
            ),
            
            // Список треков
            ...List.generate(4, (index) {
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network('https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=100&q=80', width: 50, height: 50, fit: BoxFit.cover),
                ),
                title: Text(['Её парень', 'заново', 'гуль', 'dabbackwood - назад...'][index], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('dabbackwood', style: TextStyle(color: Colors.white54)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(['1:12', '1:26', '1:34', '1:29'][index], style: const TextStyle(color: Colors.white54, fontSize: 12)),
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
              // Строка поиска
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Исполнители, песни, тексты и м...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF231C33),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Фильтры
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildChip('Все площадки', true),
                    const SizedBox(width: 8),
                    _buildChip('YouTube', false),
                    const SizedBox(width: 8),
                    _buildChip('Яндекс Музыка', false),
                  ],
                ),
              ),
              
              // Пустое состояние
              const Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Text(
                      'Введите запрос и выберите музыкальную площадку',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
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
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF3EB1E8) : const Color(0xFF231C33),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(color: isActive ? Colors.white : Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }
}
