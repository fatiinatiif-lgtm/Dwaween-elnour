import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart' show PdfPageFormat;
import 'package:pdf/widgets.dart' as pw;

import 'main.dart';
import 'poems_data.dart';
import 'saved_files.dart';
import 'salawat_page.dart';

// ════════════════════════════════════════════════
// تصدير القصيدة إلى PDF
// 13 إطار + 9 نقوش + 4 ترويسات + 22 لون زخرفة + 14 لون ورقة
// الصفحة تُرسم بنفس خط التطبيق وبنفس طريقة ضبط الأشطر (الكشيدة)
// ثم تُوضع في ملف PDF.
// ════════════════════════════════════════════════

// ───────────── خيارات الألوان ─────────────

class PdfTheme {
  final String label;
  final Color dark; // لون الترويسة والنجوم
  final Color accent; // لون الإطار والزخرفة
  const PdfTheme(this.label, this.dark, this.accent);
}

const pdfThemes = [
  PdfTheme('بني وذهبي', Color(0xFF5D4037), Color(0xFFC9A24B)),
  PdfTheme('أخضر وذهبي', Color(0xFF1B5E20), Color(0xFFC9A24B)),
  PdfTheme('أزرق وذهبي', Color(0xFF0D47A1), Color(0xFFD4AF37)),
  PdfTheme('عنابي وذهبي', Color(0xFF7B1F2E), Color(0xFFC9A24B)),
  PdfTheme('بنفسجي وذهبي', Color(0xFF4A148C), Color(0xFFC9A24B)),
  PdfTheme('أسود وذهبي', Color(0xFF212121), Color(0xFFC9A24B)),
  PdfTheme('تركوازي وذهبي', Color(0xFF00695C), Color(0xFFC9A24B)),
  PdfTheme('نيلي وفضي', Color(0xFF1A237E), Color(0xFF9FA8B5)),
  PdfTheme('زمردي وفضي', Color(0xFF004D40), Color(0xFF9DB0B5)),
  PdfTheme('وردي ملكي وذهبي', Color(0xFF880E4F), Color(0xFFE0B341)),
  PdfTheme('برتقالي محروق', Color(0xFFBF360C), Color(0xFFE6B655)),
  PdfTheme('فحمي وذهبي', Color(0xFF37474F), Color(0xFFD4AF37)),
  PdfTheme('كحلي وبرونزي', Color(0xFF0B2545), Color(0xFFCD7F32)),
  PdfTheme('أخضر زيتي', Color(0xFF33691E), Color(0xFFC0A062)),
  PdfTheme('شوكولاتة ونحاسي', Color(0xFF3E2723), Color(0xFFB87333)),
  PdfTheme('أحمر قاني وذهبي', Color(0xFFB71C1C), Color(0xFFD4AF37)),
  PdfTheme('أرجواني وفضي', Color(0xFF311B92), Color(0xFFA9B0D6)),
  PdfTheme('أزرق سماوي', Color(0xFF01579B), Color(0xFF4FA8C9)),
  PdfTheme('بيج وبني', Color(0xFF8D6E63), Color(0xFFD7B98E)),
  PdfTheme('كحلي وفيروزي', Color(0xFF102A43), Color(0xFF2EA99B)),
  PdfTheme('عنابي وفضي', Color(0xFF5C1A2B), Color(0xFFB8BEC6)),
  PdfTheme('أخضر ليموني', Color(0xFF558B2F), Color(0xFFD2B24C)),
];

class PaperChoice {
  final String label;
  final Color color;
  const PaperChoice(this.label, this.color);
}

const paperChoices = [
  PaperChoice('كريمي', Color(0xFFFFFBF2)),
  PaperChoice('أبيض', Color(0xFFFFFFFF)),
  PaperChoice('أخضر فاتح', Color(0xFFF1F8E9)),
  PaperChoice('أزرق فاتح', Color(0xFFEAF2FB)),
  PaperChoice('وردي فاتح', Color(0xFFFCEFF0)),
  PaperChoice('رملي', Color(0xFFF5ECDC)),
  PaperChoice('لافندر', Color(0xFFF3EEF9)),
  PaperChoice('ليموني', Color(0xFFFFFBE0)),
  PaperChoice('نعناعي', Color(0xFFE8F5F0)),
  PaperChoice('خوخي', Color(0xFFFFF0E5)),
  PaperChoice('رمادي فاتح', Color(0xFFF2F2F2)),
  PaperChoice('رق قديم', Color(0xFFF4E8C8)),
  PaperChoice('أزرق ثلجي', Color(0xFFE3F2FD)),
  PaperChoice('ذهبي باهت', Color(0xFFFBF3D5)),
];

// ───────────── خيارات التصميم ─────────────

const frameLabels = [
  'إسلامي كلاسيكي', // 0
  'مزدوج أنيق', // 1
  'زوايا مزخرفة', // 2
  'شريط نجمي', // 3
  'لؤلؤ', // 4
  'أقواس متتالية', // 5
  'ضفيرة متموجة', // 6
  'ثلاثي بمعيّنات', // 7
  'محراب', // 8
  'بسيط رفيع', // 9
  'شريط عريض', // 10
  'بدون إطار', // 11
  'حلقات متصلة', // 12
  'مربعات الزوايا', // 13
  'نقاط دقيقة', // 14
  'زوايا مقعّرة', // 15
  'خطوط متدرجة', // 16
  'أقواس الأركان', // 17
  'نجوم الأركان', // 18
  'زوايا مشطوفة', // 19
  'شريط ذهبي سميك', // 20
  'دوائر الأركان', // 21
  'معيّنات ونقاط', // 22
];
const _frameArch = 8;
const _frameNone = 11;

const patternLabels = [
  'نجوم', // 0
  'نقاط', // 1
  'معيّنات', // 2
  'دوائر متداخلة', // 3
  'ورود', // 4
  'سطور', // 5
  'بدون نقش', // 6
  'علامة مائية', // 7
  'نجوم متناثرة', // 8
];

const headerLabels = [
  'محراب', // 0
  'شريط ملوّن', // 1
  'مستطيل مزخرف', // 2
  'كبسولة', // 3
  'قوس مدبّب', // 4
  'داكن منقّط', // 5
  'مثمّن', // 6
  'بطن مقوّس', // 7
  'داكن مقعّر الزوايا', // 8
  'ظل مزدوج', // 9
  'خطان وزخرف', // 10
  'كبسولة داكنة', // 11
  'شرفات', // 12
  'جوانب مقعّرة', // 13
];

/// الترويسات الملوّنة (نص أبيض) مقابل الفاتحة (نص بلون الثيم)
bool _headerDark(int h) => h <= 1 || h == 5 || h == 8 || h == 11;

// ───────────── مقاسات الصفحة (A4 بالنسبة) ─────────────

const double _pageW = 420;
const double _pageH = 594;
const double _scale = 3.0; // دقة الصورة (3 = حوالي 150 DPI)
const double _mx = 46; // الهامش الجانبي
const double _top = 46;
const double _bottom = _pageH - 46;
const double _avail = _pageW - 2 * _mx;

// ───────────── أدوات رسم صغيرة ─────────────

Paint _stroke(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w;

Paint _fillP(Color c) => Paint()..color = c;

Rect _inset(double d) =>
    Rect.fromLTWH(d, d, _pageW - 2 * d, _pageH - 2 * d);

Path _pdfStar(Offset c, double r, [double ratio = .62]) {
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

Path _diamond(Offset c, double r) => Path()
  ..moveTo(c.dx, c.dy - r)
  ..lineTo(c.dx + r, c.dy)
  ..lineTo(c.dx, c.dy + r)
  ..lineTo(c.dx - r, c.dy)
  ..close();

void _medallion(Canvas c, Offset ctr, double r, PdfTheme t) {
  c.drawPath(_pdfStar(ctr, r), Paint()..color = t.dark);
  c.drawPath(
      _pdfStar(ctr, r),
      Paint()
        ..color = t.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2);
  c.drawCircle(ctr, r * .28, Paint()..color = t.accent);
}

void _diamondMark(Canvas c, Offset ctr, double r, PdfTheme t) {
  c.drawPath(_diamond(ctr, r), _fillP(t.dark));
  c.drawPath(_diamond(ctr, r), _stroke(t.accent, 1));
}

/// نقاط موزّعة على محيط مستطيل بخطوة تقريبية
List<Offset> _pointsAlongRect(Rect r, double step) {
  final pts = <Offset>[];
  void side(Offset a, Offset b) {
    final len = (b - a).distance;
    final n = math.max(1, (len / step).round());
    for (var i = 0; i < n; i++) {
      pts.add(Offset.lerp(a, b, i / n)!);
    }
  }

  side(r.topLeft, r.topRight);
  side(r.topRight, r.bottomRight);
  side(r.bottomRight, r.bottomLeft);
  side(r.bottomLeft, r.topLeft);
  return pts;
}

/// حدود مفصّصة (أقواس نصف دائرية متتالية متجهة للداخل)
void _scallop(Canvas c, Rect r, double rad, Paint p) {
  void side(Offset a, Offset b, double start) {
    final len = (b - a).distance;
    final n = math.max(1, (len / (2 * rad)).round());
    final rr = len / (2 * n);
    final dir = (b - a) / len;
    for (var i = 0; i < n; i++) {
      final ctr = a + dir * (rr * (2 * i + 1));
      c.drawArc(Rect.fromCircle(center: ctr, radius: rr), start, math.pi,
          false, p);
    }
  }

  side(r.topLeft, r.topRight, 0);
  side(r.bottomLeft, r.bottomRight, math.pi);
  side(r.topLeft, r.bottomLeft, -math.pi / 2);
  side(r.topRight, r.bottomRight, math.pi / 2);
}

/// مستطيل بحدود متموجة (جيب)
Path _wavyRect(Rect r, double amp, double wl, [double phase = 0]) {
  final p = Path();
  double w(double d) => amp * math.sin(d * 2 * math.pi / wl + phase);
  var first = true;
  void add(double x, double y) {
    if (first) {
      p.moveTo(x, y);
      first = false;
    } else {
      p.lineTo(x, y);
    }
  }

  for (var x = r.left; x <= r.right; x += 1.5) {
    add(x, r.top + w(x - r.left));
  }
  for (var y = r.top; y <= r.bottom; y += 1.5) {
    add(r.right + w(y - r.top), y);
  }
  for (var x = r.right; x >= r.left; x -= 1.5) {
    add(x, r.bottom + w(r.right - x));
  }
  for (var y = r.bottom; y >= r.top; y -= 1.5) {
    add(r.left + w(r.bottom - y), y);
  }
  return p..close();
}

/// فاصل مزخرف: خط - نجمة - خط (مركزه y)
void _divider(Canvas c, double cx, double y, double w, Color accent) {
  final half = w / 2;
  final left = Rect.fromLTRB(cx - half, y - 0.6, cx - 14, y + 0.6);
  final right = Rect.fromLTRB(cx + 14, y - 0.6, cx + half, y + 0.6);
  c.drawRect(
      left,
      Paint()
        ..shader = ui.Gradient.linear(
            Offset(left.left, y),
            Offset(left.right, y),
            [accent.withOpacity(0), accent]));
  c.drawRect(
      right,
      Paint()
        ..shader = ui.Gradient.linear(
            Offset(right.left, y),
            Offset(right.right, y),
            [accent, accent.withOpacity(0)]));
  c.drawPath(_pdfStar(Offset(cx, y), 7), Paint()..color = accent);
}

// ───────────── النقوش (خلفية شفافة) ─────────────

void _paintPattern(Canvas canvas, PdfTheme t, int pattern) {
  switch (pattern) {
    case 0:
      {
        const cell = 46.0;
        final stroke = _stroke(t.accent.withOpacity(.16), 1);
        final fill = _fillP(t.accent.withOpacity(.10));
        for (var y = 0.0; y < _pageH + cell; y += cell) {
          for (var x = 0.0; x < _pageW + cell; x += cell) {
            canvas.drawPath(_pdfStar(Offset(x, y), 13), stroke);
            canvas.drawPath(
                _pdfStar(Offset(x + cell / 2, y + cell / 2), 5), fill);
          }
        }
      }
    case 1:
      {
        final fill = _fillP(t.accent.withOpacity(.22));
        var row = 0;
        for (var y = 12.0; y < _pageH; y += 16) {
          final off = row.isEven ? 0.0 : 8.0;
          for (var x = 8.0 + off; x < _pageW; x += 16) {
            canvas.drawCircle(Offset(x, y), 1.5, fill);
          }
          row++;
        }
      }
    case 2:
      {
        final p = _stroke(t.accent.withOpacity(.16), .8);
        for (var k = -_pageH; k < _pageW; k += 24) {
          canvas.drawLine(Offset(k, 0), Offset(k + _pageH, _pageH), p);
          canvas.drawLine(Offset(k + _pageH, 0), Offset(k, _pageH), p);
        }
      }
    case 3:
      {
        const cell = 36.0;
        final p = _stroke(t.accent.withOpacity(.16), .9);
        for (var y = 0.0; y < _pageH + cell; y += cell) {
          for (var x = 0.0; x < _pageW + cell; x += cell) {
            canvas.drawCircle(Offset(x, y), cell / 2, p);
            canvas.drawCircle(Offset(x + cell / 2, y + cell / 2), cell / 2, p);
          }
        }
      }
    case 4:
      {
        final p = _stroke(t.accent.withOpacity(.17), .9);
        final dot = _fillP(t.accent.withOpacity(.14));
        var row = 0;
        for (var y = 0.0; y < _pageH + 48; y += 42) {
          final off = row.isEven ? 0.0 : 28.0;
          for (var x = -28.0 + off; x < _pageW + 56; x += 56) {
            final c = Offset(x, y);
            canvas.drawCircle(c, 9, p);
            for (var i = 0; i < 6; i++) {
              final a = i * math.pi / 3;
              canvas.drawCircle(
                  c + Offset(math.cos(a), math.sin(a)) * 9, 9, p);
            }
            canvas.drawCircle(c, 2.2, dot);
          }
          row++;
        }
      }
    case 5:
      {
        final p = _stroke(t.accent.withOpacity(.16), .7);
        for (var y = 22.0; y < _pageH; y += 14) {
          canvas.drawLine(Offset(0, y), Offset(_pageW, y), p);
        }
      }
    case 7:
      {
        final c = Offset(_pageW / 2, _pageH / 2);
        canvas.drawPath(_pdfStar(c, 200, .8), _stroke(t.accent.withOpacity(.14), 2));
        canvas.drawPath(_pdfStar(c, 140, .6), _stroke(t.accent.withOpacity(.14), 1.6));
        canvas.drawPath(_pdfStar(c, 80, .62), _fillP(t.accent.withOpacity(.06)));
        canvas.drawCircle(c, 40, _stroke(t.accent.withOpacity(.16), 1.2));
      }
    case 8:
      {
        final rnd = math.Random(5);
        final fill = _fillP(t.accent.withOpacity(.20));
        for (var i = 0; i < 80; i++) {
          final c = Offset(rnd.nextDouble() * _pageW, rnd.nextDouble() * _pageH);
          canvas.drawPath(_pdfStar(c, 2 + rnd.nextDouble() * 5, .5), fill);
        }
      }
    default:
      break;
  }
}

// ───────────── الإطارات ─────────────

RRect _frameClip(int frame) {
  if (frame == _frameNone) {
    return RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, _pageW, _pageH), Radius.zero);
  }
  if (frame == _frameArch) {
    return RRect.fromRectAndCorners(_inset(10),
        topLeft: const Radius.circular(62),
        topRight: const Radius.circular(62),
        bottomLeft: const Radius.circular(12),
        bottomRight: const Radius.circular(12));
  }
  return RRect.fromRectAndRadius(_inset(10), const Radius.circular(10));
}

