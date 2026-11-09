import 'dart:convert' show latin1;
import 'dart:io' show ZLibEncoder;
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
  PdfTheme('أخضر ملكي ونحاسي', Color(0xFF0B3D2E), Color(0xFFB87333)),
  PdfTheme('أزرق ليلي وذهبي', Color(0xFF0A1F44), Color(0xFFE0B341)),
  PdfTheme('عنابي داكن ونحاسي', Color(0xFF4A0E1F), Color(0xFFC9885B)),
  PdfTheme('بنفسجي وذهبي فاتح', Color(0xFF6A1B9A), Color(0xFFE8C170)),
  PdfTheme('أخضر نعناعي وفضي', Color(0xFF2E7D6B), Color(0xFFB5C9C3)),
  PdfTheme('طوبي وذهبي', Color(0xFF8E2A1A), Color(0xFFD9A441)),
  PdfTheme('رمادي أزرق وذهبي', Color(0xFF34495E), Color(0xFFD4AF37)),
  PdfTheme('زيتي وبرونزي', Color(0xFF4B5320), Color(0xFFCD9B4A)),
  PdfTheme('أسود وفضي', Color(0xFF1C1C1C), Color(0xFFB0B7BF)),
  PdfTheme('وردي غامق وذهبي وردي', Color(0xFFAD1457), Color(0xFFE6B89C)),
  PdfTheme('تركوازي ملكي وذهبي', Color(0xFF006064), Color(0xFFD4AF37)),
  PdfTheme('نيلي وذهبي', Color(0xFF283593), Color(0xFFE0B341)),
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
  PaperChoice('عاجي', Color(0xFFFFF8E7)),
  PaperChoice('وردة باهتة', Color(0xFFFBE9E7)),
  PaperChoice('سماوي باهت', Color(0xFFE0F7FA)),
  PaperChoice('أخضر ربيعي', Color(0xFFF4F9E5)),
  PaperChoice('بنفسجي باهت', Color(0xFFEDE7F6)),
  PaperChoice('قهوة بالحليب', Color(0xFFEFE3D3)),
];

// ───────────── تأثيرات الورقة (اختيارية) ─────────────

/// تأثيرات اختيارية على الورقة. تُحفظ اختياراتك أثناء استخدام التطبيق
/// وتنطبق على المعاينة وعلى كل الـ PDF والصور.
class PaperFx {
  bool gradient = false; // تدرّج: الوسط بلون الورقة والحواف أغمق
  bool watermark = false; // علامة مائية كبيرة خفيفة خلف النص
  int edge = 0; // لون حواف التدرّج (0 = تلقائي من لون الزخرفة)
}

final paperFx = PaperFx();

const paperEdgeLabels = [
  'تلقائي',
  'بيج',
  'ذهبي',
  'فضي',
  'بني',
  'أخضر',
  'أزرق',
  'وردي',
  'بنفسجي',
];
const paperEdgeColors = <Color?>[
  null,
  Color(0xFFD7B98E),
  Color(0xFFC9A24B),
  Color(0xFFB0B7BF),
  Color(0xFF8D6E63),
  Color(0xFF7CB342),
  Color(0xFF4FA8C9),
  Color(0xFFE6B89C),
  Color(0xFFB39DDB),
];

/// إشعار «تم الحفظ» مع زر يفتح صفحة «الملفات» مباشرة (على تبويب الـ PDF أو الصور)
void _toastSaved(BuildContext context, ScaffoldMessengerState messenger,
    String text, SavedKind kind) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(text, textAlign: TextAlign.center),
      duration: const Duration(seconds: 6),
      action: SnackBarAction(
        label: 'فتح الملفات',
        textColor: accentGold,
        onPressed: () {
          if (!context.mounted) return;
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => SavedFilesPage(
                  initialTab: kind == SavedKind.pdf ? 0 : 1)));
        },
      ),
    ));
}

/// قسم «تأثيرات الورقة» في نوافذ التصميم؛ [apply] يعيد بناء النافذة (والمعاينة)
Widget _paperFxSection(void Function(VoidCallback) apply) {
  Widget sw(String label, bool v, void Function(bool) set) => SwitchListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        activeColor: brown,
        title: Text(label, style: TextStyle(fontSize: 14, color: brownDark)),
        value: v,
        onChanged: (x) => apply(() => set(x)),
      );
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      sw('تدرّج لون الورقة (الحواف أغمق)', paperFx.gradient,
          (x) => paperFx.gradient = x),
      if (paperFx.gradient)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Wrap(spacing: 8, runSpacing: 6, children: [
            for (var i = 0; i < paperEdgeLabels.length; i++)
              ChoiceChip(
                label: Text(paperEdgeLabels[i],
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: paperFx.edge == i
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color:
                            paperFx.edge == i ? Colors.white : brownDark)),
                selected: paperFx.edge == i,
                showCheckmark: false,
                selectedColor: brown,
                backgroundColor: Colors.white,
                onSelected: (_) => apply(() => paperFx.edge = i),
              ),
          ]),
        ),
      sw('علامة مائية خفيفة خلف النص', paperFx.watermark,
          (x) => paperFx.watermark = x),
    ],
  );
}

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
  'أوراق متسلسلة', // 23
  'ربع الحزب', // 24
  'سلسلة معيّنات', // 25
  'مربعات مثمّنة', // 26
  'هلال ونجوم', // 27
  'ذهبي متدرّج', // 28
  'عقود علوية وسفلية', // 29
  'أزهار الزوايا', // 30
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
  'قشور', // 9
  'سداسيات', // 10
  'خطوط مائلة', // 11
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
  'مفصّص علوي', // 14
  'قوس مدبّب داكن', // 15
  'لوح بنجوم', // 16
  'شريط ورقي', // 17
];

/// الترويسات الملوّنة (نص أبيض) مقابل الفاتحة (نص بلون الثيم)
bool _headerDark(int h) =>
    h <= 1 || h == 5 || h == 8 || h == 11 || h == 15 || h == 17;

// ───────────── مقاسات الصفحة (A4 بالنسبة) ─────────────

const double _pageW = 420;
const double _pageH = 594;
const double _scale = 3.0; // دقة الصورة (3 = حوالي 150 DPI)
const double _mx = 46; // الهامش الجانبي
const double _top = 46;
const double _bottom = _pageH - 52; // آخر 52 للترقيم أسفل الصفحة
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

/// شعار كبير لغلاف الديوان (نجمة مزخرفة) لو لم تُختر أيقونة
void _coverEmblem(Canvas canvas, PdfTheme t, Offset c, double r) {
  canvas.drawCircle(c, r * 1.15, _fillP(t.accent.withOpacity(.10)));
  canvas.drawCircle(c, r * 1.15, _stroke(t.accent.withOpacity(.55), .8));
  canvas.drawPath(_pdfStar(c, r), _fillP(t.dark));
  canvas.drawPath(_pdfStar(c, r), _stroke(t.accent, 1.6));
  canvas.drawPath(_pdfStar(c, r * .62, .62), _stroke(t.accent, 1.2));
  canvas.drawCircle(c, r * .2, _fillP(t.accent));
}

/// عنوان الغلاف: يصغّر الخط تدريجيًا لو العنوان طويل. يرجع (النص، ارتفاع الترويسة)
(TextPainter, double) _coverTitle(String text, TextStyle base, Color color) {
  TextPainter at(double sz) => _centeredPainter(
      text,
      base.merge(TextStyle(
          color: color,
          fontSize: sz,
          height: 1.5,
          fontWeight: FontWeight.bold)),
      _avail - 60);
  var sz = 30.0;
  var tp = at(sz);
  while (tp.height > 120 && sz > 16) {
    sz -= 2;
    tp = at(sz);
  }
  return (tp, math.max(tp.height + 52, 90.0));
}

/// الغلاف الأمامي: أيقونة/شعار، العنوان في ترويسة، سطر تحته، ثم الختام
void _paintCoverPage(Canvas canvas, PdfTheme t, int header, int icon,
    TextPainter title, double bannerH, TextPainter sub, TextPainter f1,
    TextPainter f2) {
  const cx = _pageW / 2;
  if (icon > 0) {
    _paintIcon(canvas, t, icon, const Offset(cx, 105), 80);
  } else {
    _coverEmblem(canvas, t, const Offset(cx, 105), 50);
  }
  const top = 180.0;
  _paintHeaderShape(canvas, t, header, Rect.fromLTWH(_mx, top, _avail, bannerH));
  title.paint(canvas, Offset(_mx + 30, top + (bannerH - title.height) / 2));
  var cy = top + bannerH + _headerOverhang(header) + 22;
  _divider(canvas, cx, cy + 8, _avail * .6, t.accent);
  cy += 16 + 10;
  sub.paint(canvas, Offset(_mx, cy));
  final y2 = _pageH - 66 - f2.height;
  final y1 = y2 - 6 - f1.height;
  _divider(canvas, cx, y1 - 22, _avail * .5, t.accent);
  f1.paint(canvas, Offset(_mx, y1));
  f2.paint(canvas, Offset(_mx, y2));
}

/// الغلاف الخلفي: زخرفة فقط بدون أي كلام
void _paintBackCover(Canvas canvas, PdfTheme t, int icon) {
  const cx = _pageW / 2;
  const cy = _pageH / 2;
  if (icon > 0) {
    _paintIcon(canvas, t, icon, const Offset(cx, cy), 110);
  } else {
    _coverEmblem(canvas, t, const Offset(cx, cy), 62);
  }
  _divider(canvas, cx, cy - 112, _avail * .6, t.accent);
  _divider(canvas, cx, cy + 112, _avail * .6, t.accent);
}

/// رقم الصفحة أسفلها: ◆ ٣ ◆ بخطين متلاشيين (لا يظهر لو الملف صفحة واحدة)
void _paintPageNumber(
    Canvas canvas, PdfTheme t, TextStyle base, int n, int total) {
  if (total <= 1) return;
  final tp = TextPainter(
    text: TextSpan(
        text: arDigits(n),
        style: base.merge(TextStyle(
            color: t.dark,
            fontSize: 13,
            height: 1.0,
            fontWeight: FontWeight.bold))),
    textDirection: TextDirection.rtl,
    textScaler: TextScaler.noScaling,
  )..layout();
  const cx = _pageW / 2;
  const cy = _pageH - 44.0;
  final half = math.max(tp.width / 2, 6.0) + 11;
  const lineW = 36.0;
  final l = Rect.fromLTRB(cx - half - lineW, cy - .6, cx - half - 5, cy + .6);
  final r = Rect.fromLTRB(cx + half + 5, cy - .6, cx + half + lineW, cy + .6);
  canvas.drawRect(
      l,
      Paint()
        ..shader = ui.Gradient.linear(Offset(l.left, cy), Offset(l.right, cy),
            [t.accent.withOpacity(0), t.accent]));
  canvas.drawRect(
      r,
      Paint()
        ..shader = ui.Gradient.linear(Offset(r.left, cy), Offset(r.right, cy),
            [t.accent, t.accent.withOpacity(0)]));
  _diamondMark(canvas, Offset(cx - half, cy), 3.5, t);
  _diamondMark(canvas, Offset(cx + half, cy), 3.5, t);
  tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
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
    case 9:
      {
        // قشور (أقواس متراكبة)
        final p = _stroke(t.accent.withOpacity(.18), .9);
        var row = 0;
        for (var y = 0.0; y < _pageH + 14; y += 12) {
          final off = row.isEven ? 0.0 : 14.0;
          for (var x = -14.0 + off; x < _pageW + 28; x += 28) {
            canvas.drawArc(Rect.fromCircle(center: Offset(x, y), radius: 14), 0,
                math.pi, false, p);
          }
          row++;
        }
      }
    case 10:
      {
        // خلية سداسية
        const r = 16.0;
        final h = math.sqrt(3) * r;
        final p = _stroke(t.accent.withOpacity(.17), .9);
        var col = 0;
        for (var x = 0.0; x < _pageW + r * 2; x += r * 1.5) {
          for (var y = (col.isOdd ? h / 2 : 0.0) - h; y < _pageH + h; y += h) {
            final hex = Path();
            for (var i = 0; i < 6; i++) {
              final a = i * math.pi / 3;
              final pt = Offset(x + r * math.cos(a), y + r * math.sin(a));
              if (i == 0) {
                hex.moveTo(pt.dx, pt.dy);
              } else {
                hex.lineTo(pt.dx, pt.dy);
              }
            }
            canvas.drawPath(hex..close(), p);
          }
          col++;
        }
      }
    case 11:
      {
        final p = _stroke(t.accent.withOpacity(.16), .8);
        for (var k = -_pageH; k < _pageW; k += 11) {
          canvas.drawLine(Offset(k, _pageH), Offset(k + _pageH, 0), p);
        }
      }
    default:
      break;
  }
}

