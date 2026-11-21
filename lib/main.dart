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
      theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Позволяет панели красиво парить над контентом
      body: Container(
        // Красивый градиентный фон (как на твоих скриншотах)
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2D1B4E), Color(0xFF1E1B2E), Color(0xFF0F172A)],
          ),
        ),
        child: Center(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PlayerScreen()));
            },
            child: const Text('Открыть плеер', style: TextStyle(fontSize: 18)),
          ),
        ),
      ),
      
      // Нижняя часть (Мини-плеер + Навигация)
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- МИНИ-ПЛЕЕР (Стекло) ---
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0), // Размытие
                  child: Container(
                    height: 65,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
                    ),
                    child: Row(
                      children: [
                        // Заглушка обложки (градиент)
                        Container(
                          width: 45, height: 45,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: const LinearGradient(colors: [Colors.pinkAccent, Colors.purple]),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Её парень', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis),
                              Text('Shluzov', style: TextStyle(color: Colors.white54, fontSize: 13)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.play_arrow_rounded, size: 35),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const PlayerScreen()));
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // --- НАВИГАЦИЯ (Стекло) ---
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

  Widget _buildNavIcon(IconData icon, int index) {
    bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
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

// --- ЭКРАН ПОЛНОЭКРАННОГО ПЛЕЕРА ---
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  double _currentTime = 0.0;
  
  // Наш текст с таймингами
  final List<Map<String, dynamic>> _lyrics = [
    {'word': 'Её', 'start': 0.0, 'end': 0.8},
    {'word': 'парень', 'start': 0.8, 'end': 1.5},
    {'word': 'лох,', 'start': 1.5, 'end': 2.5},
    {'word': 'она', 'start': 2.5, 'end': 3.2},
    {'word': 'любит', 'start': 3.2, 'end': 3.9},
    {'word': 'меня', 'start': 3.9, 'end': 4.5},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1B2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Сейчас играет', style: TextStyle(fontSize: 14, color: Colors.white54)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Большая обложка (заглушка)
            Container(
              height: 280, width: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.pinkAccent.withOpacity(0.3), blurRadius: 40, spreadRadius: 5)],
                gradient: const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Colors.pinkAccent, Colors.deepPurple],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Караоке текст
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: _lyrics.map((line) {
                  bool isSinging = _currentTime >= line['start'] && _currentTime <= line['end'];
                  bool isPast = _currentTime > line['end'];
                  return TextSpan(
                    text: "${line['word']} ",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isSinging ? Colors.cyanAccent : (isPast ? Colors.white54 : Colors.white30),
                      shadows: isSinging ? [const Shadow(color: Colors.cyanAccent, blurRadius: 15)] : [],
                    ),
                  );
                }).toList(),
              ),
            ),

            const Spacer(),

            // Кнопки управления
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Icon(Icons.shuffle, color: Colors.white54),
                const Icon(Icons.skip_previous_rounded, size: 40),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentTime += 0.5; 
                      if (_currentTime > 5.0) _currentTime = 0.0;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.deepPurpleAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded, size: 40),
                  ),
                ),
                const Icon(Icons.skip_next_rounded, size: 40),
                const Icon(Icons.repeat, color: Colors.white54),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
