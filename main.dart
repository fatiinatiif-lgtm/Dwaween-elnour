import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'poems_data.dart';
import 'pdf_export.dart';

// ملف التطبيق الكامل (ما عدا القصائد: poems_data.dart)
// الأقسام بالترتيب:
//  1) الألوان والتطبيق والشاشات
//  2) عرض القصيدة (التصميم الإسلامي)
//  3) صفحة إعدادات الخط
//  4) إعدادات الخط (الحجم/اللون/التشكيل) وحفظها
//  5) أدوات النص العربي (بحث + كشيدة)
//  6) التاريخ الهجري والأرقام العربية

// ───────────── ألوان التطبيق: بني وبيج ─────────────
const brown = Color(0xFF6D4C41);
const brownDark = Color(0xFF3E2723);
const beige = Color(0xFFF5ECDC);
const cream = Color(0xFFFFFBF2);
const accentGold = Color(0xFFC9A24B);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadFontSettings();
  runApp(const DiwanApp());
}

class DiwanApp extends StatelessWidget {
  const DiwanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'دواوين النور',
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: beige,
        colorScheme: ColorScheme.fromSeed(seedColor: brown),
        appBarTheme: const AppBarTheme(
          backgroundColor: brown,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ───────────── شاشة البداية: سيد الشعراء + عدّاد إلى 5 ─────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int count = 5;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (count <= 1) {
        t.cancel();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      } else {
        setState(() => count--);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [brown, brownDark],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('سيد الشعراء',
                      style: TextStyle(
                          fontFamily: 'WinsoftThuluth',
                          color: Colors.white,
                          fontSize: 80,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(
                                color: Color(0x66000000),
                                blurRadius: 8,
                                offset: Offset(0, 3)),
                          ])),
                ),
              ),
              const SizedBox(height: 10),
              const Text('عبدالرحمن مصطفى الأزهري',
                  style: TextStyle(
                      fontFamily: 'WinsoftThuluth',
                      color: Color(0xFFE8D9BC),
                      fontSize: 26,
                      height: 1.3,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 40),
              Text(arDigits(count),
                  style: const TextStyle(
                      color: accentGold,
                      fontSize: 48,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}

// ───────────── الهيكل + الشريط السفلي ─────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int selected = 0;
  final pages = const [HomePage(), DiwansPage(), SettingsPage()];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(index: selected, children: pages),
        bottomNavigationBar: _FancyBottomBar(
          selected: selected,
          onTap: (i) => setState(() => selected = i),
        ),
      );
}

class _FancyBottomBar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;
  const _FancyBottomBar({required this.selected, required this.onTap});

  static const _items = [
    (Icons.home_rounded, 'الرئيسية'),
    (Icons.auto_stories_rounded, 'الدواوين'),
    (Icons.settings_rounded, 'الإعدادات'),
  ];

  @override
  Widget build(BuildContext context) => Container(
        color: beige,
        child: SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 6, 14, 10),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [brown, brownDark]),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: accentGold.withOpacity(.7), width: 1.2),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(.3),
                    blurRadius: 14,
                    offset: const Offset(0, 5)),
              ],
            ),
            child: Row(
              children: [
                for (var i = 0; i < _items.length; i++)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: selected == i ? accentGold : Colors.transparent,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_items[i].$1,
                                size: 34,
                                color: selected == i
                                    ? brownDark
                                    : beige.withOpacity(.8)),
                            const SizedBox(height: 2),
                            Text(_items[i].$2,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: selected == i
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: selected == i
                                        ? brownDark
                                        : beige.withOpacity(.8))),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}