/// مستطيل بزوايا مشطوفة (مثمّن)
Path _chamferPath(Rect r, double c) => Path()
  ..moveTo(r.left + c, r.top)
  ..lineTo(r.right - c, r.top)
  ..lineTo(r.right, r.top + c)
  ..lineTo(r.right, r.bottom - c)
  ..lineTo(r.right - c, r.bottom)
  ..lineTo(r.left + c, r.bottom)
  ..lineTo(r.left, r.bottom - c)
  ..lineTo(r.left, r.top + c)
  ..close();

/// مستطيل بزوايا مقعّرة (على شكل تذكرة)
Path _ticketPath(Rect r, double rad) => Path()
  ..moveTo(r.left + rad, r.top)
  ..lineTo(r.right - rad, r.top)
  ..arcToPoint(Offset(r.right, r.top + rad),
      radius: Radius.circular(rad), clockwise: false)
  ..lineTo(r.right, r.bottom - rad)
  ..arcToPoint(Offset(r.right - rad, r.bottom),
      radius: Radius.circular(rad), clockwise: false)
  ..lineTo(r.left + rad, r.bottom)
  ..arcToPoint(Offset(r.left, r.bottom - rad),
      radius: Radius.circular(rad), clockwise: false)
  ..lineTo(r.left, r.top + rad)
  ..arcToPoint(Offset(r.left + rad, r.top),
      radius: Radius.circular(rad), clockwise: false)
  ..close();

/// الترويسات الإضافية (الأرقام 4 إلى 13)
void _paintHeaderExtra(Canvas canvas, PdfTheme t, int style, Rect rect) {
  final darker = Color.lerp(t.dark, Colors.black, .35)!;
  Paint grad() => Paint()
    ..shader = ui.Gradient.linear(
        rect.topCenter, rect.bottomCenter, [t.dark, darker]);
  switch (style) {
    case 4: // قوس مدبّب
      {
        final shoulder = rect.top + 40;
        final p = Path()
          ..moveTo(rect.left, rect.bottom)
          ..lineTo(rect.left, shoulder)
          ..quadraticBezierTo(
              rect.left, rect.top + 14, rect.center.dx, rect.top)
          ..quadraticBezierTo(
              rect.right, rect.top + 14, rect.right, shoulder)
          ..lineTo(rect.right, rect.bottom)
          ..close();
        canvas.drawPath(p, _fillP(t.accent.withOpacity(.13)));
        canvas.drawPath(p, _stroke(t.accent, 2.2));
      }
    case 5: // داكن منقّط
      {
        final rr = RRect.fromRectAndRadius(rect, const Radius.circular(12));
        canvas.drawRRect(rr, grad());
        canvas.drawRRect(rr, _stroke(t.accent, 2));
        for (final pt in _pointsAlongRect(rect.deflate(8), 14)) {
          canvas.drawCircle(pt, 1.7, _fillP(t.accent.withOpacity(.9)));
        }
      }
    case 6: // مثمّن
      {
        final p = _chamferPath(rect, 24);
        canvas.drawPath(p, _fillP(t.accent.withOpacity(.14)));
        canvas.drawPath(p, _stroke(t.accent, 2.2));
        canvas.drawPath(_chamferPath(rect.deflate(6), 19),
            _stroke(t.dark.withOpacity(.6), .9));
      }
    case 7: // بطن مقوّس
      {
        final p = Path()
          ..moveTo(rect.left, rect.top)
          ..lineTo(rect.right, rect.top)
          ..lineTo(rect.right, rect.bottom - 12)
          ..quadraticBezierTo(
              rect.center.dx, rect.bottom + 14, rect.left, rect.bottom - 12)
          ..close();
        canvas.drawPath(p, _fillP(t.accent.withOpacity(.13)));
        canvas.drawPath(p, _stroke(t.accent, 2));
        canvas.drawLine(rect.topLeft, rect.topRight, _stroke(t.dark, 4));
      }
    case 8: // داكن مقعّر الزوايا
      {
        final p = _ticketPath(rect, 16);
        canvas.drawPath(p, grad());
        canvas.drawPath(p, _stroke(t.accent, 2));
        canvas.drawPath(_ticketPath(rect.deflate(7), 10),
            _stroke(t.accent.withOpacity(.6), .8));
      }
    case 9: // ظل مزدوج
      {
        final rr = RRect.fromRectAndRadius(rect, const Radius.circular(14));
        final shadow = Path.combine(
            PathOperation.difference,
            Path()..addRRect(rr.shift(const Offset(4, 4))),
            Path()..addRRect(rr));
        canvas.drawPath(shadow, _fillP(t.accent.withOpacity(.4)));
        canvas.drawRRect(rr, _stroke(t.accent, 2));
        canvas.drawRRect(
            rr.deflate(5), _stroke(t.dark.withOpacity(.55), .8));
      }
    case 10: // خطان وزخرف
      {
        final y1 = rect.top + 4;
        final y2 = rect.bottom - 4;
        for (final y in [y1, y2]) {
          final inner = y == y1 ? y + 5 : y - 5;
          canvas.drawLine(
              Offset(rect.left, y), Offset(rect.right, y), _stroke(t.accent, 2.2));
          canvas.drawLine(Offset(rect.left + 10, inner),
              Offset(rect.right - 10, inner), _stroke(t.dark.withOpacity(.6), .8));
          _diamondMark(canvas, Offset(rect.center.dx, y), 6, t);
          _diamondMark(canvas, Offset(rect.left, y), 5, t);
          _diamondMark(canvas, Offset(rect.right, y), 5, t);
        }
      }
    case 11: // كبسولة داكنة
      {
        final rr = RRect.fromRectAndRadius(rect, const Radius.circular(46));
        canvas.drawRRect(rr, grad());
        canvas.drawRRect(rr, _stroke(t.accent, 2));
        canvas.drawRRect(
            rr.deflate(6), _stroke(t.accent.withOpacity(.6), .8));
      }
    case 12: // شرفات
      {
        const n = 9;
        const mh = 10.0;
        final step = rect.width / n;
        final p = Path()..moveTo(rect.left, rect.bottom);
        for (var i = 0; i < n; i++) {
          final x0 = rect.left + i * step;
          final y = i.isEven ? rect.top : rect.top + mh;
          p.lineTo(x0, y);
          p.lineTo(x0 + step, y);
        }
        p
          ..lineTo(rect.right, rect.bottom)
          ..close();
        canvas.drawPath(p, _fillP(t.accent.withOpacity(.13)));
        canvas.drawPath(p, _stroke(t.accent, 2));
      }
    case 13: // جوانب مقعّرة
      {
        const b = 14.0;
        final p = Path()
          ..moveTo(rect.left, rect.top)
          ..lineTo(rect.right, rect.top)
          ..quadraticBezierTo(
              rect.right - b * 2, rect.center.dy, rect.right, rect.bottom)
          ..lineTo(rect.left, rect.bottom)
          ..quadraticBezierTo(
              rect.left + b * 2, rect.center.dy, rect.left, rect.top)
          ..close();
        canvas.drawPath(p, _fillP(t.accent.withOpacity(.12)));
        canvas.drawPath(p, _stroke(t.accent, 2));
        for (final c in [
          rect.topLeft,
          rect.topRight,
          rect.bottomLeft,
          rect.bottomRight
        ]) {
          _diamondMark(canvas, c, 5, t);
        }
      }
    default:
      break;
  }
}

