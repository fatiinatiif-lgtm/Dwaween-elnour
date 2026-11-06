import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'arabic_text.dart';
import 'constants.dart';
import 'font_settings.dart';
import 'font_settings_page.dart';
import 'hijri.dart';
import 'poem_view.dart';
import 'poems_data.dart';

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
              const Text('سيد الشعراء',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              const Text('عبدالرحمن مصطفى الأزهري',
                  style: TextStyle(
                      color: Color(0xFFE8D9BC),
                      fontSize: 20,
                      fontWeight: FontWeight.w500)),
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
