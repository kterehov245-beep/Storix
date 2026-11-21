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
        scaffoldBackgroundColor: const Color(0xFF1A1625), // Темный фон как в RX
      ),
      home: const MainScreen(),
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

  // Данные для карточек (как на 1 скрине)
  final List<Map<String, String>> _tracks = [
    {'title': 'гуль', 'artist': 'dabbackwood', 'img': 'https://i.pinimg.com/736x/8b/58/5e/8b585e0e3a0e7b5b5c5e5b5e5b5e5b5e.jpg'}, // Заглушка
    {'title': 'dabbackwood - назад...', 'artist': 'dabbackwood', 'img': 'https://i.pinimg.com/736x/8b/58/5e/8b585e0e3a0e7b5b5c5e5b5e5b5e5b5e.jpg'},
    {'title': 'хирург', 'artist': 'curdest', 'img': 'https://i.pinimg.com/736x/8b/58/5e/8b585e0e3a0e7b5b5c5e5b5e5b5e5b5e.jpg'},
    {'title': 'Её парень', 'artist': 'Shluzov', 'img': 'https://i.pinimg.com/736x/8b/58/5e/8b585e0e3a0e7b5b5c5e5b5e5b5e5b5e.jpg'},
    {'title': 'назад в кресты', 'artist': 'curdest', 'img': 'https://i.pinimg.com/736x/8b/58/5e/8b585e0e3a0e7b5b5c5e5b5e5b5e5b5e.jpg'},
    {'title': 'хирург (extended)', 'artist': 'curdest', 'img': 'https://i.pinimg.com/736x/8b/58/5e/8b585e0e3a0e7b5b5c5e5b5e5b5e5b5e.jpg'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF241D35), Color(0xFF1A1625), Color(0xFF121016)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _currentIndex,
            children: [
              // --- ЭКРАН 1: ГЛАВНАЯ (КОПИЯ RX) ---
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 180), // Место под плеер
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Шапка
                    Padding(
                      padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Добрый день', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                          CircleAvatar(
                            backgroundColor: Colors.white.withOpacity(0.1),
                            child: const Icon(Icons.person, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Text('SoundCloud и аддоны: импорт и действия в RX Playa; лайки аккаунта недоступны.', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    ),
                    
                    // Баннер RX Wave
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Container(
                        height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                            colors: [Color(0xFF3EB1E8), Color(0xFF9A6BC6)],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('RX Wave', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                              Container(
                                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.3)),
                                child: const Icon(Icons.pause, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Фильтры
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.8,
                        ),
                        itemCount: _tracks.length,
                        itemBuilder: (context, index) {
                          return Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2438),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                // Обложка
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
                                  child: Container(
                                    width: 60,
                                    color: Colors.pinkAccent, // Заглушка
                                    child: const Icon(Icons.image, color: Colors.white54),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(_tracks[index]['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 4),
                                        // Плашка платформы (как на скрине SC/YT)
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                                              child: const Text('SC', style: TextStyle(fontSize: 8, color: Colors.orange)),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
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
              const Center(child: Text('Библиотека', style: TextStyle(fontSize: 24, color: Colors.white54))),
              const Center(child: Text('Плейлисты', style: TextStyle(fontSize: 24, color: Colors.white54))),
            ],
          ),
        ),
      ),

      // --- МИНИ-ПЛЕЕР И НАВИГАЦИЯ ---
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Мини-плеер (в точности как на скрине)
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PlayerScreen()));
                },
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2438).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: const DecorationImage(
                            image: NetworkImage('https://i.pinimg.com/736x/8b/58/5e/8b585e0e3a0e7b5b5c5e5b5e5b5e5b5e.jpg'), // Картинка с скрина
                            fit: BoxFit.cover,
                          )
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.equalizer, size: 14, color: Colors.white70),
                                SizedBox(width: 4),
                                Text('Её парень', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                            Text('Shluzov', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.pause, color: Colors.white),
                      const SizedBox(width: 8),
                      const Icon(Icons.skip_next, color: Colors.white),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              
              // Навигация
              Container(
                height: 65,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2438).withOpacity(0.95),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String text, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF39A9E5) : const Color(0xFF2A2438),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(color: isActive ? Colors.white : Colors.white70, fontSize: 12)),
    );
  }

  Widget _buildNavIcon(IconData icon, int index) {
    bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Icon(icon, color: isActive ? Colors.white : Colors.white54, size: 26),
      ),
    );
  }
}