void _paintFrame(Canvas canvas, PdfTheme t, int frame) {
  switch (frame) {
    case 0:
      {
        // الإطار الإسلامي الكلاسيكي
        final outer = RRect.fromRectAndRadius(
            Rect.fromLTWH(8, 8, _pageW - 16, _pageH - 16),
            const Radius.circular(12));
        canvas.drawRRect(outer, _stroke(t.accent, 2.4));
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(13, 13, _pageW - 26, _pageH - 26),
                const Radius.circular(9)),
            _stroke(t.accent.withOpacity(.55), .8));
        final inner = Rect.fromLTWH(19, 19, _pageW - 38, _pageH - 38);
        canvas.drawRRect(RRect.fromRectAndRadius(inner, const Radius.circular(5)),
            _stroke(t.dark.withOpacity(.65), 1.2));
        for (final c in [
          inner.topLeft,
          inner.topRight,
          inner.bottomLeft,
          inner.bottomRight,
        ]) {
          _medallion(canvas, c, 13, t);
        }
        _medallion(canvas, Offset(inner.center.dx, inner.top), 8, t);
        _medallion(canvas, Offset(inner.center.dx, inner.bottom), 8, t);
        _medallion(canvas, Offset(inner.left, inner.center.dy), 8, t);
        _medallion(canvas, Offset(inner.right, inner.center.dy), 8, t);
      }
    case 1:
      {
        canvas.drawRRect(
            RRect.fromRectAndRadius(_inset(10), const Radius.circular(6)),
            _stroke(t.accent, 3));
        canvas.drawRRect(
            RRect.fromRectAndRadius(_inset(17), const Radius.circular(3)),
            _stroke(t.dark.withOpacity(.8), 1.2));
        canvas.drawRect(_inset(21), _stroke(t.accent, .8));
      }
    case 2:
      {
        canvas.drawRRect(
            RRect.fromRectAndRadius(_inset(14), const Radius.circular(4)),
            _stroke(t.accent.withOpacity(.7), 1));
        final pts = [
          const Offset(14, 14),
          const Offset(_pageW - 14, 14),
          const Offset(_pageW - 14, _pageH - 14),
          const Offset(14, _pageH - 14),
        ];
        final starts = [0.0, math.pi / 2, math.pi, 3 * math.pi / 2];
        for (var i = 0; i < 4; i++) {
          canvas.drawArc(Rect.fromCircle(center: pts[i], radius: 30), starts[i],
              math.pi / 2, false, _stroke(t.accent, 1.8));
          canvas.drawArc(Rect.fromCircle(center: pts[i], radius: 22), starts[i],
              math.pi / 2, false, _stroke(t.dark.withOpacity(.8), 1.2));
          _medallion(canvas, pts[i], 11, t);
        }
        for (final c in [
          const Offset(_pageW / 2, 14),
          const Offset(_pageW / 2, _pageH - 14),
          const Offset(14, _pageH / 2),
          const Offset(_pageW - 14, _pageH / 2),
        ]) {
          _diamondMark(canvas, c, 6, t);
        }
      }
    case 3:
      {
        final outer = _inset(9);
        final inner = _inset(25);
        final band = Path()
          ..addRect(outer)
          ..addRect(inner)
          ..fillType = PathFillType.evenOdd;
        canvas.drawPath(band, _fillP(t.accent.withOpacity(.22)));
        canvas.drawRect(outer, _stroke(t.accent, 2));
        canvas.drawRect(inner, _stroke(t.dark.withOpacity(.8), 1.2));
        for (final p in _pointsAlongRect(_inset(17), 22)) {
          canvas.drawPath(_pdfStar(p, 5.5, .5), _fillP(t.dark));
        }
        for (final c in [
          Offset(17, 17),
          Offset(_pageW - 17, 17),
          Offset(17, _pageH - 17),
          Offset(_pageW - 17, _pageH - 17),
        ]) {
          _medallion(canvas, c, 11, t);
        }
      }
    case 4:
      {
        canvas.drawRRect(
            RRect.fromRectAndRadius(_inset(10), const Radius.circular(8)),
            _stroke(t.accent, 2));
        canvas.drawRRect(
            RRect.fromRectAndRadius(_inset(26), const Radius.circular(4)),
            _stroke(t.accent.withOpacity(.6), 1));
        for (final p in _pointsAlongRect(_inset(18), 9)) {
          canvas.drawCircle(p, 2.3, _fillP(t.accent));
        }
        for (final c in [
          Offset(18, 18),
          Offset(_pageW - 18, 18),
          Offset(18, _pageH - 18),
          Offset(_pageW - 18, _pageH - 18),
        ]) {
          canvas.drawCircle(c, 6.5, _fillP(t.dark));
          canvas.drawCircle(c, 6.5, _stroke(t.accent, 1.4));
          canvas.drawCircle(c, 2, _fillP(t.accent));
        }
      }
    case 5:
      {
        _scallop(canvas, _inset(10), 9, _stroke(t.accent, 1.7));
        canvas.drawRect(_inset(26), _stroke(t.dark.withOpacity(.75), 1.2));
        canvas.drawRect(_inset(29), _stroke(t.accent.withOpacity(.6), .7));
      }
    case 6:
      {
        canvas.drawRRect(
            RRect.fromRectAndRadius(_inset(10), const Radius.circular(10)),
            _stroke(t.accent, 2.2));
        canvas.drawPath(_wavyRect(_inset(21), 3, 16), _stroke(t.dark.withOpacity(.85), 1.3));
        canvas.drawPath(
            _wavyRect(_inset(21), 3, 16, math.pi), _stroke(t.accent.withOpacity(.85), 1.3));
      }
    case 7:
      {
        canvas.drawRect(_inset(10), _stroke(t.accent, 2.4));
        canvas.drawRect(_inset(15), _stroke(t.dark.withOpacity(.85), 1));
        canvas.drawRect(_inset(19), _stroke(t.accent, 1.6));
        for (final c in [
          const Offset(14, 14),
          const Offset(_pageW - 14, 14),
          const Offset(14, _pageH - 14),
          const Offset(_pageW - 14, _pageH - 14),
        ]) {
          _diamondMark(canvas, c, 11, t);
        }
        for (final c in [
          const Offset(_pageW / 2, 14),
          const Offset(_pageW / 2, _pageH - 14),
          const Offset(14, _pageH / 2),
          const Offset(_pageW - 14, _pageH / 2),
        ]) {
          _diamondMark(canvas, c, 6, t);
        }
      }
    case 8:
      {
        // محراب: قوس علوي كبير
        RRect arch(double d, double top, double bottom) =>
            RRect.fromRectAndCorners(_inset(d),
                topLeft: Radius.circular(top),
                topRight: Radius.circular(top),
                bottomLeft: Radius.circular(bottom),
                bottomRight: Radius.circular(bottom));
        canvas.drawRRect(arch(10, 62, 12), _stroke(t.accent, 2.6));
        canvas.drawRRect(arch(17, 55, 6), _stroke(t.dark.withOpacity(.8), 1.2));
        canvas.drawRRect(
            arch(22, 50, 3), _stroke(t.accent.withOpacity(.6), .8));
        _medallion(canvas, const Offset(_pageW / 2, 11), 10, t);
        _medallion(canvas, const Offset(_pageW / 2, _pageH - 11), 10, t);
        _medallion(canvas, const Offset(17, _pageH - 17), 9, t);
        _medallion(canvas, const Offset(_pageW - 17, _pageH - 17), 9, t);
      }
    case 9:
      {
        canvas.drawRRect(
            RRect.fromRectAndRadius(_inset(14), const Radius.circular(10)),
            _stroke(t.accent, 1.4));
        canvas.drawRRect(
            RRect.fromRectAndRadius(_inset(18), const Radius.circular(7)),
            _stroke(t.accent.withOpacity(.5), .7));
        for (final c in [
          const Offset(_pageW / 2, 14),
          const Offset(_pageW / 2, _pageH - 14),
          const Offset(14, _pageH / 2),
          const Offset(_pageW - 14, _pageH / 2),
        ]) {
          _diamondMark(canvas, c, 5, t);
        }
      }
    case 10:
      {
        canvas.drawRRect(
            RRect.fromRectAndRadius(_inset(13), const Radius.circular(8)),
            _stroke(t.dark, 8));
        canvas.drawRRect(
            RRect.fromRectAndRadius(_inset(9), const Radius.circular(12)),
            _stroke(t.accent, 1.4));
        canvas.drawRRect(
            RRect.fromRectAndRadius(_inset(17), const Radius.circular(4)),
            _stroke(t.accent, 1.4));
        for (final p in _pointsAlongRect(_inset(13), 20)) {
          canvas.drawCircle(p, 1.8, _fillP(t.accent));
        }
        for (final c in [
          const Offset(13, 13),
          const Offset(_pageW - 13, 13),
          const Offset(13, _pageH - 13),
          const Offset(_pageW - 13, _pageH - 13),
        ]) {
          canvas.drawCircle(c, 6, _fillP(t.accent));
          canvas.drawCircle(c, 6, _stroke(t.dark, 1.2));
        }
      }
    case 12:
      {
        canvas.drawRRect(
            RRect.fromRectAndRadius(_inset(11), const Radius.circular(8)),
            _stroke(t.accent, 1.6));
        canvas.drawRRect(
            RRect.fromRectAndRadius(_inset(27), const Radius.circular(4)),
            _stroke(t.dark.withOpacity(.7), 1));
        for (final p in _pointsAlongRect(_inset(19), 12)) {
          canvas.drawCircle(p, 6, _stroke(t.accent, 1.1));
          canvas.drawCircle(p, 1.3, _fillP(t.dark));
        }
        for (final c in [
          Offset(19, 19),
          Offset(_pageW - 19, 19),
          Offset(19, _pageH - 19),
          Offset(_pageW - 19, _pageH - 19),
        ]) {
          _medallion(canvas, c, 10, t);
        }
      }
    case 13:
      {
        canvas.drawRect(_inset(12), _stroke(t.accent, 2));
        canvas.drawRect(_inset(18), _stroke(t.dark.withOpacity(.75), 1));
        for (final c in [
          Offset(12, 12),
          Offset(_pageW - 12, 12),
          Offset(12, _pageH - 12),
          Offset(_pageW - 12, _pageH - 12),
        ]) {
          final sq = Rect.fromCenter(center: c, width: 16, height: 16);
          canvas.drawRect(sq, _fillP(t.accent));
          canvas.drawRect(sq, _stroke(t.dark, 1.2));
          canvas.drawRect(Rect.fromCenter(center: c, width: 6, height: 6),
              _fillP(t.dark));
        }
      }
    case 14:
      {
        canvas.drawRRect(
            RRect.fromRectAndRadius(_inset(10), const Radius.circular(8)),
            _stroke(t.accent, 1.2));
        for (final p in _pointsAlongRect(_inset(16), 7)) {
          canvas.drawCircle(p, 1.4, _fillP(t.accent));
        }
        canvas.drawRRect(
            RRect.fromRectAndRadius(_inset(22), const Radius.circular(4)),
            _stroke(t.dark.withOpacity(.6), .8));
      }
    case 15:
      {
        canvas.drawPath(_ticketPath(_inset(10), 24), _stroke(t.accent, 2.2));
        canvas.drawPath(_ticketPath(_inset(18), 14),
            _stroke(t.dark.withOpacity(.8), 1));
      }
    case 16:
      {
        canvas.drawRect(_inset(9), _stroke(t.accent, 3));
        canvas.drawRect(_inset(15), _stroke(t.dark.withOpacity(.85), 1));
        canvas.drawRect(_inset(19), _stroke(t.accent, 1.2));
        canvas.drawRect(_inset(23), _stroke(t.accent.withOpacity(.5), .6));
      }
    case 17:
      {
        final r = _inset(14);
        canvas.drawRect(r, _stroke(t.accent.withOpacity(.35), 1));
        const len = 46.0;
        final p = Path()
          ..moveTo(r.left, r.top + len)
          ..lineTo(r.left, r.top)
          ..lineTo(r.left + len, r.top)
          ..moveTo(r.right - len, r.top)
          ..lineTo(r.right, r.top)
          ..lineTo(r.right, r.top + len)
          ..moveTo(r.right, r.bottom - len)
          ..lineTo(r.right, r.bottom)
          ..lineTo(r.right - len, r.bottom)
          ..moveTo(r.left + len, r.bottom)
          ..lineTo(r.left, r.bottom)
          ..lineTo(r.left, r.bottom - len);
        canvas.drawPath(p, _stroke(t.accent, 3.2));
        for (final c in [r.topLeft, r.topRight, r.bottomLeft, r.bottomRight]) {
          canvas.drawCircle(c, 4, _fillP(t.dark));
        }
      }
    case 18:
      {
        canvas.drawRRect(
            RRect.fromRectAndRadius(_inset(12), const Radius.circular(6)),
            _stroke(t.accent, 1.8));
        canvas.drawRRect(
            RRect.fromRectAndRadius(_inset(20), const Radius.circular(3)),
            _stroke(t.dark.withOpacity(.7), 1));
        for (final c in [
          Offset(14, 14),
          Offset(_pageW - 14, 14),
          Offset(14, _pageH - 14),
          Offset(_pageW - 14, _pageH - 14),
        ]) {
          canvas.drawPath(_pdfStar(c, 13), _fillP(t.accent));
          canvas.drawPath(_pdfStar(c, 13), _stroke(t.dark, 1));
        }
        for (final c in [
          Offset(_pageW / 2, 12),
          Offset(_pageW / 2, _pageH - 12),
          Offset(12, _pageH / 2),
          Offset(_pageW - 12, _pageH / 2),
        ]) {
          canvas.drawPath(_pdfStar(c, 6, .5), _fillP(t.dark));
        }
      }
    case 19:
      {
        canvas.drawPath(_chamferPath(_inset(10), 24), _stroke(t.accent, 2.2));
        canvas.drawPath(_chamferPath(_inset(17), 17),
            _stroke(t.dark.withOpacity(.8), 1.1));
        for (final c in [
          Offset(22, 22),
          Offset(_pageW - 22, 22),
          Offset(22, _pageH - 22),
          Offset(_pageW - 22, _pageH - 22),
        ]) {
          _diamondMark(canvas, c, 6, t);
        }
      }
    case 20:
      {
        canvas.drawRRect(
            RRect.fromRectAndRadius(_inset(12), const Radius.circular(6)),
            _stroke(t.accent, 7));
        canvas.drawRRect(
            RRect.fromRectAndRadius(_inset(7), const Radius.circular(9)),
            _stroke(t.dark.withOpacity(.85), 1));
        canvas.drawRRect(
            RRect.fromRectAndRadius(_inset(17), const Radius.circular(3)),
            _stroke(t.dark.withOpacity(.85), 1));
      }
    case 21:
      {
        canvas.drawRect(_inset(20), _stroke(t.accent, 1.6));
        for (final c in [
          Offset(20, 20),
          Offset(_pageW - 20, 20),
          Offset(20, _pageH - 20),
          Offset(_pageW - 20, _pageH - 20),
        ]) {
          canvas.drawCircle(c, 15, _stroke(t.accent, 1.8));
          canvas.drawCircle(c, 10.5, _stroke(t.dark.withOpacity(.8), 1));
          _medallion(canvas, c, 6, t);
        }
        for (final c in [
          Offset(_pageW / 2, 20),
          Offset(_pageW / 2, _pageH - 20),
          Offset(20, _pageH / 2),
          Offset(_pageW - 20, _pageH / 2),
        ]) {
          canvas.drawCircle(c, 4, _fillP(t.accent));
        }
      }
    case 22:
      {
        canvas.drawRRect(
            RRect.fromRectAndRadius(_inset(11), const Radius.circular(5)),
            _stroke(t.accent, 1.3));
        canvas.drawRRect(
            RRect.fromRectAndRadius(_inset(25), const Radius.circular(3)),
            _stroke(t.dark.withOpacity(.7), .9));
        var k = 0;
        for (final p in _pointsAlongRect(_inset(18), 16)) {
          if (k.isEven) {
            _diamondMark(canvas, p, 4, t);
          } else {
            canvas.drawCircle(p, 1.8, _fillP(t.accent));
          }
          k++;
        }
      }
    default:
      break; // بدون إطار
  }
}

