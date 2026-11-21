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
        scaffoldBackgroundColor: const Color(0xFF1A1635), // Глубокий фиолетово-синий
      ),
      home: const MainScreen(),
    );
  }
}

// --- МОДЕЛЬ ТРЕКА ---
class Track {
  final String title;
  final String artist;
  final String platform; // 'YT', 'SC', 'YM'
  final String imageUrl;

  Track(this.title, this.artist, this.platform, this.imageUrl);
}

// --- ГЛАВНЫЙ ЭКРАН ---
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Данные для сетки (как на скрине 2)
  final List<Track> _gridTracks = [
    Track('гуль', 'dabbackwood', 'YT', 'https://images.unsplash.com/photo-1578632767115-351597cf2477?q=80&w=200&auto=format&fit=crop'),
    Track('dabbackwood - наза...', 'dabbackwood', 'YT', 'https://images.unsplash.com/photo-1578632767115-351597cf2477?q=80&w=200&auto=format&fit=crop'),
    Track('хирург', 'curdest', 'SC', 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?q=80&w=200&auto=format&fit=crop'),
    Track('Её парень', 'Shluzov', 'YT', 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=200&auto=format&fit=crop'),
    Track('назад в кресты', 'curdest', 'YT', 'https://images.unsplash.com/photo-1578632767115-351597cf2477?q=80&w=200&auto=format&fit=crop'),
    Track('ФРУКТОВЫЙ', 'Unknown', 'YT', 'https://images.unsplash.com/photo-1493225457124-a1a2a5f5646f?q=80&w=200&auto=format&fit=crop'),
  ];

  @override
  Widget build(BuildContext context) {
    // 5 экранов под 5 иконок
    final List<Widget> screens = [
      _buildHomeTab(),
      const Center(child: Text('Сетка', style: TextStyle(fontSize: 24, color: Colors.white54))),
      const Center(child: Text('Библиотека', style: TextStyle(fontSize: 24, color: Colors.white54))),
      const Center(child: Text('Избранное', style: TextStyle(fontSize: 24, color: Colors.white54))),
      const Center(child: Text('Поиск', style: TextStyle(fontSize: 24, color: Colors.white54))),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: screens),

      // --- НИЖНЯЯ ПАНЕЛЬ (Мини-плеер + Навигация) ---
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Мини-плеер (как на скрине 2)
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
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.15)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network('https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=200&auto=format&fit=crop', width: 45, height: 45, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('распять (folk remix)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text('stellla и plateexx', style: TextStyle(color: Colors.white54, fontSize: 13)),
                              ],
                            ),
                          ),
                          const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 35),
                          const SizedBox(width: 8),
                          const Icon(Icons.skip_next_rounded, color: Colors.white, size: 35),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Панель навигации (5 иконок)
              ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavIcon(Icons.home_filled, 0),
                        _buildNavIcon(Icons.grid_view_rounded, 1),
                        _buildNavIcon(Icons.library_music_rounded, 2),
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

  // --- ДИЗАЙН ГЛАВНОГО ЭКРАНА ---
  Widget _buildHomeTab() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFF261C3D), Color(0xFF1A1635), Color(0xFF121016)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 180), // Отступ под плеер
          children: [
            // Шапка с приветствием
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Добрый вечер', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white)),
                  CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    child: const Icon(Icons.person_outline, color: Colors.white),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text('SoundCloud и аддоны: импорт и действия в RX Playa; лайки аккаунта недоступны.', style: TextStyle(color: Colors.white54, fontSize: 11)),
            ),

            // Баннер RX Wave (ИСПРАВЛЕНА ОШИБКА OVERFLOW)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFF5AB6E5), Color(0xFF9A81D7)], // Градиент как на фото
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('RX Wave', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.3)),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Фильтры (Кнопки)
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

            // Сетка карточек (2 колонки, как на скрине 2)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.5, // Делает карточки горизонтальными
                ),
                itemCount: _gridTracks.length,
                itemBuilder: (context, index) {
                  return _buildHorizontalGridCard(_gridTracks[index]);
                },
              ),
            ),

            // Заголовок "Для вас"
            const Padding(
              padding: EdgeInsets.only(left: 20, top: 20, bottom: 10),
              child: Text('Для вас', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            ),

            // Горизонтальная карусель "Для вас"
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _gridTracks.length,
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
                              _gridTracks[index].imageUrl,
                              width: 140, height: 140, fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(_gridTracks[index].title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(_gridTracks[index].artist, style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
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

  // Карточка для сетки (В точности как на фото)
  Widget _buildHorizontalGridCard(Track track) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PlayerScreen())),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2A2442), // Темно-фиолетовый фон карточки
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Обложка слева
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
              child: Image.network(track.imageUrl, width: 70, height: 70, fit: BoxFit.cover),
            ),
            const SizedBox(width: 8),
            // Текст и бейджи справа
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(track.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    // Бейдж платформы
                    _buildPlatformBadge(track.platform),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String text, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF3EB1E8) : const Color(0xFF2A2442),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(color: isActive ? Colors.white : Colors.white70, fontSize: 13)),
    );
  }

  // Бейджи платформ (SC, YT)
  Widget _buildPlatformBadge(String platform) {
    Color color;
    IconData? icon;
    if (platform == 'YT') {
      color = Colors.redAccent;
      icon = Icons.play_arrow;
    } else if (platform == 'SC') {
      color = Colors.orangeAccent;
      icon = Icons.cloud_queue;
    } else {
      color = Colors.yellow;
      icon = Icons.music_note;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
          child: Icon(icon, size: 10, color: color),
        ),
        const SizedBox(width: 4),
        Text(platform, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
      ],
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

// --- ПОЛНОЭКРАННЫЙ ПЛЕЕР (Оставляем как был, он красивый) ---
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