// ───────────── الإطارات ─────────────

// ───────────── الأيقونات الإسلامية (تُرسم أعلى الصفحة الأولى / أعلى الصورة) ─────────────

const iconLabels = [
  'بدون أيقونة', // 0
  'القبة الخضراء', // 1
  'الكعبة المشرفة', // 2
  'سبحة', // 3
  'يدان للدعاء', // 4
  'هلال ونجمة', // 5
  'مسجد', // 6
  'فانوس', // 7
  'مصحف', // 8
];

const double _iconBand = 70; // المساحة التي تحجزها الأيقونة أعلى الصفحة الأولى
const double _iconSize = 54;
const double _iconCy = 64; // مركز الأيقونة رأسيًا في الصفحة الأولى

/// طبقة واحدة من الأيقونة: مسار SVG مبسّط (M L C Q Z) داخل مربع 100×100.
/// color: 0 = لون الثيم الداكن، 1 = لون الزخرفة، وغير ذلك = لون ثابت ARGB.
class _IconLayer {
  final bool stroke;
  final int color;
  final double w;
  final String d;
  const _IconLayer(this.stroke, this.color, this.w, this.d);
}

const _icons = <List<_IconLayer>>[
  // القبة الخضراء
  [
    _IconLayer(false, 1, 0, 'M49 6L51 6L51 19L49 19Z'),
    _IconLayer(false, 1, 0, 'M53 8C53 9.7 51.7 11 50 11C48.3 11 47 9.7 47 8C47 6.3 48.3 5 50 5C51.7 5 53 6.3 53 8Z'),
    _IconLayer(false, 0xFF2E7D32, 0, 'M24 58C24 40 36 26 50 19C64 26 76 40 76 58Z'),
    _IconLayer(false, 0xFF66BB6A, 0, 'M32 56C32 43 40 33 50 26C43 35 38 45 38 56Z'),
    _IconLayer(true, 1, 1.2, 'M24 58C24 40 36 26 50 19C64 26 76 40 76 58'),
    _IconLayer(false, 1, 0, 'M26 58L74 58L74 68L26 68Z'),
    _IconLayer(false, 0, 0, 'M33 66L33 62Q36 58.5 39 62L39 66Z'),
    _IconLayer(false, 0, 0, 'M45 66L45 62Q48 58.5 51 62L51 66Z'),
    _IconLayer(false, 0, 0, 'M57 66L57 62Q60 58.5 63 62L63 66Z'),
    _IconLayer(false, 0, 0, 'M63 66L63 62Q66 58.5 69 62L69 66Z'),
    _IconLayer(false, 0, 0, 'M14 68L86 68L86 88L14 88Z'),
    _IconLayer(false, 1, 0, 'M14 68L86 68L86 70.5L14 70.5Z'),
    _IconLayer(false, 1, 0, 'M22 88L22 80Q26 74 30 80L30 88Z'),
    _IconLayer(false, 1, 0, 'M36 88L36 80Q40 74 44 80L44 88Z'),
    _IconLayer(false, 1, 0, 'M50 88L50 80Q54 74 58 80L58 88Z'),
    _IconLayer(false, 1, 0, 'M64 88L64 80Q68 74 72 80L72 88Z'),
    _IconLayer(false, 0, 0, 'M6 50L12 50L12 88L6 88Z'),
    _IconLayer(false, 0, 0, 'M88 50L94 50L94 88L88 88Z'),
    _IconLayer(false, 1, 0, 'M5 50L9 40L13 50Z'),
    _IconLayer(false, 1, 0, 'M87 50L91 40L95 50Z'),
  ],
  // الكعبة
  [
    _IconLayer(false, 0xFF1B1B1B, 0, 'M14 38L62 38L62 90L14 90Z'),
    _IconLayer(false, 0xFF2C2C2C, 0, 'M62 38L88 28L88 80L62 90Z'),
    _IconLayer(false, 0xFF3A3A3A, 0, 'M14 38L40 28L88 28L62 38Z'),
    _IconLayer(false, 1, 0, 'M14 47L62 47L62 55L14 55Z'),
    _IconLayer(false, 0xFFC9A24B, 0, 'M62 47L88 38L88 46L62 55Z'),
    _IconLayer(false, 1, 0, 'M14 38L62 38L62 41L14 41Z'),
    _IconLayer(false, 0, 0, 'M22 48.4L22.8 50.2L24.6 51L22.8 51.8L22 53.6L21.2 51.8L19.4 51L21.2 50.2Z'),
    _IconLayer(false, 0, 0, 'M32 48.4L32.8 50.2L34.6 51L32.8 51.8L32 53.6L31.2 51.8L29.4 51L31.2 50.2Z'),
    _IconLayer(false, 0, 0, 'M42 48.4L42.8 50.2L44.6 51L42.8 51.8L42 53.6L41.2 51.8L39.4 51L41.2 50.2Z'),
    _IconLayer(false, 0, 0, 'M52 48.4L52.8 50.2L54.6 51L52.8 51.8L52 53.6L51.2 51.8L49.4 51L51.2 50.2Z'),
    _IconLayer(false, 1, 0, 'M40 90L40 68L54 68L54 90Z'),
    _IconLayer(false, 0xFF1B1B1B, 0, 'M42.5 71L51 71L51 90L42.5 90Z'),
    _IconLayer(true, 1, 1.0, 'M20 60L34 60Z'),
  ],
  // سبحة
  [
    _IconLayer(false, 1, 0, 'M50.6 66.7C50.6 69.2 48.5 71.3 46 71.3C43.4 71.3 41.4 69.2 41.4 66.7C41.4 64.2 43.4 62.1 46 62.1C48.5 62.1 50.6 64.2 50.6 66.7Z'),
    _IconLayer(false, 0x66FFFFFF, 0, 'M46 65.3C46 66.1 45.3 66.7 44.6 66.7C43.8 66.7 43.2 66.1 43.2 65.3C43.2 64.5 43.8 63.9 44.6 63.9C45.3 63.9 46 64.5 46 65.3Z'),
    _IconLayer(false, 0, 0, 'M42.9 64.3C42.9 66.9 40.8 68.9 38.3 68.9C35.7 68.9 33.7 66.9 33.7 64.3C33.7 61.8 35.7 59.7 38.3 59.7C40.8 59.7 42.9 61.8 42.9 64.3Z'),
    _IconLayer(false, 0x66FFFFFF, 0, 'M38.3 62.9C38.3 63.7 37.7 64.3 36.9 64.3C36.1 64.3 35.5 63.7 35.5 62.9C35.5 62.2 36.1 61.5 36.9 61.5C37.7 61.5 38.3 62.2 38.3 62.9Z'),
    _IconLayer(false, 1, 0, 'M36.2 59.8C36.2 62.3 34.2 64.4 31.6 64.4C29.1 64.4 27 62.3 27 59.8C27 57.3 29.1 55.2 31.6 55.2C34.2 55.2 36.2 57.3 36.2 59.8Z'),
    _IconLayer(false, 0x66FFFFFF, 0, 'M31.6 58.4C31.6 59.2 31 59.8 30.2 59.8C29.5 59.8 28.8 59.2 28.8 58.4C28.8 57.6 29.5 57 30.2 57C31 57 31.6 57.6 31.6 58.4Z'),
    _IconLayer(false, 0, 0, 'M31.2 53.5C31.2 56 29.2 58.1 26.6 58.1C24.1 58.1 22 56 22 53.5C22 51 24.1 48.9 26.6 48.9C29.2 48.9 31.2 51 31.2 53.5Z'),
    _IconLayer(false, 0x66FFFFFF, 0, 'M26.6 52.1C26.6 52.9 26 53.5 25.2 53.5C24.4 53.5 23.8 52.9 23.8 52.1C23.8 51.3 24.4 50.7 25.2 50.7C26 50.7 26.6 51.3 26.6 52.1Z'),
    _IconLayer(false, 1, 0, 'M28.3 46C28.3 48.5 26.2 50.6 23.7 50.6C21.1 50.6 19.1 48.5 19.1 46C19.1 43.5 21.1 41.4 23.7 41.4C26.2 41.4 28.3 43.5 28.3 46Z'),
    _IconLayer(false, 0x66FFFFFF, 0, 'M23.7 44.6C23.7 45.4 23.1 46 22.3 46C21.5 46 20.9 45.4 20.9 44.6C20.9 43.8 21.5 43.2 22.3 43.2C23.1 43.2 23.7 43.8 23.7 44.6Z'),
    _IconLayer(false, 0, 0, 'M27.7 38C27.7 40.5 25.6 42.6 23.1 42.6C20.5 42.6 18.5 40.5 18.5 38C18.5 35.4 20.5 33.4 23.1 33.4C25.6 33.4 27.7 35.4 27.7 38Z'),
    _IconLayer(false, 0x66FFFFFF, 0, 'M23.1 36.6C23.1 37.4 22.4 38 21.7 38C20.9 38 20.3 37.4 20.3 36.6C20.3 35.8 20.9 35.2 21.7 35.2C22.4 35.2 23.1 35.8 23.1 36.6Z'),
    _IconLayer(false, 1, 0, 'M29.5 30.1C29.5 32.7 27.4 34.7 24.9 34.7C22.3 34.7 20.3 32.7 20.3 30.1C20.3 27.6 22.3 25.5 24.9 25.5C27.4 25.5 29.5 27.6 29.5 30.1Z'),
    _IconLayer(false, 0x66FFFFFF, 0, 'M24.9 28.7C24.9 29.5 24.2 30.1 23.5 30.1C22.7 30.1 22.1 29.5 22.1 28.7C22.1 28 22.7 27.3 23.5 27.3C24.2 27.3 24.9 28 24.9 28.7Z'),
    _IconLayer(false, 0, 0, 'M33.5 23.2C33.5 25.7 31.4 27.8 28.9 27.8C26.4 27.8 24.3 25.7 24.3 23.2C24.3 20.6 26.4 18.6 28.9 18.6C31.4 18.6 33.5 20.6 33.5 23.2Z'),
    _IconLayer(false, 0x66FFFFFF, 0, 'M28.9 21.8C28.9 22.5 28.3 23.2 27.5 23.2C26.7 23.2 26.1 22.5 26.1 21.8C26.1 21 26.7 20.4 27.5 20.4C28.3 20.4 28.9 21 28.9 21.8Z'),
    _IconLayer(false, 1, 0, 'M39.4 17.7C39.4 20.2 37.3 22.3 34.8 22.3C32.2 22.3 30.2 20.2 30.2 17.7C30.2 15.2 32.2 13.1 34.8 13.1C37.3 13.1 39.4 15.2 39.4 17.7Z'),
    _IconLayer(false, 0x66FFFFFF, 0, 'M34.8 16.3C34.8 17.1 34.2 17.7 33.4 17.7C32.6 17.7 32 17.1 32 16.3C32 15.5 32.6 14.9 33.4 14.9C34.2 14.9 34.8 15.5 34.8 16.3Z'),
    _IconLayer(false, 0, 0, 'M46.6 14.2C46.6 16.7 44.6 18.8 42 18.8C39.5 18.8 37.4 16.7 37.4 14.2C37.4 11.7 39.5 9.6 42 9.6C44.6 9.6 46.6 11.7 46.6 14.2Z'),
    _IconLayer(false, 0x66FFFFFF, 0, 'M42 12.8C42 13.6 41.4 14.2 40.6 14.2C39.9 14.2 39.2 13.6 39.2 12.8C39.2 12 39.9 11.4 40.6 11.4C41.4 11.4 42 12 42 12.8Z'),
    _IconLayer(false, 1, 0, 'M54.6 13C54.6 15.5 52.5 17.6 50 17.6C47.5 17.6 45.4 15.5 45.4 13C45.4 10.5 47.5 8.4 50 8.4C52.5 8.4 54.6 10.5 54.6 13Z'),
    _IconLayer(false, 0x66FFFFFF, 0, 'M50 11.6C50 12.4 49.4 13 48.6 13C47.8 13 47.2 12.4 47.2 11.6C47.2 10.8 47.8 10.2 48.6 10.2C49.4 10.2 50 10.8 50 11.6Z'),
    _IconLayer(false, 0, 0, 'M62.6 14.2C62.6 16.7 60.5 18.8 58 18.8C55.4 18.8 53.4 16.7 53.4 14.2C53.4 11.7 55.4 9.6 58 9.6C60.5 9.6 62.6 11.7 62.6 14.2Z'),
    _IconLayer(false, 0x66FFFFFF, 0, 'M58 12.8C58 13.6 57.3 14.2 56.6 14.2C55.8 14.2 55.2 13.6 55.2 12.8C55.2 12 55.8 11.4 56.6 11.4C57.3 11.4 58 12 58 12.8Z'),
    _IconLayer(false, 1, 0, 'M69.8 17.7C69.8 20.2 67.8 22.3 65.2 22.3C62.7 22.3 60.6 20.2 60.6 17.7C60.6 15.2 62.7 13.1 65.2 13.1C67.8 13.1 69.8 15.2 69.8 17.7Z'),
    _IconLayer(false, 0x66FFFFFF, 0, 'M65.2 16.3C65.2 17.1 64.6 17.7 63.8 17.7C63 17.7 62.4 17.1 62.4 16.3C62.4 15.5 63 14.9 63.8 14.9C64.6 14.9 65.2 15.5 65.2 16.3Z'),
    _IconLayer(false, 0, 0, 'M75.7 23.2C75.7 25.7 73.6 27.8 71.1 27.8C68.6 27.8 66.5 25.7 66.5 23.2C66.5 20.6 68.6 18.6 71.1 18.6C73.6 18.6 75.7 20.6 75.7 23.2Z'),
    _IconLayer(false, 0x66FFFFFF, 0, 'M71.1 21.8C71.1 22.5 70.5 23.2 69.7 23.2C68.9 23.2 68.3 22.5 68.3 21.8C68.3 21 68.9 20.4 69.7 20.4C70.5 20.4 71.1 21 71.1 21.8Z'),
    _IconLayer(false, 1, 0, 'M79.7 30.1C79.7 32.7 77.7 34.7 75.1 34.7C72.6 34.7 70.5 32.7 70.5 30.1C70.5 27.6 72.6 25.5 75.1 25.5C77.7 25.5 79.7 27.6 79.7 30.1Z'),
    _IconLayer(false, 0x66FFFFFF, 0, 'M75.1 28.7C75.1 29.5 74.5 30.1 73.7 30.1C73 30.1 72.3 29.5 72.3 28.7C72.3 28 73 27.3 73.7 27.3C74.5 27.3 75.1 28 75.1 28.7Z'),
    _IconLayer(false, 0, 0, 'M81.5 38C81.5 40.5 79.5 42.6 76.9 42.6C74.4 42.6 72.3 40.5 72.3 38C72.3 35.4 74.4 33.4 76.9 33.4C79.5 33.4 81.5 35.4 81.5 38Z'),
    _IconLayer(false, 0x66FFFFFF, 0, 'M76.9 36.6C76.9 37.4 76.3 38 75.5 38C74.8 38 74.1 37.4 74.1 36.6C74.1 35.8 74.8 35.2 75.5 35.2C76.3 35.2 76.9 35.8 76.9 36.6Z'),
    _IconLayer(false, 1, 0, 'M80.9 46C80.9 48.5 78.9 50.6 76.3 50.6C73.8 50.6 71.7 48.5 71.7 46C71.7 43.5 73.8 41.4 76.3 41.4C78.9 41.4 80.9 43.5 80.9 46Z'),
    _IconLayer(false, 0x66FFFFFF, 0, 'M76.3 44.6C76.3 45.4 75.7 46 74.9 46C74.1 46 73.5 45.4 73.5 44.6C73.5 43.8 74.1 43.2 74.9 43.2C75.7 43.2 76.3 43.8 76.3 44.6Z'),
    _IconLayer(false, 0, 0, 'M78 53.5C78 56 75.9 58.1 73.4 58.1C70.8 58.1 68.8 56 68.8 53.5C68.8 51 70.8 48.9 73.4 48.9C75.9 48.9 78 51 78 53.5Z'),
    _IconLayer(false, 0x66FFFFFF, 0, 'M73.4 52.1C73.4 52.9 72.8 53.5 72 53.5C71.2 53.5 70.6 52.9 70.6 52.1C70.6 51.3 71.2 50.7 72 50.7C72.8 50.7 73.4 51.3 73.4 52.1Z'),
    _IconLayer(false, 1, 0, 'M73 59.8C73 62.3 70.9 64.4 68.4 64.4C65.8 64.4 63.8 62.3 63.8 59.8C63.8 57.3 65.8 55.2 68.4 55.2C70.9 55.2 73 57.3 73 59.8Z'),
    _IconLayer(false, 0x66FFFFFF, 0, 'M68.4 58.4C68.4 59.2 67.7 59.8 67 59.8C66.2 59.8 65.6 59.2 65.6 58.4C65.6 57.6 66.2 57 67 57C67.7 57 68.4 57.6 68.4 58.4Z'),
    _IconLayer(false, 0, 0, 'M66.3 64.3C66.3 66.9 64.3 68.9 61.7 68.9C59.2 68.9 57.1 66.9 57.1 64.3C57.1 61.8 59.2 59.7 61.7 59.7C64.3 59.7 66.3 61.8 66.3 64.3Z'),
    _IconLayer(false, 0x66FFFFFF, 0, 'M61.7 62.9C61.7 63.7 61.1 64.3 60.3 64.3C59.5 64.3 58.9 63.7 58.9 62.9C58.9 62.2 59.5 61.5 60.3 61.5C61.1 61.5 61.7 62.2 61.7 62.9Z'),
    _IconLayer(false, 1, 0, 'M58.6 66.7C58.6 69.2 56.6 71.3 54 71.3C51.5 71.3 49.4 69.2 49.4 66.7C49.4 64.2 51.5 62.1 54 62.1C56.6 62.1 58.6 64.2 58.6 66.7Z'),
    _IconLayer(false, 0x66FFFFFF, 0, 'M54 65.3C54 66.1 53.4 66.7 52.6 66.7C51.9 66.7 51.2 66.1 51.2 65.3C51.2 64.5 51.9 63.9 52.6 63.9C53.4 63.9 54 64.5 54 65.3Z'),
    _IconLayer(true, 0, 1.0, 'M77 40C77 54.9 64.9 67 50 67C35.1 67 23 54.9 23 40C23 25.1 35.1 13 50 13C64.9 13 77 25.1 77 40'),
    _IconLayer(false, 0, 0, 'M56.2 72C56.2 76.1 53.4 79.4 50 79.4C46.6 79.4 43.8 76.1 43.8 72C43.8 67.9 46.6 64.6 50 64.6C53.4 64.6 56.2 67.9 56.2 72Z'),
    _IconLayer(false, 1, 0, 'M52.4 72C52.4 73.3 51.3 74.4 50 74.4C48.7 74.4 47.6 73.3 47.6 72C47.6 70.7 48.7 69.6 50 69.6C51.3 69.6 52.4 70.7 52.4 72Z'),
    _IconLayer(true, 0, 1.4, 'M50 79L50 84Z'),
    _IconLayer(false, 1, 0, 'M53.2 87C53.2 88.8 51.8 90.2 50 90.2C48.2 90.2 46.8 88.8 46.8 87C46.8 85.2 48.2 83.8 50 83.8C51.8 83.8 53.2 85.2 53.2 87Z'),
    _IconLayer(false, 0, 0, 'M50 89L44 99L56 99Z'),
    _IconLayer(true, 1, 1.0, 'M50 90L46 98Z'),
    _IconLayer(true, 1, 1.0, 'M50 90L50 98Z'),
    _IconLayer(true, 1, 1.0, 'M50 90L54 98Z'),
    _IconLayer(true, 0, 1.4, 'M50 67L50 66Z'),
  ],
  // يدا الدعاء
  [
    _IconLayer(false, 0, 0, 'M55.2 62.5C57.1 57.6 62.7 55.2 67.5 57.2C72.4 59.1 74.8 64.7 72.8 69.5L64.8 89.5C62.9 94.4 57.3 96.8 52.5 94.8C47.6 92.9 45.2 87.3 47.2 82.5Z'),
    _IconLayer(false, 0, 0, 'M74 62C74 67 69.1 71 63 71C56.9 71 52 67 52 62C52 57 56.9 53 63 53C69.1 53 74 57 74 62Z'),
    _IconLayer(false, 0, 0, 'M50 39.3C49.9 37.5 51.3 35.9 53.1 35.8C54.9 35.6 56.5 37 56.6 38.8L58.3 62.8C58.4 64.6 57 66.2 55.2 66.3C53.4 66.4 51.8 65 51.7 63.2Z'),
    _IconLayer(false, 0, 0, 'M61 22.9C61.2 21.1 62.8 19.9 64.5 20.1C66.3 20.3 67.5 21.9 67.3 23.6L63.2 57.4C63 59.1 61.4 60.4 59.6 60.2C57.9 60 56.6 58.4 56.8 56.6Z'),
    _IconLayer(false, 0, 0, 'M71.2 19.4C71.7 17.7 73.4 16.7 75.1 17.1C76.9 17.6 77.9 19.3 77.4 21.1L68.1 55.8C67.6 57.5 65.9 58.5 64.2 58.1C62.5 57.6 61.5 55.9 61.9 54.2Z'),
    _IconLayer(false, 0, 0, 'M80.7 26.7C81.4 25.1 83.3 24.5 84.8 25.2C86.4 25.9 87.1 27.8 86.3 29.3L72.8 58.3C72.1 59.9 70.2 60.5 68.7 59.8C67.1 59.1 66.5 57.2 67.2 55.7Z'),
    _IconLayer(false, 0, 0, 'M87.1 40.5C88.1 39.3 89.9 39 91.2 40C92.4 41 92.7 42.8 91.7 44.1L76.3 63.8C75.3 65 73.5 65.3 72.2 64.3C71 63.3 70.7 61.5 71.7 60.2Z'),
    _IconLayer(false, 0, 0, 'M27.2 69.5C25.2 64.7 27.6 59.1 32.5 57.2C37.3 55.2 42.9 57.6 44.8 62.5L52.8 82.5C54.8 87.3 52.4 92.9 47.5 94.8C42.7 96.8 37.1 94.4 35.2 89.5Z'),
    _IconLayer(false, 0, 0, 'M48 62C48 67 43.1 71 37 71C30.9 71 26 67 26 62C26 57 30.9 53 37 53C43.1 53 48 57 48 62Z'),
    _IconLayer(false, 0, 0, 'M43.4 38.8C43.5 37 45.1 35.6 46.9 35.8C48.7 35.9 50.1 37.5 50 39.3L48.3 63.2C48.2 65 46.6 66.4 44.8 66.3C43 66.2 41.6 64.6 41.7 62.8Z'),
    _IconLayer(false, 0, 0, 'M32.7 23.6C32.5 21.9 33.7 20.3 35.5 20.1C37.2 19.9 38.8 21.1 39 22.9L43.2 56.6C43.4 58.4 42.1 60 40.4 60.2C38.6 60.4 37 59.1 36.8 57.4Z'),
    _IconLayer(false, 0, 0, 'M22.6 21.1C22.1 19.3 23.1 17.6 24.9 17.1C26.6 16.7 28.3 17.7 28.8 19.4L38.1 54.2C38.5 55.9 37.5 57.6 35.8 58.1C34.1 58.5 32.4 57.5 31.9 55.8Z'),
    _IconLayer(false, 0, 0, 'M13.7 29.3C12.9 27.8 13.6 25.9 15.2 25.2C16.7 24.5 18.6 25.1 19.3 26.7L32.8 55.7C33.5 57.2 32.9 59.1 31.3 59.8C29.8 60.5 27.9 59.9 27.2 58.3Z'),
    _IconLayer(false, 0, 0, 'M8.3 44.1C7.3 42.8 7.6 41 8.8 40C10.1 39 11.9 39.3 12.9 40.5L28.3 60.2C29.3 61.5 29 63.3 27.8 64.3C26.5 65.3 24.7 65 23.7 63.8Z'),
    _IconLayer(true, 1, 1.6, 'M26 76C34 92 66 92 74 76'),
    _IconLayer(false, 1, 0, 'M50 5L51.5 10.5L56.4 7.6L53.5 12.5L59 14L53.5 15.5L56.4 20.4L51.5 17.5L50 23L48.5 17.5L43.6 20.4L46.5 15.5L41 14L46.5 12.5L43.6 7.6L48.5 10.5Z'),
    _IconLayer(false, 1, 0, 'M31.8 9C31.8 10 31 10.8 30 10.8C29 10.8 28.2 10 28.2 9C28.2 8 29 7.2 30 7.2C31 7.2 31.8 8 31.8 9Z'),
    _IconLayer(false, 1, 0, 'M71.8 9C71.8 10 71 10.8 70 10.8C69 10.8 68.2 10 68.2 9C68.2 8 69 7.2 70 7.2C71 7.2 71.8 8 71.8 9Z'),
  ],
  // هلال ونجمة
  [
    _IconLayer(false, 1, 0, 'M60.7 21.1C42.9 13.2 22 20.8 13.6 38.4C5.1 55.9 12.1 77 29.4 86C46.7 94.9 68 88.5 77.5 71.5L77.5 71.5C67.6 80.4 53 81.5 41.9 74.1C30.9 66.8 26.2 52.9 30.7 40.3C35.1 27.8 47.4 19.9 60.7 21.1Z'),
    _IconLayer(true, 0, 1.2, 'M60.7 21.1C42.9 13.2 22 20.8 13.6 38.4C5.1 55.9 12.1 77 29.4 86C46.7 94.9 68 88.5 77.5 71.5L77.5 71.5C67.6 80.4 53 81.5 41.9 74.1C30.9 66.8 26.2 52.9 30.7 40.3C35.1 27.8 47.4 19.9 60.7 21.1Z'),
    _IconLayer(false, 0, 0, 'M66 33L68.1 40.8L75.2 36.8L71.2 43.9L79 46L71.2 48.1L75.2 55.2L68.1 51.2L66 59L63.9 51.2L56.8 55.2L60.8 48.1L53 46L60.8 43.9L56.8 36.8L63.9 40.8Z'),
    _IconLayer(true, 1, 1.0, 'M66 33L68.1 40.8L75.2 36.8L71.2 43.9L79 46L71.2 48.1L75.2 55.2L68.1 51.2L66 59L63.9 51.2L56.8 55.2L60.8 48.1L53 46L60.8 43.9L56.8 36.8L63.9 40.8Z'),
    _IconLayer(false, 1, 0, 'M68.4 46C68.4 47.3 67.3 48.4 66 48.4C64.7 48.4 63.6 47.3 63.6 46C63.6 44.7 64.7 43.6 66 43.6C67.3 43.6 68.4 44.7 68.4 46Z'),
  ],
  // مسجد
  [
    _IconLayer(false, 0, 0, 'M30 62C30 44 40 32 50 26C60 32 70 44 70 62Z'),
    _IconLayer(false, 1, 0, 'M49 12L51 12L51 27L49 27Z'),
    _IconLayer(false, 1, 0, 'M53 11C53 12.7 51.7 14 50 14C48.3 14 47 12.7 47 11C47 9.3 48.3 8 50 8C51.7 8 53 9.3 53 11Z'),
    _IconLayer(false, 1, 0, 'M50 38.5L50.9 41.8L53.9 40.1L52.2 43.1L55.5 44L52.2 44.9L53.9 47.9L50.9 46.2L50 49.5L49.1 46.2L46.1 47.9L47.8 44.9L44.5 44L47.8 43.1L46.1 40.1L49.1 41.8Z'),
    _IconLayer(false, 0, 0, 'M24 62L76 62L76 90L24 90Z'),
    _IconLayer(false, 1, 0, 'M24 62L76 62L76 64.5L24 64.5Z'),
    _IconLayer(false, 1, 0, 'M43 90L43 76C43 66 57 66 57 76L57 90Z'),
    _IconLayer(false, 0, 0, 'M46 90L46 77C46 70 54 70 54 77L54 90Z'),
    _IconLayer(false, 1, 0, 'M28 80L28 73Q31 68 34 73L34 80Z'),
    _IconLayer(false, 1, 0, 'M66 80L66 73Q69 68 72 73L72 80Z'),
    _IconLayer(false, 0, 0, 'M10 36L18 36L18 90L10 90Z'),
    _IconLayer(false, 1, 0, 'M8 44L20 44L20 47L8 47Z'),
    _IconLayer(false, 1, 0, 'M8 58L20 58L20 61L8 61Z'),
    _IconLayer(false, 0, 0, 'M9 36L14 20L19 36Z'),
    _IconLayer(false, 1, 0, 'M16 18C16 19.1 15.1 20 14 20C12.9 20 12 19.1 12 18C12 16.9 12.9 16 14 16C15.1 16 16 16.9 16 18Z'),
    _IconLayer(false, 1, 0, 'M12.5 72L12.5 68Q14 66 15.5 68L15.5 72Z'),
    _IconLayer(false, 0, 0, 'M82 36L90 36L90 90L82 90Z'),
    _IconLayer(false, 1, 0, 'M80 44L92 44L92 47L80 47Z'),
    _IconLayer(false, 1, 0, 'M80 58L92 58L92 61L80 61Z'),
    _IconLayer(false, 0, 0, 'M81 36L86 20L91 36Z'),
    _IconLayer(false, 1, 0, 'M88 18C88 19.1 87.1 20 86 20C84.9 20 84 19.1 84 18C84 16.9 84.9 16 86 16C87.1 16 88 16.9 88 18Z'),
    _IconLayer(false, 1, 0, 'M84.5 72L84.5 68Q86 66 87.5 68L87.5 72Z'),
    _IconLayer(false, 0, 0, 'M6 88L94 88L94 92L6 92Z'),
  ],
  // فانوس
  [
    _IconLayer(true, 1, 2.0, 'M40 18C40 2 60 2 60 18'),
    _IconLayer(false, 1, 0, 'M53 5C53 6.7 51.7 8 50 8C48.3 8 47 6.7 47 5C47 3.3 48.3 2 50 2C51.7 2 53 3.3 53 5Z'),
    _IconLayer(false, 0, 0, 'M32 30C36 22 44 20 50 14C56 20 64 22 68 30Z'),
    _IconLayer(false, 1, 0, 'M30 30L70 30L70 35L30 35Z'),
    _IconLayer(false, 0xFFFFE082, 0, 'M34 35L66 35C70 52 70 64 64 76L36 76C30 64 30 52 34 35Z'),
    _IconLayer(false, 0x80FFC107, 0, 'M40 40L60 40C63 52 62 62 58 70L42 70C38 62 37 52 40 40Z'),
    _IconLayer(true, 1, 2.0, 'M34 35L66 35C70 52 70 64 64 76L36 76C30 64 30 52 34 35Z'),
    _IconLayer(true, 1, 1.2, 'M42 36C39.2 50 40 64 42 75'),
    _IconLayer(true, 1, 1.2, 'M50 36C50 50 50 64 50 75'),
    _IconLayer(true, 1, 1.2, 'M58 36C60.8 50 60 64 58 75'),
    _IconLayer(true, 1, 1.0, 'M31 52L69 52'),
    _IconLayer(false, 1, 0, 'M32 76L68 76L68 81L32 81Z'),
    _IconLayer(false, 0, 0, 'M34 81L66 81L60 92L40 92Z'),
    _IconLayer(false, 1, 0, 'M53 95C53 96.7 51.7 98 50 98C48.3 98 47 96.7 47 95C47 93.3 48.3 92 50 92C51.7 92 53 93.3 53 95Z'),
    _IconLayer(false, 0, 0, 'M50 56L50.7 58.3L52.8 57.2L51.7 59.3L54 60L51.7 60.7L52.8 62.8L50.7 61.7L50 64L49.3 61.7L47.2 62.8L48.3 60.7L46 60L48.3 59.3L47.2 57.2L49.3 58.3Z'),
  ],
  // مصحف
  [
    _IconLayer(false, 0, 0, 'M22 88L50 72L78 88L72 92L50 80L28 92Z'),
    _IconLayer(false, 0xFFFFF8E1, 0, 'M50 34C40 28 22 28 12 34L12 76C22 70 40 70 50 76Z'),
    _IconLayer(false, 0xFFFFF8E1, 0, 'M50 34C60 28 78 28 88 34L88 76C78 70 60 70 50 76Z'),
    _IconLayer(true, 1, 1.6, 'M50 34C40 28 22 28 12 34L12 76C22 70 40 70 50 76Z'),
    _IconLayer(true, 1, 1.6, 'M50 34C60 28 78 28 88 34L88 76C78 70 60 70 50 76Z'),
    _IconLayer(true, 0, 1.4, 'M50 34L50 76Z'),
    _IconLayer(true, 0, 1.2, 'M18 44Q30 41 45 45'),
    _IconLayer(true, 0, 1.2, 'M55 45Q70 41 82 44'),
    _IconLayer(true, 0, 1.2, 'M18 50Q30 47 45 51'),
    _IconLayer(true, 0, 1.2, 'M55 51Q70 47 82 50'),
    _IconLayer(true, 0, 1.2, 'M18 56Q30 53 45 57'),
    _IconLayer(true, 0, 1.2, 'M55 57Q70 53 82 56'),
    _IconLayer(true, 0, 1.2, 'M18 62Q30 59 45 63'),
    _IconLayer(true, 0, 1.2, 'M55 63Q70 59 82 62'),
    _IconLayer(false, 1, 0, 'M50 6L51.6 12.1L57.1 8.9L53.9 14.4L60 16L53.9 17.6L57.1 23.1L51.6 19.9L50 26L48.4 19.9L42.9 23.1L46.1 17.6L40 16L46.1 14.4L42.9 8.9L48.4 12.1Z'),
    _IconLayer(false, 0, 0, 'M52.6 16C52.6 17.4 51.4 18.6 50 18.6C48.6 18.6 47.4 17.4 47.4 16C47.4 14.6 48.6 13.4 50 13.4C51.4 13.4 52.6 14.6 52.6 16Z'),
  ],
];