/// الورقة: لون + نقش شفاف + إطار
void _paintPage(
    Canvas canvas, PdfTheme t, Color paper, int frame, int pattern) {
  canvas.drawRect(Rect.fromLTWH(0, 0, _pageW, _pageH), Paint()..color = paper);
  canvas.save();
  canvas.clipRRect(_frameClip(frame));
  _paintPattern(canvas, t, pattern);
  canvas.restore();
  _paintFrame(canvas, t, frame);
}

// ───────────── الترويسة ─────────────

/// الترويسة: نجمة + العنوان في الوسط + زخرفة + اسم الديوان (4 أشكال)
void _paintHeader(Canvas canvas, PdfTheme t, int style, double top, double h,
    TextPainter title, TextPainter diwan) {
  final rect = Rect.fromLTWH(_mx, top, _avail, h);
  final filled = _headerDark(style);
  if (style >= 4) {
    _paintHeaderExtra(canvas, t, style, rect);
  } else {
  final rr = switch (style) {
    1 => RRect.fromRectAndRadius(rect, const Radius.circular(18)),
    2 => RRect.fromRectAndRadius(rect, const Radius.circular(6)),
    3 => RRect.fromRectAndRadius(rect, const Radius.circular(46)),
    _ => RRect.fromRectAndCorners(
        rect,
        topLeft: const Radius.circular(100),
        topRight: const Radius.circular(100),
        bottomLeft: const Radius.circular(14),
        bottomRight: const Radius.circular(14),
      ),
  };
  if (filled) {
    final darker = Color.lerp(t.dark, Colors.black, .35)!;
    canvas.drawRRect(
        rr,
        Paint()
          ..shader = ui.Gradient.linear(
              rect.topCenter, rect.bottomCenter, [t.dark, darker]));
  } else if (style == 3) {
    canvas.drawRRect(rr, _fillP(t.accent.withOpacity(.16)));
  }
  canvas.drawRRect(rr, _stroke(t.accent, style == 2 ? 2.2 : 2));
  if (style == 1) {
    canvas.drawRRect(
        rr.deflate(5), _stroke(t.accent.withOpacity(.6), .8));
  } else if (style == 2) {
    canvas.drawRRect(rr.deflate(5), _stroke(t.dark.withOpacity(.7), .9));
  } else if (style == 3) {
    canvas.drawRRect(rr.deflate(6), _stroke(t.dark.withOpacity(.55), .9));
  }
  }

  var y = top + 30;
  canvas.drawPath(_pdfStar(Offset(_pageW / 2, y + 11), 11),
      Paint()..color = filled ? t.accent : t.dark);
  y += 22 + 10;
  title.paint(canvas, Offset(_mx + 30, y));
  y += title.height + 10;
  _divider(canvas, _pageW / 2, y + 8, _avail - 60, t.accent);
  y += 16 + 10;
  diwan.paint(canvas, Offset(_mx + 30, y));
}

// ───────────── بناء ملف الـ PDF ─────────────

Future<Uint8List> buildPoemPdf({
  required BuildContext context,
  required Poem poem,
  required String diwan,
  required PdfTheme theme,
  required Color textColor,
  required Color paper,
  int frame = 0,
  int pattern = 0,
  int header = 0,
}) async {
  // نفس ستايل النص الذي يستخدمه التطبيق داخل الصفحات (من الثيم)
  final baseStyle = (Theme.of(context).textTheme.bodyMedium ?? const TextStyle())
      .copyWith(decoration: TextDecoration.none);

  TextStyle styleFor(double s) => withPoemFont(baseStyle.merge(TextStyle(
        fontSize: s,
        height: 1.0,
        color: textColor,
        fontWeight: poemFontWeight,
      )));

  double indentOf(TextStyle st) =>
      measureText('ا        ا', st) - measureText('اا', st);

  // نفس منطق التطبيق: نصغّر الخط لو أطول شطر لا يتّسع
  final texts = <String>[
    for (final v in poem.verses) ...[displayText(v.sadr), displayText(v.ajz)]
  ].map((t) => t.trim().replaceAll(RegExp(r'\s+'), ' ')).toList();

  var size = poemFontSize.value;
  var st = styleFor(size);
  var w = _avail - indentOf(st);
  for (var i = 0; i < 6 && texts.isNotEmpty; i++) {
    final maxW = texts.map((t) => measureText(t, st)).reduce(math.max);
    if (maxW <= w) break;
    size = math.max(12, size * (w / maxW) * 0.995);
    st = styleFor(size);
    w = _avail - indentOf(st);
  }
  final style = st;
  final hw = w;

  TextPainter hemistich(Justified j) => TextPainter(
        text: TextSpan(
          text: j.text,
          style: style.copyWith(
              wordSpacing: j.wordSpacing, height: j.fits ? 1.0 : 1.7),
        ),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        textScaler: TextScaler.noScaling,
      )..layout(minWidth: hw, maxWidth: j.fits ? hw + 2 : hw);

  final sadr = <TextPainter>[];
  final ajz = <TextPainter>[];
  for (final v in poem.verses) {
    sadr.add(hemistich(justifyHemistich(displayText(v.sadr), style, hw)));
    ajz.add(hemistich(justifyHemistich(displayText(v.ajz), style, hw)));
  }
  final n = poem.verses.length;
  final gapV = size * .45;
  final gap = size * .95;
  final hv = [for (var i = 0; i < n; i++) sadr[i].height + gapV + ajz[i].height];
  final sep = gap * 1.2 + 16;

  TextPainter centered(String text, TextStyle s, double width) => TextPainter(
        text: TextSpan(text: text, style: s),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
        textScaler: TextScaler.noScaling,
      )..layout(minWidth: width, maxWidth: width);

  // الترويسة (الصفحة الأولى)
  final darkHeader = _headerDark(header);
  final titleP = centered(
      poem.title,
      baseStyle.merge(TextStyle(
          color: darkHeader ? Colors.white : theme.dark,
          fontSize: 22,
          height: 1.5,
          fontWeight: FontWeight.bold)),
      _avail - 60);
  final diwanP = centered(
      diwan,
      baseStyle.merge(TextStyle(
          color: darkHeader
              ? const Color(0xFFE8D9BC)
              : Color.lerp(theme.accent, Colors.black, .35),
          fontSize: 14,
          height: 1.4)),
      _avail - 60);
  final headerH = 30 + 22 + 10 + titleP.height + 10 + 16 + 10 + diwanP.height + 22;
  const headerTop = 38.0;
  final firstStart = headerTop + headerH + 26;

  // التذييل (الصفحة الأخيرة)
  final f1 = centered(
      'كلمات شاعر رسول الله ﷺ',
      baseStyle.merge(TextStyle(
          color: theme.dark, fontSize: 17, fontWeight: FontWeight.bold)),
      _avail);
  final f2 = centered(
      'عبدالرحمن مصطفى الأزهري',
      baseStyle.merge(TextStyle(
          color: Color.lerp(theme.accent, Colors.black, .3),
          fontSize: 15,
          fontWeight: FontWeight.w600)),
      _avail);
  final footerH = 26 + 16 + 14 + f1.height + 8 + f2.height + 4;

  // توزيع الأبيات على الصفحات
  final pages = <List<int>>[<int>[]];
  var y = firstStart;
  for (var i = 0; i < n; i++) {
    final need = hv[i] + (i == n - 1 ? footerH : 0);
    var before = pages.last.isEmpty ? 0.0 : sep;
    if (pages.last.isNotEmpty && y + before + need > _bottom) {
      pages.add(<int>[]);
      y = _top;
      before = 0;
    }
    y += before + hv[i];
    pages.last.add(i);
  }

  Future<Uint8List> renderPage(int pi, List<int> idx) async {
    final rec = ui.PictureRecorder();
    // بدون cullRect: وجوده مع التكبير كان يقص كل ما بعد أول ثلث من الصفحة
    final canvas = Canvas(rec);
    canvas.scale(_scale);
    _paintPage(canvas, theme, paper, frame, pattern);

    var py = _top;
    if (pi == 0) {
      _paintHeader(canvas, theme, header, headerTop, headerH, titleP, diwanP);
      py = firstStart;
    }
    for (var k = 0; k < idx.length; k++) {
      final i = idx[k];
      if (k > 0) {
        py += gap * .6;
        _divider(canvas, _pageW / 2, py + 8, _avail * .9, theme.accent);
        py += 16 + gap * .6;
      }
      // الصدر: من أقصى اليمين
      sadr[i].paint(canvas, Offset(_mx + _avail - sadr[i].width, py));
      py += sadr[i].height + gapV;
      // العجز: تحته مزاحًا لليسار
      ajz[i].paint(canvas, Offset(_mx, py));
      py += ajz[i].height;
    }
    if (pi == pages.length - 1) {
      py += 26;
      _divider(canvas, _pageW / 2, py + 8, _avail * .6, theme.accent);
      py += 16 + 14;
      f1.paint(canvas, Offset(_mx, py));
      py += f1.height + 8;
      f2.paint(canvas, Offset(_mx, py));
    }

    final pic = rec.endRecording();
    final img = await pic.toImage(
        (_pageW * _scale).round(), (_pageH * _scale).round());
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    pic.dispose();
    return bd!.buffer.asUint8List();
  }

  final doc = pw.Document();
  for (var pi = 0; pi < pages.length; pi++) {
    final png = await renderPage(pi, pages[pi]);
    final image = pw.MemoryImage(png);
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (_) => pw.FullPage(
        ignoreMargins: true,
        child: pw.Image(image, fit: pw.BoxFit.fill),
      ),
    ));
  }
  return doc.save();
}

// ───────────── معاينة حيّة للتصميم ─────────────

class _DesignPreview extends CustomPainter {
  final PdfTheme theme;
  final Color paper;
  final Color text;
  final int frame;
  final int pattern;
  final int header;
  const _DesignPreview(
      this.theme, this.paper, this.text, this.frame, this.pattern, this.header);