// ───────────── الشاشة الرئيسية ─────────────
class _SearchHit {
  final String diwan;
  final Poem poem;
  final String snippet;
  const _SearchHit(this.diwan, this.poem, this.snippet);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  List<_SearchHit> get hits {
    final q = normalizeArabic(controller.text);
    if (q.isEmpty) return [];
    final out = <_SearchHit>[];
    for (final e in poems.entries) {
      for (final poem in e.value) {
        String? snippet;
        for (final v in poem.verses) {
          if (normalizeArabic('${v.sadr} ${v.ajz}').contains(q)) {
            snippet = '${v.sadr} … ${v.ajz}';
            break;
          }
        }
        if (snippet == null && normalizeArabic(poem.title).contains(q)) {
          snippet = '';
        }
        if (snippet != null) out.add(_SearchHit(e.key, poem, snippet));
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final searching = controller.text.trim().isNotEmpty;
    final results = hits;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          const Text('ابحث داخل النصوص كلها',
              style: TextStyle(
                  color: brown, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'اكتب كلمة أو عبارة من أي قصيدة',
              prefixIcon: const Icon(Icons.search, color: brown),
              suffixIcon: searching
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(controller.clear))
                  : null,
              filled: true,
              fillColor: cream,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: accentGold.withOpacity(.6)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: brown, width: 1.6),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _ClockAndDates()),
              SizedBox(width: 12),
              _DomeFrame(),
            ],
          ),
          const SizedBox(height: 24),
          if (searching) ...[
            const SectionHeading('نتائج البحث'),
            if (results.isEmpty)
              const Padding(
                padding: EdgeInsets.all(18),
                child: Text('لا توجد نتائج مطابقة.'),
              )
            else
              ...results.map((h) => Card(
                    child: ListTile(
                      title: Text(h.poem.title),
                      subtitle: Text(
                        h.snippet.isEmpty ? h.diwan : '${h.diwan}\n${h.snippet}',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  PoemPage(poem: h.poem, diwan: h.diwan))),
                    ),
                  )),
          ] else ...[
            const SectionHeading('الدواوين الشعرية'),
            ...diwanNames.take(3).toList().asMap().entries.map(
                (e) => DiwanTile(name: e.value, number: e.key + 1)),
          ],
        ],
      ),
    );
  }
}

class _DomeFrame extends StatelessWidget {
  const _DomeFrame();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
              colors: [Color(0xFFE6C26B), accentGold, Color(0xFF9A7428)]),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(.18),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
              color: beige, borderRadius: BorderRadius.circular(19)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset('assets/images/green_dome.jpg',
                width: 120, height: 138, fit: BoxFit.cover),
          ),
        ),
      );
}

class _ClockAndDates extends StatefulWidget {
  const _ClockAndDates();
  @override
  State<_ClockAndDates> createState() => _ClockAndDatesState();
}

class _ClockAndDatesState extends State<_ClockAndDates> {
  late Timer timer;
  DateTime now = DateTime.now();

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => now = DateTime.now());
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var h = now.hour % 12;
    if (h == 0) h = 12;
    final mm = now.minute.toString().padLeft(2, '0');
    final time = '${arDigits(h)}:${arDigits(mm)} ${now.hour < 12 ? 'ص' : 'م'}';
    final greg =
        '${weekdays[now.weekday - 1]} ${arDigits(now.day)} ${gregorianMonths[now.month - 1]} ${arDigits(now.year)} م';
    final hj = toHijri(now);
    final hijri = '${arDigits(hj.day)} ${hj.monthName} ${arDigits(hj.year)} هـ';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentGold.withOpacity(.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(time,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: brown)),
          const SizedBox(height: 6),
          Text(greg,
              style: const TextStyle(fontSize: 12.5, color: Colors.black87)),
          const SizedBox(height: 3),
          Text(hijri,
              style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
        ],
      ),
    );
  }
}

// ───────────── الدواوين ─────────────
class DiwansPage extends StatelessWidget {
  const DiwansPage({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SectionHeading('الدواوين'),
            ...diwanNames.asMap().entries
                .map((e) => DiwanTile(name: e.value, number: e.key + 1)),
          ],
        ),
      );
}

class DiwanTile extends StatelessWidget {
  final String name;
  final int number;
  const DiwanTile({super.key, required this.name, required this.number});
  @override
  Widget build(BuildContext context) => Card(
        elevation: 1,
        color: cream,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: accentGold.withOpacity(.45)),
        ),
        child: ListTile(
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: brown,
            child: Text(arDigits(number),
                style: const TextStyle(color: accentGold, fontWeight: FontWeight.bold)),
          ),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${arDigits((poems[name] ?? []).length)} قصيدة',
              style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_left),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => DiwanDetailPage(name: name))),
        ),
      );
}