final _iconPathCache = <String, Path>{};

Path _svgPath(String d) => _iconPathCache.putIfAbsent(d, () {
      final p = Path();
      final t = RegExp(r'[MLCQZ]|-?\d+\.?\d*')
          .allMatches(d)
          .map((m) => m[0]!)
          .toList();
      var i = 0;
      double n() => double.parse(t[i++]);
      while (i < t.length) {
        final c = t[i++];
        switch (c) {
          case 'M':
            p.moveTo(n(), n());
          case 'L':
            p.lineTo(n(), n());
          case 'C':
            p.cubicTo(n(), n(), n(), n(), n(), n());
          case 'Q':
            p.quadraticBezierTo(n(), n(), n(), n());
          case 'Z':
            p.close();
        }
      }
      return p;
    });

/// يرسم الأيقونة [icon] (1..8) في مركز [center] بارتفاع [size]، مع هالة خفيفة خلفها
void _paintIcon(
    Canvas canvas, PdfTheme t, int icon, Offset center, double size) {
  if (icon <= 0 || icon > _icons.length) return;
  canvas.drawCircle(center, size * .62, _fillP(t.accent.withOpacity(.10)));
  canvas.drawCircle(
      center, size * .62, _stroke(t.accent.withOpacity(.55), .8));
  canvas.save();
  canvas.translate(center.dx - size / 2, center.dy - size / 2);
  canvas.scale(size / 100);
  for (final l in _icons[icon - 1]) {
    final c = l.color == 0
        ? t.dark
        : (l.color == 1 ? t.accent : Color(l.color));
    final p = _svgPath(l.d);
    if (l.stroke) {
      canvas.drawPath(
          p,
          Paint()
            ..color = c
            ..style = PaintingStyle.stroke
            ..strokeWidth = l.w
            ..strokeJoin = StrokeJoin.round
            ..strokeCap = StrokeCap.round);
    } else {
      canvas.drawPath(p, Paint()..color = c);
    }
  }
  canvas.restore();
}

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
    case 14: // مفصّص علوي
      {
        const n = 10;
        final step = rect.width / n;
        final p = Path()
          ..moveTo(rect.left, rect.bottom)
          ..lineTo(rect.left, rect.top + step / 2);
        for (var i = 0; i < n; i++) {
          p.arcToPoint(Offset(rect.left + (i + 1) * step, rect.top + step / 2),
              radius: Radius.circular(step / 2), clockwise: true);
        }
        p
          ..lineTo(rect.right, rect.bottom)
          ..close();
        canvas.drawPath(p, _fillP(t.accent.withOpacity(.13)));
        canvas.drawPath(p, _stroke(t.accent, 2));
      }
    case 15: // قوس مدبّب داكن
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
        canvas.drawPath(p, grad());
        canvas.drawPath(p, _stroke(t.accent, 2.2));
        canvas.drawPath(
            Path()
              ..moveTo(rect.left + 6, rect.bottom - 5)
              ..lineTo(rect.left + 6, shoulder + 2)
              ..quadraticBezierTo(
                  rect.left + 6, rect.top + 20, rect.center.dx, rect.top + 7)
              ..quadraticBezierTo(rect.right - 6, rect.top + 20,
                  rect.right - 6, shoulder + 2)
              ..lineTo(rect.right - 6, rect.bottom - 5),
            _stroke(t.accent.withOpacity(.6), .8));
      }
    case 16: // لوح بنجوم
      {
        final rr = RRect.fromRectAndRadius(rect, const Radius.circular(8));
        canvas.drawRRect(rr, _fillP(t.accent.withOpacity(.12)));
        canvas.drawRRect(rr, _stroke(t.accent, 2));
        canvas.drawRRect(
            rr.deflate(6), _stroke(t.dark.withOpacity(.5), .8));
        for (final c in [
          rect.topLeft,
          rect.topRight,
          rect.bottomLeft,
          rect.bottomRight,
          rect.topCenter,
          rect.bottomCenter,
        ]) {
          canvas.drawPath(_pdfStar(c, 9), _fillP(t.dark));
          canvas.drawPath(_pdfStar(c, 9), _stroke(t.accent, 1.2));
          canvas.drawCircle(c, 2.2, _fillP(t.accent));
        }
      }
    case 17: // شريط ورقي بذيلين
      {
        const f = 18.0;
        final l = rect.left, r = rect.right, tp = rect.top, bt = rect.bottom;
        final tailL = Path()
          ..moveTo(l, tp + 12)
          ..lineTo(l + f + 6, tp + 12)
          ..lineTo(l + f + 6, bt + 12)
          ..lineTo(l, bt + 12)
          ..lineTo(l + 9, (tp + bt) / 2 + 12)
          ..close();
        final tailR = Path()
          ..moveTo(r, tp + 12)
          ..lineTo(r - f - 6, tp + 12)
          ..lineTo(r - f - 6, bt + 12)
          ..lineTo(r, bt + 12)
          ..lineTo(r - 9, (tp + bt) / 2 + 12)
          ..close();
        for (final tail in [tailL, tailR]) {
          canvas.drawPath(tail, _fillP(darker));
          canvas.drawPath(tail, _stroke(t.accent, 1.6));
        }
        final body = Rect.fromLTRB(l + f, tp, r - f, bt);
        canvas.drawRect(body, grad());
        canvas.drawRect(body, _stroke(t.accent, 2));
        canvas.drawRect(
            body.deflate(5), _stroke(t.accent.withOpacity(.55), .8));
      }
    default:
      break;
  }
}

