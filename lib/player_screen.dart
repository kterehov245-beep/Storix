import 'dart:ui' show FontFeature, ImageFilter;

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import 'library_screen.dart' show LibraryStore, PlaybackController;
import 'main.dart' show Track;

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
  static const Color _base = Color(0xFF0F0F1B);

  // Текущий трек берём из контроллера, чтобы экран обновлялся при переключении.
  Track get _track => PlaybackController.instance.current ?? widget.track;

  bool get _hasArt => _track.thumbnail.trim().isNotEmpty;

  // Оттенок зависит от названия: один и тот же трек всегда одного цвета.
  double get _hue {
    var hash = 0;
    for (final unit in _track.title.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return (hash % 360).toDouble();
  }

  Color get _accent => HSLColor.fromAHSL(1, _hue, 0.65, 0.55).toColor();

  Color get _accentDark =>
      HSLColor.fromAHSL(1, (_hue + 40) % 360, 0.70, 0.28).toColor();

  Widget _buildBackground() {
    if (_hasArt) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _track.thumbnail,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(color: Colors.black.withAlpha(150)),
          ),
        ],
      );
    }
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.5),
          radius: 1.1,
          colors: [_accent.withAlpha(110), _base],
        ),
      ),
    );
  }

  Widget _buildCover() {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: _hasArt
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_accent, _accentDark],
                ),
          image: _hasArt
              ? DecorationImage(
                  image: NetworkImage(_track.thumbnail),
                  fit: BoxFit.cover,
                  onError: (_, __) {},
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: _accent.withAlpha(100),
              blurRadius: 50,
              offset: const Offset(0, 24),
            ),
          ],
        ),
        child: _hasArt
            ? null
            : const Center(
                child: Icon(
                  Icons.music_note_rounded,
                  size: 96,
                  color: Colors.white70,
                ),
              ),
      ),
    );
  }

  Widget _buildHeart() {
    return ListenableBuilder(
      listenable: LibraryStore.instance,
      builder: (context, _) {
        final track = _track;
        final inLibrary = LibraryStore.instance.tracks
            .any((t) => t.streamUrl == track.streamUrl);
        if (!inLibrary) return const SizedBox.shrink();
        final isFav = LibraryStore.instance.isFavorite(track);
        return IconButton(
          iconSize: 30,
          icon: Icon(
            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFav ? Colors.pinkAccent : Colors.white70,
          ),
          onPressed: () => LibraryStore.instance.toggleFavorite(track),
        );
      },
    );
  }

  Widget _buildProgress() {
    return StreamBuilder<Duration>(
      stream: widget.player.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = widget.player.duration ?? _track.duration;
        final maxMs = duration.inMilliseconds.toDouble();
        final valueMs =
            position.inMilliseconds.toDouble().clamp(0.0, maxMs).toDouble();
        const timeStyle = TextStyle(
          color: Colors.white54,
          fontSize: 12,
          fontFeatures: [FontFeature.tabularFigures()],
        );
        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white24,
                thumbColor: Colors.white,
                overlayColor: Colors.white24,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 16),
              ),
              child: Slider(
                value: valueMs,
                max: maxMs == 0 ? 1.0 : maxMs,
                onChanged: (v) =>
                    widget.player.seek(Duration(milliseconds: v.toInt())),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(position), style: timeStyle),
                  Text(_formatDuration(duration), style: timeStyle),
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
          width: 76,
          height: 76,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: busy
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.black,
                  ),
                )
              : IconButton(
                  iconSize: 44,
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

        return Scaffold(
          backgroundColor: _base,
          body: Stack(
            fit: StackFit.expand,
            children: [
              _buildBackground(),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        iconSize: 34,
                        color: Colors.white,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: _buildCover()),
                        ),
                      ),
                      Row(
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
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    height: 1.15,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  track.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white60,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildHeart(),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildProgress(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            iconSize: 46,
                            color: Colors.white,
                            icon: const Icon(Icons.skip_previous_rounded),
                            onPressed: () => controller.previous(),
                          ),
                          _buildPlayButton(),
                          IconButton(
                            iconSize: 46,
                            color: Colors.white,
                            disabledColor: Colors.white24,
                            icon: const Icon(Icons.skip_next_rounded),
                            onPressed:
                                controller.hasNext ? () => controller.next() : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

String _formatDuration(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$m:$s';
}