class DiwanDetailPage extends StatelessWidget {
  final String name;
  const DiwanDetailPage({super.key, required this.name});
  @override
  Widget build(BuildContext context) {
    final list = poems[name] ?? [];
    return Scaffold(
      appBar: AppBar(title: Text(name, style: const TextStyle(fontSize: 16))),
      body: list.isEmpty
          ? const Center(child: Text('ستظهر القصائد هنا عند إضافتها.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) => Card(
                color: cream,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: accentGold.withOpacity(.45)),
                ),
                child: ListTile(
                  leading: const Icon(Icons.auto_stories, color: brown),
                  title: Text(list[i].title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => PoemPage(poem: list[i], diwan: name))),
                ),
              ),
            ),
    );
  }
}

// ───────────── صفحة القصيدة ─────────────
class PoemPage extends StatelessWidget {
  final Poem poem;
  final String diwan;
  const PoemPage({super.key, required this.poem, required this.diwan});

  /// نص القصيدة كاملًا مع التذييل
  String get _fullText {
    final b = StringBuffer()..writeln(displayText(poem.title))..writeln();
    for (final v in poem.verses) {
      b
        ..writeln(displayText(v.sadr).trim())
        ..writeln(displayText(v.ajz).trim())
        ..writeln();
    }
    b.write('كلمات شاعر رسول الله ﷺ / عبدالرحمن مصطفى الأزهري');
    return b.toString();
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _fullText));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        content: Text('تم نسخ القصيدة', textAlign: TextAlign.center),
        duration: Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('دواوين النور', style: TextStyle(fontSize: 17)),
          actions: [
            IconButton(
              tooltip: 'نسخ القصيدة',
              iconSize: 28,
              icon: const Icon(Icons.copy_rounded),
              onPressed: () => _copy(context),
            ),
            PopupMenuButton<String>(
              tooltip: 'خيارات',
              icon: const Icon(Icons.more_vert_rounded),
              color: cream,
              onSelected: (v) {
                if (v == 'pdf') showPoemPdfSheet(context, poem, diwan);
                if (v == 'copy') _copy(context);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'pdf',
                  child: Row(children: [
                    Icon(Icons.picture_as_pdf_rounded, color: brown),
                    SizedBox(width: 10),
                    Text('تحويل القصيدة إلى PDF'),
                  ]),
                ),
                PopupMenuItem(
                  value: 'copy',
                  child: Row(children: [
                    Icon(Icons.copy_rounded, color: brown),
                    SizedBox(width: 10),
                    Text('نسخ القصيدة'),
                  ]),
                ),
              ],
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 30),
          children: [
            PoemHeader(title: poem.title, diwan: diwan),
            const SizedBox(height: 16),
            PoemFrame(child: PoemBody(poem: poem)),
            const SizedBox(height: 18),
            Center(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: brown,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                ),
                onPressed: () => _copy(context),
                icon: const Icon(Icons.copy_rounded, size: 24),
                label: const Text('نسخ القصيدة',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
}

// ───────────── الإعدادات ─────────────
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const SectionHeading('الإعدادات'),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: brown,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const FontSettingsPage())),
                icon: const Icon(Icons.text_fields_rounded, size: 28),
                label: const Text('إعدادات الخط',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 14),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.info_outline, color: brown),
              title: Text('عن التطبيق'),
              subtitle: Text('دواوين النور — دواوين شعرية'),
            ),
          ],
        ),
      );
}

class SectionHeading extends StatelessWidget {
  final String text;
  const SectionHeading(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text,
            style: const TextStyle(
                fontSize: 21, fontWeight: FontWeight.bold, color: brown)),
      );
}

