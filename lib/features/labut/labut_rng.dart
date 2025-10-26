// lib/features/labut/labut_rng.dart
import 'dart:convert';
import 'labut_models.dart';

String todayIso() {
  final now = DateTime.now().toLocal();
  String two(int n) => n < 10 ? "0$n" : "$n";
  return "${now.year}-${two(now.month)}-${two(now.day)}";
}

int fnv1a32(String s) {
  int h = 0x811c9dc5;
  for (final b in utf8.encode(s)) {
    h ^= b;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h;
}

typedef Rnd = double Function();
Rnd mulberry32(int seed) {
  int t = seed & 0xffffffff;
  return () {
    t = (t + 0x6d2b79f5) & 0xffffffff;
    int x = t ^ (t >>> 15);
    x = (x * (t | 1)) & 0xffffffff;
    x ^= (x ^ (x >>> 7)) + ((x ^ (x >>> 7)) * 61) & 0xffffffff;
    return ((x ^ (x >>> 14)) & 0xffffffff) / 4294967296;
  };
}

List<T> shuffleSeeded<T>(List<T> a, Rnd rnd) {
  final arr = List<T>.from(a);
  for (int i = arr.length - 1; i > 0; i--) {
    final j = (rnd() * (i + 1)).floor();
    final tmp = arr[i];
    arr[i] = arr[j];
    arr[j] = tmp;
  }
  return arr;
}

int hamming<T>(List<T> a, List<T> b) {
  int d = 0;
  for (int i = 0; i < a.length; i++) if (a[i] != b[i]) d++;
  return d;
}

/// Günlük üretim: renk sayısı (2..5), renk seçimi (paletten), adetler, hedef & başlangıç.
/// palette: istediğin kadar renk kodu ekleyebilirsin.
DailyGame generateDaily({required String iso, String salt = "YurtPalLabutV2"}) {
  final seed = fnv1a32("$iso|$salt");
  final rnd = mulberry32(seed);

  //  kullanılabilir renk paleti (kodlar)
  final palette = ["Y", "G", "R", "B", "K", "P", "O", "C", "M"];
  //  Y: sarı, G: yeşil, R: kırmızı, B: mavi(blue), K: siyah(black), P: pembe(pink),
  //  O: turuncu(orange), C: camgöbeği(cyan), M: mor(magenta/purple)

  // Bugünün renk sayısı: 2..5
  final colorCount = 2 + (rnd() * 4).floor(); // 2,3,4,5
  // Paleti karıştır, ilk colorCount’u seç
  final shuffledPalette = shuffleSeeded(palette, rnd);
  final todaysColors = shuffledPalette
      .take(colorCount)
      .toList(); // örn ["P","K"]

  // Board uzunluğu: 7..10
  final boardLen = 7 + (rnd() * 4).floor(); // 7,8,9,10

  // Her renkten en az 1 ver, kalanları rastgele dağıt
  final counts = <String, int>{for (final c in todaysColors) c: 1};
  int left = boardLen - colorCount;
  while (left-- > 0) {
    final i = (rnd() * todaysColors.length).floor();
    counts[todaysColors[i]] = (counts[todaysColors[i]] ?? 0) + 1;
  }
  final spec = GameSpec(boardLen: boardLen, counts: counts);

  // Hedef (target) – counts’a göre çoklu küme oluşturup karıştır
  final base = <LabutColor>[];
  counts.forEach((code, n) => base.addAll(List.filled(n, code)));
  final target = shuffleSeeded(base, rnd);

  // Başlangıç – farklı akışla karıştır, yeterince uzak olsun
  final rnd2 = mulberry32(seed + 7);
  List<LabutColor> start;
  final minHam = (boardLen * 0.6).ceil();
  do {
    start = shuffleSeeded(target, rnd2);
  } while (hamming(start, target) < minHam);

  return DailyGame(iso: iso, spec: spec, target: target, start: start);
}
