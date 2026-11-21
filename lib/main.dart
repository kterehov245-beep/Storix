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
      backgroundColor: const Color(0xFF1E1B2E),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const PlayerScreen()));
          },
          child: const Text('Открыть плеер'),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: const Color(0xFF2C2A3B),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Icon(Icons.home_filled, color: _currentIndex == 0 ? Colors.white : Colors.white54),
              Icon(Icons.grid_view_rounded, color: _currentIndex == 1 ? Colors.white : Colors.white54),
              Icon(Icons.album_rounded, color: _currentIndex == 2 ? Colors.white : Colors.white54),
              Icon(Icons.star_rounded, color: _currentIndex == 3 ? Colors.white : Colors.white54),
              Icon(Icons.search_rounded, color: _currentIndex == 4 ? Colors.white : Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  double _currentTime = 0.0;
  final List<Map<String, dynamic>> _lyrics = [
    {'word': 'Её', 'start': 0.0, 'end': 0.8},
    {'word': 'парень', 'start': 0.8, 'end': 1.5},
    {'word': 'лох,', 'start': 1.5, 'end': 2.5},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(title: const Text('Плеер')),
      body: Center(
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: _lyrics.map((line) {
              bool isSinging = _currentTime >= line['start'] && _currentTime <= line['end'];
              return TextSpan(
                text: "${line['word']} ",
                style: TextStyle(
                  fontSize: 30,
                  color: isSinging ? Colors.cyanAccent : Colors.white,
                ),
              );
            }).toList(),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() { _currentTime += 0.5; if(_currentTime > 3) _currentTime = 0; });
        },
        child: const Icon(Icons.play_arrow),
      ),
    );
  }
}