// ════════════════════════════════════════════════
// 2) عرض القصيدة (التصميم الإسلامي)
// ════════════════════════════════════════════════

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
            color: poemFontColor.value,
            fontWeight: FontWeight.w500,
          ));

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
              '${widget.poem.title}|${c.maxWidth.toStringAsFixed(1)}|$base|${poemFontColor.value}|${removeTashkeel.value}';
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
  canvas.drawPath(_star8(c, r), Paint()..color = brown);
  canvas.drawPath(
      _star8(c, r),
      Paint()
        ..color = accentGold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4);
  canvas.drawCircle(c, r * .28, Paint()..color = accentGold);
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
                colors: [accentGold, accentGold.withOpacity(0)],
              ),
            ),
          ),
        );
    return Row(
      children: [
        line(false),
        const SizedBox(width: 8),
        CustomPaint(
            size: const Size(16, 16), painter: _StarPainter(accentGold)),
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
      ..color = accentGold.withOpacity(.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final fill = Paint()..color = accentGold.withOpacity(.10);
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
      ..color = accentGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    final inner = Paint()
      ..color = brown.withOpacity(.65)
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
              colors: [brown, brownDark]),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(110),
            topRight: Radius.circular(110),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: accentGold, width: 2),
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
                size: const Size(22, 22), painter: _StarPainter(accentGold)),
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

// ════════════════════════════════════════════════
// 3) صفحة إعدادات الخط
// ════════════════════════════════════════════════

const _sample = Poem('معاينة', [
  Verse('قلبي للهادي مشتاقٌ', 'وبنبضِ فؤادي أشواقٌ'),
  Verse('لحبيبي بَلِّغْ آهاتي', 'وحنينَ القلبِ ودمعاتي'),
]);

