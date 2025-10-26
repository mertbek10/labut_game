import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'labut_cubit.dart';
import 'labut_models.dart';

class LabutPage extends StatelessWidget {
  const LabutPage({super.key});

  // Renk kodu -> görünür renk
  Color _color(LabutColor code) {
    switch (code) {
      case "Y":
        return Colors.amber;
      case "G":
        return Colors.green;
      case "R":
        return Colors.red;
      case "B":
        return Colors.blue;
      case "K":
        return Colors.black;
      case "P":
        return Colors.pinkAccent;
      case "O":
        return Colors.orange;
      case "C":
        return Colors.cyan;
      case "M":
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _mmss(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LabutCubit()..load(),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff101522), Color(0xff1b2238), Color(0xff0e1116)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: BlocBuilder<LabutCubit, LabutState>(
              builder: (ctx, s) {
                if (s.loading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                final percent = s.current.isEmpty
                    ? 0.0
                    : (s.correct / s.current.length);
                final percentText = "${(percent * 100).toStringAsFixed(0)}%";

                return Stack(
                  children: [
                    Column(
                      children: [
                        const SizedBox(height: 12),

                        // ===== Üst Bilgi Paneli =====
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _StatusPanel(
                            timeText: _mmss(s.seconds),
                            moves: s.moves,
                            correctText: "${s.correct}/${s.current.length}",
                            percent: percent,
                            percentText: percentText,
                            solved: s.solved,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ===== LABUT TAHTASI =====
                        _LabutBoard(
                          colors: s.current,
                          ids: s.ids,
                          selectedIndex: s.selected,
                          colorOf: _color,
                          onTap: (i) => ctx.read<LabutCubit>().tap(i),
                        ),
                        SizedBox(
                          height: 0,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            itemCount: s.current.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),
                            itemBuilder: (ctx, i) {
                              final selected = s.selected == i;
                              return GestureDetector(
                                onTap: () => ctx.read<LabutCubit>().tap(i),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 140),
                                  width: 56,
                                  decoration: BoxDecoration(
                                    color: _color(s.current[i]),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: selected
                                          ? Colors.white
                                          : Colors.black12,
                                      width: selected ? 3 : 1,
                                    ),
                                    // 💡 sade alt gölge
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black38,
                                        blurRadius: 10,
                                        offset: Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: const SizedBox.shrink(),
                                ),
                              );
                            },
                          ),
                        ),

                        const Spacer(),

                        // ===== Alt Bilgi (çözülünce) =====
                        if (s.solved)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              "Tamamlandı ✅  •  Süre: ${_mmss(s.seconds)}  •  Hamle: ${s.moves}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                      ],
                    ),

                    // ===== Üst Yeşil Banner =====
                    if (s.solved)
                      Positioned(
                        top: 8,
                        left: 16,
                        right: 16,
                        child: _SuccessBanner(),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Üstte çıkan yeşil “tamamlandı” bandı
class _SuccessBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.green.withOpacity(.15),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 18, color: Colors.greenAccent),
            const SizedBox(width: 8),
            Text(
              "Bugünün bulmacası tamamlandı",
              style: TextStyle(
                color: Colors.greenAccent.shade100,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animasyonlu ve responsive labut tahtası
class _LabutBoard extends StatelessWidget {
  final List<LabutColor> colors;
  final List<int> ids;
  final int? selectedIndex;
  final Color Function(LabutColor) colorOf;
  final ValueChanged<int> onTap;

  const _LabutBoard({
    required this.colors,
    required this.ids,
    required this.selectedIndex,
    required this.colorOf,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final n = colors.length;
    if (n == 0) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        const double paddingH = 16.0;
        final size = MediaQuery.of(context).size;
        final bool isTablet = size.shortestSide >= 600;
        final double maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : size.width;

        // Fit all items without horizontal scrolling using a spacing ratio.
        // spacing = r * tileW, with r chosen per device type.
        final double r = isTablet ? 0.15 : 0.18;
        final double denom = n + (n - 1) * r;
        final double tileW = (maxW - paddingH * 2) / denom;
        final double spacing = r * tileW;
        final double tileH =
            tileW * 1.6; // keep aspect ratio; height scales with width

        return SizedBox(
          height: tileH,
          width: double.infinity,
          child: Stack(
            children: [
              for (int i = 0; i < n; i++)
                AnimatedPositioned(
                  key: ValueKey(ids[i]),
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeInOutCubic,
                  left: paddingH + i * (tileW + spacing),
                  top: 0,
                  width: tileW,
                  height: tileH,
                  child: _LabutTile(
                    color: colorOf(colors[i]),
                    selected: selectedIndex == i,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _LabutTile extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _LabutTile({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        scale: selected ? 1.06 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              const BoxShadow(
                color: Colors.black38,
                blurRadius: 10,
                offset: Offset(0, 6),
              ),
              if (selected)
                BoxShadow(
                  color: Colors.white.withOpacity(.10),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
            ],
          ),
          child: CustomPaint(painter: _PinPainter(baseColor: color)),
        ),
      ),
    );
  }
}

class _NoGlowBehavior extends ScrollBehavior {
  const _NoGlowBehavior();
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class _PinPainter extends CustomPainter {
  final Color baseColor;
  _PinPainter({required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Compute shades
    final light = _lighten(baseColor, 0.18);
    final dark = _darken(baseColor, 0.22);

    // Neck and body proportions
    final top = h * 0.22;
    final neckHalf = w * 0.18;
    final widestHalf = w * 0.46;
    final midY = h * 0.58;
    final bottomY = h * 0.96;
    final baseHalf = w * 0.46;

    // Floor/contact shadow (soft oval under the pin)
    final floorShadowRect = Rect.fromCenter(
      center: Offset(w * 0.5, bottomY + h * 0.015),
      width: w * 0.72,
      height: h * 0.09,
    );
    final floorShadow = Paint()
      ..color = Colors.black.withOpacity(.22)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, _sigma(8));
    canvas.drawOval(floorShadowRect, floorShadow);

    // Body path (symmetric)
    final body = Path()
      ..moveTo(w * 0.5 - neckHalf, top)
      ..cubicTo(
        w * 0.5 - neckHalf * 1.6,
        top + h * 0.05,
        w * 0.5 - widestHalf,
        midY - h * 0.12,
        w * 0.5 - baseHalf,
        bottomY - h * 0.05,
      )
      ..quadraticBezierTo(
        w * 0.5,
        bottomY,
        w * 0.5 + baseHalf,
        bottomY - h * 0.05,
      )
      ..cubicTo(
        w * 0.5 + widestHalf,
        midY - h * 0.12,
        w * 0.5 + neckHalf * 1.6,
        top + h * 0.05,
        w * 0.5 + neckHalf,
        top,
      )
      ..close();

    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [light, baseColor, dark],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(body, bodyPaint);

    // Head (ball) on top
    final headR = w * 0.22;
    final headC = Offset(w * 0.5, top - headR * 0.2);
    final headPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          _lighten(baseColor, 0.22),
          baseColor,
          _darken(baseColor, 0.18),
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: headC, radius: headR));
    canvas.drawCircle(headC, headR, headPaint);

    // Ambient occlusion near base (inside body)
    canvas.save();
    canvas.clipPath(body);
    final aoRect = Rect.fromLTWH(0, bottomY - h * 0.10, w, h * 0.14);
    final aoPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.black.withOpacity(.12), Colors.transparent],
        stops: const [0.0, 1.0],
      ).createShader(aoRect);
    canvas.drawRect(aoRect, aoPaint);
    canvas.restore();

    // Collar band
    final bandTop = top + h * 0.02;
    final bandH = h * 0.04;
    final bandR = Radius.circular(bandH * 0.4);
    final bandRect = RRect.fromLTRBR(
      w * 0.5 - neckHalf * 1.15,
      bandTop,
      w * 0.5 + neckHalf * 1.15,
      bandTop + bandH,
      bandR,
    );
    final bandPaint = Paint()..color = Colors.white.withOpacity(.92);
    canvas.drawRRect(bandRect, bandPaint);
    // Red center stripe
    final red = Paint()..color = Colors.redAccent.withOpacity(.95);
    final stripeH = bandH * 0.32;
    final stripeRect = RRect.fromLTRBR(
      bandRect.left + 2,
      bandRect.top + (bandH - stripeH) / 2,
      bandRect.right - 2,
      bandRect.top + (bandH + stripeH) / 2,
      Radius.circular(stripeH * 0.3),
    );
    canvas.drawRRect(stripeRect, red);

    // Band shadow below (subtle)
    final bandShadowRect = RRect.fromLTRBR(
      bandRect.left,
      bandRect.bottom - bandH * 0.2,
      bandRect.right,
      bandRect.bottom + bandH * 0.35,
      Radius.circular(bandH * 0.5),
    );
    final bandShadow = Paint()
      ..color = Colors.black.withOpacity(.16)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, _sigma(4));
    canvas.drawRRect(bandShadowRect, bandShadow);

    // Specular highlight on left
    final hl = Path()
      ..moveTo(w * 0.35, top + h * 0.02)
      ..quadraticBezierTo(w * 0.28, h * 0.52, w * 0.40, h * 0.82)
      ..quadraticBezierTo(w * 0.33, h * 0.60, w * 0.36, top + h * 0.08)
      ..close();
    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white.withOpacity(.35), Colors.white.withOpacity(0)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(hl, highlightPaint);

    // Small specular on head
    final specDot = Paint()..color = Colors.white.withOpacity(.65);
    canvas.drawCircle(
      headC.translate(-headR * 0.30, -headR * 0.20),
      headR * 0.18,
      specDot,
    );

    // Rim light on right edge
    final rim = Path()
      ..moveTo(w * 0.5 + neckHalf * 0.9, top + h * 0.01)
      ..quadraticBezierTo(
        w * 0.74,
        h * 0.40,
        w * 0.5 + baseHalf * 0.92,
        bottomY - h * 0.06,
      )
      ..quadraticBezierTo(
        w * 0.70,
        h * 0.46,
        w * 0.5 + neckHalf * 0.9,
        top + h * 0.01,
      )
      ..close();
    final rimPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white.withOpacity(.25), Colors.white.withOpacity(0)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(rim, rimPaint);

    // Subtle outline
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.black.withOpacity(.18);
    canvas.drawPath(body, outline);
  }

  @override
  bool shouldRepaint(covariant _PinPainter oldDelegate) =>
      oldDelegate.baseColor != baseColor;

  double _sigma(double r) => r * 0.57735 + 0.5; // px radius -> sigma
}

Color _lighten(Color c, double amount) {
  final h = HSLColor.fromColor(c);
  final l = (h.lightness + amount).clamp(0.0, 1.0);
  return h.withLightness(l).toColor();
}

Color _darken(Color c, double amount) {
  final h = HSLColor.fromColor(c);
  final l = (h.lightness - amount).clamp(0.0, 1.0);
  return h.withLightness(l).toColor();
}

/// Üstteki durum paneli (süre + doğru + hamle + progress)
class _StatusPanel extends StatelessWidget {
  final String timeText;
  final int moves;
  final String correctText;
  final double percent;
  final String percentText;
  final bool solved;

  const _StatusPanel({
    required this.timeText,
    required this.moves,
    required this.correctText,
    required this.percent,
    required this.percentText,
    required this.solved,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff1b2330), Color(0xff151a22)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        boxShadow: const [
          BoxShadow(
            blurRadius: 16,
            color: Colors.black54,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Üst satır: süre / doğru / hamle
          Row(
            children: [
              _Pill(
                icon: Icons.timer_rounded,
                label: timeText,
                color: Colors.blueAccent,
              ),
              const SizedBox(width: 8),
              _Pill(
                icon: Icons.done_all_rounded,
                label: correctText,
                color: Colors.tealAccent.shade700,
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(
                    Icons.touch_app_rounded,
                    size: 18,
                    color: Colors.white54,
                  ),
                  const SizedBox(width: 6),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (c, anim) =>
                        ScaleTransition(scale: anim, child: c),
                    child: Text(
                      "$moves",
                      key: ValueKey(moves),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Alt satır: progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: percent.clamp(0, 1),
                    minHeight: 10,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      solved ? Colors.greenAccent : Colors.lightBlueAccent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (c, anim) =>
                    ScaleTransition(scale: anim, child: c),
                child: Text(
                  percentText,
                  key: ValueKey(percentText),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Küçük rozet stili
class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Pill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (c, anim) =>
                FadeTransition(opacity: anim, child: c),
            child: Text(
              label,
              key: ValueKey(label),
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
