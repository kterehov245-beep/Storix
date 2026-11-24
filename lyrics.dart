import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Одна строка песни и время, когда она начинается.
class LyricLine {
  final Duration time;
  final String text;
  const LyricLine(this.time, this.text);
}

/// Разбирает текст в формате LRC: "[01:23.45] строка".
List<LyricLine> parseLrc(String lrc) {
  final stamp = RegExp(r'\[(\d{1,3}):(\d{2})(?:[.:](\d{1,3}))?\]');
  final lines = <LyricLine>[];
  for (final raw in lrc.split('\n')) {
    final matches = stamp.allMatches(raw).toList();
    if (matches.isEmpty) continue;
    final text = raw.replaceAll(stamp, '').trim();
    if (text.isEmpty) continue;
    for (final m in matches) {
      final minutes = int.parse(m.group(1)!);
      final seconds = int.parse(m.group(2)!);
      final fraction = m.group(3);
      final ms = fraction == null
          ? 0
          : int.parse(fraction.padRight(3, '0').substring(0, 3));
      lines.add(
        LyricLine(
          Duration(minutes: minutes, seconds: seconds, milliseconds: ms),
          text,
        ),
      );
    }
  }
  lines.sort((a, b) => a.time.compareTo(b.time));
  return lines;
}

/// Ищет синхронный текст песни в открытой базе LRCLIB.
class LyricsService {
  LyricsService._();
  static final Map<String, List<LyricLine>> _cache = {};

  static Future<List<LyricLine>> fetch({
    required String title,
    required String artist,
    Duration? duration,
  }) async {
    final key = '$artist|$title';
    final cached = _cache[key];
    if (cached != null) return cached;

    final known = artist.isNotEmpty && artist != 'Неизвестный исполнитель';
    final cleaned =
        title.replaceAll(RegExp(r'[\(\[][^\)\]]*[\)\]]'), '').trim();
    final queries = <String>{
      known ? '$artist $title' : title,
      if (cleaned.isNotEmpty) (known ? '$artist $cleaned' : cleaned),
    };

    var failed = true;
    for (final q in queries) {
      final result = await _trySearch(q, duration);
      if (result == null) continue; // ошибка сети
      failed = false;
      if (result.isNotEmpty) {
        _cache[key] = result;
        return result;
      }
    }
    if (!failed) _cache[key] = const []; // точно не нашли — запоминаем
    return const [];
  }

  static Future<dynamic> _getJson(Uri uri) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.getUrl(uri);
      request.headers
          .set(HttpHeaders.userAgentHeader, 'Storix/1.0 (personal music player)');
      final response =
          await request.close().timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final body = await response.transform(utf8.decoder).join();
      return jsonDecode(body);
    } finally {
      client.close(force: true);
    }
  }

  /// null — ошибка сети, пустой список — текста нет.
  static Future<List<LyricLine>?> _trySearch(
    String query,
    Duration? duration,
  ) async {
    try {
      final data = await _getJson(
        Uri.https('lrclib.net', '/api/search', {'q': query}),
      );
      if (data is! List) return const [];

      final wanted = (duration != null && duration > Duration.zero)
          ? duration.inSeconds
          : null;
      Map<String, dynamic>? best;
      var bestDiff = 1 << 30;
      for (final item in data) {
        if (item is! Map<String, dynamic>) continue;
        final synced = item['syncedLyrics'];
        if (synced is! String || synced.trim().isEmpty) continue;
        final d = item['duration'];
        final diff = (wanted != null && d is num)
            ? (d.toDouble() - wanted).abs().round()
            : 0;
        if (diff < bestDiff) {
          best = item;
          bestDiff = diff;
        }
      }
      if (best == null) return const [];
      // Другая длина трека — скорее всего другая версия, время не совпадёт.
      if (wanted != null && bestDiff > 10) return const [];
      return parseLrc(best['syncedLyrics'] as String);
    } catch (_) {
      return null;
    }
  }
}
