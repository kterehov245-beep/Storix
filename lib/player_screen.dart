import 'dart:async';
import 'dart:io';
import 'dart:ui' show FontFeature, ImageFilter;

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import 'library_screen.dart'
    show LibraryStore, PlaybackController, TrackArt, hueFor;
import 'lyrics.dart';
import 'main.dart' show Track;

const Color _black = Color(0xFF060607);
final Map<String, Color> _tintCache = {};

String _formatTime(Duration d) {
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '${d.inMinutes}:$s';
}

Color _hueTint(double hue) => HSLColor.fromAHSL(1, hue, 0.45, 0.26).toColor();

/// Оттенок для фона: берём его из обложки (если она есть).
Future<Color?> _imageTint(Track track) async {
  final thumb = track.thumbnail.trim();
  if (thumb.isEmpty) return null;
  try {
    final ImageProvider provider =
        thumb.startsWith('http') ? NetworkImage(thumb) : FileImage(File(thumb));
    final scheme = await ColorScheme.fromImageProvider(
      provider: provider,
      brightness: Brightness.dark,
    );
    final hsl = HSLColor.fromColor(scheme.primary);
    return HSLColor.fromAHSL(
      1,
      hsl.hue,
      hsl.saturation.clamp(0.25, 0.6).toDouble(),
      0.27,
    ).toColor();
  } catch (_) {
    return null;
  }
}

/// Номер строки текста, которая поётся сейчас.
int _lyricIndex(List<LyricLine> lines, Duration position) {
  final p = position + const Duration(milliseconds: 250);
  var index = -1;
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].time <= p) {
      index = i;
    } else {
      break;
    }
  }
  return index;
}

Widget _sheetHandle() => Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white38,
        borderRadius: BorderRadius.circular(2),
      ),
    );

/// Экран плеера выезжает снизу.
Route<void> nowPlayingRoute(Track track, AudioPlayer player) {
  return PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (_, __, ___) => NowPlayingScreen(track: track, player: player),
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
  );
}

// --- МИНИ-ПЛЕЕР ---
class MiniPlayerBar extends StatelessWidget {
  final Track track;
  final AudioPlayer player;
  final bool isLoading;
  const MiniPlayerBar({
    super.key,
    required this.track,
    required this.player,
    required this.isLoading,
  });

  Widget _playButton() {
    return StreamBuilder<PlayerState>(
      stream: player.playerStateStream,
      builder: (context, snapshot) {
        final playing = snapshot.data?.playing ?? false;
        if (isLoading) {
          return const SizedBox(
            width: 48,
            height: 48,
            child: Padding(
              padding: EdgeInsets.all(13),
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            ),
          );
        }
        return IconButton(
          iconSize: 34,
          color: Colors.white,
          icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
          onPressed: () => playing ? player.pause() : player.play(),
        );
      },
    );
  }

  Widget _nextButton() {
    return ListenableBuilder(
      listenable: PlaybackController.instance,
      builder: (context, _) {
        final hasNext = PlaybackController.instance.hasNext;
        return IconButton(
          iconSize: 34,
          color: Colors.white,
          disabledColor: Colors.white24,
          icon: const Icon(Icons.fast_forward_rounded),
          onPressed: hasNext ? () => PlaybackController.instance.next() : null,
        );
      },
    );
  }

