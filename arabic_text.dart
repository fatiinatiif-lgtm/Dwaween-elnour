import 'dart:math' as math;
import 'package:flutter/widgets.dart';

/// تطبيع النص للبحث: يحذف التشكيل والتطويل ويوحّد الهمزات والياء/الألف المقصورة.
String normalizeArabic(String s) {
  final b = StringBuffer();
  for (final r in s.runes) {
    if ((r >= 0x064B && r <= 0x065F) ||
        r == 0x0670 ||
        r == 0x0640 ||
        (r >= 0x06D6 && r <= 0x06ED)) {
      continue;
    }
    switch (r) {
      case 0x0622:
      case 0x0623:
      case 0x0625:
      case 0x0671:
        b.write('ا');
        break;
      case 0x0649:
        b.write('ي');
        break;
      case 0x0629:
        b.write('ه');
        break;
      default:
        b.writeCharCode(r);
    }
  }
  return b.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

// ───────────── الكشيدة (التطويل) ─────────────

const String kTatweel = '\u0640';

bool _isDiacritic(int c) => (c >= 0x064B && c <= 0x065F) || c == 0x0670;
bool _isLetter(int c) => (c >= 0x0621 && c <= 0x063A) || (c >= 0x0641 && c <= 0x064A);

// حروف لا تتصل بما بعدها (لا يصح وضع تطويل بعدها)
const _nonJoining = {
  0x0621, 0x0622, 0x0623, 0x0624, 0x0625, 0x0627, 0x0629,
  0x062F, 0x0630, 0x0631, 0x0632, 0x0648, 0x0649,
};

double measureText(String text, TextStyle style) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.rtl,
    textScaler: TextScaler.noScaling,
    maxLines: 1,
  )..layout();
  final w = tp.width;
  tp.dispose();
  return w;
}

/// مواضع إدخال التطويل: بين حرفين متصلين داخل الكلمة نفسها.
List<int> _slots(String s) {
  final out = <int>[];
  for (var i = 0; i < s.length; i++) {
    final c = s.codeUnitAt(i);
    if (!_isLetter(c) || _nonJoining.contains(c)) continue;
    var j = i + 1;
    while (j < s.length && _isDiacritic(s.codeUnitAt(j))) {
      j++;
    }
    if (j >= s.length) continue;
    final n = s.codeUnitAt(j);
    if (!_isLetter(n)) continue;
    // لا نفصل لام-ألف (لا)
    if (c == 0x0644 && (n == 0x0627 || n == 0x0623 || n == 0x0625 || n == 0x0622)) {
      continue;
    }
    out.add(j);
  }
  return out;
}

String _build(String s, List<int> slots, List<int> counts) {
  final b = StringBuffer();
  var last = 0;
  for (var k = 0; k < slots.length; k++) {
    if (counts[k] == 0) continue;
    b.write(s.substring(last, slots[k]));
    b.write(kTatweel * counts[k]);
    last = slots[k];
  }
  b.write(s.substring(last));
  return b.toString();
}

class Justified {
  final String text;
  final double wordSpacing;
  final bool fits;
  const Justified(this.text, this.wordSpacing, this.fits);
}

/// يمدّ الشطر بالكشيدة حتى يطابق [target] بالضبط تقريبًا.
/// أي فرق صغير متبقٍ (أقل من عرض تطويلة) يُوزَّع على المسافات بين الكلمات.
Justified justifyHemistich(String text, TextStyle style, double target) {
  final s = text.trim().replaceAll(RegExp(r'\s+'), ' ');
  var current = s;
  var w = measureText(s, style);
  if (w > target + 0.5) return Justified(s, 0, false);

  final slots = _slots(s);
  if (slots.isNotEmpty) {
    var tatW = measureText('بب$kTatweel', style) - measureText('بب', style);
    if (tatW <= 0.5) tatW = style.fontSize ?? 20 * 0.2;

    final counts = List<int>.filled(slots.length, 0);
    final order = List<int>.generate(slots.length, (i) => i)
      ..sort((a, b) =>
          ((a * 0.6180339887) % 1).compareTo((b * 0.6180339887) % 1));
    var cursor = 0;
    var fine = false;
    const maxPerSlot = 6;

    for (var guard = 0; guard < 120; guard++) {
      final remaining = target - w;
      if (remaining < tatW * 0.5) break;
      final want = fine ? 1 : math.max(1, (remaining / tatW * 0.8).floor());

      final backup = List<int>.from(counts);
      final backupCursor = cursor;
      var added = 0, tries = 0;
      while (added < want && tries < order.length * (maxPerSlot + 1)) {
        final idx = order[cursor % order.length];
        cursor++;
        tries++;
        if (counts[idx] < maxPerSlot) {
          counts[idx]++;
          added++;
        }
      }
      if (added == 0) break;

      final candidate = _build(s, slots, counts);
      final cw = measureText(candidate, style);
      if (cw > target + 0.3) {
        for (var k = 0; k < counts.length; k++) {
          counts[k] = backup[k];
        }
        cursor = backupCursor;
        if (want == 1) break;
        fine = true;
        continue;
      }
      current = candidate;
      w = cw;
    }
  }

  // الباقي (أقل من تطويلة) يُمتص في المسافات بين الكلمات
  final residual = target - w;
  final spaces = ' '.allMatches(current).length;
  var ws = 0.0;
  if (spaces > 0 && residual > 0.3) ws = math.min(residual / spaces, 14);
  return Justified(current, ws, true);
}