/// ورقة نباتية صغيرة تبدأ من [o] باتجاه [ang]
void _leaf(Canvas c, Offset o, double ang, double len, double w, Paint p) {
  c.save();
  c.translate(o.dx, o.dy);
  c.rotate(ang);
  final path = Path()
    ..moveTo(0, 0)
    ..quadraticBezierTo(len * .5, -w, len, 0)
    ..quadraticBezierTo(len * .5, w, 0, 0);
  c.drawPath(path, p);
  c.restore();
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
    case 23:
      {
        // أوراق متسلسلة
        canvas.drawRRect(
            RRect.fromRectAndRadius(_inset(12), const Radius.circular(8)),
            _stroke(t.accent, 1.6));
        final r = _inset(21);
        canvas.drawRect(r, _stroke(t.dark.withOpacity(.55), .8));
        final pts = _pointsAlongRect(r, 15);
        for (var k = 0; k < pts.length; k++) {
          final p = pts[k];
          final q = pts[(k + 1) % pts.length];
          final dir = (q - p).direction;
          final side = k.isEven ? -1.0 : 1.0;
          _leaf(canvas, p, dir + side * .9, 9, 3.2,
              _fillP(k % 4 < 2 ? t.accent : t.dark.withOpacity(.85)));
        }
      }
    case 24:
      {
        // ربع الحزب في الزوايا
        canvas.drawRRect(
            RRect.fromRectAndRadius(_inset(14), const Radius.circular(3)),
            _stroke(t.accent, 2));
        canvas.drawRRect(
            RRect.fromRectAndRadius(_inset(21), const Radius.circular(2)),
            _stroke(t.dark.withOpacity(.6), .9));
        final r = _inset(17.5);
        for (final c in [r.topLeft, r.topRight, r.bottomLeft, r.bottomRight]) {
          canvas.drawPath(_pdfStar(c, 15, .765), _fillP(t.dark));
          canvas.drawPath(_pdfStar(c, 15, .765), _stroke(t.accent, 1.4));
          canvas.drawPath(_pdfStar(c, 8, .765), _stroke(t.accent, 1));
          canvas.drawCircle(c, 2.2, _fillP(t.accent));
        }
        for (final c in [
          Offset(_pageW / 2, r.top),
          Offset(_pageW / 2, r.bottom),
          Offset(r.left, _pageH / 2),
          Offset(r.right, _pageH / 2),
        ]) {
          _diamondMark(canvas, c, 6, t);
        }
      }
    case 25:
      {
        // سلسلة معيّنات متصلة
        canvas.drawRRect(
            RRect.fromRectAndRadius(_inset(11), const Radius.circular(6)),
            _stroke(t.accent, 1.4));
        final pts = _pointsAlongRect(_inset(21), 16);
        for (final p in pts) {
          canvas.drawPath(_diamond(p, 9), _stroke(t.accent.withOpacity(.8), 1));
        }
        for (final p in pts) {
          canvas.drawCircle(p, 1.6, _fillP(t.dark));
        }
        canvas.drawRRect(
            RRect.fromRectAndRadius(_inset(32), const Radius.circular(2)),
            _stroke(t.dark.withOpacity(.4), .7));
      }
    case 26:
      {
        // مربعات مثمّنة متبادلة
        canvas.drawRRect(
            RRect.fromRectAndRadius(_inset(11), const Radius.circular(5)),
            _stroke(t.accent, 2));
        final pts = _pointsAlongRect(_inset(22), 20);
        for (var k = 0; k < pts.length; k++) {
          final p = pts[k];
          final s = k.isEven ? 6.0 : 4.0;
          canvas.save();
          canvas.translate(p.dx, p.dy);
          canvas.rotate(math.pi / 4);
          final box = Rect.fromCenter(
              center: Offset.zero, width: s * 2, height: s * 2);
          canvas.drawRect(box, _fillP(k.isEven ? t.dark : t.accent));
          if (k.isEven) canvas.drawRect(box, _stroke(t.accent, 1));
          canvas.restore();
        }
        canvas.drawRRect(
            RRect.fromRectAndRadius(_inset(32), const Radius.circular(2)),
            _stroke(t.dark.withOpacity(.5), .8));
      }
    case 27:
      {
        // هلال ونجوم في الزوايا
        canvas.drawRRect(
            RRect.fromRectAndRadius(_inset(12), const Radius.circular(10)),
            _stroke(t.accent, 2));
        canvas.drawRRect(
            RRect.fromRectAndRadius(_inset(17), const Radius.circular(6)),
            _stroke(t.dark.withOpacity(.55), .8));
        final mid = Offset(_pageW / 2, _pageH / 2);
        for (final c in const [
          Offset(31, 31),
          Offset(_pageW - 31, 31),
          Offset(31, _pageH - 31),
          Offset(_pageW - 31, _pageH - 31),
        ]) {
          final u = (mid - c) / (mid - c).distance;
          final moon = Path.combine(
              PathOperation.difference,
              Path()..addOval(Rect.fromCircle(center: c, radius: 10)),
              Path()
                ..addOval(Rect.fromCircle(center: c + u * 4.6, radius: 8.4)));
          canvas.drawPath(moon, _fillP(t.accent));
          canvas.drawPath(_pdfStar(c + u * 5.5, 3.6), _fillP(t.dark));
        }
        for (final c in [
          Offset(_pageW / 2, 14.5),
          Offset(_pageW / 2, _pageH - 14.5),
          Offset(14.5, _pageH / 2),
          Offset(_pageW - 14.5, _pageH / 2),
        ]) {
          _diamondMark(canvas, c, 5, t);
        }
      }
    case 28:
      {
        // شريط ذهبي متدرّج
        final shader = ui.Gradient.linear(
            const Offset(0, 0),
            const Offset(_pageW, _pageH),
            [
              t.accent,
              Color.lerp(t.accent, Colors.white, .55)!,
              t.accent,
              t.dark,
              t.accent,
            ],
            const [0, .25, .5, .75, 1]);
        canvas.drawRRect(
            RRect.fromRectAndRadius(_inset(13), const Radius.circular(10)),
            Paint()
              ..shader = shader
              ..style = PaintingStyle.stroke
              ..strokeWidth = 7);
        canvas.drawRRect(
            RRect.fromRectAndRadius(_inset(20), const Radius.circular(6)),
            _stroke(t.dark.withOpacity(.7), 1));
        canvas.drawRRect(
            RRect.fromRectAndRadius(_inset(9), const Radius.circular(12)),
            _stroke(t.accent.withOpacity(.6), .8));
      }
    case 29:
      {
        // عقود مدبّبة أعلى الصفحة وأسفلها
        canvas.drawRRect(
            RRect.fromRectAndRadius(_inset(11), const Radius.circular(4)),
            _stroke(t.accent, 1.6));
        const n = 9;
        const w = (_pageW - 32) / n;
        void arches() {
          for (var i = 0; i < n; i++) {
            final x0 = 16 + i * w;
            final p = Path()
              ..moveTo(x0, 11)
              ..lineTo(x0, 22)
              ..quadraticBezierTo(x0, 30, x0 + w / 2, 34)
              ..quadraticBezierTo(x0 + w, 30, x0 + w, 22)
              ..lineTo(x0 + w, 11);
            canvas.drawPath(p, _stroke(t.accent, 1.2));
            canvas.drawCircle(Offset(x0 + w / 2, 21), 1.8, _fillP(t.dark));
          }
        }

        arches();
        canvas.save();
        canvas.translate(0, _pageH);
        canvas.scale(1, -1);
        arches();
        canvas.restore();
      }
    case 30:
      {
        // أزهار في الزوايا ومنتصف الأضلاع
        canvas.drawRRect(
            RRect.fromRectAndRadius(_inset(13), const Radius.circular(8)),
            _stroke(t.accent, 1.8));
        canvas.drawRRect(
            RRect.fromRectAndRadius(_inset(19), const Radius.circular(5)),
            _stroke(t.dark.withOpacity(.55), .8));
        void flower(Offset c, double r) {
          for (var i = 0; i < 8; i++) {
            final a = i * math.pi / 4;
            canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * (r * .55),
                r * .42, _stroke(t.accent, 1.1));
          }
          canvas.drawCircle(c, r * .32, _fillP(t.dark));
          canvas.drawCircle(c, r * .32, _stroke(t.accent, 1));
          canvas.drawCircle(c, r * .13, _fillP(t.accent));
        }

        final r = _inset(16);
        for (final c in [r.topLeft, r.topRight, r.bottomLeft, r.bottomRight]) {
          flower(c, 22);
        }
        for (final c in [
          Offset(_pageW / 2, r.top),
          Offset(_pageW / 2, r.bottom),
          Offset(r.left, _pageH / 2),
          Offset(r.right, _pageH / 2),
        ]) {
          flower(c, 13);
        }
      }
    default:
      break; // بدون إطار
  }
}

