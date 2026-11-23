import 'dart:ui' show FontFeature, ImageFilter;

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import 'library_screen.dart' show LibraryStore, PlaybackController;
import 'main.dart' show Track;

const Color _base = Color(0xFF0F0F1B);

// --- ЦВЕТ ТРЕКА ---
// Оттенок зависит от названия: один и тот же трек всегда одного цвета.
double _hueFor(String title) {
  var hash = 0;
  for (final unit in title.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return (hash % 360).toDouble();
}

Color _accentFor(String title) =>
    HSLColor.fromAHSL(1, _hueFor(title), 0.65, 0.55).toColor();

Color _accentDarkFor(String title) =>
    HSLColor.fromAHSL(1, (_hueFor(title) + 40) % 360, 0.70, 0.28).toColor();

String _formatTime(Duration d) {
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '${d.inMinutes}:$s';
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

// --- НАРИСОВАННАЯ ОБЛОЖКА (для треков без картинки) ---
class _GeneratedArt extends StatelessWidget {
  final String title;
  final double iconSize;
  final bool big;
  const _GeneratedArt({
    required this.title,
    required this.iconSize,
    this.big = false,
  });

  Widget _blob(double size, int alpha) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withAlpha(alpha),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_accentFor(title), _accentDarkFor(title)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (big) Positioned(top: -90, right: -70, child: _blob(280, 34)),
          if (big) Positioned(bottom: 40, left: -100, child: _blob(320, 22)),
          Center(
            child: Icon(
              Icons.music_note_rounded,
              size: iconSize,
              color: Colors.white.withAlpha(big ? 80 : 210),
            ),
          ),
        ],
      ),
    );
  }
}

/// Маленькая обложка трека (для мини-плеера, списков).
class TrackArt extends StatelessWidget {
  final Track track;
  final double size;
  final double radius;
  const TrackArt({
    super.key,
    required this.track,
    required this.size,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final generated = _GeneratedArt(title: track.title, iconSize: size * 0.5);
    final hasArt = track.thumbnail.trim().isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: hasArt
            ? Image.network(
                track.thumbnail,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => generated,
              )
            : generated,
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
          icon: const Icon(Icons.skip_next_rounded),
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
                color: Colors.white.withAlpha(24),
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
  // Текущий трек берём из контроллера, чтобы экран обновлялся при переключении.
  Track get _track => PlaybackController.instance.current ?? widget.track;

  Widget _glassButton({
    required IconData icon,
    required VoidCallback? onPressed,
    Color color = Colors.white,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(36),
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

  Widget _buildArt(Track track, double height) {
    final hasArt = track.thumbnail.trim().isNotEmpty;
    final generated =
        _GeneratedArt(title: track.title, iconSize: 200, big: true);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasArt)
            Image.network(
              track.thumbnail,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => generated,
            )
          else
            generated,
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x440F0F1B), Color(0x000F0F1B), _base],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeart(Track track) {
    return ListenableBuilder(
      listenable: LibraryStore.instance,
      builder: (context, _) {
        final inLibrary = LibraryStore.instance.tracks
            .any((t) => t.streamUrl == track.streamUrl);
        if (!inLibrary) return const SizedBox.shrink();
        final isFav = LibraryStore.instance.isFavorite(track);
        return _glassButton(
          icon: isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: isFav ? Colors.pinkAccent : Colors.white,
          onPressed: () => LibraryStore.instance.toggleFavorite(track),
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
        final remaining = duration > position ? duration - position : Duration.zero;
        const timeStyle = TextStyle(
          color: Colors.white60,
          fontSize: 13,
          fontFeatures: [FontFeature.tabularFigures()],
        );
        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 6,
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white24,
                thumbColor: Colors.white,
                overlayColor: Colors.white24,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 6),
              ),
              child: Slider(
                value: valueMs,
                max: maxMs == 0 ? 1.0 : maxMs,
                onChanged: (v) =>
                    widget.player.seek(Duration(milliseconds: v.toInt())),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
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

        IconData icon =
            playing ? Icons.pause_rounded : Icons.play_arrow_rounded;
        if (completed) icon = Icons.replay_rounded;

        return Container(
          width: 84,
          height: 84,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: busy
              ? const Padding(
                  padding: EdgeInsets.all(27),
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.black,
                  ),
                )
              : IconButton(
                  iconSize: 50,
                  color: Colors.black,
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
                ),
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
        final size = MediaQuery.of(context).size;
        final fromLabel = track.streamUrl.startsWith('http')
            ? 'Играет из SoundCloud'
            : 'Играет из библиотеки';

        return Scaffold(
          backgroundColor: _base,
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragEnd: (details) {
              if ((details.primaryVelocity ?? 0) > 300) {
                Navigator.pop(context);
              }
            },
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildArt(track, size.height * 0.62),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _glassButton(
                              icon: Icons.keyboard_arrow_down_rounded,
                              onPressed: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: Text(
                                fromLabel,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 44),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    track.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      height: 1.12,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    track.artist,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            _buildHeart(track),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildProgress(track),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              iconSize: 52,
                              color: Colors.white,
                              icon: const Icon(Icons.skip_previous_rounded),
                              onPressed: () => controller.previous(),
                            ),
                            _buildPlayButton(),
                            IconButton(
                              iconSize: 52,
                              color: Colors.white,
                              disabledColor: Colors.white24,
                              icon: const Icon(Icons.skip_next_rounded),
                              onPressed: controller.hasNext
                                  ? () => controller.next()
                                  : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
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
