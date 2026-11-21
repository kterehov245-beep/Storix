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
        scaffoldBackgroundColor: const Color(0xFF0F0C1B), // Глубокий фон
      ),
      home: const MainScreen(),
    );
  }
}

// --- МОДЕЛЬ ТРЕКА ---
class Track {
  final String title;
  final String artist;
  final String platform; // SC, YT, YM
  final List<Color> gradientColors;

  Track(this.title, this.artist, this.platform, this.gradientColors);
}

// --- ГЛАВНЫЙ ЭКРАН ---
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Наши рандомные треки с разными цветами
  final List<Track> _recentTracks = [
    Track('Её парень', 'Shluzov', 'SC', [Colors.pinkAccent, Colors.deepPurple]),
    Track('гуль', 'dabbackwood', 'YT', [Colors.orangeAccent, Colors.redAccent]),
    Track('хирург', 'curdest', 'SC', [Colors.teal, Colors.blueAccent]),
    Track('назад в кресты', 'curdest', 'YM', [Colors.yellow, Colors.orange]),
  ];

  final List<Track> _recommendations = [
    Track('Микс дня', 'Подборка для тебя', 'YM', [Colors.purpleAccent, Colors.indigo]),
    Track('Новинки', 'Свежие релизы', 'SC', [Colors.cyan, Colors.blue]),
    Track('Хиты', 'Топ 100', 'YT', [Colors.red, Colors.pink]),
    Track('Спокойное', 'Для сна и отдыха', 'SC', [Colors.deepPurple, Colors.black]),
  ];

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildHomeTab(),
      const Center(child: Text('Библиотека', style: TextStyle(fontSize: 24, color: Colors.white54))),
      const Center(child: Text('Плейлисты', style: TextStyle(fontSize: 24, color: Colors.white54))),
      const Center(child: Text('Избранное', style: TextStyle(fontSize: 24, color: Colors.white54))),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: screens),

      // --- НИЖНЯЯ ПАНЕЛЬ (Стекло) ---
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Мини-плеер
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PlayerScreen())),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                    child: Container(
                      height: 65,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          // Градиентная обложка мини-плеера
                          Container(
                            width: 45, height: 45,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: LinearGradient(colors: [Colors.pinkAccent, Colors.deepPurple]),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Её парень', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text('Shluzov', style: TextStyle(color: Colors.white54, fontSize: 13)),
                              ],
                            ),
                          ),
                          const Icon(Icons.pause_rounded, color: Colors.white, size: 30),
                          const SizedBox(width: 10),
                          const Icon(Icons.skip_next_rounded, color: Colors.white, size: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Навигация
              ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavIcon(Icons.home_filled, 0),
                        _buildNavIcon(Icons.grid_view_rounded, 1),
                        _buildNavIcon(Icons.album_rounded, 2),
                        _buildNavIcon(Icons.star_rounded, 3),
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

  // --- ДИЗАЙН ГЛАВНОГО ЭКРАНА ---
  Widget _buildHomeTab() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1E1338), Color(0xFF0F0C1B)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 180),
          children: [
            // Шапка
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Добрый день', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                  CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    child: const Icon(Icons.person_outline, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Большой баннер (как в RX, но наш)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFF6B4EFF), Color(0xFF3B2D7D)],
                  ),
                  boxShadow: [BoxShadow(color: const Color(0xFF6B4EFF).withOpacity(0.3), blurRadius: 20)],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Твой личный саундтрек', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 8),
                      const Text('Обновлено сегодня', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const Spacer(),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.black),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),

            // Раздел 1: Горизонтальная карусель
            const Padding(
              padding: EdgeInsets.only(left: 20, top: 20, bottom: 12),
              child: Text('Недавно прослушано', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _recentTracks.length,
                itemBuilder: (context, index) {
                  return _buildHorizontalCard(_recentTracks[index]);
                },
              ),
            ),

            // Раздел 2: Сетка рекомендаций
            const Padding(
              padding: EdgeInsets.only(left: 20, top: 30, bottom: 12),
              child: Text('Специально для тебя', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 0.85,
                ),
                itemCount: _recommendations.length,
                itemBuilder: (context, index) {
                  return _buildGridCard(_recommendations[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Карточка для горизонтальной карусели
  Widget _buildHorizontalCard(Track track) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PlayerScreen())),
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                // Градиентная обложка
                Container(
                  height: 140, width: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: track.gradientColors),
                  ),
                ),
                // Значок платформы (SC, YT...)
                Positioned(
                  bottom: 8, right: 8,
                  child: _buildPlatformBadge(track.platform),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(track.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(track.artist, style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  // Карточка для сетки (2 колонки)
  Widget _buildGridCard(Track track) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PlayerScreen())),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: track.gradientColors),
                    ),
                  ),
                  Positioned(
                    bottom: 8, right: 8,
                    child: _buildPlatformBadge(track.platform),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(track.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(track.artist, style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Виджет значка платформы
  Widget _buildPlatformBadge(String platform) {
    Color color;
    String text;
    if (platform == 'SC') {
      color = Colors.orangeAccent; text = 'SC';
    } else if (platform == 'YT') {
      color = Colors.redAccent; text = 'YT';
    } else {
      color = Colors.yellow; text = 'YM';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildNavIcon(IconData icon, int index) {
    bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.15) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isActive ? Colors.white : Colors.white54, size: 26),
      ),
    );
  }
}

// --- ПОЛНОЭКРАННЫЙ ПЛЕЕР (ОСТАЛСЯ КРАСИВЫМ) ---
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
                  // Шапка
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_down, size: 32),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text('Сейчас играет', style: TextStyle(fontSize: 12, color: Colors.white54, letterSpacing: 1.2)),
                        IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Обложка (градиент)
                  Container(
                    height: 300, width: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.pinkAccent.withOpacity(0.3), blurRadius: 40, offset: const Offset(0, 20))
                      ],
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight, 
                        colors: [Colors.pinkAccent, Colors.deepPurple]
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),

                  // Инфо о треке и бейдж
                  Column(
                    children: [
                      const Text('Её парень', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Shluzov', style: TextStyle(fontSize: 16, color: Colors.white54)),
                          const SizedBox(width: 8),
                          _buildPlatformBadge('SC'),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Караоке текст
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

                  // Слайдер
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
                  
                  // Тайминги
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

                  // Управление
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

                  // Доп кнопки
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

  // Бейдж (дублируется для плеера)
  Widget _buildPlatformBadge(String platform) {
    Color color = platform == 'SC' ? Colors.orangeAccent : (platform == 'YT' ? Colors.redAccent : Colors.yellow);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(platform, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