/// الورقة: لون + نقش شفاف + إطار
void _paintPage(
    Canvas canvas, PdfTheme t, Color paper, int frame, int pattern) {
  if (paperFx.gradient) {
    // تدرّج: الوسط بلون الورقة والحواف أغمق قليلًا (مثل الورق القديم)
    final tint = paperEdgeColors[paperFx.edge] ?? t.accent;
    final edge = Color.lerp(paper, tint, paperFx.edge == 0 ? .14 : .28)!;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, _pageW, _pageH),
        Paint()
          ..shader = ui.Gradient.radial(const Offset(_pageW / 2, _pageH / 2),
              _pageH * .72, [paper, paper, edge], const [0, .5, 1]));
  } else {
    canvas.drawRect(
        Rect.fromLTWH(0, 0, _pageW, _pageH), Paint()..color = paper);
  }
  canvas.save();
  canvas.clipRRect(_frameClip(frame));
  // علامة مائية كبيرة خفيفة خلف النص (النقش رقم ٧ فيه علامة مائية خاصة به)
  if (paperFx.watermark && pattern != 7) {
    const c = Offset(_pageW / 2, _pageH / 2);
    canvas.drawPath(_pdfStar(c, 175, .78), _fillP(t.accent.withOpacity(.045)));
    canvas.drawPath(
        _pdfStar(c, 175, .78), _stroke(t.accent.withOpacity(.10), 1.2));
    canvas.drawCircle(c, 95, _stroke(t.accent.withOpacity(.08), 1));
  }
  _paintPattern(canvas, t, pattern);
  canvas.restore();
  _paintFrame(canvas, t, frame);
}

