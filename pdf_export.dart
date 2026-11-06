import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart' show PdfPageFormat;
import 'package:pdf/widgets.dart' as pw;

import 'main.dart';
import 'poems_data.dart';

// ════════════════════════════════════════════════
// تصدير القصيدة إلى PDF (إطار إسلامي + نقوش شفافة)
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
];

// ───────────── مقاسات الصفحة (A4 بالنسبة) ─────────────

const double _pageW = 420;
const double _pageH = 594;
const double _scale = 3.0; // دقة الصورة (3 = حوالي 150 DPI)
const double _mx = 46; // الهامش الجانبي
const double _top = 46;
const double _bottom = _pageH - 46;
const double _avail = _pageW - 2 * _mx;

// ───────────── الرسم ─────────────

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

/// الورقة: لون + نقوش نجمية شفافة + إطار مذهّب بنجوم
void _paintPage(Canvas canvas, PdfTheme t, Color paper) {
  canvas.drawRect(Rect.fromLTWH(0, 0, _pageW, _pageH), Paint()..color = paper);

  final outer = RRect.fromRectAndRadius(
      Rect.fromLTWH(8, 8, _pageW - 16, _pageH - 16), const Radius.circular(12));

  // النقوش الشفافة داخل الإطار
  canvas.save();
  canvas.clipRRect(outer);
  const cell = 46.0;
  final stroke = Paint()
    ..color = t.accent.withOpacity(.16)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  final fill = Paint()..color = t.accent.withOpacity(.10);
  for (var y = 0.0; y < _pageH + cell; y += cell) {
    for (var x = 0.0; x < _pageW + cell; x += cell) {
      canvas.drawPath(_pdfStar(Offset(x, y), 13), stroke);
      canvas.drawPath(_pdfStar(Offset(x + cell / 2, y + cell / 2), 5), fill);
    }
  }
  canvas.restore();

  // الإطار: خط ذهبي سميك + خط رفيع + خط داخلي ملوّن
  canvas.drawRRect(
      outer,
      Paint()
        ..color = t.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4);
  canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(13, 13, _pageW - 26, _pageH - 26),
          const Radius.circular(9)),
      Paint()
        ..color = t.accent.withOpacity(.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8);
  final inner = Rect.fromLTWH(19, 19, _pageW - 38, _pageH - 38);
  canvas.drawRRect(
      RRect.fromRectAndRadius(inner, const Radius.circular(5)),
      Paint()
        ..color = t.dark.withOpacity(.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2);

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

/// الترويسة على شكل محراب: نجمة + العنوان في الوسط + زخرفة + اسم الديوان
void _paintHeader(Canvas canvas, PdfTheme t, double top, double h,
    TextPainter title, TextPainter diwan) {
  final rect = Rect.fromLTWH(_mx, top, _avail, h);
  final rr = RRect.fromRectAndCorners(
    rect,
    topLeft: const Radius.circular(100),
    topRight: const Radius.circular(100),
    bottomLeft: const Radius.circular(14),
    bottomRight: const Radius.circular(14),
  );
  final darker = Color.lerp(t.dark, Colors.black, .35)!;
  canvas.drawRRect(
      rr,
      Paint()
        ..shader = ui.Gradient.linear(
            rect.topCenter, rect.bottomCenter, [t.dark, darker]));
  canvas.drawRRect(
      rr,
      Paint()
        ..color = t.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);

  var y = top + 30;
  canvas.drawPath(
      _pdfStar(Offset(_pageW / 2, y + 11), 11), Paint()..color = t.accent);
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
}) async {
  // نفس ستايل النص الذي يستخدمه التطبيق داخل الصفحات (من الثيم)
  final baseStyle = (Theme.of(context).textTheme.bodyMedium ?? const TextStyle())
      .copyWith(decoration: TextDecoration.none);

  TextStyle styleFor(double s) => baseStyle.merge(TextStyle(
        fontSize: s,
        height: 1.0,
        color: textColor,
        fontWeight: FontWeight.w500,
      ));

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
      )..layout(minWidth: hw, maxWidth: hw);

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
  final titleP = centered(
      poem.title,
      baseStyle.merge(const TextStyle(
          color: Colors.white,
          fontSize: 22,
          height: 1.5,
          fontWeight: FontWeight.bold)),
      _avail - 60);
  final diwanP = centered(
      diwan,
      baseStyle.merge(const TextStyle(
          color: Color(0xFFE8D9BC), fontSize: 14, height: 1.4)),
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
    final canvas = Canvas(rec, Rect.fromLTWH(0, 0, _pageW, _pageH));
    canvas.scale(_scale);
    _paintPage(canvas, theme, paper);

    var py = _top;
    if (pi == 0) {
      _paintHeader(canvas, theme, headerTop, headerH, titleP, diwanP);
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
      sadr[i].paint(canvas, Offset(_mx + _avail - hw, py));
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

// ───────────── نافذة الخيارات + الحفظ ─────────────

Future<void> showPoemPdfSheet(
    BuildContext context, Poem poem, String diwan) async {
  var themeI = 0;
  var textI = colorChoices.indexWhere((c) => c.color == poemFontColor.value);
  if (textI < 0) textI = 0;
  var paperI = 0;

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
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: brown)),
      );

  final go = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: cream,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('تحويل القصيدة إلى PDF',
                  style: TextStyle(
                      fontSize: 19, fontWeight: FontWeight.bold, color: brown)),
              title('لون الإطار والزخرفة'),
              Wrap(spacing: 10, runSpacing: 10, children: [
                for (var i = 0; i < pdfThemes.length; i++)
                  swatch(
                    dot: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: pdfThemes[i].dark,
                        border: Border.all(color: pdfThemes[i].accent, width: 3),
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
                            shape: BoxShape.circle, color: colorChoices[i].color)),
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
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: brown,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () => Navigator.pop(ctx, true),
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text('إنشاء وحفظ PDF',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  if (go != true || !context.mounted) return;
  await _exportPdf(context, poem, diwan, pdfThemes[themeI],
      colorChoices[textI].color, paperChoices[paperI].color);
}

Future<void> _exportPdf(BuildContext context, Poem poem, String diwan,
    PdfTheme theme, Color text, Color paper) async {
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
    );
  } catch (_) {
    bytes = null;
  }
  if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

  if (bytes == null) {
    toast('تعذّر إنشاء الملف');
    return;
  }

  final name = poem.title
      .replaceAll(RegExp(r'[\\/:*?"<>|\n\r]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  try {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'حفظ القصيدة كملف PDF',
      fileName: '${name.isEmpty ? 'قصيدة' : name}.pdf',
      bytes: bytes,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (path != null) toast('تم حفظ القصيدة كملف PDF');
  } catch (_) {
    toast('تعذّر حفظ الملف');
  }
}