class FontSettingsPage extends StatelessWidget {
  const FontSettingsPage({super.key});

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: Text(t,
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.bold, color: brown)),
      );

  Widget _optionButton(
          {required IconData icon,
          required String title,
          required Widget trailing,
          required VoidCallback onTap}) =>
      Material(
        color: const Color(0xFFFFFBF2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: accentGold.withOpacity(.6)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: Row(
              children: [
                Icon(icon, color: brown, size: 28),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600))),
                trailing,
                const SizedBox(width: 6),
                const Icon(Icons.chevron_left),
              ],
            ),
          ),
        ),
      );

  Future<void> _pickColor(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFFFFBF2),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 18,
            runSpacing: 18,
            children: [
              for (final c in colorChoices)
                GestureDetector(
                  onTap: () {
                    poemFontColor.value = c.color;
                    Navigator.pop(ctx);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: c.color,
                        child: poemFontColor.value == c.color
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 6),
                      Text(c.label, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: const Text('إعدادات الخط', style: TextStyle(fontSize: 17))),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
          children: [
            const PoemFrame(child: PoemBody(poem: _sample)),

            // ── حجم الخط ──
            _title('حجم الخط'),
            ListenableBuilder(
              listenable: poemFontSize,
              builder: (_, __) {
                final v = poemFontSize.value;
                return Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                            backgroundColor: brown,
                            padding: const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: v > minPoemFont
                            ? () => poemFontSize.value =
                                (v - 1).clamp(minPoemFont, maxPoemFont).toDouble()
                            : null,
                        icon: const Icon(Icons.remove_rounded),
                        label: const Text('تصغير'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(arDigits(v.round()),
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: brown)),
                    ),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                            backgroundColor: brown,
                            padding: const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: v < maxPoemFont
                            ? () => poemFontSize.value =
                                (v + 1).clamp(minPoemFont, maxPoemFont).toDouble()
                            : null,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('تكبير'),
                      ),
                    ),
                  ],
                );
              },
            ),

            // ── لون الخط ──
            _title('لون الخط'),
            ListenableBuilder(
              listenable: poemFontColor,
              builder: (_, __) => _optionButton(
                icon: Icons.palette_rounded,
                title: 'اختيار لون الخط',
                trailing: CircleAvatar(
                    radius: 11, backgroundColor: poemFontColor.value),
                onTap: () => _pickColor(context),
              ),
            ),

            // ── التشكيل ──
            _title('التشكيل'),
            ListenableBuilder(
              listenable: removeTashkeel,
              builder: (_, __) {
                final off = removeTashkeel.value;
                ButtonStyle filled() => FilledButton.styleFrom(
                    backgroundColor: brown,
                    padding: const EdgeInsets.symmetric(vertical: 14));
                ButtonStyle outlined() => OutlinedButton.styleFrom(
                    foregroundColor: brown,
                    side: const BorderSide(color: brown),
                    padding: const EdgeInsets.symmetric(vertical: 14));
                return Row(
                  children: [
                    Expanded(
                      child: off
                          ? FilledButton(
                              style: filled(),
                              onPressed: () {},
                              child: const Text('إزالة التشكيل'))
                          : OutlinedButton(
                              style: outlined(),
                              onPressed: () => removeTashkeel.value = true,
                              child: const Text('إزالة التشكيل')),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: !off
                          ? FilledButton(
                              style: filled(),
                              onPressed: () {},
                              child: const Text('التشكيل كما هو'))
                          : OutlinedButton(
                              style: outlined(),
                              onPressed: () => removeTashkeel.value = false,
                              child: const Text('التشكيل كما هو')),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      );
}

// ════════════════════════════════════════════════
// 4) إعدادات الخط وحفظها
// ════════════════════════════════════════════════

// ───────────── إعدادات الخط (تُحفظ على الهاتف) ─────────────

/// حجم خط القصيدة
final ValueNotifier<double> poemFontSize = ValueNotifier<double>(22);

/// لون خط القصيدة
final ValueNotifier<Color> poemFontColor =
    ValueNotifier<Color>(const Color(0xFF3E2723));

/// true = بدون تشكيل، false = التشكيل كما هو
final ValueNotifier<bool> removeTashkeel = ValueNotifier<bool>(false);

/// يتغيّر عند تغيّر أي إعداد
final Listenable poemSettings = Listenable.merge([poemFontSize, poemFontColor, removeTashkeel]);

const double minPoemFont = 16;
const double maxPoemFont = 30;

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

    poemFontSize.addListener(() => p.setDouble('poemFontSize', poemFontSize.value));
    poemFontColor.addListener(() {
      final i = colorChoices.indexWhere((c) => c.color == poemFontColor.value);
      if (i >= 0) p.setInt('poemFontColorIndex', i);
    });
    removeTashkeel
        .addListener(() => p.setBool('removeTashkeel', removeTashkeel.value));
  } catch (_) {
    // لو فشل الحفظ يشتغل التطبيق بالإعدادات الافتراضية
  }
}

// ════════════════════════════════════════════════
// 5) أدوات النص العربي
// ════════════════════════════════════════════════

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

// ════════════════════════════════════════════════
// 6) التاريخ الهجري والأرقام العربية
// ════════════════════════════════════════════════

// تحويل ميلادي -> هجري بالحساب الجدولي (دون أي حزمة خارجية).
// قد يختلف يومًا واحدًا عن تقويم أم القرى / رؤية الهلال.

const gregorianMonths = [
  'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
  'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
];

const hijriMonths = [
  'محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأولى',
  'جمادى الآخرة', 'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة',
];

// DateTime.weekday: الاثنين = 1 ... الأحد = 7
const weekdays = [
  'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد',
];

class HijriDate {
  final int year, month, day;
  const HijriDate(this.year, this.month, this.day);
  String get monthName => hijriMonths[month - 1];
}

HijriDate toHijri(DateTime g) {
  final a = (14 - g.month) ~/ 12;
  final y = g.year + 4800 - a;
  final m = g.month + 12 * a - 3;
  final jdn = g.day + (153 * m + 2) ~/ 5 + 365 * y + y ~/ 4 - y ~/ 100 + y ~/ 400 - 32045;
  var l = jdn - 1948440 + 10632;
  final n = (l - 1) ~/ 10631;
  l = l - 10631 * n + 354;
  final j = ((10985 - l) ~/ 5316) * ((50 * l) ~/ 17719) +
      (l ~/ 5670) * ((43 * l) ~/ 15238);
  l = l -
      ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
      (j ~/ 16) * ((15238 * j) ~/ 43) +
      29;
  final mm = (24 * l) ~/ 709;
  final dd = l - (709 * mm) ~/ 24;
  final yy = 30 * n + j - 30;
  return HijriDate(yy, mm, dd);
}

/// أرقام عربية (٠١٢٣…)
String arDigits(Object value) {
  const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return value.toString().split('').map((c) {
    final i = int.tryParse(c);
    return i == null ? c : d[i];
  }).join();
}