  Widget _progressLine() {
    return StreamBuilder<Duration>(
      stream: player.positionStream,
      builder: (context, snapshot) {
        final total = (player.duration ?? track.duration).inMilliseconds;
        final pos = (snapshot.data ?? Duration.zero).inMilliseconds;
        final value =
            total <= 0 ? 0.0 : (pos / total).clamp(0.0, 1.0).toDouble();
        return ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(
            height: 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: Colors.white12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: value,
                    child: Container(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 90 + MediaQuery.of(context).padding.bottom,
      child: GestureDetector(
        onTap: () => Navigator.push(context, nowPlayingRoute(track, player)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(90),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white.withAlpha(50)),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 6, 0),
                    child: Row(
                      children: [
                        TrackArt(track: track, size: 48, radius: 14),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                track.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _playButton(),
                        _nextButton(),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 0,
                    child: _progressLine(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- ПОЛНОЭКРАННЫЙ ПЛЕЕР ---
class NowPlayingScreen extends StatefulWidget {
  final Track track;
  final AudioPlayer player;
  const NowPlayingScreen({
    super.key,
    required this.track,
    required this.player,
  });

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  String? _loadedKey;
  Color? _tint;
  List<LyricLine> _lyrics = const [];

  // Текущий трек берём из контроллера, чтобы экран обновлялся при переключении.
  Track get _track => PlaybackController.instance.current ?? widget.track;

  @override
  void initState() {
    super.initState();
    PlaybackController.instance.addListener(_onTrackChanged);
    _onTrackChanged();
  }

  @override
  void dispose() {
    PlaybackController.instance.removeListener(_onTrackChanged);
    super.dispose();
  }

  void _onTrackChanged() {
    final track = _track;
    if (_loadedKey == track.streamUrl) return;
    _loadedKey = track.streamUrl;
    _lyrics = const [];
    _tint = _tintCache[track.streamUrl];
    unawaited(_loadTint(track));
    unawaited(_loadLyrics(track));
  }

  Future<void> _loadTint(Track track) async {
    if (_tintCache.containsKey(track.streamUrl)) return;
    final tint = await _imageTint(track);
    if (tint == null) return;
    _tintCache[track.streamUrl] = tint;
    if (mounted && _loadedKey == track.streamUrl) {
      setState(() => _tint = tint);
    }
  }

  Future<void> _loadLyrics(Track track) async {
    final lines = await LyricsService.fetch(
      title: track.title,
      artist: track.artist,
      duration: track.duration,
    );
    if (mounted && _loadedKey == track.streamUrl) {
      setState(() => _lyrics = lines);
    }
  }

  void _openLyrics() {
    if (_lyrics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Для этого трека текст не найден')),
      );
      return;
    }
    final track = _track;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LyricsSheet(
        lines: _lyrics,
        player: widget.player,
        track: track,
        tint: _tint ?? _hueTint(hueFor(track.title)),
      ),
    );
  }

  void _openQueue() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _QueueSheet(),
    );
  }

  Widget _glassButton({
    required IconData icon,
    required VoidCallback? onPressed,
    Color color = Colors.white,
  }) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(40),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 24,
        color: color,
        icon: Icon(icon),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildStar(Track track) {
    return ListenableBuilder(
      listenable: LibraryStore.instance,
      builder: (context, _) {
        final inLibrary = LibraryStore.instance.tracks
            .any((t) => t.streamUrl == track.streamUrl);
        if (!inLibrary) return const SizedBox.shrink();
        final fav = LibraryStore.instance.isFavorite(track);
        return _glassButton(
          icon: fav ? Icons.star_rounded : Icons.star_border_rounded,
          color: fav ? const Color(0xFFFFD54F) : Colors.white,
          onPressed: () => LibraryStore.instance.toggleFavorite(track),
        );
      },
    );
  }

  Widget _buildLyricLine() {
    if (_lyrics.isEmpty) return const SizedBox(height: 44);
    return StreamBuilder<Duration>(
      stream: widget.player.positionStream,
      builder: (context, snapshot) {
        final i = _lyricIndex(_lyrics, snapshot.data ?? Duration.zero);
        final text = i >= 0 ? _lyrics[i].text : '♪';
        return InkWell(
          onTap: _openLyrics,
          child: SizedBox(
            height: 44,
            child: Row(
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Align(
                      key: ValueKey(text),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white60),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgress(Track track) {
    return StreamBuilder<Duration>(
      stream: widget.player.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = widget.player.duration ?? track.duration;
        final maxMs = duration.inMilliseconds.toDouble();
        final valueMs =
            position.inMilliseconds.toDouble().clamp(0.0, maxMs).toDouble();
        final remaining =
            duration > position ? duration - position : Duration.zero;
        const timeStyle = TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontFeatures: [FontFeature.tabularFigures()],
        );
        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 8,
                activeTrackColor: Colors.white.withAlpha(235),
                inactiveTrackColor: Colors.white.withAlpha(60),
                thumbShape: SliderComponentShape.noThumb,
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                value: valueMs,
                max: maxMs == 0 ? 1.0 : maxMs,
                onChanged: (v) =>
                    widget.player.seek(Duration(milliseconds: v.toInt())),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatTime(position), style: timeStyle),
                  Text('-${_formatTime(remaining)}', style: timeStyle),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlayButton() {
    return StreamBuilder<PlayerState>(
      stream: widget.player.playerStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final playing = state?.playing ?? false;
        final processing = state?.processingState;
        final busy = processing == ProcessingState.loading ||
            processing == ProcessingState.buffering;
        final completed = processing == ProcessingState.completed;

        if (busy) {
          return const SizedBox(
            width: 88,
            height: 88,
            child: Padding(
              padding: EdgeInsets.all(26),
              child: CircularProgressIndicator(
                strokeWidth: 3.5,
                color: Colors.white,
              ),
            ),
          );
        }

        IconData icon =
            playing ? Icons.pause_rounded : Icons.play_arrow_rounded;
        if (completed) icon = Icons.replay_rounded;

        return IconButton(
          padding: EdgeInsets.zero,
          iconSize: 88,
          color: Colors.white,
          icon: Icon(icon),
          onPressed: () {
            if (completed) {
              widget.player.seek(Duration.zero);
              widget.player.play();
            } else if (playing) {
              widget.player.pause();
            } else {
              widget.player.play();
            }
          },
        );
      },
    );
  }

  Widget _buildRepeat() {
    return StreamBuilder<LoopMode>(
      stream: widget.player.loopModeStream,
      builder: (context, snapshot) {
        final one = (snapshot.data ?? LoopMode.off) == LoopMode.one;
        return IconButton(
          iconSize: 30,
          color: one ? Colors.white : Colors.white60,
          icon: Icon(one ? Icons.repeat_one_rounded : Icons.repeat_rounded),
          onPressed: () =>
              widget.player.setLoopMode(one ? LoopMode.off : LoopMode.one),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PlaybackController.instance,
      builder: (context, _) {
        final track = _track;
        final controller = PlaybackController.instance;
        final width = MediaQuery.of(context).size.width;
        final tint = _tint ?? _hueTint(hueFor(track.title));
        final from = track.streamUrl.startsWith('http')
            ? 'Играет из SoundCloud'
            : 'Играет из библиотеки';
        const shadows = [Shadow(blurRadius: 8, color: Colors.black54)];

        return Scaffold(
          backgroundColor: _black,
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragEnd: (d) {
              if ((d.primaryVelocity ?? 0) > 300) Navigator.pop(context);
            },
            child: Stack(
              children: [
                // Фон: цвет берётся из обложки и уходит в чёрный.
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color.lerp(tint, Colors.white, 0.08)!,
                          tint,
                          _black,
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
                // Обложка во всю ширину, низ плавно растворяется.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: width,
                  child: ShaderMask(
                    shaderCallback: (rect) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, Colors.white, Colors.transparent],
                      stops: [0.0, 0.62, 1.0],
                    ).createShader(rect),
                    blendMode: BlendMode.dstIn,
                    child: TrackArt(
                      track: track,
                      size: width,
                      radius: 0,
                      big: true,
                    ),
                  ),
                ),
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 120,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x66000000), Color(0x00000000)],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white54,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            from,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              shadows: shadows,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 38,
                                    child: _MarqueeText(
                                      key: ValueKey(track.title),
                                      text: track.title,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    track.artist,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            _buildStar(track),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildLyricLine(),
                        _buildProgress(track),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              iconSize: 64,
                              color: Colors.white,
                              icon: const Icon(Icons.fast_rewind_rounded),
                              onPressed: () => controller.previous(),
                            ),
                            _buildPlayButton(),
                            IconButton(
                              iconSize: 64,
                              color: Colors.white,
                              disabledColor: Colors.white24,
                              icon: const Icon(Icons.fast_forward_rounded),
                              onPressed: controller.hasNext
                                  ? () => controller.next()
                                  : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              iconSize: 30,
                              color: _lyrics.isEmpty
                                  ? Colors.white30
                                  : Colors.white,
                              icon: const Icon(Icons.lyrics_outlined),
                              onPressed: _openLyrics,
                            ),
                            _buildRepeat(),
                            IconButton(
                              iconSize: 30,
                              color: Colors.white,
                              icon: const Icon(Icons.queue_music_rounded),
                              onPressed: _openQueue,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// --- БЕГУЩАЯ СТРОКА (длинное название) ---
class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const _MarqueeText({super.key, required this.text, required this.style});

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText> {
  final ScrollController _controller = ScrollController();
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loop());
  }

  Future<void> _loop() async {
    while (!_disposed) {
      await Future<void>.delayed(const Duration(seconds: 2));
      if (_disposed) return;
      if (!_controller.hasClients) continue;
      final max = _controller.position.maxScrollExtent;
      if (max <= 0) continue; // название помещается — не двигаем
      await _controller.animateTo(
        max,
        duration: Duration(milliseconds: (max * 25).round() + 400),
        curve: Curves.linear,
      );
      if (_disposed) return;
      await Future<void>.delayed(const Duration(seconds: 1));
      if (_disposed || !_controller.hasClients) continue;
      _controller.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        colors: [Colors.white, Colors.white, Colors.transparent],
        stops: [0.0, 0.92, 1.0],
      ).createShader(rect),
      blendMode: BlendMode.dstIn,
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Text(
          widget.text,
          maxLines: 1,
          softWrap: false,
          style: widget.style,
        ),
      ),
    );
  }
}

// --- ВЕСЬ ТЕКСТ ПЕСНИ ---
class _LyricsSheet extends StatefulWidget {
  final List<LyricLine> lines;
  final AudioPlayer player;
  final Track track;
  final Color tint;
  const _LyricsSheet({
    required this.lines,
    required this.player,
    required this.track,
    required this.tint,
  });

  @override
  State<_LyricsSheet> createState() => _LyricsSheetState();
}

class _LyricsSheetState extends State<_LyricsSheet> {
  late final List<GlobalKey> _keys =
      List.generate(widget.lines.length, (_) => GlobalKey());
  StreamSubscription<Duration>? _sub;
  int _index = -1;

  @override
  void initState() {
    super.initState();
    _sub = widget.player.positionStream.listen((pos) {
      final i = _lyricIndex(widget.lines, pos);
      if (i == _index) return;
      setState(() => _index = i);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (i < 0 || i >= _keys.length) return;
        final ctx = _keys[i].currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            alignment: 0.3,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = Color.lerp(widget.tint, _black, 0.45)!;
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          _sheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    widget.track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < widget.lines.length; i++)
                    GestureDetector(
                      key: _keys[i],
                      onTap: () => widget.player.seek(widget.lines[i].time),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 250),
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            color: i == _index ? Colors.white : Colors.white38,
                          ),
                          child: Text(widget.lines[i].text),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- ОЧЕРЕДЬ ---
class _QueueSheet extends StatelessWidget {
  const _QueueSheet();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PlaybackController.instance,
      builder: (context, _) {
        final controller = PlaybackController.instance;
        final queue = controller.queue;
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Color(0xFF15151C),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              _sheetHandle(),
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Очередь',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: queue.length,
                  itemBuilder: (context, i) {
                    final t = queue[i];
                    final isCurrent = i == controller.index;
                    return ListTile(
                      leading: TrackArt(track: t, size: 46, radius: 10),
                      title: Text(
                        t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight:
                              isCurrent ? FontWeight.w800 : FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        t.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white54),
                      ),
                      trailing: isCurrent
                          ? const Icon(Icons.graphic_eq_rounded,
                              color: Colors.white)
                          : null,
                      onTap: () => controller.playAt(i),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
