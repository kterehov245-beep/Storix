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
        scaffoldBackgroundColor: const Color(0xFF0F0C1B), // Глубокий космический фон
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9D4EDD), // Фиолетовый акцент
          brightness: Brightness.dark,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

// --- ГЛАВНЫЙ ЭКРАН ---
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Треки для главной страницы
  final List<Map<String, String>> _tracks = [
    {'title': 'Её парень', 'artist': 'Shluzov', 'img': 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=200&auto=format&fit=crop'},
    {'title': 'гуль', 'artist': 'dabbackwood', 'img': 'https://images.unsplash.com/photo-1493225457124-a1a2a5f5646f?q=80&w=200&auto=format&fit=crop'},
    {'title': 'хирург', 'artist': 'curdest', 'img': 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?q=80&w=200&auto=format&fit=crop'},
    {'title': 'назад в кресты', 'artist': 'SOURCE', 'img': 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?q=80&w=200&auto=format&fit=crop'},
  ];

  @override
  Widget build(BuildContext context) {
    // ВАЖНО: Здесь 4 экрана, чтобы не было красного экрана при нажатии на 4-ю иконку
    final List<Widget> screens = [
      _buildHomeTab(),
      const Center(child: Text('Библиотека', style: TextStyle(fontSize: 24, color: Colors.white54))),
      const Center(child: Text('Плейлисты', style: TextStyle(fontSize: 24, color: Colors.white54))),
      const Center(child: Text('Избранное', style: TextStyle(fontSize: 24, color: Colors.white54))),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),

      // --- НИЖНЯЯ ПАНЕЛЬ ---
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
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(_tracks[0]['img']!, width: 45, height: 45, fit: BoxFit.cover),
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
              
              // Панель навигации
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
          padding: const EdgeInsets.only(bottom: 180), // Отступ под плеер
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Добрый день', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                  CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    child: const Icon(Icons.person_outline, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text('Недавно прослушано', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            
            // Горизонтальный список больших обложек (Стиль Spotify)
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _tracks.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PlayerScreen())),
                    child: Container(
                      width: 140,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              _tracks[index]['img']!,
                              width: 140, height: 140, fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(_tracks[index]['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(_tracks[index]['artist']!, style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text('Сделано для тебя', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),

            // Вертикальный список (Стиль современных плейлистов)
            ..._tracks.map((track) {
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(track['img']!, width: 55, height: 55, fit: BoxFit.cover),
                ),
                title: Text(track['title']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(track['artist']!, style: const TextStyle(color: Colors.white54)),
                trailing: const Icon(Icons.more_vert, color: Colors.white54),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PlayerScreen())),
              );
            }),
          ],
        ),
      ),
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

// --- ПОЛНОЭКРАННЫЙ ПЛЕЕР ---
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
          // Оборачиваем в ScrollView, чтобы 100% не было желтых полос!
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  // Шапка плеера
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

                  // Большая обложка с тенью
                  Container(
                    height: 300, width: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, offset: const Offset(0, 15))
                      ],
                      image: const DecorationImage(
                        image: NetworkImage('https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=500&auto=format&fit=crop'), 
                        fit: BoxFit.cover,
                      )
                    ),
                  ),
                  
                  const SizedBox(height: 40),

                  // Название и исполнитель
                  const Column(
                    children: [
                      Text('Её парень', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      SizedBox(height: 6),
                      Text('Shluzov', style: TextStyle(fontSize: 16, color: Colors.white54)),
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

                  // Полоса прогресса
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

                  // Кнопки управления
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
                            boxShadow: [
                              BoxShadow(color: Colors.white.withOpacity(0.2), blurRadius: 20)
                            ]
                          ),
                          child: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 45, color: Colors.black),
                        ),
                      ),
                      const Icon(Icons.skip_next_rounded, size: 45),
                      const Icon(Icons.repeat, color: Colors.white54),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Доп. кнопки
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
                  const Text('Наушники подключены', style: TextStyle(color: Colors.white30, fontSize: 12)),
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
