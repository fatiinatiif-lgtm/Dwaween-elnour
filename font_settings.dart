import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ───────────── إعدادات الخط (تُحفظ على الهاتف) ─────────────

/// حجم خط القصيدة
final ValueNotifier<double> poemFontSize = ValueNotifier<double>(22);

/// اسم الخط (من الخطوط المضمّنة داخل التطبيق)، أو null للخط الافتراضي
final ValueNotifier<String?> poemFontFamily = ValueNotifier<String?>(null);

/// لون خط القصيدة
final ValueNotifier<Color> poemFontColor =
    ValueNotifier<Color>(const Color(0xFF3E2723));

/// true = بدون تشكيل، false = التشكيل كما هو
final ValueNotifier<bool> removeTashkeel = ValueNotifier<bool>(false);

/// يتغيّر عند تغيّر أي إعداد
final Listenable poemSettings = Listenable.merge(
    [poemFontSize, poemFontFamily, poemFontColor, removeTashkeel]);

const double minPoemFont = 16;
const double maxPoemFont = 30;

class FontChoice {
  final String label;
  final String? family;
  const FontChoice(this.label, this.family);
}

const fontChoices = [
  FontChoice('الخط الافتراضي', null),
  FontChoice('أميري', 'Amiri'),
  FontChoice('شهرزاد', 'Scheherazade'),
  FontChoice('نسخ', 'NotoNaskh'),
  FontChoice('لطيف', 'Lateef'),
  FontChoice('رقعة', 'ArefRuqaa'),
];

class ColorChoice {
  final String label;
  final Color color;
  const ColorChoice(this.label, this.color);
}

const colorChoices = [
  ColorChoice('بني داكن', Color(0xFF3E2723)),
  ColorChoice('أسود', Color(0xFF1B1B1B)),
  ColorChoice('أخضر', Color(0xFF1B5E20)),
  ColorChoice('أزرق', Color(0xFF0D47A1)),
  ColorChoice('عنابي', Color(0xFF7B1F2E)),
  ColorChoice('رمادي', Color(0xFF455A64)),
  ColorChoice('ذهبي', Color(0xFF8A6A12)),
  ColorChoice('بنفسجي', Color(0xFF4A148C)),
];

// ───────────── التشكيل ─────────────
final RegExp _tashkeelRe = RegExp(
    '[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED]');

/// يحذف الحركات (التشكيل) من النص
String stripTashkeel(String s) => s.replaceAll(_tashkeelRe, '');

/// النص كما يجب أن يظهر حسب إعداد التشكيل
String displayText(String s) => removeTashkeel.value ? stripTashkeel(s) : s;

// ───────────── الخط ─────────────

/// يطبّق الخط المختار على النمط
TextStyle applyPoemFont(TextStyle base) {
  final f = poemFontFamily.value;
  return f == null ? base : base.copyWith(fontFamily: f);
}

// ───────────── الحفظ والاسترجاع ─────────────
Future<void> loadFontSettings() async {
  try {
    final p = await SharedPreferences.getInstance();
    final size = p.getDouble('poemFontSize');
    if (size != null) {
      poemFontSize.value = size.clamp(minPoemFont, maxPoemFont).toDouble();
    }
    final ci = p.getInt('poemFontColorIndex');
    if (ci != null && ci >= 0 && ci < colorChoices.length) {
      poemFontColor.value = colorChoices[ci].color;
    }
    removeTashkeel.value = p.getBool('removeTashkeel') ?? false;
    final family = p.getString('poemFontFamily');
    if (family != null && fontChoices.any((c) => c.family == family)) {
      poemFontFamily.value = family;
    }

    poemFontSize.addListener(() => p.setDouble('poemFontSize', poemFontSize.value));
    poemFontColor.addListener(() {
      final i = colorChoices.indexWhere((c) => c.color == poemFontColor.value);
      if (i >= 0) p.setInt('poemFontColorIndex', i);
    });
    removeTashkeel
        .addListener(() => p.setBool('removeTashkeel', removeTashkeel.value));
    poemFontFamily.addListener(() {
      final f = poemFontFamily.value;
      if (f == null) {
        p.remove('poemFontFamily');
      } else {
        p.setString('poemFontFamily', f);
      }
    });
  } catch (_) {
    // لو فشل الحفظ يشتغل التطبيق بالإعدادات الافتراضية
  }
}