// ───────────── الترويسة ─────────────

/// شكل الترويسة فقط (بدون نص) داخل [rect] — يُستخدم للترويسة وللعناوين المزخرفة
void _paintHeaderShape(Canvas canvas, PdfTheme t, int style, Rect rect) {
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
}

/// ما تتجاوزه بعض الأشكال أسفل المستطيل (بطن مقوّس، ذيلا الشريط، الظل)
double _headerOverhang(int style) => switch (style) {
      7 => 14.0,
      17 => 12.0,
      9 => 4.0,
      _ => 0.0,
    };

/// الترويسة: نجمة + العنوان في الوسط + زخرفة + اسم الديوان (4 أشكال)
void _paintHeader(Canvas canvas, PdfTheme t, int style, double top, double h,
    TextPainter title, TextPainter diwan) {
  final rect = Rect.fromLTWH(_mx, top, _avail, h);
  final filled = _headerDark(style);
  _paintHeaderShape(canvas, t, style, rect);

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
  int icon = 0,
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

  final darkHeader = _headerDark(header);
  final titleColor = darkHeader ? Colors.white : theme.dark;

  // التذييل (الغلاف + الصفحة الأخيرة)
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

  // الغلاف: عنوان القصيدة في ترويسة، واسم الديوان تحتها
  final (coverTitle, coverBannerH) =
      _coverTitle(poem.title, baseStyle, titleColor);
  final coverSub = centered(
      diwan,
      baseStyle.merge(TextStyle(
          color: Color.lerp(theme.accent, Colors.black, .35),
          fontSize: 16,
          height: 1.4,
          fontWeight: FontWeight.w600)),
      _avail);

  // عنوان القصيدة أعلى أول صفحة: ترويسة مزخرفة مدمجة
  final titleP = centered(
      poem.title,
      baseStyle.merge(TextStyle(
          color: titleColor,
          fontSize: 20,
          height: 1.5,
          fontWeight: FontWeight.bold)),
      _avail - 60);
  final bannerH = math.max(titleP.height + 28, 58.0);
  final overhang = _headerOverhang(header);
  final firstStart = _top + bannerH + overhang + 22;

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

  Future<Uint8List> rasterPng(void Function(Canvas) draw) async {
    final rec = ui.PictureRecorder();
    // بدون cullRect: وجوده مع التكبير كان يقص كل ما بعد أول ثلث من الصفحة
    final canvas = Canvas(rec);
    canvas.scale(_scale);
    _paintPage(canvas, theme, paper, frame, pattern);
    draw(canvas);
    final pic = rec.endRecording();
    final img = await pic.toImage(
        (_pageW * _scale).round(), (_pageH * _scale).round());
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    pic.dispose();
    return bd!.buffer.asUint8List();
  }

  void paintContent(Canvas canvas, int pi, List<int> idx) {
    var py = _top;
    if (pi == 0) {
      _paintHeaderShape(
          canvas, theme, header, Rect.fromLTWH(_mx, _top, _avail, bannerH));
      titleP.paint(
          canvas, Offset(_mx + 30, _top + (bannerH - titleP.height) / 2));
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
    _paintPageNumber(canvas, theme, baseStyle, pi + 1, pages.length);
  }

  final doc = pw.Document();
  void addImage(Uint8List png) {
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

  // الغلاف الأمامي ثم الأبيات ثم الغلاف الخلفي (بدون كلام)
  addImage(await rasterPng((c) => _paintCoverPage(c, theme, header, icon,
      coverTitle, coverBannerH, coverSub, f1, f2)));
  for (var pi = 0; pi < pages.length; pi++) {
    addImage(await rasterPng((c) => paintContent(c, pi, pages[pi])));
  }
  addImage(await rasterPng((c) => _paintBackCover(c, theme, icon)));
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
  final int icon;
  const _DesignPreview(this.theme, this.paper, this.text, this.frame,
      this.pattern, this.header, this.icon);

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
    final top = 38.0 + (icon > 0 ? _iconBand : 0);
    _paintIcon(canvas, theme, icon, const Offset(_pageW / 2, _iconCy), _iconSize);
    _paintHeader(canvas, theme, header, top, headerH, title, diwan);

    final bar = _fillP(text.withOpacity(.5));
    var y = top + headerH + 30;
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
  int header,
  int icon
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
  var iconI = 0;

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
            iconI = r.nextInt(5) == 0 ? 0 : 1 + r.nextInt(iconLabels.length - 1);
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
                            headI,
                            iconI),
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
                        title('أيقونة أعلى الصفحة الأولى'),
                        chips(iconLabels, iconI, (i) => iconI = i),
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
                        title('تأثيرات الورقة'),
                        _paperFxSection((f) => setS(f)),
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
    icon: iconI,
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
    d.icon,
  );
}

