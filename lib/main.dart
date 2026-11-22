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
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF141026), // Очень темный фон
      ),
      home: const MainScreen(),
    );
  }
}

// --- МОДЕЛЬ ТРЕКА ---
class Track {
  final String title;
  final String platform;
  final String imageUrl;

  Track(this.title, this.platform, this.imageUrl);
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Track> _tracks = [
    Track('гуль', 'YT', 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=200&q=80'),
    Track('dabbackwood - наза...', 'YT', 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=200&q=80'),
    Track('хирург', 'SC', 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=200&q=80'),
    Track('Её парень', 'YT', 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=200&q=80'),
    Track('назад в кресты', 'YT', 'https://images.unsplash.com/photo-1493225457124-a1a2a5f5646f?w=200&q=80'),
    Track('ФРУКТОВЫЙ', 'YT', 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=200&q=80'),
  ];

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildHomeTab(),
      const Center(child: Text('Сетка', style: TextStyle(color: Colors.white54))),
      const Center(child: Text('Библиотека', style: TextStyle(color: Colors.white54))),
      const Center(child: Text('Избранное', style: TextStyle(color: Colors.white54))),
      const Center(child: Text('Поиск', style: TextStyle(color: Colors.white54))),
    ];

    return Scaffold(
      extendBody: true, // Позволяет контенту уходить под панели
      body: IndexedStack(index: _currentIndex, children: screens),

      // --- НИЖНЯЯ ПАНЕЛЬ (ПАРЯЩАЯ КАПСУЛА + СТЕКЛО) ---
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Мини-плеер (Стекло)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0), // Сильное размытие
                  child: Container(
                    height: 65,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08), // Полупрозрачный фон
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(_tracks[3].imageUrl, width: 45, height: 45, fit: BoxFit.cover),
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
              
              // Навигация (Стекло)
              ClipRRect(
                borderRadius: BorderRadius.circular(40), // Сильное закругление (капсула)
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavIcon(Icons.home_filled, 0),
                        _buildNavIcon(Icons.grid_view_rounded, 1),
                        _buildNavIcon(Icons.folder_rounded, 2), // Иконка папки
                        _buildNavIcon(Icons.star_rounded, 3),
                        _buildNavIcon(Icons.search_rounded, 4),
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

  // --- ГЛАВНЫЙ ЭКРАН С ЦВЕТНЫМ СВЕЧЕНИЕМ ---
  Widget _buildHomeTab() {
    return Stack(
      children: [
        // 1. Цветные пятна на фоне (чтобы стекло размывало их и было видно эффект)
        Positioned(
          top: -50, left: -50,
          child: Container(
            width: 300, height: 300,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.deepPurple.withOpacity(0.3), boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.3), blurRadius: 100)]),
          ),
        ),
        Positioned(
          bottom: 100, right: -50,
          child: Container(
            width: 250, height: 250,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blueAccent.withOpacity(0.2), boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.2), blurRadius: 100)]),
          ),
        ),
        