// --- ЭКРАН ПЛЕЕРА (ТОЧНАЯ КОПИЯ) ---
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
    // ИСПОЛЬЗУЕМ SingleChildScrollView, ЧТОБЫ УБРАТЬ ЖЕЛТЫЕ ПОЛОСЫ (OVERFLOW)
    return Scaffold(
      backgroundColor: const Color(0xFF1A1625),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Шапка плеера
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.keyboard_arrow_down, size: 30, color: Colors.white),
                    Column(
                      children: const [
                        Text('Playing from SoundCloud', style: TextStyle(fontSize: 11, color: Colors.white54)),
                        SizedBox(height: 4),
                        Icon(Icons.expand_more, size: 14, color: Colors.white54),
                      ],
                    ),
                    const Icon(Icons.more_horiz, color: Colors.white),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Обложка (Квадратная, без вращения!)
              Container(
                height: 300, width: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  image: const DecorationImage(
                    image: NetworkImage('https://i.pinimg.com/736x/8b/58/5e/8b585e0e3a0e7b5b5c5e5b5e5b5e5b5e.jpg'), 
                    fit: BoxFit.cover,
                  )
                ),
              ),
              
              const SizedBox(height: 30),

              // Информация о треке и кнопки справа
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.equalizer, size: 18, color: Colors.white),
                            SizedBox(width: 6),
                            Text('Её парень', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Text('Shluzov', style: TextStyle(fontSize: 16, color: Colors.white54)),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.thumb_down_alt_outlined, color: Colors.white54, size: 22),
                        const SizedBox(width: 20),
                        Icon(Icons.star_border_rounded, color: Colors.white54, size: 26),
                        const SizedBox(width: 20),
                        Icon(Icons.more_horiz, color: Colors.white54, size: 26),
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Текст караоке (разбит на строки)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: RichText(
                    textAlign: TextAlign.left,
                    text: TextSpan(
                      children: _lyrics.map((line) {
                        bool isSinging = _currentTime >= line['start'] && _currentTime <= line['end'];
                        bool isPast = _currentTime > line['end'];
                        return TextSpan(
                          text: "${line['word']} ",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isSinging ? Colors.white : (isPast ? Colors.white38 : Colors.white24),
                            shadows: isSinging ? [const Shadow(color: Colors.cyanAccent, blurRadius: 20)] : [],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              
              // Вторая строчка текста (для красоты)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Её парень лох', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white24)),
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
                  child: Slider(
                    value: _currentTime.clamp(0.0, 5.0),
                    min: 0.0,
                    max: 5.0,
                    onChanged: (val) => setState(() => _currentTime = val),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
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
                  const Icon(Icons.skip_previous_rounded, size: 45, color: Colors.white),
                  GestureDetector(
                    onTap: () => setState(() => _isPlaying = !_isPlaying),
                    child: Container(
                      height: 80, width: 80,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 45, color: Colors.black),
                    ),
                  ),
                  const Icon(Icons.skip_next_rounded, size: 45, color: Colors.white),
                ],
              ),

              const SizedBox(height: 30),

              // Нижние кнопки (комментарии, трансляция, очередь)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Icon(Icons.comment_outlined, color: Colors.white54),
                  const Icon(Icons.headphones_outlined, color: Colors.white54),
                  const Icon(Icons.format_list_bulleted, color: Colors.white54),
                ],
              ),
              
              const SizedBox(height: 20),
              const Text('Redmi Buds 6 Play', style: TextStyle(color: Colors.white30, fontSize: 12)),
              const SizedBox(height: 20), // Отступ снизу, чтобы ничего не перекрывалось
            ],
          ),
        ),
      ),
    );
  }
}