  TextPainter _tp(String s, TextStyle st) => TextPainter(
        text: TextSpan(text: s, style: st),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
      )..layout(minWidth: _avail - 60, maxWidth: _avail - 60);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _pageW);
    canvas.clipRect(Rect.fromLTWH(0, 0, _pageW, _pageH));
    _paintPage(canvas, theme, paper, frame, pattern);

    final dark = _headerDark(header);
    final title = _tp(
        'عنوان القصيدة',
        TextStyle(
            color: dark ? Colors.white : theme.dark,
            fontSize: 22,
            height: 1.5,
            fontWeight: FontWeight.bold));
    final diwan = _tp(
        'اسم الديوان',
        TextStyle(
            color: dark
                ? const Color(0xFFE8D9BC)
                : Color.lerp(theme.accent, Colors.black, .35),
            fontSize: 14,
            height: 1.4));
    final headerH = 30 + 22 + 10 + title.height + 10 + 16 + 10 + diwan.height + 22;
    _paintHeader(canvas, theme, header, 38, headerH, title, diwan);

    final bar = _fillP(text.withOpacity(.5));
    var y = 38 + headerH + 30;
    for (var k = 0; k < 7 && y < _pageH - 70; k++) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(_mx + _avail * .12, y, _avail * .88, 7),
              const Radius.circular(3)),
          bar);
      y += 17;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(_mx, y, _avail * .86, 7), const Radius.circular(3)),
          bar);
      y += 30;
    }
  }

  @override
  bool shouldRepaint(covariant _DesignPreview old) => true;
}

// ───────────── نافذة الخيارات + الحفظ ─────────────

/// اختيارات تصميم الـ PDF
typedef _Design = ({
  int theme,
  int text,
  int paper,
  int frame,
  int pattern,
  int header
});

/// نافذة اختيار التصميم (الإطار والنقوش والترويسة والألوان) مع معاينة حيّة.
/// ترجع null لو أُغلقت النافذة بدون إنشاء.
Future<_Design?> _pickDesign(BuildContext context, String heading,
    {Color? initialText}) async {
  var themeI = 0;
  var textI = colorChoices
      .indexWhere((c) => c.color == (initialText ?? poemFontColor.value));
  if (textI < 0) textI = 0;
  var paperI = 0;
  var frameI = 0;
  var patI = 0;
  var headI = 0;

  Widget swatch({
    required Widget dot,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 66,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: selected ? brown : Colors.black26,
                      width: selected ? 3 : 1),
                ),
                child: dot,
              ),
              const SizedBox(height: 4),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ),
      );

  Widget title(String t) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 8),
        child: Text(t,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: brown)),
      );

  final go = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: cream,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) {
        Widget chips(List<String> labels, int sel, void Function(int) pick) =>
            Wrap(spacing: 8, runSpacing: 6, children: [
              for (var i = 0; i < labels.length; i++)
                ChoiceChip(
                  label: Text(labels[i],
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              sel == i ? FontWeight.bold : FontWeight.normal,
                          color: sel == i ? Colors.white : brownDark)),
                  selected: sel == i,
                  showCheckmark: false,
                  selectedColor: brown,
                  backgroundColor: Colors.white,
                  onSelected: (_) => setS(() => pick(i)),
                ),
            ]);

        void shuffle() {
          final r = math.Random();
          setS(() {
            themeI = r.nextInt(pdfThemes.length);
            paperI = r.nextInt(paperChoices.length);
            frameI = r.nextInt(frameLabels.length);
            patI = r.nextInt(patternLabels.length);
            headI = r.nextInt(headerLabels.length);
          });
        }

        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * .92,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(heading,
                            style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: brown)),
                      ),
                      TextButton.icon(
                        onPressed: shuffle,
                        icon: Icon(Icons.shuffle_rounded, color: brown),
                        label: Text('تصميم عشوائي',
                            style: TextStyle(color: brown)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 210,
                  child: AspectRatio(
                    aspectRatio: _pageW / _pageH,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3)),
                        ],
                      ),
                      child: CustomPaint(
                        painter: _DesignPreview(
                            pdfThemes[themeI],
                            paperChoices[paperI].color,
                            colorChoices[textI].color,
                            frameI,
                            patI,
                            headI),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        title('شكل الإطار'),
                        chips(frameLabels, frameI, (i) => frameI = i),
                        title('نقوش الخلفية'),
                        chips(patternLabels, patI, (i) => patI = i),
                        title('شكل الترويسة'),
                        chips(headerLabels, headI, (i) => headI = i),
                        title('لون الإطار والزخرفة'),
                        Wrap(spacing: 10, runSpacing: 10, children: [
                          for (var i = 0; i < pdfThemes.length; i++)
                            swatch(
                              dot: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: pdfThemes[i].dark,
                                  border: Border.all(
                                      color: pdfThemes[i].accent, width: 3),
                                ),
                              ),
                              label: pdfThemes[i].label,
                              selected: themeI == i,
                              onTap: () => setS(() => themeI = i),
                            ),
                        ]),
                        title('لون الخط'),
                        Wrap(spacing: 10, runSpacing: 10, children: [
                          for (var i = 0; i < colorChoices.length; i++)
                            swatch(
                              dot: Container(
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: colorChoices[i].color)),
                              label: colorChoices[i].label,
                              selected: textI == i,
                              onTap: () => setS(() => textI = i),
                            ),
                        ]),
                        title('لون الورقة'),
                        Wrap(spacing: 10, runSpacing: 10, children: [
                          for (var i = 0; i < paperChoices.length; i++)
                            swatch(
                              dot: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: paperChoices[i].color,
                                  border: Border.all(color: Colors.black12),
                                ),
                              ),
                              label: paperChoices[i].label,
                              selected: paperI == i,
                              onTap: () => setS(() => paperI = i),
                            ),
                        ]),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                          backgroundColor: brown,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: () => Navigator.pop(ctx, true),
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: const Text('إنشاء وحفظ PDF',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  if (go != true) return null;
  return (
    theme: themeI,
    text: textI,
    paper: paperI,
    frame: frameI,
    pattern: patI,
    header: headI,
  );
}

Future<void> showPoemPdfSheet(
    BuildContext context, Poem poem, String diwan) async {
  final d = await _pickDesign(context, 'تحويل القصيدة إلى PDF');
  if (d == null || !context.mounted) return;
  await _exportPdf(
    context,
    poem,
    diwan,
    pdfThemes[d.theme],
    colorChoices[d.text].color,
    paperChoices[d.paper].color,
    d.frame,
    d.pattern,
    d.header,
  );
}

Future<void> _exportPdf(BuildContext context, Poem poem, String diwan,
    PdfTheme theme, Color text, Color paper, int frame, int pattern,
    int header) async {
  final messenger = ScaffoldMessenger.of(context);

  void toast(String m) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
        content: Text(m, textAlign: TextAlign.center),
        duration: const Duration(seconds: 3)));

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: Dialog(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 18),
              Text('جاري إنشاء ملف PDF…'),
            ],
          ),
        ),
      ),
    ),
  );
  await Future<void>.delayed(const Duration(milliseconds: 150));

  Uint8List? bytes;
  try {
    bytes = await buildPoemPdf(
      context: context,
      poem: poem,
      diwan: diwan,
      theme: theme,
      textColor: text,
      paper: paper,
      frame: frame,
      pattern: pattern,
      header: header,
    );
  } catch (_) {
    bytes = null;
  }
  if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

  if (bytes == null) {
    toast('تعذّر إنشاء الملف');
    return;
  }

  // يُحفظ مباشرة داخل التطبيق (قسم "الملفات") باسم القصيدة، بدون أي سؤال
  final inApp = await SavedFiles.save(SavedKind.pdf, poem.title, bytes);
  toast(inApp != null
      ? 'تم حفظ القصيدة في قسم «الملفات»'
      : 'تعذّر حفظ الملف');
}


// ════════════════════════════════════════════════
// بيت واحد كصورة (بنفس تصميم الـ PDF)
// ════════════════════════════════════════════════

Future<Uint8List> buildVerseImage({
  required BuildContext context,
  required String title,
  required List<(String, String)> verses, // من 1 إلى 3 أبيات (صدر، عجز)
  required PdfTheme theme,
  required Color textColor,
  required Color paper,
  int frame = 0,
  int pattern = 0,
}) async {
  final baseStyle = (Theme.of(context).textTheme.bodyMedium ?? const TextStyle())
      .copyWith(decoration: TextDecoration.none);

  TextStyle styleFor(double s) => withPoemFont(baseStyle.merge(TextStyle(
        fontSize: s,
        height: 1.0,
        color: textColor,
        fontWeight: poemFontWeight,
      )));

  double indentOf(TextStyle st) =>
      measureText('ا        ا', st) - measureText('اا', st);

  final count = verses.length;
  final texts = [
    for (final v in verses) ...[displayText(v.$1), displayText(v.$2)],
  ].map((t) => t.trim().replaceAll(RegExp(r'\s+'), ' ')).toList();

  var size = count == 1 ? 26.0 : (count == 2 ? 24.0 : 22.0);
  var st = styleFor(size);
  var w = _avail - indentOf(st);
  for (var i = 0; i < 6; i++) {
    final maxW = texts.map((t) => measureText(t, st)).reduce(math.max);
    if (maxW <= w) break;
    size = math.max(12, size * (w / maxW) * 0.995);
    st = styleFor(size);
    w = _avail - indentOf(st);
  }
  final style = st;
  final hw = w;

  TextPainter hemistich(Justified j) => TextPainter(
        text: TextSpan(
          text: j.text,
          style: style.copyWith(
              wordSpacing: j.wordSpacing, height: j.fits ? 1.0 : 1.7),
        ),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        textScaler: TextScaler.noScaling,
      )..layout(minWidth: hw, maxWidth: j.fits ? hw + 2 : hw);

  TextPainter centered(String text, TextStyle s, double width) => TextPainter(
        text: TextSpan(text: text, style: s),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
        textScaler: TextScaler.noScaling,
      )..layout(minWidth: width, maxWidth: width);

  final sp = <TextPainter>[];
  final aj = <TextPainter>[];
  for (var i = 0; i < count; i++) {
    sp.add(hemistich(justifyHemistich(texts[2 * i], style, hw)));
    aj.add(hemistich(justifyHemistich(texts[2 * i + 1], style, hw)));
  }
  final titleP = centered(
      title,
      baseStyle.merge(TextStyle(
          color: theme.dark,
          fontSize: 17,
          height: 1.5,
          fontWeight: FontWeight.bold)),
      _avail - 20);
  final f1 = centered(
      'كلمات شاعر رسول الله ﷺ',
      baseStyle.merge(TextStyle(
          color: theme.dark, fontSize: 14, fontWeight: FontWeight.bold)),
      _avail);
  final f2 = centered(
      'عبدالرحمن مصطفى الأزهري',
      baseStyle.merge(TextStyle(
          color: Color.lerp(theme.accent, Colors.black, .3),
          fontSize: 13,
          fontWeight: FontWeight.w600)),
      _avail);

  final gapV = size * .45;
  const betweenVerses = 14.0 + 16 + 14; // فاصل زخرفي بين الأبيات
  var versesH = 0.0;
  for (var i = 0; i < count; i++) {
    versesH += sp[i].height + gapV + aj[i].height;
    if (i > 0) versesH += betweenVerses;
  }
  final contentH = 24 + 12 + titleP.height + 12 + 16 + 28 + versesH + 28 + 16 +
      12 + f1.height + 4 + f2.height;
  var y = math.max(70.0, (_pageH - contentH) / 2);

  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  canvas.scale(_scale);
  _paintPage(canvas, theme, paper, frame, pattern);

  canvas.drawPath(
      _pdfStar(Offset(_pageW / 2, y + 12), 12), Paint()..color = theme.accent);
  y += 24 + 12;
  titleP.paint(canvas, Offset(_mx + 10, y));
  y += titleP.height + 12;
  _divider(canvas, _pageW / 2, y + 8, _avail * .8, theme.accent);
  y += 16 + 28;
  for (var i = 0; i < count; i++) {
    if (i > 0) {
      y += 14;
      _divider(canvas, _pageW / 2, y + 8, _avail * .35, theme.accent);
      y += 16 + 14;
    }
    sp[i].paint(canvas, Offset(_mx + _avail - sp[i].width, y));
    y += sp[i].height + gapV;
    aj[i].paint(canvas, Offset(_mx, y));
    y += aj[i].height;
  }
  y += 28;
  _divider(canvas, _pageW / 2, y + 8, _avail * .5, theme.accent);
  y += 16 + 12;
  f1.paint(canvas, Offset(_mx, y));
  y += f1.height + 4;
  f2.paint(canvas, Offset(_mx, y));

  final pic = rec.endRecording();
  final img = await pic.toImage(
      (_pageW * _scale).round(), (_pageH * _scale).round());
  final bd = await img.toByteData(format: ui.ImageByteFormat.png);
  img.dispose();
  pic.dispose();
  return bd!.buffer.asUint8List();
}