        // 2. Основной контент
        SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 200), // Место под плавающие панели
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Добрый вечер', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
                    CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.1),
                      child: const Icon(Icons.person_outline, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text('SoundCloud и аддоны: импорт и действия в RX Playa; лайки аккаунта недоступны.', style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.4)),
              ),

              // Баннер
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft, end: Alignment.centerRight,
                      colors: [Color(0xFF5CB8E6), Color(0xFFB39DDB)], 
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('RX Wave', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.25)),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Фильтры
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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

              // Сетка карточек
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.9, // Сделал карточки приземистее (как на фото)
                  ),
                  itemCount: _tracks.length,
                  itemBuilder: (context, index) {
                    return _buildGridCard(_tracks[index]);
                  },
                ),
              ),

              // Заголовок "Для вас"
              const Padding(
                padding: EdgeInsets.only(left: 20, top: 10, bottom: 12),
                child: Text('Для вас', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
              ),

              // Карусель
              SizedBox(
                height: 170,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _tracks.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 150,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              _tracks[index].imageUrl,
                              width: 150, height: 130, fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(_tracks[index].title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
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

  // --- КАРТОЧКА СЕТКИ (БЕЗ ТЕНИ, ПЛОТНАЯ) ---
  Widget _buildGridCard(Track track) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF231C33).withOpacity(0.8), // Фон карточки (чуть прозрачный)
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
            child: Image.network(track.imageUrl, width: 75, height: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, height: 1.2),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                _buildPlatformBadge(track.platform),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String text, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF3EB1E8) : const Color(0xFF231C33),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(color: isActive ? Colors.white : Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildPlatformBadge(String platform) {
    Color color = platform == 'YT' ? Colors.redAccent : Colors.orangeAccent;
    IconData icon = platform == 'YT' ? Icons.play_arrow_rounded : Icons.cloud_queue_rounded;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(platform, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  // Убрал кружки вокруг иконок. Теперь просто меняется цвет.
  Widget _buildNavIcon(IconData icon, int index) {
    bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Icon(
        icon, 
        color: isActive ? Colors.white : Colors.white38, 
        size: 28, // Иконки чуть крупнее
      ),
    );
  }
}

// --- ПОЛНОЭКРАННЫЙ ПЛЕЕР (Оставляем без изменений) ---
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  double _currentTime = 0.0;
  bool _isPlaying = true;
  Timer? _timer;

  final List<Map<String, dynamic>> _lyrics = [
    {'word': 'Её', 'start': 0.0, 'end': 0.8},
    {'word': 'парень', 'start': 0.8, 'end': 1.5},
    {'word': 'лох,', 'start': 1.5, 'end': 2.5},
    {'word': 'она', 'start': 2.5, 'end': 3.2},
    {'word': 'любит', 'start': 3.2, 'end': 3.9},
    {'word': 'меня', 'start': 3.9, 'end': 4.5},
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_isPlaying) {
        setState(() {
          _currentTime += 0.1;
          if (_currentTime > 5.0) _currentTime = 0.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF2A1B4D), Color(0xFF0F0C1B)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_down, size: 32),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text('Playing from SoundCloud', style: TextStyle(fontSize: 12, color: Colors.white54)),
                        IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 300, width: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.pinkAccent.withOpacity(0.3), blurRadius: 40, offset: const Offset(0, 20))
                      ],
                      image: const DecorationImage(
                        image: NetworkImage('https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=500&auto=format&fit=crop'), 
                        fit: BoxFit.cover,
                      )
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Column(
                    children: [
                      Text('Её парень', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      SizedBox(height: 6),
                      Text('Shluzov', style: TextStyle(fontSize: 16, color: Colors.white54)),
                    ],
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 60,
                    child: Center(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: _lyrics.map((line) {
                            bool isSinging = _currentTime >= line['start'] && _currentTime <= line['end'];
                            bool isPast = _currentTime > line['end'];
                            return TextSpan(
                              text: "${line['word']} ",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isSinging ? Colors.cyanAccent : (isPast ? Colors.white38 : Colors.white24),
                                shadows: isSinging ? [const Shadow(color: Colors.cyanAccent, blurRadius: 20)] : [],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4.0,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.white,
                    ),
                    child: Slider(
                      value: _currentTime.clamp(0.0, 5.0),
                      min: 0.0,
                      max: 5.0,
                      onChanged: (val) => setState(() => _currentTime = val),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('0:53', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        Text('-0:18', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const Icon(Icons.shuffle, color: Colors.white54),
                      const Icon(Icons.skip_previous_rounded, size: 45),
                      GestureDetector(
                        onTap: () => setState(() => _isPlaying = !_isPlaying),
                        child: Container(
                          height: 80, width: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.2), blurRadius: 20)]
                          ),
                          child: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 45, color: Colors.black),
                        ),
                      ),
                      const Icon(Icons.skip_next_rounded, size: 45),
                      const Icon(Icons.repeat, color: Colors.white54),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(icon: const Icon(Icons.thumb_down_alt_outlined, color: Colors.white54), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.chat_bubble_outline, color: Colors.white54), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.share_outlined, color: Colors.white54), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.queue_music, color: Colors.white54), onPressed: () {}),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