Future<void> _exportPdf(BuildContext context, Poem poem, String diwan,
    PdfTheme theme, Color text, Color paper, int frame, int pattern,
    int header, int icon) async {
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
      icon: icon,
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
  if (inApp != null && context.mounted) {
    _toastSaved(context, messenger, 'تم حفظ القصيدة في قسم «الملفات»',
        SavedKind.pdf);
  } else {
    toast('تعذّر حفظ الملف');
  }
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
  int icon = 0,
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
  final iconH = icon > 0 ? 66.0 : 0.0;
  final contentH = iconH + 24 + 12 + titleP.height + 12 + 16 + 28 + versesH + 28 + 16 +
      12 + f1.height + 4 + f2.height;
  var y = math.max(70.0, (_pageH - contentH) / 2);

  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  canvas.scale(_scale);
  _paintPage(canvas, theme, paper, frame, pattern);

  if (icon > 0) {
    _paintIcon(canvas, theme, icon, Offset(_pageW / 2, y + 30), 52);
    y += iconH;
  }
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
  var iconI = 0;
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
              icon: iconI,
            );
        fut ??= make();
        void change(VoidCallback f) => setS(() {
              f();
              fut = make();
            });

        void shuffle() {
          final r = math.Random();
          change(() {
            themeI = r.nextInt(pdfThemes.length);
            paperI = r.nextInt(paperChoices.length);
            frameI = r.nextInt(frameLabels.length);
            patI = r.nextInt(patternLabels.length);
            iconI = r.nextInt(5) == 0 ? 0 : 1 + r.nextInt(iconLabels.length - 1);
          });
        }

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
                  child: Row(children: [
                    Expanded(
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
                    TextButton.icon(
                      onPressed: shuffle,
                      icon: Icon(Icons.shuffle_rounded, color: brown),
                      label: Text('تصميم عشوائي',
                          style: TextStyle(color: brown)),
                    ),
                  ]),
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
                        title('أيقونة أعلى الصورة'),
                        chips(iconLabels, iconI, (i) => iconI = i),
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
                        title('تأثيرات الورقة'),
                        _paperFxSection(change),
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
                            if (inApp != null && context.mounted) {
                              _toastSaved(
                                  context,
                                  messenger,
                                  'تم حفظ الصورة في قسم «الملفات»',
                                  SavedKind.image);
                            } else {
                              toast('تعذّر حفظ الصورة');
                            }
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
  int icon = 0,
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

  final darkHeader = _headerDark(header);
  final titleColor = darkHeader ? Colors.white : theme.dark;

  // الغلاف: عنوان القسم في ترويسة، والسطر الفرعي تحته
  final (coverTitle, coverBannerH) = _coverTitle(title, baseStyle, titleColor);
  final coverSub = _centeredPainter(
      subtitle,
      baseStyle.merge(TextStyle(
          color: Color.lerp(theme.accent, Colors.black, .35),
          fontSize: 16,
          height: 1.4,
          fontWeight: FontWeight.w600)),
      _avail);

  // عنوان القسم أعلى أول صفحة: ترويسة مزخرفة مدمجة
  final titleP = _centeredPainter(
      title,
      baseStyle.merge(TextStyle(
          color: titleColor,
          fontSize: 20,
          height: 1.5,
          fontWeight: FontWeight.bold)),
      _avail - 60);
  final bannerH = math.max(titleP.height + 28, 58.0);
  final firstStart = _top + bannerH + _headerOverhang(header) + 22;

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
  Future<Uint8List> rasterPng(void Function(Canvas) draw) async {
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    canvas.scale(scale);
    _paintPage(canvas, theme, paper, frame, pattern);
    draw(canvas);
    final pic = rec.endRecording();
    final img = await pic.toImage(
        (_pageW * scale).round(), (_pageH * scale).round());
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    pic.dispose();
    return bd!.buffer.asUint8List();
  }

  void paintContent(Canvas canvas, int pi, List<int> idx) {
    var py = _top;
    if (pi == 0) {
      _paintHeaderShape(
          canvas, theme, header, Rect.fromLTWH(_mx, _top, _avail, bannerH));
      titleP.paint(
          canvas, Offset(_mx + 30, _top + (bannerH - titleP.height) / 2));
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
    _paintPageNumber(canvas, theme, baseStyle, pi + 1, pages.length);
  }

  final doc = pw.Document();
  void addImage(Uint8List png) {
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

  // الغلاف الأمامي ثم الصيغ ثم الغلاف الخلفي (بدون كلام)
  addImage(await rasterPng((c) => _paintCoverPage(c, theme, header, icon,
      coverTitle, coverBannerH, coverSub, credit.$1, credit.$2)));
  await Future<void>.delayed(Duration.zero);
  for (var pi = 0; pi < pages.length; pi++) {
    addImage(await rasterPng((c) => paintContent(c, pi, pages[pi])));
    await Future<void>.delayed(Duration.zero);
  }
  addImage(await rasterPng((c) => _paintBackCover(c, theme, icon)));
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
      icon: d.icon,
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
  if (inApp != null && context.mounted) {
    _toastSaved(context, messenger, 'تم حفظ الملف في قسم «الملفات»',
        SavedKind.pdf);
  } else {
    toast('تعذّر حفظ الملف');
  }
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
  int icon = 0,
}) async {
  final baseStyle = (Theme.of(context).textTheme.bodyMedium ?? const TextStyle())
      .copyWith(decoration: TextDecoration.none);
  final iconH = icon > 0 ? 66.0 : 0.0;

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
  final maxH = _pageH - 2 * 74.0 - iconH;
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
    contentH = iconH + 24 + 12 + titleP.height + 12 + 16 + 28 + bodyH + 24 + 16 + 10 + creditH;
    if (contentH <= maxH || size <= 12) break;
    size = math.max(12, size * .92);
  }

  var y = math.max(70.0, (_pageH - contentH) / 2);

  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  canvas.scale(_scale);
  _paintPage(canvas, theme, paper, frame, pattern);

  if (icon > 0) {
    _paintIcon(canvas, theme, icon, Offset(_pageW / 2, y + 30), 52);
    y += iconH;
  }
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
  var iconI = 0;
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
              icon: iconI,
            );
        fut ??= make();
        void change(VoidCallback f) => setS(() {
              f();
              fut = make();
            });

        void shuffle() {
          final r = math.Random();
          change(() {
            themeI = r.nextInt(pdfThemes.length);
            paperI = r.nextInt(paperChoices.length);
            frameI = r.nextInt(frameLabels.length);
            patI = r.nextInt(patternLabels.length);
            iconI = r.nextInt(5) == 0 ? 0 : 1 + r.nextInt(iconLabels.length - 1);
          });
        }

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
                  child: Row(children: [
                    Expanded(
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
                    TextButton.icon(
                      onPressed: shuffle,
                      icon: Icon(Icons.shuffle_rounded, color: brown),
                      label: Text('تصميم عشوائي',
                          style: TextStyle(color: brown)),
                    ),
                  ]),
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
                        title('أيقونة أعلى الصورة'),
                        chips(iconLabels, iconI, (i) => iconI = i),
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
                        title('تأثيرات الورقة'),
                        _paperFxSection(change),
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
                            if (inApp != null && context.mounted) {
                              _toastSaved(
                                  context,
                                  messenger,
                                  'تم حفظ الصورة في قسم «الملفات»',
                                  SavedKind.image);
                            } else {
                              messenger
                                ..hideCurrentSnackBar()
                                ..showSnackBar(SnackBar(
                                    content: Text('تعذّر حفظ الصورة',
                                        textAlign: TextAlign.center),
                                    duration: const Duration(seconds: 3)));
                            }
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
  final double bannerH; // ارتفاع ترويسة العنوان
  final double overhang; // ما يزيد أسفلها حسب الشكل
  final List<TextPainter> sadr;
  final List<TextPainter> ajz;
  final double gapV;
  final double gap;
  final List<double> hv;
  _DPoem(this.title, this.bannerH, this.overhang, this.sadr, this.ajz,
      this.gapV, this.gap, this.hv);
  double get titleH => bannerH + overhang + 8;
}

class _DiwanCancelled implements Exception {}

final _zlibFast = ZLibEncoder(level: 3);

/// استراحة قصيرة ليتحدّث شريط التقدّم أثناء العمل الطويل
Future<void> _uiBreath() =>
    Future<void>.delayed(const Duration(milliseconds: 2));

/// كاتب PDF بسيط: كل صفحة صورة RGB مضغوطة تُكتب مباشرة (بدون فكّ/إعادة ضغط).
/// هذا هو سبب السرعة: مكتبة pdf كانت تفكّ كل صورة PNG ببطء ثم تُبقيها في الذاكرة.
class _MiniPdf {
  static const _wPt = '595.28';
  static const _hPt = '841.89';
  final _out = BytesBuilder(copy: false);
  final _offsets = <int, int>{};
  final _pageIds = <int>[];

  _MiniPdf() {
    _str('%PDF-1.4\n');
    _out.add(const [0x25, 0xE2, 0xE3, 0xCF, 0xD3, 0x0A]);
  }

  void _str(String s) => _out.add(latin1.encode(s));

  void _begin(int id) {
    _offsets[id] = _out.length;
    _str('$id 0 obj\n');
  }

  // أرقام الكائنات: 1 الفهرس، 2 الصفحات، 3 المعلومات، ثم لكل صفحة 3 كائنات
  void addPage(Uint8List flateRgb, int w, int h) {
    final pageId = 4 + 3 * _pageIds.length;
    final contentId = pageId + 1;
    final imgId = pageId + 2;
    _pageIds.add(pageId);

    _begin(imgId);
    _str('<< /Type /XObject /Subtype /Image /Width $w /Height $h '
        '/ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /FlateDecode '
        '/Length ${flateRgb.length} >>\nstream\n');
    _out.add(flateRgb);
    _str('\nendstream\nendobj\n');

    const content = 'q $_wPt 0 0 $_hPt 0 0 cm /Im0 Do Q';
    _begin(contentId);
    _str('<< /Length ${content.length} >>\nstream\n$content\nendstream\nendobj\n');

    _begin(pageId);
    _str('<< /Type /Page /Parent 2 0 R /MediaBox [0 0 $_wPt $_hPt] '
        '/Resources << /XObject << /Im0 $imgId 0 R >> >> '
        '/Contents $contentId 0 R >>\nendobj\n');
  }

