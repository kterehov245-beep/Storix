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
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Глубокий темный
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurpleAccent,
          brightness: Brightness.dark,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

// --- ГЛАВНЫЙ ЭКРАН С НАВИГАЦИЕЙ ---
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Данные для карточек на главном экране
  final List<Map<String, String>> _recentTracks = [
    {'title': 'Её парень', 'artist': 'Shluzov', 'time': '1:29'},
    {'title': 'гуль', 'artist': 'dabbackwood', 'time': '2:15'},
    {'title': 'хирург', 'artist': 'SOURCE', 'time': '3:05'},
    {'title': 'назад в кресты', 'artist': 'curdest', 'time': '1:52'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2D1B4E), Color(0xFF1E1B2E), Color(0xFF0F172A)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _currentIndex,
            children: [
              // Экран 1: Главная
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 160), // Отступ для плеера и меню
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'Добрый день',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text('Недавно прослушано', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.5,
                      ),
                      itemCount: _recentTracks.length,
                      itemBuilder: (context, index) {
                        return _buildTrackCard(_recentTracks[index]);
                      },
                    ),
                  ],
                ),
              ),
              // Экран 2: Заглушка (Библиотека)
              const Center(child: Text('Библиотека', style: TextStyle(fontSize: 24, color: Colors.white54))),
              // Экран 3: Заглушка (Плейлисты)
              const Center(child: Text('Плейлисты', style: TextStyle(fontSize: 24, color: Colors.white54))),
              // Экран 4: Заглушка (Избранное)
              const Center(child: Text('Избранное', style: TextStyle(fontSize: 24, color: Colors.white54))),
            ],
          ),
        ),
      ),
      
      // Нижняя часть: Мини-плеер + Навигация
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- МИНИ-ПЛЕЕР (Liquid Glass) ---
              GestureDetector(
                onTap: () {
                  Navigator.push(context, PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const PlayerScreen(),
                    transitionsBuilder: (_, animation, __, child) {
                      return SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(animation),
                        child: child,
                      );
                    },
                  ));
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                    child: Container(
                      height: 70,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50, height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(colors: [Colors.pinkAccent, Colors.purple]),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Её парень', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                                Text('Shluzov', style: TextStyle(color: Colors.white54, fontSize: 13)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.play_arrow_rounded, size: 40, color: Colors.white),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // --- ПАНЕЛЬ НАВИГАЦИИ (Liquid Glass) ---
              ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
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

  Widget _buildTrackCard(Map<String, String> track) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(topLeft: Radius.circular(11), bottomLeft: Radius.circular(11)),
              gradient: LinearGradient(colors: [Colors.deepPurple, Colors.indigo]),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(track['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(track['artist']!, style: const TextStyle(color: Colors.white54, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index) {
    bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.15) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isActive ? Colors.white : Colors.white54, size: 26),
      ),
    );
  }
}

// --- ИДЕАЛЬНЫЙ ПОЛНОЭКРАННЫЙ ПЛЕЕР ---
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with SingleTickerProviderStateMixin {
  double _currentTime = 0.0;
  final double _totalDuration = 6.0;
  bool _isPlaying = true;
  Timer? _timer;
  late AnimationController _rotationController;

  // Караоке текст
  final List<Map<String, dynamic>> _lyrics = [
    {'word': 'Её', 'start': 0.0, 'end': 0.8},
    {'word': 'парень', 'start': 0.8, 'end': 1.5},
    {'word': 'лох,', 'start': 1.5, 'end': 2.5},
    {'word': 'она', 'start': 2.5, 'end': 3.2},
    {'word': 'любит', 'start': 3.2, 'end': 3.9},
    {'word': 'меня', 'start': 3.9, 'end': 4.5},
    {'word': 'сильно', 'start': 4.5, 'end': 5.5},
  ];

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_isPlaying) {
        setState(() {
          _currentTime += 0.1;
          if (_currentTime > _totalDuration) {
            _currentTime = 0.0;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _rotationController.dispose();
    super.dispose();
  }

  String _formatTime(double time) {
    int seconds = time.toInt();
    return '0:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 32, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          children: [
            Text('Playing from SoundCloud', style: TextStyle(fontSize: 11, color: Colors.white70)),
            Text('Shluzov - Её парень', style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.more_horiz, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: Container(
        // Красивый размытый фон (имитация обложки)
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF5C2E71), Color(0xFF1E1B2E), Color(0xFF0F172A)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Анимированная обложка с тенью
                AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationController.value * 2 * 3.14159, // Медленное вращение как у винила
                      child: Container(
                        height: 300, width: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pinkAccent.withOpacity(0.4),
                              blurRadius: 50,
                              spreadRadius: 10,
                            )
                          ],
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                            colors: [Colors.pinkAccent, Colors.deepPurple],
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.music_note, size: 80, color: Colors.white54),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 50),
                
                // --- КАРАОКЕ ТЕКСТ ---
                SizedBox(
                  height: 120, // Фиксированная высота, чтобы не прыгал интерфейс
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
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: isSinging ? Colors.white : (isPast ? Colors.white70 : Colors.white30),
                              shadows: isSinging ? [
                                const Shadow(color: Colors.cyanAccent, blurRadius: 20),
                                const Shadow(color: Colors.cyanAccent, blurRadius: 40),
                              ] : [],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // --- ПОЛОСА ПРОГРЕССА ---
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
                    value: _currentTime.clamp(0.0, _totalDuration),
                    min: 0.0,
                    max: _totalDuration,
                    onChanged: (val) {
                      setState(() { _currentTime = val; });
                    },
                  ),
                ),
                
                // Тайминги
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatTime(_currentTime), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      Text(_formatTime(_totalDuration), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // --- КНОПКИ УПРАВЛЕНИЯ ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(icon: const Icon(Icons.shuffle, color: Colors.white54), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.skip_previous_rounded, size: 45, color: Colors.white), onPressed: () {}),
                    
                    // Главная кнопка Play/Pause
                    GestureDetector(
                      onTap: () {
                        setState(() { _isPlaying = !_isPlaying; });
                        if (_isPlaying) {
                          _rotationController.repeat();
                        } else {
                          _rotationController.stop();
                        }
                      },
                      child: Container(
                        height: 80, width: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)
                          ]
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          size: 45, color: Colors.black87,
                        ),
                      ),
                    ),
                    
                    IconButton(icon: const Icon(Icons.skip_next_rounded, size: 45, color: Colors.white), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.repeat, color: Colors.white54), onPressed: () {}),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Кнопка "Поделиться / Лайк"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(icon: const Icon(Icons.favorite_border, color: Colors.white54), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.share_outlined, color: Colors.white54), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.download_outlined, color: Colors.white54), onPressed: () {}),
                  ],
                ),
                
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
