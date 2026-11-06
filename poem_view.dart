import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'arabic_text.dart';
import 'constants.dart';
import 'font_settings.dart';
import 'poems_data.dart';

export 'font_settings.dart' show poemFontSize;

class _Line {
  final Justified sadr;
  final Justified ajz;
  const _Line(this.sadr, this.ajz);
}

class PoemBody extends StatefulWidget {
  final Poem poem;
  const PoemBody({super.key, required this.poem});
  @override
  State<PoemBody> createState() => _PoemBodyState();
}

class _PoemBodyState extends State<PoemBody> {
  String? _key;
  List<_Line> _lines = const [];
  double _w = 0, _size = 22;
  TextStyle _style = const TextStyle();
  bool _allFit = true;

  TextStyle _styleFor(BuildContext ctx, double size) =>
      applyPoemFont(DefaultTextStyle.of(ctx).style.merge(TextStyle(
            fontSize: size,
            height: 1.0,
            color: poemFontColor.value,
            fontWeight: FontWeight.w500,
          )));

  // عرض 8 مسافات بالخط الحالي
  double _indent(TextStyle st) =>
      measureText('ا        ا', st) - measureText('اا', st);

  void _compute(BuildContext ctx, double avail, double base) {
    final texts = <String>[
      for (final v in widget.poem.verses) ...[displayText(v.sadr), displayText(v.ajz)]
    ].map((t) => t.trim().replaceAll(RegExp(r'\s+'), ' ')).toList();

    var size = base;
    var st = _styleFor(ctx, size);
    var w = avail - _indent(st);
    // نصغّر الخط لو أطول شطر لا يتّسع
    for (var i = 0; i < 6 && texts.isNotEmpty; i++) {
      final maxW = texts.map((t) => measureText(t, st)).reduce(math.max);
      if (maxW <= w) break;
      size = math.max(12, size * (w / maxW) * 0.995);
      st = _styleFor(ctx, size);
      w = avail - _indent(st);
    }

    var allFit = true;
    final lines = <_Line>[];
    for (final v in widget.poem.verses) {
      final a = justifyHemistich(displayText(v.sadr), st, w);
      final b = justifyHemistich(displayText(v.ajz), st, w);
      if (!a.fits || !b.fits) allFit = false;
      lines.add(_Line(a, b));
    }
    _lines = lines;
    _w = w;
    _size = size;
    _style = st;
    _allFit = allFit;
  }