/// نسخ البيت (أو البيتين / الثلاثة) كنص مع اسم القصيدة
Future<void> copyVerseText(BuildContext context, Poem poem, Verse v,
    [Verse? next, Verse? third]) async {
  String two(Verse x) =>
      '${displayText(x.sadr).trim()}\n${displayText(x.ajz).trim()}\n';
  final text = '${two(v)}'
      '${next == null ? '' : two(next)}'
      '${third == null ? '' : two(third)}'
      '— ${poem.title}\nكلمات شاعر رسول الله ﷺ / عبدالرحمن مصطفى الأزهري';
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(
          third != null
              ? 'تم نسخ الأبيات'
              : (next == null ? 'تم نسخ البيت' : 'تم نسخ البيتين'),
          textAlign: TextAlign.center),
      duration: const Duration(seconds: 2),
    ));
}

/// نافذة تصميم صورة البيت (معاينة حيّة) ثم الحفظ
Future<void> showVerseImageSheet(
    BuildContext context, String diwan, Poem poem, Verse verse,
    {Verse? nextVerse, Verse? thirdVerse}) async {
  final messenger = ScaffoldMessenger.of(context);
  var themeI = 0;
  var paperI = 0;
  var frameI = 0;
  var patI = 0;
  var textI = colorChoices.indexWhere((c) => c.color == poemFontColor.value);
  if (textI < 0) textI = 0;
  Future<Uint8List>? fut;

  Widget swatch(Color fill, Color? border, bool selected, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.only(left: 8),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: selected ? brown : Colors.black26,
                width: selected ? 3 : 1),
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fill,
              border: border == null ? null : Border.all(color: border, width: 3),
            ),
          ),
        ),
      );

  Widget title(String t) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Text(t,
            style: TextStyle(
                fontSize: 14.5, fontWeight: FontWeight.bold, color: brown)),
      );

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: cream,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) {
        Future<Uint8List> make() => buildVerseImage(
              context: ctx,
              title: poem.title,
              verses: [
                (verse.sadr, verse.ajz),
                if (nextVerse != null) (nextVerse.sadr, nextVerse.ajz),
                if (thirdVerse != null) (thirdVerse.sadr, thirdVerse.ajz),
              ],
              theme: pdfThemes[themeI],
              textColor: colorChoices[textI].color,
              paper: paperChoices[paperI].color,
              frame: frameI,
              pattern: patI,
            );
        fut ??= make();
        void change(VoidCallback f) => setS(() {
              f();
              fut = make();
            });

        Widget chips(List<String> labels, int sel, void Function(int) pick) =>
            Wrap(spacing: 8, runSpacing: 6, children: [
              for (var i = 0; i < labels.length; i++)
                ChoiceChip(
                  label: Text(labels[i],
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              sel == i ? FontWeight.bold : FontWeight.normal,
                          color: sel == i ? Colors.white : brownDark)),
                  selected: sel == i,
                  showCheckmark: false,
                  selectedColor: brown,
                  backgroundColor: Colors.white,
                  onSelected: (_) => change(() => pick(i)),
                ),
            ]);

        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * .92,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                        thirdVerse != null
                            ? 'حفظ الأبيات كصورة'
                            : (nextVerse == null
                                ? 'حفظ البيت كصورة'
                                : 'حفظ البيتين كصورة'),
                        style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: brown)),
                  ),
                ),
                SizedBox(
                  height: 300,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: _pageW / _pageH,
                      child: DecoratedBox(
                        decoration: BoxDecoration(boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3)),
                        ]),
                        child: FutureBuilder<Uint8List>(
                          future: fut,
                          builder: (_, snap) => snap.hasData
                              ? Image.memory(snap.data!,
                                  fit: BoxFit.fill, gaplessPlayback: true)
                              : const Center(
                                  child: CircularProgressIndicator()),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        title('لون الإطار والزخرفة'),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(children: [
                            for (var i = 0; i < pdfThemes.length; i++)
                              swatch(pdfThemes[i].dark, pdfThemes[i].accent,
                                  themeI == i, () => change(() => themeI = i)),
                          ]),
                        ),
                        title('لون الورقة'),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(children: [
                            for (var i = 0; i < paperChoices.length; i++)
                              swatch(paperChoices[i].color, Colors.black12,
                                  paperI == i, () => change(() => paperI = i)),
                          ]),
                        ),
                        title('لون الخط'),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(children: [
                            for (var i = 0; i < colorChoices.length; i++)
                              swatch(colorChoices[i].color, null, textI == i,
                                  () => change(() => textI = i)),
                          ]),
                        ),
                        title('شكل الإطار'),
                        chips(frameLabels, frameI, (i) => frameI = i),
                        title('نقوش الخلفية'),
                        chips(patternLabels, patI, (i) => patI = i),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                              backgroundColor: brown,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14)),
                          onPressed: () async {
                            final bytes = await fut!;
                            if (ctx.mounted) Navigator.pop(ctx);
                            void toast(String m) => messenger
                              ..hideCurrentSnackBar()
                              ..showSnackBar(SnackBar(
                                  content: Text(m, textAlign: TextAlign.center),
                                  duration: const Duration(seconds: 3)));
                            // يُحفظ مباشرة داخل التطبيق (قسم "الملفات") باسم القصيدة، بدون أي سؤال
                            final inApp = await SavedFiles.save(
                                SavedKind.image, poem.title, bytes);
                            toast(inApp != null
                                ? 'تم حفظ الصورة في قسم «الملفات»'
                                : 'تعذّر حفظ الصورة');
                          },
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('حفظ الصورة',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                              foregroundColor: brown,
                              side: BorderSide(color: brown),
                              padding: const EdgeInsets.symmetric(vertical: 14)),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await copyVerseText(
                                context, poem, verse, nextVerse, thirdVerse);
                          },
                          icon: const Icon(Icons.copy_rounded),
                          label: const Text('نسخ النص'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}


// ════════════════════════════════════════════════
// الصلوات: PDF للقسم كاملًا + صورة لصيغة إلى ثلاث صيغ
// (نفس تصميم القصائد: الإطار والنقوش والترويسة والألوان)
// ════════════════════════════════════════════════

/// صيغة واحدة (أو عنوان) بعد ضبط أسطرها بالكشيدة
class _SalawatPara {
  final bool heading;
  final List<TextPainter> lines;
  final double lineGap;
  final double height;
  _SalawatPara(this.heading, this.lines, this.lineGap)
      : height = lines.fold<double>(0, (a, p) => a + p.height) +
            (lines.length > 1 ? (lines.length - 1) * lineGap : 0);
}

/// سطر واحد مضبوط بالكشيدة (ورقم الصلاة في أول سطر يُلوَّن)
TextPainter _salawatLine(Justified j, TextStyle style, double hw,
    {Color? numberColor}) {
  final List<InlineSpan> kids;
  final sp = j.text.indexOf(' ');
  if (numberColor != null && sp > 0) {
    kids = [
      TextSpan(
          text: j.text.substring(0, sp), style: TextStyle(color: numberColor)),
      TextSpan(text: j.text.substring(sp)),
    ];
  } else {
    kids = [TextSpan(text: j.text)];
  }
  return TextPainter(
    text: TextSpan(
      style: style.copyWith(
          wordSpacing: j.wordSpacing, height: j.fits ? 1.0 : 1.7),
      children: kids,
    ),
    textDirection: TextDirection.rtl,
    textAlign: TextAlign.right,
    textScaler: TextScaler.noScaling,
  )..layout(minWidth: hw, maxWidth: j.fits ? hw + 2 : hw);
}

_SalawatPara _makeSalawatPara(
    SBlock b, TextStyle style, double hw, double size, PdfTheme theme) {
  if (b.heading) {
    final tp = TextPainter(
      text: TextSpan(
        text: salawatDisplayText(b.text),
        style: style.copyWith(
            color: theme.dark,
            fontWeight: FontWeight.bold,
            fontSize: size * .95,
            height: 1.3),
      ),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
      textScaler: TextScaler.noScaling,
    )..layout(minWidth: hw, maxWidth: hw);
    return _SalawatPara(true, [tp], 0);
  }
  var t = salawatDisplayText(b.text);
  if (b.number != null) t = '(${arDigits(b.number!)}) $t';
  final lines = salawatBreakLines(t, style, hw);
  final painters = <TextPainter>[];
  for (var k = 0; k < lines.length; k++) {
    final j = justifyHemistich(lines[k], style, hw,
        maxPerSlot: 16, maxWordSpacing: 24);
    painters.add(_salawatLine(j, style, hw,
        numberColor: (b.number != null && k == 0) ? theme.accent : null));
  }
  return _SalawatPara(false, painters, size * .62);
}

/// يرسم الصيغة ويرجع الإحداثي الرأسي بعدها
double _paintSalawatPara(Canvas canvas, _SalawatPara p, double y) {
  if (p.heading) {
    p.lines.first.paint(canvas, Offset(_mx, y));
    return y + p.height;
  }
  var py = y;
  for (var k = 0; k < p.lines.length; k++) {
    if (k > 0) py += p.lineGap;
    final tp = p.lines[k];
    tp.paint(canvas, Offset(_mx + _avail - tp.width, py));
    py += tp.height;
  }
  return py;
}

/// سطرا «كلمات / شاعر رسول الله ﷺ» و«عبدالرحمن مصطفى الأزهري»
(TextPainter, TextPainter) _salawatCreditPainters(
    TextStyle base, PdfTheme theme) {
  final s1 = withSalawatFont(base.merge(TextStyle(
      color: Color.lerp(theme.accent, Colors.black, .35),
      fontSize: 13,
      height: 1.5,
      fontWeight: FontWeight.w600)));
  final s2 = withSalawatFont(base.merge(TextStyle(
      color: theme.dark,
      fontSize: 16,
      height: 1.5,
      fontWeight: FontWeight.bold)));
  return (
    _centeredPainter(kSalawatCredit1, s1, _avail),
    _centeredPainter(kSalawatCredit2, s2, _avail),
  );
}

/// يرسم الختام (فاصل + السطرين) من الإحداثي [y]
void _paintSalawatCredit(Canvas canvas, (TextPainter, TextPainter) c,
    PdfTheme theme, double y) {
  _divider(canvas, _pageW / 2, y + 8, _avail * .5, theme.accent);
  var py = y + 16 + 8;
  c.$1.paint(canvas, Offset(_mx, py));
  py += c.$1.height + 2;
  c.$2.paint(canvas, Offset(_mx, py));
}

double _salawatCreditHeight((TextPainter, TextPainter) c) =>
    16 + 8 + c.$1.height + 2 + c.$2.height;

TextPainter _centeredPainter(String text, TextStyle s, double width) =>
    TextPainter(
      text: TextSpan(text: text, style: s),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
      textScaler: TextScaler.noScaling,
    )..layout(minWidth: width, maxWidth: width);

// ───────────── القسم كاملًا كملف PDF ─────────────

