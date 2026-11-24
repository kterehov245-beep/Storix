import 'dart:async';
import 'dart:io';
import 'dart:ui' show FontFeature, ImageFilter;

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import 'glass.dart';
import 'library_screen.dart'
    show LibraryStore, PlaybackController, TrackArt, hueFor;
import 'lyrics.dart';
import 'main.dart' show Track;

const Color _black = Color(0xFF060607);
const Color _gold = Color(0xFFFFD54F);
final Map<String, Color> _tintCache = {};

/// Сдвиг текста песни в миллисекундах: плюс — строки появляются позже.
int _lyricsOffsetMs = 0;

String _formatTime(Duration d) {
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '${d.inMinutes}:$s';
}

String _clock(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

Color _hueTint(double hue) => HSLColor.fromAHSL(1, hue, 0.45, 0.26).toColor();

/// Оттенок для фона: берём его из обложки (если она есть).
Future<Color?> _imageTint(Track track) async {
  final thumb = track.thumbnail.trim();
  if (thumb.isEmpty) return null;
  try {
    final ImageProvider<Object> provider;
    if (thumb.startsWith('http')) {
      provider = NetworkImage(thumb);
    } else {
      provider = FileImage(File(thumb));
    }
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
  final p = position -
      Duration(milliseconds: _lyricsOffsetMs) +
      const Duration(milliseconds: 250);
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

Widget _infoRow(String key, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(key, style: const TextStyle(color: Colors.white54, fontSize: 12.5)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );

/// Таймер сна: останавливает музыку через заданное время.
class SleepTimer extends ChangeNotifier {
  SleepTimer._();
  static final SleepTimer instance = SleepTimer._();

  Timer? _timer;
  DateTime? endsAt;

  void start(Duration duration, AudioPlayer player) {
    _timer?.cancel();
    endsAt = DateTime.now().add(duration);
    _timer = Timer(duration, () {
      player.pause();
      endsAt = null;
      notifyListeners();
    });
    notifyListeners();
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    endsAt = null;
    notifyListeners();
  }
}

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

// --- ФОН ПЛЕЕРА: обложка, которая плавно размывается книзу ---
class _PlayerBackground extends StatelessWidget {
  final Track track;
  final Color tint;
  const _PlayerBackground({required this.track, required this.tint});

  Widget _generated() {
    final hue = hueFor(track.title);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HSLColor.fromAHSL(1, hue, 0.65, 0.55).toColor(),
            HSLColor.fromAHSL(1, (hue + 40) % 360, 0.70, 0.28).toColor(),
          ],
        ),
      ),
      child: Align(
        alignment: const Alignment(0, -0.5),
        child: Icon(
          Icons.music_note_rounded,
          size: 200,
          color: Colors.white.withAlpha(70),
        ),
      ),
    );
  }

  Widget _art(int cacheWidth) {
    final thumb = track.thumbnail.trim();
    if (thumb.isEmpty) return _generated();
    if (thumb.startsWith('http')) {
      return Image.network(
        thumb,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        cacheWidth: cacheWidth,
        errorBuilder: (_, __, ___) => _generated(),
      );
    }
    return Image.file(
      File(thumb),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      cacheWidth: cacheWidth,
      errorBuilder: (_, __, ___) => _generated(),
    );
  }

  /// Размытая копия обложки, которая «проявляется» между долями from и to.
  Widget _blurLayer(double sigma, double from, double to) {
    return ShaderMask(
      shaderCallback: (rect) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Colors.transparent, Colors.white],
        stops: [from, to],
      ).createShader(rect),
      blendMode: BlendMode.dstIn,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: _art(360),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: tint),
          // Сильно размытая обложка на весь экран.
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
            child: _art(160),
          ),
          // Чёткая обложка сверху, которая книзу размывается ступенями.
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
                stops: [0.0, 0.72, 1.0],
              ).createShader(rect),
              blendMode: BlendMode.dstIn,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _art(1080),
                  _blurLayer(5, 0.28, 0.55),
                  _blurLayer(14, 0.45, 0.80),
                  _blurLayer(30, 0.65, 1.0),
                ],
              ),
            ),
          ),
          // Затемнение: чуть сверху (для времени и батареи) и сильно снизу.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x59000000),
                  Color(0x00000000),
                  Color(0x00000000),
                  Color(0x73000000),
                  Color(0xD0000000),
                ],
                stops: [0.0, 0.12, 0.30, 0.58, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
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
        child: GlassSurface(
          radius: 26,
          blur: 24,
          fillAlpha: 55,
          child: SizedBox(
            height: 68,
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
                                color: Colors.white70,
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
    _lyricsOffsetMs = 0;
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

  // --- Действия из меню и кнопок ---

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

  void _shuffleLibrary() {
    final all = List<Track>.of(LibraryStore.instance.tracks)..shuffle();
    if (all.isEmpty) return;
    PlaybackController.instance.setQueue(all);
    PlaybackController.instance.playAt(0);
  }

  void _openSleepTimer() {
    showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: const Color(0xFF1B1B22),
        title: const Text('Таймер сна'),
        children: [
          for (final minutes in const [15, 30, 45, 60])
            SimpleDialogOption(
              onPressed: () {
                SleepTimer.instance
                    .start(Duration(minutes: minutes), widget.player);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Музыка выключится через $minutes мин'),
                  ),
                );
              },
              child: Text('$minutes минут'),
            ),
          if (SleepTimer.instance.endsAt != null)
            SimpleDialogOption(
              onPressed: () {
                SleepTimer.instance.cancel();
                Navigator.pop(ctx);
              },
              child: const Text('Выключить таймер'),
            ),
        ],
      ),
    );
  }

  void _openLyricsOffset() {
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final seconds = _lyricsOffsetMs / 1000;
          final label =
              '${seconds > 0 ? '+' : ''}${seconds.toStringAsFixed(1)} с';
          return AlertDialog(
            backgroundColor: const Color(0xFF1B1B22),
            title: const Text('Сдвиг текста'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      onPressed: () => setLocal(() => _lyricsOffsetMs -= 500),
                    ),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      onPressed: () => setLocal(() => _lyricsOffsetMs += 500),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Минус: строки появляются раньше.\nПлюс: позже.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => setLocal(() => _lyricsOffsetMs = 0),
                child: const Text('Сбросить'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Готово'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openInfo() {
    final track = _track;
    final duration = widget.player.duration ?? track.duration;
    final isLocal = !track.streamUrl.startsWith('http');
    var size = '';
    if (isLocal) {
      try {
        final mb = File(track.streamUrl).lengthSync() / 1048576;
        size = '${mb.toStringAsFixed(1)} МБ';
      } catch (_) {}
    }
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B1B22),
        title: const Text('Информация о песне'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Название', track.title),
            _infoRow('Исполнитель', track.artist),
            _infoRow('Длительность', _formatTime(duration)),
            _infoRow('Источник', isLocal ? 'Библиотека' : 'SoundCloud'),
            if (size.isNotEmpty) _infoRow('Размер файла', size),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  // --- Меню «⋯» ---

  void _openMenu() {
    final track = _track;
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Закрыть меню',
      barrierColor: Colors.black26,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, _, __) {
        final height = MediaQuery.of(ctx).size.height;
        return SafeArea(
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 20, top: 16, bottom: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 270,
                  maxHeight: height * 0.82,
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: GlassSurface(
                    radius: 34,
                    blur: 30,
                    fillAlpha: 30,
                    child: Container(
                      color: Colors.black.withAlpha(125),
                      child: _buildMenu(ctx, track),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, animation, _, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            alignment: const Alignment(0.9, 0.2),
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildMenu(BuildContext ctx, Track track) {
    final inLibrary = LibraryStore.instance.tracks
        .any((t) => t.streamUrl == track.streamUrl);
    final isFav = LibraryStore.instance.isFavorite(track);
    final timerEnd = SleepTimer.instance.endsAt;

    void run(VoidCallback action) {
      Navigator.pop(ctx);
      action();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 18, 8, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MenuTopAction(
                icon: isFav ? Icons.star_rounded : Icons.star_border_rounded,
                label: 'Нравится',
                color: isFav ? _gold : Colors.white,
                onTap: inLibrary
                    ? () => run(() => LibraryStore.instance.toggleFavorite(track))
                    : null,
              ),
              _MenuTopAction(
                icon: Icons.queue_music_rounded,
                label: 'Очередь',
                onTap: () => run(_openQueue),
              ),
              _MenuTopAction(
                icon: Icons.lyrics_outlined,
                label: 'Текст',
                onTap: () => run(_openLyrics),
              ),
            ],
          ),
          const _MenuDivider(),
          _MenuItem(
            icon: Icons.shuffle_rounded,
            title: 'Перемешать библиотеку',
            onTap: () => run(_shuffleLibrary),
          ),
          const _MenuDivider(),
          _MenuItem(
            icon: Icons.bedtime_outlined,
            title: 'Таймер сна',
            subtitle: timerEnd == null ? null : 'до ${_clock(timerEnd)}',
            onTap: () => run(_openSleepTimer),
          ),
          _MenuItem(
            icon: Icons.tune_rounded,
            title: 'Сдвиг текста',
            onTap: () => run(_openLyricsOffset),
          ),
          const _MenuDivider(),
          _MenuItem(
            icon: Icons.info_outline_rounded,
            title: 'Информация о песне',
            onTap: () => run(_openInfo),
          ),
        ],
      ),
    );
  }

  // --- Части экрана ---

  Widget _buildStar(Track track) {
    return ListenableBuilder(
      listenable: LibraryStore.instance,
      builder: (context, _) {
        final inLibrary = LibraryStore.instance.tracks
            .any((t) => t.streamUrl == track.streamUrl);
        if (!inLibrary) return const SizedBox.shrink();
        final fav = LibraryStore.instance.isFavorite(track);
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GlassButton(
            size: 38,
            iconSize: 20,
            icon: fav ? Icons.star_rounded : Icons.star_border_rounded,
            color: fav ? _gold : Colors.white,
            fillAlpha: 60,
            onPressed: () => LibraryStore.instance.toggleFavorite(track),
          ),
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
            width: 76,
            height: 76,
            child: Padding(
              padding: EdgeInsets.all(22),
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
          iconSize: 76,
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
          iconSize: 28,
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
        final tint = _tint ?? _hueTint(hueFor(track.title));
        final from = track.streamUrl.startsWith('http')
            ? 'Играет из SoundCloud'
            : 'Играет из библиотеки';
        const shadows = [Shadow(blurRadius: 8, color: Colors.black87)];

        return Scaffold(
          backgroundColor: _black,
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragEnd: (d) {
              if ((d.primaryVelocity ?? 0) > 300) Navigator.pop(context);
            },
            child: Stack(
              children: [
                // Фон: обложка, которая плавно размывается книзу.
                Positioned.fill(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: KeyedSubtree(
                      key: ValueKey(track.streamUrl),
                      child: _PlayerBackground(track: track, tint: tint),
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
                            GlassButton(
                              size: 38,
                              iconSize: 20,
                              icon: Icons.more_horiz_rounded,
                              fillAlpha: 60,
                              onPressed: _openMenu,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildLyricLine(),
                        _buildProgress(track),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              iconSize: 58,
                              color: Colors.white,
                              icon: const Icon(Icons.fast_rewind_rounded),
                              onPressed: () => controller.previous(),
                            ),
                            _buildPlayButton(),
                            IconButton(
                              iconSize: 58,
                              color: Colors.white,
                              disabledColor: Colors.white24,
                              icon: const Icon(Icons.fast_forward_rounded),
                              onPressed: controller.hasNext
                                  ? () => controller.next()
                                  : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 26),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              iconSize: 28,
                              color: _lyrics.isEmpty
                                  ? Colors.white38
                                  : Colors.white,
                              icon: const Icon(Icons.lyrics_outlined),
                              onPressed: _openLyrics,
                            ),
                            _buildRepeat(),
                            IconButton(
                              iconSize: 28,
                              color: Colors.white,
                              icon: const Icon(Icons.queue_music_rounded),
                              onPressed: _openQueue,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
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

// --- ЭЛЕМЕНТЫ МЕНЮ ---
class _MenuTopAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _MenuTopAction({
    required this.icon,
    required this.label,
    this.color = Colors.white,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: enabled ? color : Colors.white30),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: enabled ? Colors.white : Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.white),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Divider(height: 1, color: Colors.white12),
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
    return GlassSheet(
      height: MediaQuery.of(context).size.height * 0.88,
      tint: Color.lerp(widget.tint, _black, 0.5)!,
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
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
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
        return GlassSheet(
          height: MediaQuery.of(context).size.height * 0.7,
          tint: const Color(0xFF15151C),
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
                        style: const TextStyle(color: Colors.white60),
                      ),
                      trailing: isCurrent
                          ? const Icon(
                              Icons.graphic_eq_rounded,
                              color: Colors.white,
                            )
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