  Widget _hemistich(Justified j, Alignment align) => Align(
        alignment: align,
        child: SizedBox(
          width: _w,
          child: Text(
            j.text,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            textScaler: TextScaler.noScaling,
            maxLines: j.fits ? 1 : null,
            softWrap: !j.fits,
            overflow: TextOverflow.visible,
            style: _style.copyWith(
              wordSpacing: j.wordSpacing,
              height: j.fits ? 1.0 : 1.7,
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: poemSettings,
      builder: (ctx, _) => LayoutBuilder(
        builder: (ctx, c) {
          final base = poemFontSize.value;
          final key =
              '${widget.poem.title}|${c.maxWidth.toStringAsFixed(1)}|$base|${poemFontFamily.value}|${poemFontColor.value}|${removeTashkeel.value}';
          if (key != _key) {
            _compute(ctx, c.maxWidth, base);
            _key = key;
          }
          final gap = _size * 0.95;
          return Column(
            children: [
              for (var i = 0; i < _lines.length; i++) ...[
                Column(
                  children: [
                    // الصدر: يبدأ من أقصى اليمين
                    _hemistich(_lines[i].sadr, Alignment.centerRight),
                    SizedBox(height: _size * 0.45),
                    // العجز: تحته مباشرة، مزاح 8 مسافات لليسار
                    _hemistich(_lines[i].ajz, Alignment.centerLeft),
                  ],
                ),
                if (i < _lines.length - 1)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: gap * 0.6),
                    child: const OrnamentDivider(),
                  )
                else
                  SizedBox(height: gap * 0.4),
              ],
              if (!_allFit)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('بعض الأشطر طويلة جدًا فلُفّت على سطرين.',
                      style: TextStyle(fontSize: 11, color: Colors.black45)),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ───────────── التصميم الإسلامي: نجمة ثمانية وزخارف ─────────────

Path _star8(Offset c, double r, [double ratio = .62]) {
  final p = Path();
  for (var i = 0; i < 16; i++) {
    final rad = i.isEven ? r : r * ratio;
    final a = -math.pi / 2 + i * math.pi / 8;
    final pt = Offset(c.dx + rad * math.cos(a), c.dy + rad * math.sin(a));
    if (i == 0) {
      p.moveTo(pt.dx, pt.dy);
    } else {
      p.lineTo(pt.dx, pt.dy);
    }
  }
  return p..close();
}

void _drawMedallion(Canvas canvas, Offset c, double r) {
  canvas.drawPath(_star8(c, r), Paint()..color = appGreen);
  canvas.drawPath(
      _star8(c, r),
      Paint()
        ..color = appGold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4);
  canvas.drawCircle(c, r * .28, Paint()..color = appGold);
}

class _StarPainter extends CustomPainter {
  final Color color;
  const _StarPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
      _star8(size.center(Offset.zero), size.width / 2),
      Paint()..color = color);
  @override
  bool shouldRepaint(covariant _StarPainter old) => old.color != color;
}

/// فاصل مزخرف بين الأبيات: خط - نجمة - خط
class OrnamentDivider extends StatelessWidget {
  const OrnamentDivider({super.key});
  @override
  Widget build(BuildContext context) {
    Widget line(bool fadeLeft) => Expanded(
          child: Container(
            height: 1.2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: fadeLeft ? Alignment.centerRight : Alignment.centerLeft,
                end: fadeLeft ? Alignment.centerLeft : Alignment.centerRight,
                colors: [appGold, appGold.withOpacity(0)],
              ),
            ),
          ),
        );
    return Row(
      children: [
        line(false),
        const SizedBox(width: 8),
        CustomPaint(
            size: const Size(16, 16), painter: _StarPainter(appGold)),
        const SizedBox(width: 8),
        line(true),
      ],
    );
  }
}

/// خلفية مزخرفة خفيفة (نجوم هندسية متكررة)
class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cell = 46.0;
    final stroke = Paint()
      ..color = appGold.withOpacity(.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final fill = Paint()..color = appGold.withOpacity(.10);
    for (var y = 0.0; y < size.height + cell; y += cell) {
      for (var x = 0.0; x < size.width + cell; x += cell) {
        canvas.drawPath(_star8(Offset(x, y), 13), stroke);
        canvas.drawPath(_star8(Offset(x + cell / 2, y + cell / 2), 5), fill);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// الإطار: خطان مذهّبان ونجوم في الزوايا ومنتصف الضلعين
class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final outer = Paint()
      ..color = appGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    final inner = Paint()
      ..color = appGreen.withOpacity(.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(1.5, 1.5, size.width - 3, size.height - 3),
            const Radius.circular(12)),
        outer);
    final r = Rect.fromLTWH(9, 9, size.width - 18, size.height - 18);
    canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(6)), inner);
    for (final c in [
      r.topLeft,
      r.topRight,
      r.bottomLeft,
      r.bottomRight,
    ]) {
      _drawMedallion(canvas, c, 14);
    }
    _drawMedallion(canvas, Offset(r.center.dx, r.top), 9);
    _drawMedallion(canvas, Offset(r.center.dx, r.bottom), 9);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// إطار القصيدة
class PoemFrame extends StatelessWidget {
  final Widget child;
  const PoemFrame({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF2),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(.15),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Positioned.fill(
                  child: RepaintBoundary(
                      child: CustomPaint(painter: _PatternPainter()))),
              Positioned.fill(child: CustomPaint(painter: _FramePainter())),
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 36, 26, 30),
                child: child,
              ),
            ],
          ),
        ),
      );
}

/// ترويسة على شكل محراب: عنوان القصيدة واسم الديوان
class PoemHeader extends StatelessWidget {
  final String title;
  final String diwan;
  const PoemHeader({super.key, required this.title, required this.diwan});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [appGreen, appDarkGreen]),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(110),
            topRight: Radius.circular(110),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: appGold, width: 2),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(.25),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            CustomPaint(
                size: const Size(22, 22), painter: _StarPainter(appGold)),
            const SizedBox(height: 10),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    height: 1.5,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: OrnamentDivider(),
            ),
            const SizedBox(height: 10),
            Text(diwan,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFFE8D9BC), fontSize: 14, height: 1.4)),
          ],
        ),
      );
}