Future<Uint8List> buildSalawatPdf({
  required BuildContext context,
  required String title,
  required String subtitle,
  required List<SBlock> blocks,
  required PdfTheme theme,
  required Color textColor,
  required Color paper,
  int frame = 0,
  int pattern = 0,
  int header = 0,
}) async {
  final baseStyle = (Theme.of(context).textTheme.bodyMedium ?? const TextStyle())
      .copyWith(decoration: TextDecoration.none);

  // نفس حجم الخط ونوعه وسُمكه وتشكيله كما في التطبيق بالضبط
  // (فتنكسر الأسطر في الملف مثلما تنكسر في الشاشة)
  final size = salawatFonts.size.value;
  final style = withSalawatFont(baseStyle.merge(TextStyle(
    fontSize: size,
    height: 1.0,
    color: textColor,
    fontWeight: salawatFontWeight,
  )));
  const hw = _avail;
  final credit = _salawatCreditPainters(baseStyle, theme);
  final creditH = _salawatCreditHeight(credit);

  // ضبط كل الصيغ (مع استراحة قصيرة حتى لا تتجمّد دائرة الانتظار)
  final paras = <_SalawatPara>[];
  for (var i = 0; i < blocks.length; i++) {
    paras.add(_makeSalawatPara(blocks[i], style, hw, size, theme));
    if (i % 6 == 5) await Future<void>.delayed(Duration.zero);
  }

  // الترويسة (الصفحة الأولى)
  final darkHeader = _headerDark(header);
  final titleP = _centeredPainter(
      title,
      baseStyle.merge(TextStyle(
          color: darkHeader ? Colors.white : theme.dark,
          fontSize: 22,
          height: 1.5,
          fontWeight: FontWeight.bold)),
      _avail - 60);
  final subP = _centeredPainter(
      subtitle,
      baseStyle.merge(TextStyle(
          color: darkHeader
              ? const Color(0xFFE8D9BC)
              : Color.lerp(theme.accent, Colors.black, .35),
          fontSize: 14,
          height: 1.4)),
      _avail - 60);
  final headerH = 30 + 22 + 10 + titleP.height + 10 + 16 + 10 + subP.height + 22;
  const headerTop = 38.0;
  final firstStart = headerTop + headerH + 26;

  // توزيع الصيغ على الصفحات
  final gap = size * .95;
  final divSpace = gap * .6 + 16 + gap * .6;
  final pages = <List<int>>[<int>[]];
  var y = firstStart;
  for (var i = 0; i < paras.length; i++) {
    var need = paras[i].height;
    // العنوان لا يبقى وحده في آخر الصفحة
    if (paras[i].heading && i + 1 < paras.length) {
      need += gap + paras[i + 1].height;
    }
    var before = 0.0;
    if (pages.last.isNotEmpty) {
      before = (paras[i - 1].heading || paras[i].heading) ? gap : divSpace;
    }
    if (pages.last.isNotEmpty && y + before + need > _bottom) {
      pages.add(<int>[]);
      y = _top;
      before = 0;
    }
    y += before + paras[i].height;
    pages.last.add(i);
  }
  // الختام في آخر الصفحة الأخيرة، ولو لم يتّسع له مكان يُوضع في صفحة جديدة
  var creditY = y + gap * 1.2;
  if (creditY + creditH > _bottom) {
    pages.add(<int>[]);
    creditY = _top + 10;
  }

  const scale = 2.5;
  Future<Uint8List> renderPage(int pi, List<int> idx) async {
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    canvas.scale(scale);
    _paintPage(canvas, theme, paper, frame, pattern);

    var py = _top;
    if (pi == 0) {
      _paintHeader(canvas, theme, header, headerTop, headerH, titleP, subP);
      py = firstStart;
    }
    for (var k = 0; k < idx.length; k++) {
      final i = idx[k];
      if (k > 0) {
        if (paras[i - 1].heading || paras[i].heading) {
          py += gap;
        } else {
          py += gap * .6;
          _divider(canvas, _pageW / 2, py + 8, _avail * .9, theme.accent);
          py += 16 + gap * .6;
        }
      }
      py = _paintSalawatPara(canvas, paras[i], py);
    }
    if (pi == pages.length - 1) {
      _paintSalawatCredit(canvas, credit, theme, creditY);
    }

    final pic = rec.endRecording();
    final img = await pic.toImage(
        (_pageW * scale).round(), (_pageH * scale).round());
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    pic.dispose();
    return bd!.buffer.asUint8List();
  }

  final doc = pw.Document();
  for (var pi = 0; pi < pages.length; pi++) {
    final png = await renderPage(pi, pages[pi]);
    final image = pw.MemoryImage(png);
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (_) => pw.FullPage(
        ignoreMargins: true,
        child: pw.Image(image, fit: pw.BoxFit.fill),
      ),
    ));
    await Future<void>.delayed(Duration.zero);
  }
  return doc.save();
}

/// نافذة تصميم الـ PDF للقسم كاملًا ثم الإنشاء والحفظ
Future<void> showSalawatPdfSheet(BuildContext context, SalawatBook book,
    List<SBlock> blocks, String subtitle) async {
  final d = await _pickDesign(context, 'تحويل القسم إلى PDF',
      initialText: salawatFonts.color.value);
  if (d == null || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  void toast(String m) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
        content: Text(m, textAlign: TextAlign.center),
        duration: const Duration(seconds: 3)));

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: Dialog(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 18),
              Flexible(child: Text('جاري إنشاء ملف PDF… قد يستغرق دقيقة')),
            ],
          ),
        ),
      ),
    ),
  );
  await Future<void>.delayed(const Duration(milliseconds: 150));

  Uint8List? bytes;
  try {
    bytes = await buildSalawatPdf(
      context: context,
      title: book.title,
      subtitle: subtitle,
      blocks: blocks,
      theme: pdfThemes[d.theme],
      textColor: colorChoices[d.text].color,
      paper: paperChoices[d.paper].color,
      frame: d.frame,
      pattern: d.pattern,
      header: d.header,
    );
  } catch (_) {
    bytes = null;
  }
  if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

  if (bytes == null) {
    toast('تعذّر إنشاء الملف');
    return;
  }
  final inApp = await SavedFiles.save(SavedKind.pdf, book.title, bytes);
  toast(inApp != null ? 'تم حفظ الملف في قسم «الملفات»' : 'تعذّر حفظ الملف');
}

// ───────────── صيغة إلى ثلاث صيغ كصورة ─────────────

Future<Uint8List> buildSalawatImage({
  required BuildContext context,
  required String title,
  required List<SBlock> items, // من 1 إلى 3
  required PdfTheme theme,
  required Color textColor,
  required Color paper,
  int frame = 0,
  int pattern = 0,
}) async {
  final baseStyle = (Theme.of(context).textTheme.bodyMedium ?? const TextStyle())
      .copyWith(decoration: TextDecoration.none);

  final titleP = _centeredPainter(
      title,
      baseStyle.merge(TextStyle(
          color: theme.dark,
          fontSize: 17,
          height: 1.5,
          fontWeight: FontWeight.bold)),
      _avail - 20);

  // نصغّر الخط تدريجيًا حتى يتّسع كل المحتوى في الصورة
  final credit = _salawatCreditPainters(baseStyle, theme);
  final creditH = _salawatCreditHeight(credit);
  var size = items.length == 1 ? 26.0 : (items.length == 2 ? 23.0 : 21.0);
  const between = 14.0 + 16 + 14; // فاصل زخرفي بين الصيغ
  const maxH = _pageH - 2 * 74.0;
  var paras = <_SalawatPara>[];
  var contentH = 0.0;
  for (var attempt = 0; attempt < 14; attempt++) {
    final style = withSalawatFont(baseStyle.merge(TextStyle(
      fontSize: size,
      height: 1.0,
      color: textColor,
      fontWeight: salawatFontWeight,
    )));
    paras = [
      for (final b in items) _makeSalawatPara(b, style, _avail, size, theme)
    ];
    final bodyH = paras.fold<double>(0, (a, p) => a + p.height) +
        (paras.length - 1) * between;
    contentH = 24 + 12 + titleP.height + 12 + 16 + 28 + bodyH + 24 + 16 + 10 + creditH;
    if (contentH <= maxH || size <= 12) break;
    size = math.max(12, size * .92);
  }

  var y = math.max(70.0, (_pageH - contentH) / 2);

  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  canvas.scale(_scale);
  _paintPage(canvas, theme, paper, frame, pattern);

  canvas.drawPath(
      _pdfStar(Offset(_pageW / 2, y + 12), 12), Paint()..color = theme.accent);
  y += 24 + 12;
  titleP.paint(canvas, Offset(_mx + 10, y));
  y += titleP.height + 12;
  _divider(canvas, _pageW / 2, y + 8, _avail * .8, theme.accent);
  y += 16 + 28;
  for (var i = 0; i < paras.length; i++) {
    if (i > 0) {
      y += 14;
      _divider(canvas, _pageW / 2, y + 8, _avail * .35, theme.accent);
      y += 16 + 14;
    }
    y = _paintSalawatPara(canvas, paras[i], y);
  }
  y += 24 + 10;
  _paintSalawatCredit(canvas, credit, theme, y);

  final pic = rec.endRecording();
  final img = await pic.toImage(
      (_pageW * _scale).round(), (_pageH * _scale).round());
  final bd = await img.toByteData(format: ui.ImageByteFormat.png);
  img.dispose();
  pic.dispose();
  return bd!.buffer.asUint8List();
}

Future<void> _copySalawatText(
    BuildContext context, String title, List<SBlock> items) async {
  final b = StringBuffer();
  for (final x in items) {
    final t = salawatDisplayText(x.text);
    b
      ..writeln(x.number != null ? '(${arDigits(x.number!)}) $t' : t)
      ..writeln();
  }
  b
    ..writeln('— $title')
    ..writeln()
    ..writeln(kSalawatCredit1)
    ..write(kSalawatCredit2);
  await Clipboard.setData(ClipboardData(text: b.toString()));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(items.length == 1 ? 'تم نسخ الصيغة' : 'تم نسخ الصيغ',
          textAlign: TextAlign.center),
      duration: const Duration(seconds: 2),
    ));
}

/// نافذة تصميم صورة الصيغ (معاينة حيّة) ثم الحفظ.
/// ترجع true لو تم الحفظ أو النسخ.
Future<bool> showSalawatImageSheet(
    BuildContext context, String bookTitle, List<SBlock> items) async {
  final messenger = ScaffoldMessenger.of(context);
  var themeI = 0;
  var paperI = 0;
  var frameI = 0;
  var patI = 0;
  var textI =
      colorChoices.indexWhere((c) => c.color == salawatFonts.color.value);
  if (textI < 0) textI = 0;
  Future<Uint8List>? fut;
  var done = false;

  Widget swatch(Color fill, Color? border, bool selected, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.only(left: 8),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: selected ? brown : Colors.black26,
                width: selected ? 3 : 1),
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fill,
              border: border == null ? null : Border.all(color: border, width: 3),
            ),
          ),
        ),
      );

  Widget title(String t) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Text(t,
            style: TextStyle(
                fontSize: 14.5, fontWeight: FontWeight.bold, color: brown)),
      );

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: cream,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) {
        Future<Uint8List> make() => buildSalawatImage(
              context: ctx,
              title: bookTitle,
              items: items,
              theme: pdfThemes[themeI],
              textColor: colorChoices[textI].color,
              paper: paperChoices[paperI].color,
              frame: frameI,
              pattern: patI,
            );
        fut ??= make();
        void change(VoidCallback f) => setS(() {
              f();
              fut = make();
            });

        Widget chips(List<String> labels, int sel, void Function(int) pick) =>
            Wrap(spacing: 8, runSpacing: 6, children: [
              for (var i = 0; i < labels.length; i++)
                ChoiceChip(
                  label: Text(labels[i],
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              sel == i ? FontWeight.bold : FontWeight.normal,
                          color: sel == i ? Colors.white : brownDark)),
                  selected: sel == i,
                  showCheckmark: false,
                  selectedColor: brown,
                  backgroundColor: Colors.white,
                  onSelected: (_) => change(() => pick(i)),
                ),
            ]);

        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * .92,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                        items.length == 1
                            ? 'حفظ الصيغة كصورة'
                            : 'حفظ الصيغ كصورة',
                        style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: brown)),
                  ),
                ),
                SizedBox(
                  height: 300,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: _pageW / _pageH,
                      child: DecoratedBox(
                        decoration: BoxDecoration(boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3)),
                        ]),
                        child: FutureBuilder<Uint8List>(
                          future: fut,
                          builder: (_, snap) => snap.hasData
                              ? Image.memory(snap.data!,
                                  fit: BoxFit.fill, gaplessPlayback: true)
                              : const Center(
                                  child: CircularProgressIndicator()),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        title('لون الإطار والزخرفة'),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(children: [
                            for (var i = 0; i < pdfThemes.length; i++)
                              swatch(pdfThemes[i].dark, pdfThemes[i].accent,
                                  themeI == i, () => change(() => themeI = i)),
                          ]),
                        ),
                        title('لون الورقة'),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(children: [
                            for (var i = 0; i < paperChoices.length; i++)
                              swatch(paperChoices[i].color, Colors.black12,
                                  paperI == i, () => change(() => paperI = i)),
                          ]),
                        ),
                        title('لون الخط'),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(children: [
                            for (var i = 0; i < colorChoices.length; i++)
                              swatch(colorChoices[i].color, null, textI == i,
                                  () => change(() => textI = i)),
                          ]),
                        ),
                        title('شكل الإطار'),
                        chips(frameLabels, frameI, (i) => frameI = i),
                        title('نقوش الخلفية'),
                        chips(patternLabels, patI, (i) => patI = i),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                              backgroundColor: brown,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14)),
                          onPressed: () async {
                            final bytes = await fut!;
                            final inApp = await SavedFiles.save(
                                SavedKind.image, bookTitle, bytes);
                            if (inApp != null) done = true;
                            if (ctx.mounted) Navigator.pop(ctx);
                            messenger
                              ..hideCurrentSnackBar()
                              ..showSnackBar(SnackBar(
                                  content: Text(
                                      inApp != null
                                          ? 'تم حفظ الصورة في قسم «الملفات»'
                                          : 'تعذّر حفظ الصورة',
                                      textAlign: TextAlign.center),
                                  duration: const Duration(seconds: 3)));
                          },
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('حفظ الصورة',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                              foregroundColor: brown,
                              side: BorderSide(color: brown),
                              padding: const EdgeInsets.symmetric(vertical: 14)),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            done = true;
                            await _copySalawatText(context, bookTitle, items);
                          },
                          icon: const Icon(Icons.copy_rounded),
                          label: const Text('نسخ النص'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
  return done;
}


