import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'arabic_text.dart';
import 'constants.dart';
import 'hijri.dart';
import 'poem_view.dart';
import 'poems_data.dart';

void main() => runApp(const DiwanApp());

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
        scaffoldBackgroundColor: paper,
        colorScheme: ColorScheme.fromSeed(seedColor: appGreen),
        appBarTheme: const AppBarTheme(
          backgroundColor: appGreen,
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
  int count = 1;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (count >= 5) {
        t.cancel();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      } else {
        setState(() => count++);
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
              colors: [Color(0xFF0B6846), appDarkGreen],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.menu_book_rounded, color: appGold, size: 76),
              const SizedBox(height: 18),
              const Text('سيد الشعراء',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 22),
              Text(arDigits(count),
                  style: const TextStyle(
                      color: appGold, fontSize: 44, fontWeight: FontWeight.w600)),
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
        bottomNavigationBar: NavigationBar(
          selectedIndex: selected,
          onDestinationSelected: (i) => setState(() => selected = i),
          indicatorColor: appGold.withOpacity(.22),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home, color: appGreen),
                label: 'الشاشة الرئيسية'),
            NavigationDestination(
                icon: Icon(Icons.library_books_outlined),
                selectedIcon: Icon(Icons.library_books, color: appGreen),
                label: 'الدواوين'),
            NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings, color: appGreen),
                label: 'الإعدادات'),
          ],
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
                  color: appGreen, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'اكتبي كلمة أو عبارة من أي قصيدة',
              prefixIcon: const Icon(Icons.search, color: appGreen),
              suffixIcon: searching
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(controller.clear))
                  : null,
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: appGold.withOpacity(.6)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: appGreen, width: 1.6),
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
              colors: [Color(0xFFE6C26B), appGold, Color(0xFF9A7428)]),
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
              color: paper, borderRadius: BorderRadius.circular(19)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appGold.withOpacity(.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(time,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: appGreen)),
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
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: appGold.withOpacity(.45)),
        ),
        child: ListTile(
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: appGreen,
            child: Text(arDigits(number),
                style: const TextStyle(color: appGold, fontWeight: FontWeight.bold)),
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
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: appGold.withOpacity(.45)),
                ),
                child: ListTile(
                  leading: const Icon(Icons.auto_stories, color: appGreen),
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
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(poem.title, style: const TextStyle(fontSize: 17))),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 30),
          children: [
            Text(diwan,
                textAlign: TextAlign.center,
                style: const TextStyle(color: appGreen, fontSize: 14)),
            const SizedBox(height: 14),
            PoemFrame(child: PoemBody(poem: poem)),
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
            const Text('حجم خط القصائد',
                style: TextStyle(fontWeight: FontWeight.w600)),
            ValueListenableBuilder<double>(
              valueListenable: poemFontSize,
              builder: (_, v, __) => Slider(
                min: 16,
                max: 30,
                divisions: 14,
                value: v,
                label: arDigits(v.round()),
                activeColor: appGreen,
                onChanged: (x) => poemFontSize.value = x,
              ),
            ),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.info_outline, color: appGreen),
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
                fontSize: 21, fontWeight: FontWeight.bold, color: appGreen)),
      );
}
