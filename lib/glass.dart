import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Стеклянная поверхность в стиле Liquid Glass: размытие того, что под ней,
/// мягкая подсветка и тонкий блик по краю.
class GlassSurface extends StatelessWidget {
  final Widget child;
  final double radius;
  final double blur;
  final int fillAlpha; // 0..255: насколько «молочное» стекло
  final EdgeInsetsGeometry? padding;

  const GlassSurface({
    super.key,
    required this.child,
    this.radius = 24,
    this.blur = 20,
    this.fillAlpha = 70,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: CustomPaint(
          foregroundPainter: _RimPainter(radius),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withAlpha(fillAlpha),
                  Colors.white.withAlpha((fillAlpha * 0.25).round()),
                  Colors.white.withAlpha((fillAlpha * 0.45).round()),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Тонкая светящаяся рамка: ярче в левом верхнем и правом нижнем углах.
class _RimPainter extends CustomPainter {
  final double radius;
  const _RimPainter(this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(0.75);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withAlpha(200),
          Colors.white.withAlpha(25),
          Colors.white.withAlpha(25),
          Colors.white.withAlpha(120),
        ],
        stops: const [0.0, 0.35, 0.65, 1.0],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      paint,
    );
  }

  @override
  bool shouldRepaint(_RimPainter oldDelegate) => oldDelegate.radius != radius;
}

/// Круглая стеклянная кнопка. При нажатии слегка «раздувается».
class GlassButton extends StatefulWidget {
  final double size;
  final IconData? icon;
  final double iconSize;
  final Color color;
  final int fillAlpha;
  final Widget? child;
  final VoidCallback? onPressed;

  const GlassButton({
    super.key,
    required this.size,
    this.icon,
    this.iconSize = 24,
    this.color = Colors.white,
    this.fillAlpha = 70,
    this.child,
    this.onPressed,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (mounted && _pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final iconColor = enabled ? widget.color : widget.color.withAlpha(90);
    final content = widget.child ??
        Icon(widget.icon, size: widget.iconSize, color: iconColor);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapUp: enabled ? (_) => _setPressed(false) : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 1.14 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        child: GlassSurface(
          radius: widget.size,
          blur: 18,
          fillAlpha: _pressed ? widget.fillAlpha + 35 : widget.fillAlpha,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}

/// Матовая стеклянная панель снизу (для шторок).
class GlassSheet extends StatelessWidget {
  final double height;
  final Color tint;
  final Widget child;

  const GlassSheet({
    super.key,
    required this.height,
    required this.tint,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: tint.withAlpha(150),
            border: Border(
              top: BorderSide(color: Colors.white.withAlpha(70), width: 1.2),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
