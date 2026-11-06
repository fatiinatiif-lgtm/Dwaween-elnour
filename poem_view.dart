import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'arabic_text.dart';
import 'constants.dart';
import 'poems_data.dart';

/// حجم خط القصيدة (يتحكم فيه من الإعدادات).
final ValueNotifier<double> poemFontSize = ValueNotifier<double>(22);

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
      DefaultTextStyle.of(ctx).style.merge(TextStyle(
            fontSize: size,
            height: 1.0,
            color: const Color(0xFF1B1B1B),
            fontWeight: FontWeight.w500,
          ));

  // عرض 8 مسافات بالخط الحالي
  double _indent(TextStyle st) =>
      measureText('ا        ا', st) - measureText('اا', st);

  void _compute(BuildContext ctx, double avail, double base) {
    final texts = <String>[
      for (final v in widget.poem.verses) ...[v.sadr, v.ajz]
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
      final a = justifyHemistich(v.sadr, st, w);
      final b = justifyHemistich(v.ajz, st, w);
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
    return ValueListenableBuilder<double>(
      valueListenable: poemFontSize,
      builder: (ctx, base, _) => LayoutBuilder(
        builder: (ctx, c) {
          final key = '${widget.poem.title}|${c.maxWidth.toStringAsFixed(1)}|$base';
          if (key != _key) {
            _compute(ctx, c.maxWidth, base);
            _key = key;
          }
          final gap = _size * 0.95;
          return Column(
            children: [
              for (final l in _lines)
                Padding(
                  padding: EdgeInsets.only(bottom: gap),
                  child: Column(
                    children: [
                      // الصدر: يبدأ من أقصى اليمين
                      _hemistich(l.sadr, Alignment.centerRight),
                      SizedBox(height: _size * 0.45),
                      // العجز: تحته مباشرة، مزاح 8 مسافات لليسار
                      _hemistich(l.ajz, Alignment.centerLeft),
                    ],
                  ),
                ),
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

/// إطار مذهّب حول القصيدة
class PoemFrame extends StatelessWidget {
  final Widget child;
  const PoemFrame({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: appGold, width: 1.6),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: appGold.withOpacity(.45)),
          ),
          child: child,
        ),
      );
}