// ════════════════════════════════════════════════
// الديوان كله كملف PDF (نفس تصميم القصيدة، وقصائده بالتتابع)
// ════════════════════════════════════════════════

class _DPoem {
  final TextPainter title;
  final List<TextPainter> sadr;
  final List<TextPainter> ajz;
  final double gapV;
  final double gap;
  final List<double> hv;
  _DPoem(this.title, this.sadr, this.ajz, this.gapV, this.gap, this.hv);
  double get titleH => title.height + 8 + 16 + 10;
}

Future<Uint8List> buildDiwanPdf({
  required BuildContext context,
  required String diwan,
  required List<Poem> poemsList,
  required PdfTheme theme,
  required Color textColor,
  required Color paper,
  int frame = 0,
  int pattern = 0,
  int header = 0,
}) async {
  final baseStyle = (Theme.of(context).textTheme.bodyMedium ?? const TextStyle())
      .copyWith(decoration: TextDecoration.none);

  TextStyle styleFor(double s) => withPoemFont(baseStyle.merge(TextStyle(
        fontSize: s,
        height: 1.0,
        color: textColor,
        fontWeight: poemFontWeight,
      )));

  double indentOf(TextStyle st) =>
      measureText('ا        ا', st) - measureText('اا', st);

  TextPainter centered(String text, TextStyle s, double width) => TextPainter(
        text: TextSpan(text: text, style: s),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
        textScaler: TextScaler.noScaling,
      )..layout(minWidth: width, maxWidth: width);

  final titleStyle = baseStyle.merge(TextStyle(
      color: theme.dark,
      fontSize: 19,
      height: 1.5,
      fontWeight: FontWeight.bold));

  // ضبط كل قصيدة (نفس منطق القصيدة المفردة: نصغّر الخط لو أطول شطر لا يتّسع)
  final laid = <_DPoem>[];
  for (var pi = 0; pi < poemsList.length; pi++) {
    final poem = poemsList[pi];
    final texts = <String>[
      for (final v in poem.verses) ...[displayText(v.sadr), displayText(v.ajz)]
    ].map((t) => t.trim().replaceAll(RegExp(r'\s+'), ' ')).toList();

    var size = poemFontSize.value;
    var st = styleFor(size);
    var w = _avail - indentOf(st);
    for (var i = 0; i < 6 && texts.isNotEmpty; i++) {
      final maxW = texts.map((t) => measureText(t, st)).reduce(math.max);
      if (maxW <= w) break;
      size = math.max(12, size * (w / maxW) * 0.995);
      st = styleFor(size);
      w = _avail - indentOf(st);
    }
    final style = st;
    final hw = w;

    TextPainter hemistich(Justified j) => TextPainter(
          text: TextSpan(
            text: j.text,
            style: style.copyWith(
                wordSpacing: j.wordSpacing, height: j.fits ? 1.0 : 1.7),
          ),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          textScaler: TextScaler.noScaling,
        )..layout(minWidth: hw, maxWidth: j.fits ? hw + 2 : hw);

    final sadr = <TextPainter>[];
    final ajz = <TextPainter>[];
    for (final v in poem.verses) {
      sadr.add(hemistich(justifyHemistich(displayText(v.sadr), style, hw)));
      ajz.add(hemistich(justifyHemistich(displayText(v.ajz), style, hw)));
    }
    final gapV = size * .45;
    final hv = [
      for (var i = 0; i < sadr.length; i++)
        sadr[i].height + gapV + ajz[i].height
    ];
    laid.add(_DPoem(centered(poem.title, titleStyle, _avail), sadr, ajz, gapV,
        size * .95, hv));
    if (pi % 3 == 2) await Future<void>.delayed(Duration.zero);
  }

  // الترويسة (الصفحة الأولى): اسم الديوان وعدد قصائده
  final darkHeader = _headerDark(header);
  final titleP = centered(
      diwan,
      baseStyle.merge(TextStyle(
          color: darkHeader ? Colors.white : theme.dark,
          fontSize: 22,
          height: 1.5,
          fontWeight: FontWeight.bold)),
      _avail - 60);
  final subP = centered(
      '${arDigits(poemsList.length)} قصيدة',
      baseStyle.merge(TextStyle(
          color: darkHeader
              ? const Color(0xFFE8D9BC)
              : Color.lerp(theme.accent, Colors.black, .35),
          fontSize: 14,
          height: 1.4)),
      _avail - 60);
  final headerH = 30 + 22 + 10 + titleP.height + 10 + 16 + 10 + subP.height + 22;
  const headerTop = 38.0;
  final firstStart = headerTop + headerH + 26;

  // التذييل (الصفحة الأخيرة) — نفس تذييل القصيدة
  final f1 = centered(
      'كلمات شاعر رسول الله ﷺ',
      baseStyle.merge(TextStyle(
          color: theme.dark, fontSize: 17, fontWeight: FontWeight.bold)),
      _avail);
  final f2 = centered(
      'عبدالرحمن مصطفى الأزهري',
      baseStyle.merge(TextStyle(
          color: Color.lerp(theme.accent, Colors.black, .3),
          fontSize: 15,
          fontWeight: FontWeight.w600)),
      _avail);
  final footerH = 26 + 16 + 14 + f1.height + 8 + f2.height + 4;

  // عناصر الترتيب: (رقم القصيدة، -1 = العنوان / رقم البيت)
  final entries = <(int, int)>[];
  for (var i = 0; i < laid.length; i++) {
    entries.add((i, -1));
    for (var v = 0; v < laid[i].hv.length; v++) {
      entries.add((i, v));
    }
  }
  double heightOf((int, int) e) =>
      e.$2 < 0 ? laid[e.$1].titleH : laid[e.$1].hv[e.$2];
  double beforeOf((int, int) e) {
    if (e.$2 < 0) return 40; // بين القصائد
    if (e.$2 == 0) return 6; // أول بيت تحت العنوان
    final g = laid[e.$1].gap;
    return g * .6 + 16 + g * .6; // فاصل بين الأبيات
  }

  // توزيع العناصر على الصفحات (العنوان لا يبقى وحده في آخر الصفحة)
  final pages = <List<int>>[<int>[]];
  var y = firstStart;
  for (var k = 0; k < entries.length; k++) {
    final e = entries[k];
    var need = heightOf(e);
    if (e.$2 < 0 && k + 1 < entries.length && entries[k + 1].$1 == e.$1) {
      need += 6 + heightOf(entries[k + 1]);
    }
    if (k == entries.length - 1) need += footerH;
    var before = pages.last.isEmpty ? 0.0 : beforeOf(e);
    if (pages.last.isNotEmpty && y + before + need > _bottom) {
      pages.add(<int>[]);
      y = _top;
      before = 0;
    }
    y += before + heightOf(e);
    pages.last.add(k);
  }

  const scale = 2.5;
  Future<Uint8List> renderPage(int pi, List<int> idx) async {
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    canvas.scale(scale);
    _paintPage(canvas, theme, paper, frame, pattern);

    var py = _top;
    if (pi == 0) {
      _paintHeader(canvas, theme, header, headerTop, headerH, titleP, subP);
      py = firstStart;
    }
    for (var n = 0; n < idx.length; n++) {
      final e = entries[idx[n]];
      final p = laid[e.$1];
      if (n > 0) {
        if (e.$2 < 0) {
          py += 40;
        } else if (e.$2 == 0) {
          py += 6;
        } else {
          py += p.gap * .6;
          _divider(canvas, _pageW / 2, py + 8, _avail * .9, theme.accent);
          py += 16 + p.gap * .6;
        }
      }
      if (e.$2 < 0) {
        p.title.paint(canvas, Offset(_mx, py));
        py += p.title.height + 8;
        _divider(canvas, _pageW / 2, py + 8, _avail * .5, theme.accent);
        py += 16 + 10;
      } else {
        final v = e.$2;
        p.sadr[v].paint(canvas, Offset(_mx + _avail - p.sadr[v].width, py));
        py += p.sadr[v].height + p.gapV;
        p.ajz[v].paint(canvas, Offset(_mx, py));
        py += p.ajz[v].height;
      }
    }
    if (pi == pages.length - 1) {
      py += 26;
      _divider(canvas, _pageW / 2, py + 8, _avail * .6, theme.accent);
      py += 16 + 14;
      f1.paint(canvas, Offset(_mx, py));
      py += f1.height + 8;
      f2.paint(canvas, Offset(_mx, py));
    }

    final pic = rec.endRecording();
    final img = await pic.toImage(
        (_pageW * scale).round(), (_pageH * scale).round());
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    pic.dispose();
    return bd!.buffer.asUint8List();
  }

  final doc = pw.Document();
  for (var pi = 0; pi < pages.length; pi++) {
    final png = await renderPage(pi, pages[pi]);
    final image = pw.MemoryImage(png);
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (_) => pw.FullPage(
        ignoreMargins: true,
        child: pw.Image(image, fit: pw.BoxFit.fill),
      ),
    ));
    await Future<void>.delayed(Duration.zero);
  }
  return doc.save();
}

/// نافذة تصميم الـ PDF ثم إنشاء الديوان كله وحفظه في قسم «الملفات»
Future<void> showDiwanPdfSheet(
    BuildContext context, String diwan, List<Poem> list) async {
  final messenger = ScaffoldMessenger.of(context);
  void toast(String m) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
        content: Text(m, textAlign: TextAlign.center),
        duration: const Duration(seconds: 3)));

  if (list.isEmpty) {
    toast('لا توجد قصائد في هذا الديوان');
    return;
  }
  final d = await _pickDesign(context, 'تحويل الديوان كله إلى PDF');
  if (d == null || !context.mounted) return;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 18),
              Flexible(
                  child: Text(
                      'جاري إنشاء ملف الديوان (${arDigits(list.length)} قصيدة)… قد يستغرق عدة دقائق')),
            ],
          ),
        ),
      ),
    ),
  );
  await Future<void>.delayed(const Duration(milliseconds: 150));

  Uint8List? bytes;
  try {
    bytes = await buildDiwanPdf(
      context: context,
      diwan: diwan,
      poemsList: list,
      theme: pdfThemes[d.theme],
      textColor: colorChoices[d.text].color,
      paper: paperChoices[d.paper].color,
      frame: d.frame,
      pattern: d.pattern,
      header: d.header,
    );
  } catch (_) {
    bytes = null;
  }
  if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

  if (bytes == null) {
    toast('تعذّر إنشاء الملف');
    return;
  }
  final inApp = await SavedFiles.save(SavedKind.pdf, diwan, bytes);
  toast(inApp != null ? 'تم حفظ الديوان في قسم «الملفات»' : 'تعذّر حفظ الملف');
}