  Uint8List finish(String title) {
    _begin(2);
    _str('<< /Type /Pages /Count ${_pageIds.length} '
        '/Kids [${_pageIds.map((i) => '$i 0 R').join(' ')}] >>\nendobj\n');
    _begin(1);
    _str('<< /Type /Catalog /Pages 2 0 R >>\nendobj\n');
    final hex = StringBuffer('FEFF');
    for (final u in title.codeUnits) {
      hex.write(u.toRadixString(16).padLeft(4, '0'));
    }
    _begin(3);
    _str('<< /Title <$hex> /Producer (Dawawin Al-Noor) >>\nendobj\n');

    final maxId = 3 + 3 * _pageIds.length;
    final xrefPos = _out.length;
    final sb = StringBuffer('xref\n0 ${maxId + 1}\n0000000000 65535 f \n');
    for (var id = 1; id <= maxId; id++) {
      sb.write('${_offsets[id]!.toString().padLeft(10, '0')} 00000 n \n');
    }
    sb.write('trailer\n<< /Size ${maxId + 1} /Root 1 0 R /Info 3 0 R >>\n'
        'startxref\n$xrefPos\n%%EOF\n');
    _str(sb.toString());
    return _out.takeBytes();
  }
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
  int icon = 0,
  void Function(double progress)? onProgress,
  bool Function()? isCancelled,
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
      color: _headerDark(header) ? Colors.white : theme.dark,
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
    // عنوان القصيدة داخل ترويسة مزخرفة بنفس شكل الترويسة المختار
    final tp = centered(poem.title, titleStyle, _avail - 60);
    final bannerH = math.max(tp.height + 28, 58.0);
    laid.add(_DPoem(tp, bannerH, _headerOverhang(header), sadr, ajz, gapV,
        size * .95, hv));
    onProgress?.call(0.25 * (pi + 1) / poemsList.length);
    if (isCancelled?.call() == true) throw _DiwanCancelled();
    await _uiBreath();
  }

  final darkHeader = _headerDark(header);
  final headOverhang = _headerOverhang(header);
  final bannerText = darkHeader ? Colors.white : theme.dark;

  // التذييل (آخر صفحة + الغلاف) — نفس تذييل القصيدة
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

  // ───── الغلاف ─────
  final (coverTitle, coverBannerH) = _coverTitle(diwan, baseStyle, bannerText);
  final coverSub = centered(
      '${arDigits(poemsList.length)} قصيدة',
      baseStyle.merge(TextStyle(
          color: Color.lerp(theme.accent, Colors.black, .35),
          fontSize: 16,
          height: 1.4,
          fontWeight: FontWeight.w600)),
      _avail);
  void paintCover(Canvas canvas) => _paintCoverPage(canvas, theme, header,
      icon, coverTitle, coverBannerH, coverSub, f1, f2);

  // ───── الفهرس (يظهر لو الديوان فيه أكثر من قصيدة) ─────
  final showToc = poemsList.length >= 2;
  const tocTw = _avail - 56;
  final tocTitleStyle = baseStyle.merge(TextStyle(
      color: theme.dark,
      fontSize: 15,
      height: 1.5,
      fontWeight: FontWeight.w600));
  final tocRows = <TextPainter>[
    if (showToc)
      for (final p in poemsList)
        TextPainter(
          text: TextSpan(text: p.title, style: tocTitleStyle),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          textScaler: TextScaler.noScaling,
        )..layout(minWidth: tocTw, maxWidth: tocTw),
  ];
  final tocBanner = centered(
      'الفهرس',
      baseStyle.merge(TextStyle(
          color: bannerText,
          fontSize: 22,
          height: 1.5,
          fontWeight: FontWeight.bold)),
      _avail - 60);
  const tocBannerH = 54.0;
  final tocStart = _top + tocBannerH + headOverhang + 22;
  const tocGap = 12.0;
  final tocPages = <List<int>>[];
  if (showToc) {
    tocPages.add(<int>[]);
    var ty = tocStart;
    for (var i = 0; i < tocRows.length; i++) {
      final h = tocRows[i].height;
      if (tocPages.last.isNotEmpty && ty + h > _bottom) {
        tocPages.add(<int>[]);
        ty = tocStart;
      }
      tocPages.last.add(i);
      ty += h + tocGap;
    }
  }

  // ───── صفحات القصائد ─────
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
  var y = _top;
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

  // أرقام الصفحات: الغلاف ١، ثم الفهرس، ثم القصائد
  final tocCount = tocPages.length;
  final totalPages = 1 + tocCount + pages.length + 1; // + الغلاف الخلفي
  int numberOf(int contentPage) => tocCount + contentPage + 2;
  final poemPage = List<int>.filled(laid.length, 0);
  for (var pi = 0; pi < pages.length; pi++) {
    for (final k in pages[pi]) {
      if (entries[k].$2 < 0) poemPage[entries[k].$1] = pi;
    }
  }

  void paintToc(Canvas canvas, int ti) {
    _paintHeaderShape(
        canvas, theme, header, Rect.fromLTWH(_mx, _top, _avail, tocBannerH));
    tocBanner.paint(
        canvas, Offset(_mx + 30, _top + (tocBannerH - tocBanner.height) / 2));
    var ry = tocStart;
    for (final i in tocPages[ti]) {
      final tp = tocRows[i];
      final x0 = _mx + 30.0;
      tp.paint(canvas, Offset(x0, ry));
      final ms = tp.computeLineMetrics();
      final first = ms.first;
      final last = ms.last;

      // رقم القصيدة في نجمة صغيرة (يمين)
      final sc = Offset(_mx + _avail - 9, ry + first.height / 2);
      canvas.drawPath(_pdfStar(sc, 9.5), _fillP(theme.dark));
      canvas.drawPath(_pdfStar(sc, 9.5), _stroke(theme.accent, .9));
      final ordP = TextPainter(
        text: TextSpan(
            text: arDigits(i + 1),
            style: baseStyle.merge(const TextStyle(
                color: Colors.white,
                fontSize: 9,
                height: 1.0,
                fontWeight: FontWeight.bold))),
        textDirection: TextDirection.rtl,
        textScaler: TextScaler.noScaling,
      )..layout();
      ordP.paint(canvas, sc - Offset(ordP.width / 2, ordP.height / 2));

      // رقم الصفحة (يسار) على نفس خط قاعدة آخر سطر من العنوان
      final pgP = TextPainter(
        text: TextSpan(
            text: arDigits(numberOf(poemPage[i])),
            style: baseStyle.merge(TextStyle(
                color: theme.dark,
                fontSize: 14,
                height: 1.0,
                fontWeight: FontWeight.bold))),
        textDirection: TextDirection.rtl,
        textScaler: TextScaler.noScaling,
      )..layout();
      final baseY = ry + last.baseline;
      pgP.paint(
          canvas,
          Offset(_mx,
              baseY - pgP.computeDistanceToActualBaseline(TextBaseline.alphabetic)));

      // نقط التوصيل بين نهاية العنوان ورقم الصفحة
      final dotsL = _mx + pgP.width + 8;
      final dotsR = x0 + last.left - 8;
      for (var dx = dotsR; dx > dotsL; dx -= 5) {
        canvas.drawCircle(Offset(dx, baseY - 3), .9, _fillP(theme.accent));
      }
      ry += tp.height + tocGap;
    }
  }

  void paintContent(Canvas canvas, int pi, List<int> idx) {
    var py = _top;
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
        _paintHeaderShape(
            canvas, theme, header, Rect.fromLTWH(_mx, py, _avail, p.bannerH));
        p.title.paint(
            canvas, Offset(_mx + 30, py + (p.bannerH - p.title.height) / 2));
        py += p.bannerH + p.overhang + 8;
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
  }

  // ───── الغلاف الخلفي ─────
  void paintBack(Canvas canvas) => _paintBackCover(canvas, theme, icon);

  // ───── تحويل كل صفحة إلى صورة مضغوطة داخل الـ PDF ─────
  const scale = 2.5;
  final wPx = (_pageW * scale).round();
  final hPx = (_pageH * scale).round();
  Future<Uint8List> rasterize(void Function(Canvas) draw) async {
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    canvas.scale(scale);
    _paintPage(canvas, theme, paper, frame, pattern);
    draw(canvas);

    final pic = rec.endRecording();
    final img = await pic.toImage(wPx, hPx);
    final bd = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    img.dispose();
    pic.dispose();
    final rgba = bd!.buffer.asUint8List(bd.offsetInBytes, bd.lengthInBytes);
    final rgb = Uint8List(wPx * hPx * 3);
    for (var s = 0, d = 0; s < rgba.length; s += 4, d += 3) {
      final a = rgba[s + 3];
      if (a == 255) {
        rgb[d] = rgba[s];
        rgb[d + 1] = rgba[s + 1];
        rgb[d + 2] = rgba[s + 2];
      } else {
        rgb[d] = math.min(255, rgba[s] + 255 - a);
        rgb[d + 1] = math.min(255, rgba[s + 1] + 255 - a);
        rgb[d + 2] = math.min(255, rgba[s + 2] + 255 - a);
      }
    }
    // ضغط سريع (zlib الأصلي) ثم يُكتب مباشرة داخل الـ PDF
    return Uint8List.fromList(_zlibFast.convert(rgb));
  }

  final pdf = _MiniPdf();
  var done = 0;
  Future<void> addPage(void Function(Canvas) draw) async {
    if (isCancelled?.call() == true) throw _DiwanCancelled();
    pdf.addPage(await rasterize(draw), wPx, hPx);
    done++;
    onProgress?.call(0.25 + 0.75 * done / totalPages);
    await _uiBreath();
  }

  await addPage(paintCover);
  for (var ti = 0; ti < tocPages.length; ti++) {
    await addPage((c) {
      paintToc(c, ti);
      _paintPageNumber(c, theme, baseStyle, ti + 2, totalPages);
    });
  }
  for (var pi = 0; pi < pages.length; pi++) {
    await addPage((c) {
      paintContent(c, pi, pages[pi]);
      _paintPageNumber(c, theme, baseStyle, numberOf(pi), totalPages);
    });
  }
  await addPage(paintBack);
  return pdf.finish(diwan);
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

  final progress = ValueNotifier<double>(0);
  final cancelled = ValueNotifier<bool>(false);
  final clock = Stopwatch()..start();

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: Dialog(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
          child: ValueListenableBuilder<double>(
            valueListenable: progress,
            builder: (_, p, __) {
              var eta = 'جاري التحضير…';
              if (p > 0.04 && p < 1) {
                final left =
                    (clock.elapsedMilliseconds * (1 - p) / p / 1000).ceil();
                eta = left >= 60
                    ? 'المتبقي حوالي ${arDigits((left / 60).ceil())} دقيقة'
                    : 'المتبقي حوالي ${arDigits(math.max(left, 1))} ثانية';
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                      'جاري إنشاء ملف الديوان (${arDigits(list.length)} قصيدة)',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                        value: p, minHeight: 10, color: brown),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${arDigits((p * 100).floor())}٪',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(eta),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.center,
                    child: TextButton(
                        onPressed: () => cancelled.value = true,
                        child: const Text('إلغاء')),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
  await Future<void>.delayed(const Duration(milliseconds: 150));

  Uint8List? bytes;
  var wasCancelled = false;
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
      icon: d.icon,
      onProgress: (p) => progress.value = p,
      isCancelled: () => cancelled.value,
    );
  } on _DiwanCancelled {
    wasCancelled = true;
    bytes = null;
  } catch (_) {
    bytes = null;
  }
  if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  progress.dispose();
  cancelled.dispose();

  if (wasCancelled) {
    toast('تم إلغاء إنشاء الملف');
    return;
  }
  if (bytes == null) {
    toast('تعذّر إنشاء الملف');
    return;
  }
  final inApp = await SavedFiles.save(SavedKind.pdf, diwan, bytes);
  if (inApp != null && context.mounted) {
    _toastSaved(context, messenger, 'تم حفظ الديوان في قسم «الملفات»',
        SavedKind.pdf);
  } else {
    toast('تعذّر حفظ الملف');
  }
}
