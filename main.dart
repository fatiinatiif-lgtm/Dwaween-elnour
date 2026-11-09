import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'poems_extra.dart';
import 'pdf_export.dart';
import 'saved_files.dart';
import 'salawat_page.dart';

// ملف التطبيق الكامل (ما عدا القصائد: poems_data.dart)
// الأقسام بالترتيب:
//  1) الثيمات (ألوان التطبيق) والتطبيق والشاشات
//  2) عرض القصيدة (التصميم الإسلامي)
//  3) صفحة إعدادات الخط
//  4) إعدادات الخط (الحجم/اللون/التشكيل) وحفظها
//  5) أدوات النص العربي (بحث + كشيدة)
//  6) التاريخ الهجري والأرقام العربية

// ════════════════════════════════════════════════
// الثيمات: ألوان التطبيق كلها تُقرأ من الثيم المختار
// ════════════════════════════════════════════════

/// خط كلمتي "خير المادحين" في شاشة البداية.
/// غيّريه لأي family من pubspec.yaml:
/// 'Amoshref' (ثلث المشرف) • 'WinsoftThuluth' • 'DecoThuluth'
/// (لا تستخدمي الخطوط الملوّنة مثل ArefRuqaa أو Topaz3D أو AAGalaxy هنا)
const String kSplashFont = 'Amoshref';

/// خط اسم الشاعر الصغير تحت الكلمتين في شاشة البداية (نفس الخطوط أعلاه)
const String kSplashAuthorFont = 'Amoshref';

class AppPalette {
  final String label;
  final Color primary; // الأزرار والشريط العلوي والأيقونات
  final Color primaryDark; // نهاية التدرّج
  final Color bg; // خلفية التطبيق
  final Color card; // خلفية البطاقات
  final Color accent; // الذهبي / لون الزخرفة
  final Color paper; // ورقة القصيدة (تبقى فاتحة حتى في الثيمات الداكنة)
  final Color ink; // لون العناوين والنصوص الأساسية
  final Color inkSoft; // لون النصوص الثانوية
  final bool dark;
  const AppPalette({
    required this.label,
    required this.primary,
    required this.primaryDark,
    required this.bg,
    required this.card,
    required this.accent,
    required this.paper,
    required this.ink,
    required this.inkSoft,
    this.dark = false,
  });
}

const appPalettes = <AppPalette>[
  AppPalette(
      label: 'بني وذهبي',
      primary: Color(0xFF6D4C41),
      primaryDark: Color(0xFF3E2723),
      bg: Color(0xFFF5ECDC),
      card: Color(0xFFFFFBF2),
      accent: Color(0xFFC9A24B),
      paper: Color(0xFFFFFBF2),
      ink: Color(0xFF3E2723),
      inkSoft: Color(0xFF7A6A62)),
  AppPalette(
      label: 'أخضر زمردي',
      primary: Color(0xFF2E6B4F),
      primaryDark: Color(0xFF143D2B),
      bg: Color(0xFFE8F1EA),
      card: Color(0xFFF8FCF9),
      accent: Color(0xFFC9A24B),
      paper: Color(0xFFF8FCF9),
      ink: Color(0xFF14301F),
      inkSoft: Color(0xFF5B7566)),
  AppPalette(
      label: 'أزرق ملكي',
      primary: Color(0xFF2C4A8A),
      primaryDark: Color(0xFF14264F),
      bg: Color(0xFFE8EDF6),
      card: Color(0xFFF8FAFD),
      accent: Color(0xFFD4AF37),
      paper: Color(0xFFF8FAFD),
      ink: Color(0xFF14213D),
      inkSoft: Color(0xFF5C6980)),
  AppPalette(
      label: 'عنابي',
      primary: Color(0xFF7B1F2E),
      primaryDark: Color(0xFF4A0F1B),
      bg: Color(0xFFF6E9EA),
      card: Color(0xFFFFF9F9),
      accent: Color(0xFFC9A24B),
      paper: Color(0xFFFFF9F9),
      ink: Color(0xFF3D0F18),
      inkSoft: Color(0xFF80595F)),
  AppPalette(
      label: 'بنفسجي',
      primary: Color(0xFF5B3A8E),
      primaryDark: Color(0xFF33204F),
      bg: Color(0xFFEFEAF6),
      card: Color(0xFFFBF9FE),
      accent: Color(0xFFD4AF37),
      paper: Color(0xFFFBF9FE),
      ink: Color(0xFF2A1B40),
      inkSoft: Color(0xFF6E6382)),
  AppPalette(
      label: 'تركوازي',
      primary: Color(0xFF00796B),
      primaryDark: Color(0xFF004D43),
      bg: Color(0xFFE2F1EF),
      card: Color(0xFFF7FCFB),
      accent: Color(0xFFD9B44A),
      paper: Color(0xFFF7FCFB),
      ink: Color(0xFF053B35),
      inkSoft: Color(0xFF50706C)),
  AppPalette(
      label: 'وردي ملكي',
      primary: Color(0xFF9C2F63),
      primaryDark: Color(0xFF5E1239),
      bg: Color(0xFFF8E9F0),
      card: Color(0xFFFFF8FB),
      accent: Color(0xFFE0B341),
      paper: Color(0xFFFFF8FB),
      ink: Color(0xFF4A1030),
      inkSoft: Color(0xFF80596D)),
  AppPalette(
      label: 'رمادي أنيق',
      primary: Color(0xFF455A64),
      primaryDark: Color(0xFF263238),
      bg: Color(0xFFECEFF1),
      card: Color(0xFFFAFBFC),
      accent: Color(0xFFC9A24B),
      paper: Color(0xFFFAFBFC),
      ink: Color(0xFF1F2A30),
      inkSoft: Color(0xFF62717A)),
  AppPalette(
      label: 'صحراوي',
      primary: Color(0xFFA1481A),
      primaryDark: Color(0xFF6B2D0E),
      bg: Color(0xFFF7EADD),
      card: Color(0xFFFFF9F2),
      accent: Color(0xFFD9A441),
      paper: Color(0xFFFFF9F2),
      ink: Color(0xFF4A2410),
      inkSoft: Color(0xFF82614F)),
  AppPalette(
      label: 'أزرق سماوي',
      primary: Color(0xFF0277BD),
      primaryDark: Color(0xFF01497A),
      bg: Color(0xFFE6F1F8),
      card: Color(0xFFF7FBFE),
      accent: Color(0xFFC9A24B),
      paper: Color(0xFFF7FBFE),
      ink: Color(0xFF0B2F4A),
      inkSoft: Color(0xFF5A7184)),
];

/// فهرس الثيم المختار (يُحفظ على الهاتف)
final ValueNotifier<int> appThemeIndex = ValueNotifier<int>(0);

/// الوضع الداكن (يطبَّق على التطبيق وورقة القصيدة، ولا يؤثر على ملف الـ PDF)
final ValueNotifier<bool> appDarkMode = ValueNotifier<bool>(false);

/// يشتق نسخة داكنة من الثيم المختار (نفس هويته اللونية)
AppPalette _darkOf(AppPalette p) => AppPalette(
      label: p.label,
      primary: Color.lerp(p.primary, Colors.white, .16)!,
      primaryDark: Color.lerp(p.primaryDark, Colors.black, .35)!,
      bg: Color.lerp(p.primaryDark, Colors.black, .76)!,
      card: Color.lerp(p.primaryDark, Colors.black, .56)!,
      accent: Color.lerp(p.accent, Colors.white, .1)!,
      paper: Color.lerp(p.primaryDark, Colors.black, .5)!,
      ink: const Color(0xFFF1EBDD),
      inkSoft: const Color(0xFFB8B2A4),
      dark: true,
    );

AppPalette get currentPalette => appDarkMode.value
    ? _darkOf(appPalettes[appThemeIndex.value])
    : appPalettes[appThemeIndex.value];

/// لون خط القصيدة: في الوضع الداكن يُفتَّح لون الخط المختار ليُقرأ على الورقة الداكنة
Color poemInk(Color c) =>
    appDarkMode.value ? Color.lerp(c, Colors.white, .82)! : c;

// أسماء الألوان القديمة بقيت كما هي، لكنها الآن تتبع الثيم المختار
Color get brown => currentPalette.primary;
Color get brownDark => currentPalette.primaryDark;
Color get beige => currentPalette.bg;
Color get cream => currentPalette.card;
Color get accentGold => currentPalette.accent;
Color get paperColor => currentPalette.paper;
Color get ink => currentPalette.ink;
Color get inkSoft => currentPalette.inkSoft;

/// آخر قصيدة تمّ فتحها (مفتاحها = اسم الديوان + عنوانها) وتُحفظ على الهاتف
final ValueNotifier<String?> lastRead = ValueNotifier<String?>(null);

void markLastRead(String diwan, Poem p) => lastRead.value = favKey(diwan, p);

Future<void> loadAppTheme() async {
  try {
    final p = await SharedPreferences.getInstance();
    final i = p.getInt('appThemeIndex');
    if (i != null && i >= 0 && i < appPalettes.length) {
      appThemeIndex.value = i;
    }
    appDarkMode.value = p.getBool('appDarkMode') ?? false;
    lastRead.value = p.getString('lastRead');
    lastRead.addListener(() {
      final v = lastRead.value;
      if (v != null) p.setString('lastRead', v);
    });
    appThemeIndex
        .addListener(() => p.setInt('appThemeIndex', appThemeIndex.value));
    appDarkMode
        .addListener(() => p.setBool('appDarkMode', appDarkMode.value));
  } catch (_) {
    // لو فشل الحفظ يشتغل التطبيق بالثيم الافتراضي
  }
}

ThemeData _buildTheme(AppPalette p) {
  final scheme = ColorScheme.fromSeed(
    seedColor: p.primary,
    brightness: p.dark ? Brightness.dark : Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: p.bg,
    colorScheme: scheme,
    appBarTheme: AppBarTheme(
      backgroundColor: p.primary,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    dividerTheme: DividerThemeData(color: p.accent.withOpacity(.35)),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.primaryDark,
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// يجبر كل الشاشات (حتى الثابتة const) على إعادة البناء بالألوان الجديدة
void _rebuildAll(Element el) {
  el.markNeedsBuild();
  el.visitChildren(_rebuildAll);
}

List<BoxShadow> _softShadow([double a = .12]) => [
      BoxShadow(
          color: Colors.black.withOpacity(a),
          blurRadius: 12,
          offset: const Offset(0, 4)),
    ];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadFontSettings();
  await loadFavorites();
  await notesStore.load();
  await loadAppTheme();
  runApp(const DiwanApp());
}

class DiwanApp extends StatefulWidget {
  const DiwanApp({super.key});
  @override
  State<DiwanApp> createState() => _DiwanAppState();
}

class _DiwanAppState extends State<DiwanApp> {
  @override
  void initState() {
    super.initState();
    appThemeIndex.addListener(_onTheme);
    appDarkMode.addListener(_onTheme);
  }

  @override
  void dispose() {
    appThemeIndex.removeListener(_onTheme);
    appDarkMode.removeListener(_onTheme);
    super.dispose();
  }

  void _onTheme() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) (context as Element).visitChildren(_rebuildAll);
    });
  }

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
      theme: _buildTheme(currentPalette),
      home: const SplashScreen(),
    );
  }
}

// ───────────── شاشة البداية: خير المادحين + عدّاد إلى 5 ─────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int count = 5;
  Timer? timer;

  TextStyle _baseStyle() => TextStyle(
      fontFamily: kSplashFont,
      fontSize: 88,
      height: 1.25,
      fontWeight: FontWeight.w700);

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

  // الكلمة: طبقة سفلية للظل + طبقة علوية بتدرّج ذهبي
  Widget _word(String t) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Stack(
            children: [
              Text(t,
                  style: _baseStyle().copyWith(
                    color: Colors.transparent,
                    shadows: const [
                      Shadow(
                          color: Color(0x99000000),
                          blurRadius: 10,
                          offset: Offset(0, 4)),
                    ],
                  )),
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (r) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFF1C1),
                    Color(0xFFE6C26B),
                    Color(0xFFB98A2E)
                  ],
                ).createShader(r),
                child: Text(t,
                    style: _baseStyle().copyWith(color: Colors.white)),
              ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [brown, brownDark],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                  child: RepaintBoundary(
                      child: CustomPaint(painter: _PatternPainter(k: 1.3)))),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      radius: 1.0,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(.38)
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    const Spacer(flex: 3),
                    CustomPaint(
                        size: const Size(30, 30),
                        painter: _StarPainter(accentGold)),
                    const SizedBox(height: 14),
                    _word('خير'),
                    _word('المادحين'),
                    const SizedBox(height: 4),
                    Text('عبدالرحمن مصطفى الأزهري',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: kSplashAuthorFont,
                            color: accentGold,
                            fontSize: 26,
                            height: 1.5,
                            shadows: const [
                              Shadow(
                                  color: Color(0x88000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 2)),
                            ])),
                    const SizedBox(height: 10),
                    const SizedBox(
                        width: 190, child: OrnamentDivider()),
                    const SizedBox(height: 12),
                    Text('دواوين النور',
                        style: TextStyle(
                            color: accentGold,
                            fontSize: 17,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w600)),
                    const Spacer(flex: 3),
                    Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(.18),
                        border: Border.all(
                            color: accentGold.withOpacity(.8), width: 1.5),
                      ),
                      child: Text(arDigits(count),
                          style: TextStyle(
                              color: accentGold,
                              fontSize: 30,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
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
  final pages = const [
    HomePage(),
    DiwansPage(),
    SalawatPage(),
    FavoritesPage(),
    SettingsPage()
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(index: selected, children: pages),
        bottomNavigationBar: _FancyBottomBar(
          selected: selected,
          onTap: (i) => setState(() => selected = i),
        ),
      );
}

// ───────────── الشريط السفلي: «لوح الذهب» ─────────────
// شريط عائم بإطار ذهبي مزدوج ونقش خفيف، والتبويب المختار داخل كبسولة ذهبية
// مضيئة تنزلق من تبويب لآخر.
class _FancyBottomBar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;
  const _FancyBottomBar({required this.selected, required this.onTap});

  static const _items = [
    (Icons.home_rounded, 'الرئيسية'),
    (Icons.auto_stories_rounded, 'الدواوين'),
    (Icons.mosque_rounded, 'الصلوات'),
    (Icons.favorite_rounded, 'المفضلة'),
    (Icons.settings_rounded, 'الإعدادات'),
  ];

  static const double _h = 70;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final gold = accentGold;
    return Container(
      color: beige,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
          child: SizedBox(
            height: _h,
            child: LayoutBuilder(builder: (ctx, c) {
              final w = c.maxWidth;
              final iw = w / _items.length;
              // مركز التبويب (يدعم RTL: أول تبويب على اليمين)
              double cxOf(double t) => rtl ? w - (t + .5) * iw : (t + .5) * iw;
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(end: selected.toDouble()),
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                builder: (_, t, __) {
                  final cx = cxOf(t);
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // جسم الشريط
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [brown, brownDark],
                            ),
                            border: Border.all(
                                color: gold.withOpacity(.95), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8)),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30.5),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                    child: RepaintBoundary(
                                        child: CustomPaint(
                                            painter: _PatternPainter(k: .9)))),
                                Positioned.fill(
                                    child: CustomPaint(
                                        painter: _BarFramePainter(gold))),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // الكبسولة الذهبية المضيئة
                      Positioned(
                        left: cx - (iw - 10) / 2,
                        top: 7,
                        bottom: 7,
                        width: iw - 10,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color.lerp(gold, Colors.white, .4)!,
                                gold,
                                Color.lerp(gold, Colors.black, .18)!,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                  color: gold.withOpacity(.5),
                                  blurRadius: 16,
                                  spreadRadius: 1),
                            ],
                          ),
                        ),
                      ),
                      // التبويبات
                      for (var i = 0; i < _items.length; i++)
                        Positioned(
                          left: rtl ? w - (i + 1) * iw : i * iw,
                          width: iw,
                          top: 0,
                          bottom: 0,
                          child: _item(i, (1 - (t - i).abs()).clamp(0.0, 1.0)),
                        ),
                    ],
                  );
                },
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _item(int i, double w) {
    final fg = Color.lerp(Colors.white.withOpacity(.8), brownDark, w)!;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(i),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_items[i].$1, size: 23 + w * 3, color: fg),
            const SizedBox(height: 2),
            Text(
              _items[i].$2,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                fontSize: 10.5 + w * .9,
                height: 1.2,
                fontWeight: w > .5 ? FontWeight.w800 : FontWeight.w500,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// خط ذهبي داخلي رفيع داخل الشريط + لمعة علوية
class _BarFramePainter extends CustomPainter {
  final Color gold;
  const _BarFramePainter(this.gold);
  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 4, size.width - 8, size.height - 8),
        const Radius.circular(28));
    canvas.drawRRect(
        r,
        Paint()
          ..color = gold.withOpacity(.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8);
    canvas.drawLine(
        Offset(34, 1.5),
        Offset(size.width - 34, 1.5),
        Paint()
          ..shader = LinearGradient(colors: [
            gold.withOpacity(0),
            Color.lerp(gold, Colors.white, .5)!.withOpacity(.9),
            gold.withOpacity(0),
          ]).createShader(Rect.fromLTWH(0, 0, size.width, 3))
          ..strokeWidth = 1.2);
  }

  @override
  bool shouldRepaint(covariant _BarFramePainter old) => old.gold != gold;
}

// ───────────── الشاشة الرئيسية ─────────────
class _SearchHit {
  final String diwan;
  final Poem poem;
  final String snippet;
  final int verseMatches; // عدد الأبيات التي ورد فيها النص
  const _SearchHit(this.diwan, this.poem, this.snippet, this.verseMatches);
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
        var matches = 0;
        for (final v in poem.verses) {
          if (normalizeArabic('${v.sadr} ${v.ajz}').contains(q)) {
            snippet ??= '${v.sadr} … ${v.ajz}';
            matches++;
          }
        }
        if (snippet == null && normalizeArabic(poem.title).contains(q)) {
          snippet = '';
        }
        if (snippet != null) out.add(_SearchHit(e.key, poem, snippet, matches));
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
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          const _DarkModeBar(),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(accentGold, Colors.white, .45)!,
                  accentGold,
                  Color.lerp(accentGold, Colors.black, .22)!,
                ],
              ),
              boxShadow: _softShadow(.16),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: cream,
                borderRadius: BorderRadius.circular(23.5),
              ),
              child: TextField(
                controller: controller,
                onChanged: (_) => setState(() {}),
                style: TextStyle(color: ink, fontSize: 15.5),
                decoration: InputDecoration(
                  hintText: 'ابحث داخل النصوص كلها: كلمة أو عبارة',
                  hintStyle: TextStyle(color: inkSoft, fontSize: 14),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(13),
                    child: CustomPaint(
                        size: const Size(20, 20),
                        painter: _StarPainter(accentGold)),
                  ),
                  suffixIcon: searching
                      ? IconButton(
                          icon: Icon(Icons.close_rounded, color: brown),
                          onPressed: () => setState(controller.clear))
                      : Icon(Icons.search_rounded, color: brown),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
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
          const SizedBox(height: 26),
          if (searching) ...[
            const SectionHeading('نتائج البحث'),
            _ResultsCount(results: results),
            if (results.isEmpty)
              const Padding(
                padding: EdgeInsets.all(18),
                child: Text('لا توجد نتائج مطابقة.'),
              )
            else
              ...results.map((h) => PoemTile(
                    poem: h.poem,
                    diwan: h.diwan,
                    snippet: h.snippet,
                    highlight: normalizeArabic(controller.text),
                  )),
          ] else ...[
            const _LastReadCard(),
            const _VerseOfDayCard(),
          ],
        ],
      ),
    );
  }
}

/// بطاقة "أكمل القراءة": آخر قصيدة فتحتها
class _LastReadCard extends StatelessWidget {
  const _LastReadCard();
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String?>(
        valueListenable: lastRead,
        builder: (_, key, __) {
          if (key == null) return const SizedBox.shrink();
          final parts = key.split('\u0001');
          if (parts.length != 2) return const SizedBox.shrink();
          final list = poems[parts[0]];
          if (list == null) return const SizedBox.shrink();
          final i = list.indexWhere((p) => p.title == parts[1]);
          if (i < 0) return const SizedBox.shrink();
          final poem = list[i];
          return ManuscriptRow(
            icon: Icons.bookmark_rounded,
            eyebrow: 'أكمل القراءة',
            title: poem.title,
            subtitle: parts[0],
            colors: diwanColorsByName(parts[0]),
            onTap: () {
              markLastRead(parts[0], poem);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => PoemPage(poem: poem, diwan: parts[0])));
            },
          );
        },
      );
}

/// بطاقة "بيت اليوم": بيت يتغيّر كل يوم + حفظه كصورة أو نسخه أو فتح قصيدته
class _VerseOfDayCard extends StatelessWidget {
  const _VerseOfDayCard();

  Widget _action(IconData icon, String label, VoidCallback onTap) => Material(
        color: accentGold.withOpacity(.16),
        shape: StadiumBorder(side: BorderSide(color: accentGold.withOpacity(.75))),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 17, color: accentGold),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        color: ink,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final all = <({String diwan, Poem poem, Verse verse})>[];
    for (final e in poems.entries) {
      for (final p in e.value) {
        for (final v in p.verses) {
          all.add((diwan: e.key, poem: p, verse: v));
        }
      }
    }
    if (all.isEmpty) return const SizedBox.shrink();
    final d = DateTime.now();
    final day = DateTime(d.year, d.month, d.day).difference(DateTime(2020)).inDays;
    final pick = all[(day * 7919) % all.length];
    // البيت التالي في نفس القصيدة (لو كان آخر بيت نأخذ السابق له ليكونا بيتين)
    final vs = pick.poem.verses;
    final at = vs.indexOf(pick.verse);
    final Verse? nextV = vs.length < 2
        ? null
        : (at >= 0 && at + 1 < vs.length ? vs[at + 1] : vs[vs.length - 2]);
    final Verse firstV = (nextV != null && at + 1 >= vs.length) ? nextV : pick.verse;
    final Verse? secondV = (nextV != null && at + 1 >= vs.length) ? pick.verse : nextV;
    final style = withPoemFont(TextStyle(
            color: ink, fontSize: 20, height: 1.7))
        .copyWith(fontWeight: poemFontWeight);
    final dc = diwanColorsByName(pick.diwan);
    return ManuscriptCard(
      colors: dc,
      seal: CardSeal(icon: Icons.auto_awesome_rounded, colors: dc),
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 26),
      onTap: () {
        markLastRead(pick.diwan, pick.poem);
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    PoemPage(poem: pick.poem, diwan: pick.diwan)));
      },
      child: Column(
        children: [
          Text('بيت اليوم',
              style: TextStyle(
                  color: currentPalette.dark ? accentGold : brown,
                  fontSize: 19,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 28),
            child: OrnamentDivider(),
          ),
          const SizedBox(height: 14),
          Text(displayText(pick.verse.sadr).trim(),
              textAlign: TextAlign.center, style: style),
          Text(displayText(pick.verse.ajz).trim(),
              textAlign: TextAlign.center, style: style),
          const SizedBox(height: 10),
          Text('— ${pick.poem.title}',
              textAlign: TextAlign.center,
              style: TextStyle(color: inkSoft, fontSize: 13)),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _action(Icons.image_rounded, 'حفظ كصورة', () {
                showVerseImageSheet(context, pick.diwan, pick.poem, firstV,
                    nextVerse: secondV);
              }),
              _action(Icons.copy_rounded, 'نسخ', () async {
                await copyVerseText(context, pick.poem, pick.verse);
              }),
              _action(Icons.menu_book_rounded, 'القصيدة', () {
                markLastRead(pick.diwan, pick.poem);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            PoemPage(poem: pick.poem, diwan: pick.diwan)));
              }),
            ],
          ),
        ],
      ),
    );
  }
}

/// شريط أعلى الشاشة الرئيسية: اسم التطبيق + زرار الوضع الداكن
class _DarkModeBar extends StatelessWidget {
  const _DarkModeBar();
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: appDarkMode,
        builder: (_, dark, __) => Row(
          children: [
            CustomPaint(
                size: const Size(18, 18), painter: _StarPainter(accentGold)),
            const SizedBox(width: 8),
            Expanded(
              child: Text('دواوين النور',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: currentPalette.dark ? ink : brown)),
            ),
            // زرار "الملفات": يفتح صفحة الـ PDF والصور المحفوظة
            Material(
              color: accentGold.withOpacity(.16),
              shape: StadiumBorder(
                  side: BorderSide(color: accentGold, width: 1.3)),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SavedFilesPage())),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.folder_copy_rounded,
                          color: accentGold, size: 22),
                      const SizedBox(width: 6),
                      Text('الملفات',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: ink)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // زرار الوضع الداكن (أيقونة فقط عشان المكان يكفي)
            Tooltip(
              message: dark ? 'الوضع الفاتح' : 'الوضع الداكن',
              child: Material(
                color: accentGold.withOpacity(.16),
                shape: CircleBorder(
                    side: BorderSide(color: accentGold, width: 1.3)),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => appDarkMode.value = !dark,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (c, a) =>
                          RotationTransition(turns: a, child: c),
                      child: Icon(
                        dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        key: ValueKey(dark),
                        color: accentGold,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

/// يقسم اسم الديوان/القسم إلى سطرين على السجع:
/// «مسك الكلام» ↵ «في مدح خير الأنام». (الاسم القصير بلا حرف جر يبقى سطرًا واحدًا)
(String, String?) titleParts(String name) {
  final t = name.trim().replaceAll(RegExp(r'\s+'), ' ');
  var best = -1; // أول موضع لحرف الربط في الاسم
  for (final m in const [' في ', ' على ', ' لسيد ', ' لخير ', ' بمدح ']) {
    final i = t.indexOf(m);
    if (i > 0 && (best < 0 || i < best)) best = i;
  }
  if (best < 0) return (t, null);
  return (t.substring(0, best), t.substring(best + 1));
}

/// اسم الديوان/القسم كعنوان: سطران (الأول والثاني على السجع)
String titleTwoLines(String name) {
  if (name.contains('\n')) return name; // عنوان مقسوم يدويًا
  final p = titleParts(name);
  return p.$2 == null ? p.$1 : '${p.$1}\n${p.$2}';
}

/// «روضة العشاق» محتواه فصول لا قصائد
bool isChapterDiwan(String name) =>
    normalizeArabic(name).contains('روضه العشاق');

String chaptersCount(int n) {
  if (n == 0) return 'لا توجد فصول';
  if (n == 1) return 'فصل واحد';
  if (n == 2) return 'فصلان';
  if (n <= 10) return '${arDigits(n)} فصول';
  return '${arDigits(n)} فصل';
}

/// عدد المحتوى تحت اسم الديوان: «٥٣ فصل» لروضة العشاق، و«٢٠ قصيدة» لغيره
String diwanCountLabel(String name, int n) =>
    isChapterDiwan(name) ? chaptersCount(n) : '${arDigits(n)} قصيدة';

String _poemsCount(int n) {
  if (n == 0) return 'لا توجد قصائد';
  if (n == 1) return 'قصيدة واحدة';
  if (n == 2) return 'قصيدتان';
  if (n <= 10) return '${arDigits(n)} قصائد';
  return '${arDigits(n)} قصيدة';
}

String _versesIn(int n) {
  if (n == 1) return 'بيت واحد';
  if (n == 2) return 'بيتين';
  if (n <= 10) return '${arDigits(n)} أبيات';
  return '${arDigits(n)} بيتًا';
}

/// عدد نتائج البحث: عدد القصائد وعدد الأبيات التي ورد فيها النص
class _ResultsCount extends StatelessWidget {
  final List<_SearchHit> results;
  const _ResultsCount({required this.results});
  @override
  Widget build(BuildContext context) {
    final verses = results.fold<int>(0, (s, h) => s + h.verseMatches);
    final text = results.isEmpty
        ? 'لم يُعثر على نتائج'
        : 'عدد النتائج: ${_poemsCount(results.length)}'
            '${verses > 0 ? ' • ورد النص في ${_versesIn(verses)}' : ''}';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: accentGold.withOpacity(.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentGold.withOpacity(.55)),
      ),
      child: Row(
        children: [
          Icon(Icons.manage_search_rounded, color: accentGold, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ink)),
          ),
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
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(colors: [
            Color.lerp(accentGold, Colors.white, .35)!,
            accentGold,
            Color.lerp(accentGold, Colors.black, .35)!,
          ]),
          boxShadow: _softShadow(.22),
        ),
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
              color: beige, borderRadius: BorderRadius.circular(21)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            // alignment.y: كلما زاد (حتى 1) طلعت القبة لفوق أكتر، وكلما قلّ نزلت (-1 = أعلى الصورة)
            child: Image.asset('assets/images/green_dome.jpg',
                width: 120,
                height: 150,
                fit: BoxFit.cover,
                alignment: const Alignment(0, .6)),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [cream, Color.lerp(cream, accentGold, .16)!],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accentGold.withOpacity(.6)),
        boxShadow: _softShadow(.10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomPaint(
                  size: const Size(16, 16), painter: _StarPainter(accentGold)),
              const SizedBox(width: 8),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(time,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: brown)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: AlignmentDirectional.centerStart,
                end: AlignmentDirectional.centerEnd,
                colors: [accentGold, accentGold.withOpacity(0)],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(greg, style: TextStyle(fontSize: 12.5, color: ink)),
          const SizedBox(height: 3),
          Text(hijri, style: TextStyle(fontSize: 12.5, color: inkSoft)),
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

/// ألوان الدواوين: لكل ديوان لون مختلف (فاتح، غامق) حسب ترتيبه،
/// وتتكرر الألوان بالترتيب لو زاد عدد الدواوين عن عدد الألوان.
const _diwanPalette = <(Color, Color)>[
  (Color(0xFF5D4037), Color(0xFF3E2723)), // بني
  (Color(0xFF1B5E20), Color(0xFF0D3B13)), // أخضر
  (Color(0xFF0D47A1), Color(0xFF082F6B)), // أزرق
  (Color(0xFF7B1F2E), Color(0xFF4E111C)), // عنابي
  (Color(0xFF4A148C), Color(0xFF2F0C5A)), // بنفسجي
  (Color(0xFF00695C), Color(0xFF00443B)), // تركوازي
  (Color(0xFFBF360C), Color(0xFF80230A)), // برتقالي محروق
  (Color(0xFF880E4F), Color(0xFF570A32)), // وردي ملكي
  (Color(0xFF33691E), Color(0xFF1F4212)), // أخضر زيتي
  (Color(0xFF1A237E), Color(0xFF0F1550)), // نيلي
  (Color(0xFF37474F), Color(0xFF222D32)), // فحمي
  (Color(0xFF01579B), Color(0xFF013A66)), // أزرق سماوي
];

(Color, Color) diwanColors(int number) =>
    _diwanPalette[(number - 1) % _diwanPalette.length];

/// لون الديوان من اسمه (لو الاسم غير معروف نرجع للون الثيم الافتراضي)
(Color, Color) diwanColorsByName(String name) {
  final i = diwanNames.indexOf(name);
  return i < 0 ? (brown, brownDark) : diwanColors(i + 1);
}

/// بطاقة الديوان (تصميم "غلاف الكتاب"):
/// كعب ملوّن على اليمين عليه محراب مذهّب يحمل الرقم،
/// وجسم فاتح فيه العنوان كاملًا + فاصل زخرفي + عدد القصائد وسهم الدخول.
class DiwanTile extends StatelessWidget {
  final String name;
  final int number;
  const DiwanTile({super.key, required this.name, required this.number});

  @override
  Widget build(BuildContext context) {
    final count = (poems[name] ?? []).length;
    final dc = diwanColors(number);
    return ManuscriptCard(
      colors: dc,
      seal: CardSeal(number: number, colors: dc),
      padding: const EdgeInsets.fromLTRB(18, 34, 18, 24),
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => DiwanDetailPage(name: name))),
      child: Column(
        children: [
          CardTitle(name),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 34),
            child: OrnamentDivider(),
          ),
          const SizedBox(height: 14),
          CardPill(
              icon: Icons.auto_stories_rounded,
              text: diwanCountLabel(name, count)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════
// تصميم «المخطوطة المزخرفة»: بطاقة ورقية بإطار ذهبي مزدوج وقلوب في الزوايا،
// وختم (رقم أو أيقونة) يجلس على حافتها العلوية، وشريط بلون الديوان في أسفلها.
// تُستخدم في بطاقات الدواوين والصلوات والقصائد.
// ════════════════════════════════════════════════

class ManuscriptCard extends StatelessWidget {
  final VoidCallback onTap;
  final (Color, Color) colors;
  final Widget child;
  final Widget? seal; // ختم يجلس على الحافة العلوية في المنتصف
  final double radius;
  final double gap; // المسافة تحت البطاقة
  final EdgeInsetsGeometry padding;
  const ManuscriptCard({
    super.key,
    required this.onTap,
    required this.colors,
    required this.child,
    this.seal,
    this.radius = 24,
    this.gap = 20,
    this.padding = const EdgeInsets.fromLTRB(18, 16, 18, 20),
  });

  @override
  Widget build(BuildContext context) {
    final dark = currentPalette.dark;
    final top = Color.lerp(cream, Colors.white, dark ? .05 : .55)!;
    final bottom = Color.lerp(cream, accentGold, dark ? .12 : .18)!;
    final lift = seal == null ? 0.0 : 28.0;
    return Padding(
      padding: EdgeInsets.only(bottom: gap),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            margin: EdgeInsets.only(top: lift),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [top, bottom],
              ),
              border: Border.all(color: accentGold, width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(.16),
                    blurRadius: 18,
                    offset: const Offset(0, 7)),
                BoxShadow(
                    color: accentGold.withOpacity(.18),
                    blurRadius: 3,
                    spreadRadius: 1),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius - 1.5),
              child: Stack(
                children: [
                  Positioned.fill(
                      child: IgnorePointer(
                          child: CustomPaint(
                              painter: _CardFramePainter(accentGold, radius)))),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 6,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient:
                              LinearGradient(colors: [colors.$1, colors.$2]),
                        ),
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onTap,
                      child: Padding(
                        padding: padding,
                        child: SizedBox(width: double.infinity, child: child),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (seal != null) seal!,
        ],
      ),
    );
  }
}

/// إطار داخلي رفيع + قلوب ذهبية في الزوايا + قلب كبير شفّاف في الخلفية
class _CardFramePainter extends CustomPainter {
  final Color gold;
  final double radius;
  const _CardFramePainter(this.gold, this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 6.0;
    final rad = math.max(4.0, radius - 7);
    final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(inset, inset, size.width - 2 * inset,
            size.height - 2 * inset),
        Radius.circular(rad));
    canvas.drawRRect(
        r,
        Paint()
          ..color = gold.withOpacity(.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .9);
    // قلب كبير خافت في الخلفية
    canvas.drawPath(
        _star8(Offset(size.width - 42, size.height - 34), 44),
        Paint()..color = gold.withOpacity(.07));
    // قلوب صغيرة على الزوايا
    final k = rad * (1 - .7071);
    final pts = [
      Offset(inset + k, inset + k),
      Offset(size.width - inset - k, inset + k),
      Offset(inset + k, size.height - inset - k),
      Offset(size.width - inset - k, size.height - inset - k),
    ];
    for (final p in pts) {
      canvas.drawPath(_star8(p, 4.6), Paint()..color = gold);
    }
  }

  @override
  bool shouldRepaint(covariant _CardFramePainter old) =>
      old.gold != gold || old.radius != radius;
}

/// الختم: قلب ذهبي مضيء فيه رقم أو أيقونة
class CardSeal extends StatelessWidget {
  final int? number;
  final IconData? icon;
  final (Color, Color) colors;
  const CardSeal({super.key, this.number, this.icon, required this.colors});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: accentGold.withOpacity(.55), blurRadius: 16),
                ],
              ),
            ),
            _NumberStar(
                number: number,
                icon: icon,
                size: 56,
                ring: accentGold,
                core: colors.$1,
                textColor: Colors.white),
          ],
        ),
      );
}

/// عنوان البطاقة: الاسم على سطرين مسجوعين (الأول كبير والثاني أصغر)
class CardTitle extends StatelessWidget {
  final String name;
  const CardTitle(this.name, {super.key});
  @override
  Widget build(BuildContext context) {
    final p = titleParts(name);
    final soft = currentPalette.dark ? inkSoft : brown;
    return Text.rich(
      TextSpan(children: [
        TextSpan(
            text: p.$1,
            style: TextStyle(
                color: ink,
                fontSize: 21,
                height: 1.55,
                fontWeight: FontWeight.w800)),
        if (p.$2 != null)
          TextSpan(
              text: '\n${p.$2}',
              style: TextStyle(
                  color: soft,
                  fontSize: 16.5,
                  height: 1.6,
                  fontWeight: FontWeight.w600)),
      ]),
      textAlign: TextAlign.center,
    );
  }
}

/// حبّة صغيرة ذهبية (عدد القصائد أو وصف القسم)
class CardPill extends StatelessWidget {
  final IconData icon;
  final String text;
  const CardPill({super.key, required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: accentGold.withOpacity(.16),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentGold.withOpacity(.7)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: accentGold),
            const SizedBox(width: 7),
            Text(text,
                style: TextStyle(
                    color: ink, fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

/// صف بطاقة بتصميم المخطوطة (للإعدادات و«أكمل القراءة»)
class ManuscriptRow extends StatelessWidget {
  final IconData? icon;
  final Widget? leading;
  final String? eyebrow; // سطر صغير فوق العنوان
  final String title;
  final String? subtitle;
  final (Color, Color)? colors;
  final VoidCallback onTap;
  const ManuscriptRow({
    super.key,
    this.icon,
    this.leading,
    this.eyebrow,
    required this.title,
    this.subtitle,
    this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dc = colors ?? (brown, brownDark);
    return ManuscriptCard(
      colors: dc,
      radius: 20,
      gap: 14,
      padding: const EdgeInsetsDirectional.fromSTEB(14, 14, 8, 20),
      onTap: onTap,
      child: Row(
        children: [
          leading ??
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [dc.$1, dc.$2],
                  ),
                  border: Border.all(color: accentGold, width: 1.6),
                  boxShadow: [
                    BoxShadow(
                        color: accentGold.withOpacity(.35), blurRadius: 8),
                  ],
                ),
                child: Icon(icon, color: accentGold, size: 25),
              ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null)
                  Text(eyebrow!,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: currentPalette.dark ? accentGold : brown)),
                Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 16.5,
                        height: 1.4,
                        fontWeight: FontWeight.w800,
                        color: ink)),
                if (subtitle != null)
                  Text(subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: inkSoft)),
              ],
            ),
          ),
          Icon(Icons.chevron_left_rounded, color: accentGold, size: 28),
        ],
      ),
    );
  }
}

/// محراب مذهّب يحمل رقم الديوان
class _ArchBadge extends StatelessWidget {
  final int number;
  final Color core;
  const _ArchBadge({required this.number, required this.core});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 56,
        height: 70,
        child: Stack(
          alignment: const Alignment(0, .28),
          children: [
            CustomPaint(
                size: const Size(56, 70),
                painter: _ArchBadgePainter(accentGold, core)),
            SizedBox(
              width: 34,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(arDigits(number),
                    style: TextStyle(
                        color: accentGold,
                        fontSize: 26,
                        height: 1.1,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
}

class _ArchBadgePainter extends CustomPainter {
  final Color gold;
  final Color core;
  const _ArchBadgePainter(this.gold, this.core);

  Path _arch(Rect r) {
    final rad = r.width / 2;
    return Path()
      ..moveTo(r.left, r.bottom)
      ..lineTo(r.left, r.top + rad)
      ..arcTo(Rect.fromLTWH(r.left, r.top, r.width, r.width), math.pi, math.pi,
          false)
      ..lineTo(r.right, r.bottom)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Offset.zero & size;
    final outerPath = _arch(outer);
    canvas.drawPath(
        outerPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(gold, Colors.white, .5)!,
              gold,
              Color.lerp(gold, Colors.black, .3)!,
            ],
          ).createShader(outer));
    final inner = _arch(outer.deflate(4.5));
    canvas.drawPath(inner, Paint()..color = core);
    canvas.drawPath(
        inner,
        Paint()
          ..color = Color.lerp(gold, Colors.white, .3)!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
    canvas.drawPath(
        _arch(outer.deflate(8)),
        Paint()
          ..color = gold.withOpacity(.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .7);
  }

  @override
  bool shouldRepaint(covariant _ArchBadgePainter old) =>
      old.gold != gold || old.core != core;
}

/// شارة الترقيم: قلب ذهبي متدرّج
/// بداخلها دائرة داكنة بحلقة رفيعة، ويتوسطها الرقم (أو أيقونة)
class _NumberStar extends StatelessWidget {
  final int? number;
  final IconData? icon;
  final double size;
  final Color ring; // لون القلب الخارجي
  final Color core; // لون الدائرة الداخلية
  final Color textColor;
  const _NumberStar({
    this.number,
    this.icon,
    required this.size,
    required this.ring,
    required this.core,
    required this.textColor,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
                size: Size(size, size), painter: _BadgePainter(ring, core)),
            if (icon != null)
              Icon(icon, color: textColor, size: size * .36)
            else
              SizedBox(
                width: size * .5,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(arDigits(number ?? 0),
                      style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                          fontSize: size * .34)),
                ),
              ),
          ],
        ),
      );
}

class _BadgePainter extends CustomPainter {
  final Color ring;
  final Color core;
  const _BadgePainter(this.ring, this.core);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final star = _heart(c, r);
    final rect = Rect.fromCircle(center: c, radius: r);
    // قلب ذهبي متدرّج
    canvas.drawPath(
        star,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(ring, Colors.white, .45)!,
              ring,
              Color.lerp(ring, Colors.black, .3)!,
            ],
          ).createShader(rect));
    canvas.drawPath(
        star,
        Paint()
          ..color = Color.lerp(ring, Colors.black, .45)!.withOpacity(.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8);
    // القلب الداخلي
    final inner = _heart(c, r * .72);
    canvas.drawPath(inner, Paint()..color = core);
    canvas.drawPath(
        inner,
        Paint()
          ..color = Color.lerp(ring, Colors.white, .35)!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4);
    canvas.drawPath(
        _heart(c, r * .62),
        Paint()
          ..color = ring.withOpacity(.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .7);
  }

  @override
  bool shouldRepaint(covariant _BadgePainter old) =>
      old.ring != ring || old.core != core;
}

class DiwanDetailPage extends StatefulWidget {
  final String name;
  const DiwanDetailPage({super.key, required this.name});
  @override
  State<DiwanDetailPage> createState() => _DiwanDetailPageState();
}

class _DiwanDetailPageState extends State<DiwanDetailPage> {
  final ctrl = TextEditingController();

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = poems[widget.name] ?? <Poem>[];
    final q = normalizeArabic(ctrl.text);
    final shown = <MapEntry<int, Poem>>[
      for (var i = 0; i < list.length; i++)
        if (q.isEmpty || normalizeArabic(list[i].title).contains(q))
          MapEntry(i, list[i]),
    ];
    final dc = diwanColorsByName(widget.name);
    return Scaffold(
      appBar: AppBar(
          backgroundColor: dc.$1,
          title: Text(titleTwoLines(widget.name),
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(fontSize: 14, height: 1.3)),
          actions: [
            IconButton(
              tooltip: 'تحويل الديوان كله إلى PDF',
              icon: const Icon(Icons.picture_as_pdf_rounded),
              onPressed: list.isEmpty
                  ? null
                  : () => showDiwanPdfSheet(context, widget.name, list),
            ),
          ]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          PoemHeader(
              title: titleTwoLines(widget.name),
              diwan: diwanCountLabel(widget.name, list.length),
              colors: dc),
          const SizedBox(height: 18),
          if (list.length > 5) ...[
            TextField(
              controller: ctrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: isChapterDiwan(widget.name)
                    ? 'ابحث في عناوين فصول هذا الديوان'
                    : 'ابحث في عناوين قصائد هذا الديوان',
                hintStyle: TextStyle(color: inkSoft, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: brown),
                suffixIcon: q.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => setState(ctrl.clear))
                    : null,
                filled: true,
                fillColor: cream,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: accentGold.withOpacity(.6)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: brown, width: 1.6),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                  child: Text(isChapterDiwan(widget.name)
                      ? 'ستظهر الفصول هنا عند إضافتها.'
                      : 'ستظهر القصائد هنا عند إضافتها.')),
            )
          else if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                  child: Text(isChapterDiwan(widget.name)
                      ? 'لا توجد فصول مطابقة.'
                      : 'لا توجد قصائد مطابقة.')),
            )
          else
            for (final e in shown)
              PoemTile(poem: e.value, diwan: widget.name, number: e.key + 1),
        ],
      ),
    );
  }
}

/// بطاقة القصيدة (في الديوان / البحث / المفضلة) مع علامة المفضلة
class PoemTile extends StatelessWidget {
  final Poem poem;
  final String diwan;
  final int? number;
  final String snippet;
  final String highlight; // نص البحث (مُطبَّع) لتمييزه
  const PoemTile({
    super.key,
    required this.poem,
    required this.diwan,
    this.number,
    this.snippet = '',
    this.highlight = '',
  });

  Widget _meta(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: brown.withOpacity(.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: accentGold),
            const SizedBox(width: 5),
            Flexible(
              child: Text(text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: inkSoft)),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final count = versesLabel(poem.verses.length);
    final dc = diwanColorsByName(diwan);
    return ManuscriptCard(
      colors: dc,
      radius: 18,
      gap: 12,
      padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 6, 18),
      onTap: () {
        markLastRead(diwan, poem);
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => PoemPage(
                    poem: poem, diwan: diwan, highlight: highlight)));
      },
      child: Row(
                      children: [
                        if (number != null)
                          _NumberStar(
                              number: number,
                              size: 50,
                              ring: accentGold,
                              core: dc.$1,
                              textColor: Colors.white)
                        else
                          _NumberStar(
                              icon: Icons.menu_book_rounded,
                              size: 50,
                              ring: accentGold,
                              core: dc.$1,
                              textColor: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text.rich(
                                  highlightSpan(poem.title,
                                      findMatchRanges(poem.title, highlight)),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 16,
                                      height: 1.4,
                                      fontWeight: FontWeight.w700,
                                      color: ink)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  if (number == null)
                                    _meta(Icons.collections_bookmark_rounded,
                                        diwan),
                                  _meta(Icons.format_list_numbered_rounded,
                                      count),
                                ],
                              ),
                              if (snippet.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: accentGold.withOpacity(.10),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text.rich(
                                      highlightSpan(snippet,
                                          findMatchRanges(snippet, highlight)),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 12.5,
                                          height: 1.45,
                                          color: inkSoft)),
                                ),
                              ],
                            ],
                          ),
                        ),
                        FavButton(diwan: diwan, poem: poem),
                        Icon(Icons.chevron_left_rounded,
                            color: accentGold, size: 26),
                      ],
                    ),
    );
  }
}

/// عدد الأبيات بصيغة عربية سليمة
String versesLabel(int n) {
  if (n == 1) return 'بيت واحد';
  if (n == 2) return 'بيتان';
  if (n >= 3 && n <= 10) return '${arDigits(n)} أبيات';
  return '${arDigits(n)} بيتًا';
}

// ───────────── المفضلة ─────────────

/// القصائد المفضلة (مفتاح القصيدة = اسم الديوان + عنوانها)
final ValueNotifier<Set<String>> favorites = ValueNotifier<Set<String>>({});

String favKey(String diwan, Poem p) => '$diwan\u0001${p.title}';

bool isFav(String diwan, Poem p) => favorites.value.contains(favKey(diwan, p));

void toggleFav(String diwan, Poem p) {
  final k = favKey(diwan, p);
  final s = Set<String>.from(favorites.value);
  if (!s.remove(k)) s.add(k);
  favorites.value = s; // نسخة جديدة ليتم الإشعار والحفظ
}

Future<void> loadFavorites() async {
  try {
    final p = await SharedPreferences.getInstance();
    favorites.value = (p.getStringList('favorites') ?? <String>[]).toSet();
    favorites.addListener(
        () => p.setStringList('favorites', favorites.value.toList()));
  } catch (_) {
    // لو فشل الحفظ تعمل المفضلة داخل الجلسة فقط
  }
}

/// زرار القلب: يضيف القصيدة للمفضلة أو يشيلها
class FavButton extends StatelessWidget {
  final String diwan;
  final Poem poem;
  final bool dark; // true = فوق شريط ملوّن (أبيض)
  final double size;
  const FavButton({
    super.key,
    required this.diwan,
    required this.poem,
    this.dark = false,
    this.size = 26,
  });

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Set<String>>(
        valueListenable: favorites,
        builder: (_, __, ___) {
          final on = isFav(diwan, poem);
          final active =
              dark ? const Color(0xFFFF8A80) : const Color(0xFFC62828);
          final idle = dark ? Colors.white : brown;
          return IconButton(
            tooltip: on ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
            iconSize: size,
            onPressed: () => toggleFav(diwan, poem),
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: Icon(
                on ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                key: ValueKey(on),
                color: on ? active : idle,
              ),
            ),
          );
        },
      );
}

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
        child: ValueListenableBuilder<Set<String>>(
          valueListenable: favorites,
          builder: (context, favs, _) {
            final items = <Widget>[];
            for (final k in favs.toList().reversed) {
              final parts = k.split('\u0001');
              if (parts.length != 2) continue;
              final list = poems[parts[0]];
              if (list == null) continue;
              final idx = list.indexWhere((p) => p.title == parts[1]);
              if (idx < 0) continue;
              items.add(PoemTile(
                  key: ValueKey(k), poem: list[idx], diwan: parts[0]));
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              children: [
                const SectionHeading('المفضلة'),
                const _NotesEntryCard(),
                if (items.isEmpty)
                  const _EmptyFavorites()
                else
                  ...items,
              ],
            );
          },
        ),
      );
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 38),
        decoration: BoxDecoration(
          color: cream,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accentGold.withOpacity(.5)),
          boxShadow: _softShadow(.08),
        ),
        child: Column(
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentGold.withOpacity(.14),
                border: Border.all(color: accentGold.withOpacity(.6)),
              ),
              child: Icon(Icons.favorite_border_rounded,
                  size: 44, color: accentGold),
            ),
            const SizedBox(height: 16),
            Text('لا توجد قصائد في المفضلة بعد',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold, color: brown)),
            const SizedBox(height: 8),
            Text('اضغط على علامة القلب بجانب أي قصيدة لتجدها هنا.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.5, color: inkSoft)),
          ],
        ),
      );
}

// ───────────── ملحوظاتي ─────────────

/// عنصر في ملحوظاتي: قسم (folder) أو نص (text) أو قصيدة (poem)
class NoteNode {
  String id;
  String kind; // 'folder' | 'text' | 'poem'
  String title;
  String body;
  String diwan;
  String poemTitle;
  int color; // 0 = بدون لون، وإلا قيمة اللون
  List<NoteNode> children;

  NoteNode({
    required this.id,
    required this.kind,
    this.title = '',
    this.body = '',
    this.diwan = '',
    this.poemTitle = '',
    this.color = 0,
    List<NoteNode>? children,
  }) : children = children ?? <NoteNode>[];

  Map<String, dynamic> toJson() => {
        'id': id,
        'k': kind,
        't': title,
        'b': body,
        'd': diwan,
        'p': poemTitle,
        if (color != 0) 'col': color,
        if (children.isNotEmpty) 'c': children.map((e) => e.toJson()).toList(),
      };

  factory NoteNode.fromJson(Map<String, dynamic> j) => NoteNode(
        id: (j['id'] as String?) ?? '',
        kind: (j['k'] as String?) ?? 'text',
        title: (j['t'] as String?) ?? '',
        body: (j['b'] as String?) ?? '',
        diwan: (j['d'] as String?) ?? '',
        poemTitle: (j['p'] as String?) ?? '',
        color: (j['col'] as int?) ?? 0,
        children: [
          for (final c in ((j['c'] as List?) ?? const []))
            NoteNode.fromJson(Map<String, dynamic>.from(c as Map)),
        ],
      );
}

/// مخزن الملحوظات (يُحفظ تلقائيًا في الجهاز)
class NotesStore extends ChangeNotifier {
  NoteNode root = NoteNode(id: 'root', kind: 'folder', title: 'ملحوظاتي');
  SharedPreferences? _prefs;

  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final raw = _prefs!.getString('notes_v1');
      if (raw != null && raw.isNotEmpty) {
        root = NoteNode.fromJson(
            Map<String, dynamic>.from(jsonDecode(raw) as Map));
        root.id = 'root';
        root.kind = 'folder';
        root.title = 'ملحوظاتي';
      }
    } catch (_) {
      // لو فشل التحميل تبدأ الملحوظات فارغة
    }
  }

  /// حفظ بدون إشعار (يُستخدم أثناء الكتابة)
  void saveOnly() {
    try {
      _prefs?.setString('notes_v1', jsonEncode(root.toJson()));
    } catch (_) {}
  }

  /// حفظ مع تحديث الشاشات
  void changed() {
    notifyListeners();
    saveOnly();
  }

  String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  int countAll(NoteNode n) {
    var c = n.children.length;
    for (final ch in n.children) {
      c += countAll(ch);
    }
    return c;
  }
}

final NotesStore notesStore = NotesStore();

Future<String?> _askName(BuildContext context, String title,
    {String initial = '', String hint = ''}) {
  final c = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: c,
        autofocus: true,
        decoration: InputDecoration(hintText: hint),
        onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        TextButton(
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: const Text('حفظ')),
      ],
    ),
  );
}

Future<bool> _confirmDelete(BuildContext context, String msg) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('حذف'),
      content: Text(msg),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء')),
        TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف',
                style: TextStyle(color: Color(0xFFC62828)))),
      ],
    ),
  );
  return r ?? false;
}

const List<Color> _noteColors = [
  Color(0xFFC62828),
  Color(0xFFEF6C00),
  Color(0xFFF9A825),
  Color(0xFF2E7D32),
  Color(0xFF00838F),
  Color(0xFF1565C0),
  Color(0xFF6A1B9A),
  Color(0xFFAD1457),
  Color(0xFF5D4037),
  Color(0xFF546E7A),
];

/// يعرض ألوانًا للاختيار. يرجع قيمة اللون، أو 0 لإزالة اللون، أو null عند الإغلاق
Future<int?> _pickNoteColor(BuildContext context, int current) {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: cream,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('اختاري اللون',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold, color: brown)),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 14,
              runSpacing: 14,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(ctx, 0),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cream,
                      border: Border.all(
                          color: current == 0 ? brown : inkSoft,
                          width: current == 0 ? 3 : 1.4),
                    ),
                    child: Icon(Icons.format_color_reset_rounded,
                        color: inkSoft, size: 24),
                  ),
                ),
                for (final c in _noteColors)
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx, c.value),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c,
                        border: Border.all(
                            color: current == c.value ? brown : Colors.white,
                            width: current == c.value ? 3 : 1.6),
                      ),
                      child: current == c.value
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 26)
                          : null,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

InputDecoration _noteDecoration(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: inkSoft, fontSize: 14),
      filled: true,
      fillColor: cream,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: accentGold.withOpacity(.6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: brown, width: 1.6),
      ),
    );

void _openNotePoem(BuildContext context, NoteNode n) {
  final list = poems[n.diwan];
  final i = list == null ? -1 : list.indexWhere((p) => p.title == n.poemTitle);
  if (list == null || i < 0) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر العثور على القصيدة')));
    return;
  }
  Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => PoemPage(poem: list[i], diwan: n.diwan)));
}

/// بطاقة «ملحوظاتي» في أعلى صفحة المفضلة
class _NotesEntryCard extends StatelessWidget {
  const _NotesEntryCard();
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: notesStore,
        builder: (context, _) {
          final count = notesStore.countAll(notesStore.root);
          return Container(
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: cream,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accentGold.withOpacity(.6)),
              boxShadow: _softShadow(.08),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => NotesPage(folder: notesStore.root))),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentGold.withOpacity(.16),
                          border: Border.all(color: accentGold.withOpacity(.6)),
                        ),
                        child: Icon(Icons.sticky_note_2_rounded,
                            color: brown, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ملحوظاتي',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: brown)),
                            const SizedBox(height: 3),
                            Text(
                                count == 0
                                    ? 'قصائد وكلام نثر وأقسام خاصة بك'
                                    : '${arDigits(count)} عنصر',
                                style:
                                    TextStyle(fontSize: 13, color: inkSoft)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_left_rounded, color: brown, size: 28),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
}

/// صفحة قسم (أو الصفحة الرئيسية لملحوظاتي)
class NotesPage extends StatelessWidget {
  final NoteNode folder;
  const NotesPage({super.key, required this.folder});

  bool get _isRoot => folder.id == 'root';

  Future<void> _newFolder(BuildContext context) async {
    final name = await _askName(context, 'قسم جديد', hint: 'اسم القسم');
    if (name == null || name.isEmpty) return;
    folder.children
        .add(NoteNode(id: notesStore.newId(), kind: 'folder', title: name));
    notesStore.changed();
  }

  Future<void> _newText(BuildContext context) async {
    final n = NoteNode(id: notesStore.newId(), kind: 'text');
    folder.children.add(n);
    notesStore.changed();
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => NoteEditorPage(node: n)));
    // ملحوظة فارغة تمامًا لا تُحفظ
    if (n.title.trim().isEmpty && n.body.trim().isEmpty) {
      folder.children.remove(n);
    }
    notesStore.changed();
  }

  void _addSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: cream,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.create_new_folder_rounded, color: brown),
              title: const Text('قسم جديد'),
              subtitle: const Text('لتنظيم ملحوظاتك في مجموعات'),
              onTap: () {
                Navigator.pop(ctx);
                _newFolder(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.edit_note_rounded, color: brown),
              title: const Text('ملحوظة أو كلام نثر'),
              subtitle: const Text('اكتبي أي نص تريدين'),
              onTap: () {
                Navigator.pop(ctx);
                _newText(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.menu_book_rounded, color: brown),
              title: const Text('إضافة قصائد'),
              subtitle: const Text('اختاري من الدواوين'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PoemPickerPage(folder: folder)));
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: notesStore,
        builder: (context, _) => Scaffold(
          appBar: AppBar(
            backgroundColor:
                folder.color != 0 ? Color(folder.color) : brown,
            title: Text(folder.title, style: const TextStyle(fontSize: 16)),
            actions: [
              if (!_isRoot)
                IconButton(
                  tooltip: 'إعادة تسمية القسم',
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () async {
                    final n = await _askName(context, 'اسم القسم',
                        initial: folder.title);
                    if (n != null && n.isNotEmpty) {
                      folder.title = n;
                      notesStore.changed();
                    }
                  },
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: brown,
            foregroundColor: Colors.white,
            onPressed: () => _addSheet(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('إضافة'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              if (folder.children.isEmpty)
                _EmptyNotes(isRoot: _isRoot)
              else
                for (final n in folder.children)
                  _NoteCard(key: ValueKey(n.id), parent: folder, node: n),
            ],
          ),
        ),
      );
}

class _EmptyNotes extends StatelessWidget {
  final bool isRoot;
  const _EmptyNotes({required this.isRoot});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 38),
        decoration: BoxDecoration(
          color: cream,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accentGold.withOpacity(.5)),
          boxShadow: _softShadow(.08),
        ),
        child: Column(
          children: [
            Icon(Icons.sticky_note_2_outlined, size: 54, color: accentGold),
            const SizedBox(height: 14),
            Text(isRoot ? 'ملحوظاتك فاضية' : 'هذا القسم فارغ',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold, color: brown)),
            const SizedBox(height: 8),
            Text(
                'اضغطي على «إضافة» لتضيفي قسمًا أو ملحوظة نثرية أو قصائد من الدواوين.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.5, color: inkSoft)),
          ],
        ),
      );
}

class _NoteCard extends StatelessWidget {
  final NoteNode parent;
  final NoteNode node;
  const _NoteCard({super.key, required this.parent, required this.node});

  IconData get _icon => node.kind == 'folder'
      ? Icons.folder_rounded
      : node.kind == 'poem'
          ? Icons.menu_book_rounded
          : Icons.edit_note_rounded;

  List<String> get _bodyLines => node.body.trim().isEmpty
      ? <String>[]
      : node.body.trim().split('\n').where((l) => l.trim().isNotEmpty).toList();

  String get _title {
    if (node.kind == 'poem') return node.poemTitle;
    if (node.title.trim().isNotEmpty) return node.title.trim();
    if (node.kind == 'folder') return 'قسم بلا اسم';
    return _bodyLines.isEmpty ? 'ملحوظة بدون عنوان' : _bodyLines.first;
  }

  String get _sub {
    if (node.kind == 'folder') {
      final c = node.children.length;
      return c == 0 ? 'قسم فارغ' : '${arDigits(c)} عنصر';
    }
    if (node.kind == 'poem') return node.diwan;
    final lines = node.title.trim().isEmpty ? _bodyLines.skip(1) : _bodyLines;
    return lines.join(' ');
  }

  Future<void> _open(BuildContext context) async {
    if (node.kind == 'folder') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => NotesPage(folder: node)));
    } else if (node.kind == 'text') {
      await Navigator.push(context,
          MaterialPageRoute(builder: (_) => NoteEditorPage(node: node)));
      notesStore.changed();
    } else {
      _openNotePoem(context, node);
    }
  }

  Future<void> _delete(BuildContext context) async {
    final msg = node.kind == 'folder' && node.children.isNotEmpty
        ? 'سيُحذف القسم بكل ما فيه (${arDigits(notesStore.countAll(node))} عنصر). متأكدة؟'
        : 'هل تريدين حذف هذا العنصر؟';
    final ok = await _confirmDelete(context, msg);
    if (!ok) return;
    parent.children.remove(node);
    notesStore.changed();
  }

  @override
  Widget build(BuildContext context) {
    final sub = _sub;
    final hasC = node.color != 0;
    final nc = Color(node.color);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: hasC ? Color.alphaBlend(nc.withOpacity(.14), cream) : cream,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: hasC ? nc.withOpacity(.85) : accentGold.withOpacity(.5),
            width: hasC ? 1.6 : 1),
        boxShadow: _softShadow(.06),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _open(context),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 4, 10),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasC ? nc : accentGold.withOpacity(.14),
                  ),
                  child: Icon(_icon,
                      color: hasC ? Colors.white : brown, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 16,
                              height: 1.4,
                              fontWeight: FontWeight.w700,
                              color: ink)),
                      if (sub.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(sub,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 13, height: 1.4, color: inkSoft)),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: brown),
                  onSelected: (v) async {
                    if (v == 'rename') {
                      final n = await _askName(context, 'اسم القسم',
                          initial: node.title);
                      if (n != null && n.isNotEmpty) {
                        node.title = n;
                        notesStore.changed();
                      }
                    } else if (v == 'color') {
                      final c = await _pickNoteColor(context, node.color);
                      if (c != null) {
                        node.color = c;
                        notesStore.changed();
                      }
                    } else if (v == 'delete') {
                      await _delete(context);
                    }
                  },
                  itemBuilder: (_) => [
                    if (node.kind == 'folder')
                      const PopupMenuItem(
                          value: 'rename',
                          child: Row(children: [
                            Icon(Icons.edit_rounded, size: 20),
                            SizedBox(width: 10),
                            Text('إعادة تسمية'),
                          ])),
                    const PopupMenuItem(
                        value: 'color',
                        child: Row(children: [
                          Icon(Icons.palette_rounded, size: 20),
                          SizedBox(width: 10),
                          Text('تغيير اللون'),
                        ])),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete_outline_rounded, size: 20),
                          SizedBox(width: 10),
                          Text('حذف'),
                        ])),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// كتابة ملحوظة نثرية (تُحفظ تلقائيًا أثناء الكتابة)
class NoteEditorPage extends StatefulWidget {
  final NoteNode node;
  const NoteEditorPage({super.key, required this.node});
  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late final TextEditingController _t =
      TextEditingController(text: widget.node.title);
  late final TextEditingController _b =
      TextEditingController(text: widget.node.body);
  Timer? _timer;

  void _changed() {
    widget.node.title = _t.text;
    widget.node.body = _b.text;
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 400), notesStore.saveOnly);
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.node.title = _t.text;
    widget.node.body = _b.text;
    notesStore.saveOnly();
    _t.dispose();
    _b.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    final text = '${_t.text.trim()}\n${_b.text.trim()}'.trim();
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('تم نسخ الملحوظة')));
  }

  Future<void> _pickColor() async {
    final c = await _pickNoteColor(context, widget.node.color);
    if (c == null || !mounted) return;
    setState(() => widget.node.color = c);
    notesStore.saveOnly();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor:
              widget.node.color != 0 ? Color(widget.node.color) : brown,
          title: const Text('ملحوظة', style: TextStyle(fontSize: 16)),
          actions: [
            IconButton(
                tooltip: 'اللون',
                icon: const Icon(Icons.palette_rounded),
                onPressed: _pickColor),
            IconButton(
                tooltip: 'نسخ',
                icon: const Icon(Icons.copy_rounded),
                onPressed: _copy),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _t,
                onChanged: (_) => _changed(),
                textInputAction: TextInputAction.next,
                style: TextStyle(
                    fontSize: 19, fontWeight: FontWeight.bold, color: ink),
                decoration: _noteDecoration('العنوان (اختياري)'),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextField(
                  controller: _b,
                  onChanged: (_) => _changed(),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline,
                  style: TextStyle(fontSize: 17, height: 1.8, color: ink),
                  decoration:
                      _noteDecoration('اكتبي هنا: كلام نثر، فوائد، أفكار...'),
                ),
              ),
            ],
          ),
        ),
      );
}

/// اختيار قصائد من الدواوين لإضافتها إلى قسم (اضغطي للإضافة، ومرة ثانية للإزالة)
class PoemPickerPage extends StatefulWidget {
  final NoteNode folder;
  const PoemPickerPage({super.key, required this.folder});
  @override
  State<PoemPickerPage> createState() => _PoemPickerPageState();
}

class _PoemPickerPageState extends State<PoemPickerPage> {
  final TextEditingController _ctrl = TextEditingController();
  late final List<(String, Poem)> _all = [
    for (final d in diwanNames)
      for (final p in (poems[d] ?? const <Poem>[])) (d, p),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  int _indexOf(String d, Poem p) => widget.folder.children.indexWhere(
      (n) => n.kind == 'poem' && n.diwan == d && n.poemTitle == p.title);

  void _toggle(String d, Poem p) {
    final i = _indexOf(d, p);
    if (i >= 0) {
      widget.folder.children.removeAt(i);
    } else {
      widget.folder.children.add(NoteNode(
          id: notesStore.newId(), kind: 'poem', diwan: d, poemTitle: p.title));
    }
    notesStore.changed();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final q = normalizeArabic(_ctrl.text);
    final shown = _all
        .where((e) =>
            q.isEmpty ||
            normalizeArabic(e.$2.title).contains(q) ||
            normalizeArabic(e.$1).contains(q))
        .toList();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: brown,
        title: const Text('إضافة قصائد', style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('تم',
                  style: TextStyle(color: Colors.white, fontSize: 16))),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: TextField(
              controller: _ctrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'ابحث باسم القصيدة أو الديوان',
                hintStyle: TextStyle(color: inkSoft, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: brown),
                filled: true,
                fillColor: cream,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: accentGold.withOpacity(.6)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: brown, width: 1.6),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('اضغطي على القصيدة لإضافتها، ومرة ثانية لإزالتها',
                style: TextStyle(fontSize: 12, color: inkSoft)),
          ),
          Expanded(
            child: shown.isEmpty
                ? const Center(child: Text('لا توجد قصائد مطابقة.'))
                : ListView.builder(
                    itemCount: shown.length,
                    itemBuilder: (_, i) {
                      final (d, p) = shown[i];
                      final on = _indexOf(d, p) >= 0;
                      return ListTile(
                        title: Text(p.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontWeight: FontWeight.w600, color: ink)),
                        subtitle: Text(d,
                            style: TextStyle(fontSize: 12, color: inkSoft)),
                        trailing: Icon(
                            on
                                ? Icons.check_circle_rounded
                                : Icons.add_circle_outline_rounded,
                            color: on ? const Color(0xFF2E7D32) : brown),
                        onTap: () => _toggle(d, p),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ───────────── صفحة القصيدة ─────────────
class PoemPage extends StatelessWidget {
  final Poem poem;
  final String diwan;
  final String highlight; // نص البحث (غير مُطبَّع) لتمييزه داخل القصيدة
  const PoemPage(
      {super.key,
      required this.poem,
      required this.diwan,
      this.highlight = ''});

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

  /// اختيار بيت من القصيدة لحفظه كصورة
  void _pickVerse(BuildContext context) {
    var count = 1; // عدد الأبيات: 1 أو 2 أو 3
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cream,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => SafeArea(
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * .75,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text('اختاري البيت',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: brown)),
                ),
                Wrap(
                  spacing: 10,
                  children: [
                    for (final opt in const [
                      (1, 'بيت واحد'),
                      (2, 'بيتان'),
                      (3, 'ثلاثة أبيات')
                    ])
                      ChoiceChip(
                        label: Text(opt.$2,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: count == opt.$1
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color:
                                    count == opt.$1 ? Colors.white : brownDark)),
                        selected: count == opt.$1,
                        showCheckmark: false,
                        selectedColor: brown,
                        backgroundColor: Colors.white,
                        onSelected: (_) => setS(() => count = opt.$1),
                      ),
                  ],
                ),
                if (count > 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text('يُحفظ البيت المختار مع الأبيات التي تليه',
                        style: TextStyle(fontSize: 12.5, color: inkSoft)),
                  ),
                const SizedBox(height: 6),
                Expanded(
                  child: ListView.separated(
                    itemCount: poem.verses.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final v = poem.verses[i];
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 15,
                          backgroundColor: brown,
                          child: Text(arDigits(i + 1),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12)),
                        ),
                        title: Text(displayText(v.sadr),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(displayText(v.ajz),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () {
                          Navigator.pop(ctx);
                          final vs = poem.verses;
                          // لو الأبيات الباقية أقل من المطلوب نبدأ من قبل البيت المختار
                          final n = math.min(count, vs.length);
                          final start = math.min(i, vs.length - n);
                          showVerseImageSheet(context, diwan, poem, vs[start],
                              nextVerse: n > 1 ? vs[start + 1] : null,
                              thirdVerse: n > 2 ? vs[start + 2] : null);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: diwanColorsByName(diwan).$1,
          title: const Text('دواوين النور', style: TextStyle(fontSize: 17)),
          actions: [
            FavButton(diwan: diwan, poem: poem, dark: true, size: 28),
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
                if (v == 'verse') _pickVerse(context);
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'pdf',
                  child: Row(children: [
                    Icon(Icons.picture_as_pdf_rounded, color: brown),
                    const SizedBox(width: 10),
                    const Text('تحويل القصيدة إلى PDF'),
                  ]),
                ),
                PopupMenuItem(
                  value: 'verse',
                  child: Row(children: [
                    Icon(Icons.image_rounded, color: brown),
                    const SizedBox(width: 10),
                    const Text('حفظ بيت كصورة'),
                  ]),
                ),
                PopupMenuItem(
                  value: 'copy',
                  child: Row(children: [
                    Icon(Icons.copy_rounded, color: brown),
                    const SizedBox(width: 10),
                    const Text('نسخ القصيدة'),
                  ]),
                ),
              ],
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 30),
          children: [
            PoemHeader(
                title: poem.title,
                diwan: diwan,
                colors: diwanColorsByName(diwan)),
            const SizedBox(height: 16),
            PoemFrame(
              child: Column(
                children: [
                  PoemBody(poem: poem, highlight: normalizeArabic(highlight)),
                  const _PoemFooter(),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: brown,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => _copy(context),
                    icon: const Icon(Icons.copy_rounded, size: 22),
                    label: const Text('نسخ القصيدة',
                        style:
                            TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: brown,
                      side: BorderSide(color: brown, width: 1.4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => showPoemPdfSheet(context, poem, diwan),
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 22),
                    label: const Text('حفظ PDF',
                        style:
                            TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

/// تذييل القصيدة داخل الإطار (نفس تذييل ملف الـ PDF)
class _PoemFooter extends StatelessWidget {
  const _PoemFooter();
  @override
  Widget build(BuildContext context) {
    // ألوان الورقة ثابتة الفاتحة لذلك نستخدم أحبارًا داكنة ثابتة النسبة
    final p = currentPalette;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        children: [
          const OrnamentDivider(),
          const SizedBox(height: 12),
          Text('كلمات شاعر رسول الله ﷺ',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: p.dark ? p.ink : p.primary,
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('عبدالرحمن مصطفى الأزهري',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Color.lerp(p.accent, Colors.black, .35),
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ───────────── الإعدادات ─────────────
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  /// نافذة اختيار الثيم
  void _pickTheme(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: cream,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border(top: BorderSide(color: accentGold, width: 2)),
        ),
        child: SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * .85),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.palette_rounded, color: accentGold),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('مظهر التطبيق',
                            style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: brown)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('تم',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: brown)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListenableBuilder(
                    listenable: appThemeIndex,
                    builder: (_, __) => LayoutBuilder(
                      builder: (_, c) {
                        const gap = 10.0;
                        final w = (c.maxWidth - gap * 2) / 3;
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            for (var i = 0; i < appPalettes.length; i++)
                              SizedBox(
                                width: w,
                                child: _ThemeCard(
                                  p: appPalettes[i],
                                  selected: appThemeIndex.value == i,
                                  onTap: () => appThemeIndex.value = i,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sub(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 12),
        child: Row(
          children: [
            Icon(icon, color: accentGold, size: 22),
            const SizedBox(width: 8),
            Text(text,
                style: TextStyle(
                    fontSize: 16.5, fontWeight: FontWeight.bold, color: ink)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const SectionHeading('الإعدادات'),

            // ── ثيمات التطبيق (داخل زرار) ──
            _sub(Icons.palette_rounded, 'مظهر التطبيق'),
            ListenableBuilder(
              listenable: appThemeIndex,
              builder: (_, __) {
                final p = appPalettes[appThemeIndex.value];
                return ManuscriptRow(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.primary,
                      border: Border.all(color: p.accent, width: 3),
                    ),
                  ),
                  title: 'اختيار الثيم',
                  subtitle: p.label,
                  onTap: () => _pickTheme(context),
                );
              },
            ),
            const SizedBox(height: 10),
            _sub(Icons.text_fields_rounded, 'القراءة'),
            ManuscriptRow(
              icon: Icons.text_fields_rounded,
              title: 'إعدادات خط القصائد',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const FontSettingsPage())),
            ),
            ManuscriptRow(
              icon: Icons.auto_awesome_rounded,
              title: 'إعدادات خط الصلوات',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const FontSettingsPage(salawat: true))),
            ),
            const SizedBox(height: 18),
            const Divider(),
            ListTile(
              leading: Icon(Icons.info_outline_rounded, color: brown),
              title: const Text('عن التطبيق'),
              subtitle: const Text('دواوين النور — دواوين شعرية'),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: OrnamentDivider(),
            ),
            const SizedBox(height: 14),
            Text('هدية إلى فضيلة الشيخ عبدالرحمن',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    fontWeight: FontWeight.w600,
                    color: ink)),
            const SizedBox(height: 4),
            Text('نور النبي',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 24,
                    height: 1.5,
                    fontWeight: FontWeight.bold,
                    color: brown)),
            const SizedBox(height: 10),
          ],
        ),
      );
}

/// بطاقة معاينة ثيم
class _ThemeCard extends StatelessWidget {
  final AppPalette p;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeCard(
      {required this.p, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? p.accent : p.primary.withOpacity(.25),
              width: selected ? 2.6 : 1,
            ),
            boxShadow: selected ? _softShadow(.18) : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 64,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      Positioned.fill(child: ColoredBox(color: p.bg)),
                      Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          child: Container(height: 18, color: p.primary)),
                      Positioned(
                        left: 8,
                        right: 8,
                        top: 25,
                        child: Container(
                          height: 22,
                          decoration: BoxDecoration(
                            color: p.card,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: p.accent, width: 1),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 6,
                        child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                                color: p.accent,
                                borderRadius: BorderRadius.circular(2))),
                      ),
                      if (selected)
                        Positioned.fill(
                          child: Center(
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle, color: p.accent),
                              child: Icon(Icons.check_rounded,
                                  size: 18, color: p.primaryDark),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(p.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                      color: p.ink)),
            ],
          ),
        ),
      );
}

class SectionHeading extends StatelessWidget {
  final String text;
  const SectionHeading(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            CustomPaint(
                size: const Size(22, 22), painter: _StarPainter(accentGold)),
            const SizedBox(width: 10),
            Text(text,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: currentPalette.dark ? ink : brown)),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 1.2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.centerStart,
                    end: AlignmentDirectional.centerEnd,
                    colors: [accentGold, accentGold.withOpacity(0)],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

// ════════════════════════════════════════════════
// 2) عرض القصيدة (التصميم الإسلامي)
// ════════════════════════════════════════════════

class _Line {
  final Justified sadr;
  final Justified ajz;
  final List<(int, int)> sadrHl; // نطاقات التمييز في الصدر
  final List<(int, int)> ajzHl; // نطاقات التمييز في العجز
  const _Line(this.sadr, this.ajz, [this.sadrHl = const [], this.ajzHl = const []]);
}

class PoemBody extends StatefulWidget {
  final Poem poem;
  final String highlight; // نص البحث المُطبَّع، أو فارغ
  const PoemBody({super.key, required this.poem, this.highlight = ''});
  @override
  State<PoemBody> createState() => _PoemBodyState();
}

class _PoemBodyState extends State<PoemBody> {
  String? _key;
  List<_Line> _lines = const [];
  double _w = 0, _size = 22;
  TextStyle _style = const TextStyle();
  bool _allFit = true;
  final GlobalKey _matchKey = GlobalKey(); // أول بيت فيه نص البحث
  bool _scrolled = false;

  TextStyle _styleFor(BuildContext ctx, double size) =>
      withPoemFont(DefaultTextStyle.of(ctx).style.merge(TextStyle(
            fontSize: size,
            height: 1.0,
            color: poemInk(poemFontColor.value),
            fontWeight: poemFontWeight,
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
      final hl = widget.highlight.isEmpty
          ? (const <(int, int)>[], const <(int, int)>[])
          : verseMatchRanges(a.text, b.text, widget.highlight);
      lines.add(_Line(a, b, hl.$1, hl.$2));
    }
    _lines = lines;
    _w = w;
    _size = size;
    _style = st;
    _allFit = allFit;
  }

  Widget _hemistich(Justified j, Alignment align,
          [List<(int, int)> hl = const []]) =>
      Align(
        alignment: align,
        child: SizedBox(
          width: _w,
          child: Text.rich(
            highlightSpan(j.text, hl),
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
              '${widget.poem.title}|${c.maxWidth.toStringAsFixed(1)}|$base|${poemFontColor.value}|${poemFontWeightIndex.value}|${poemFontFamilyIndex.value}|${removeTashkeel.value}|${appDarkMode.value}|${widget.highlight}';
          if (key != _key) {
            _compute(ctx, c.maxWidth, base);
            _key = key;
          }
          final gap = _size * 0.95;
          // أول بيت فيه تمييز: ننزل إليه مرة واحدة عند فتح القصيدة
          final firstMatch = _lines.indexWhere(
              (l) => l.sadrHl.isNotEmpty || l.ajzHl.isNotEmpty);
          if (!_scrolled && firstMatch >= 0) {
            _scrolled = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final c = _matchKey.currentContext;
              if (!mounted || c == null) return;
              Scrollable.ensureVisible(c,
                  alignment: 0.3,
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeInOut);
            });
          }
          return Column(
            children: [
              for (var i = 0; i < _lines.length; i++) ...[
                Column(
                  key: i == firstMatch ? _matchKey : null,
                  children: [
                    // الصدر: يبدأ من أقصى اليمين
                    _hemistich(_lines[i].sadr, Alignment.centerRight,
                        _lines[i].sadrHl),
                    SizedBox(height: _size * 0.45),
                    // العجز: تحته مباشرة، مزاح 8 مسافات لليسار
                    _hemistich(_lines[i].ajz, Alignment.centerLeft,
                        _lines[i].ajzHl),
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
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ───────────── التصميم الإسلامي: قلوب وزخارف ─────────────

Path _heart(Offset c, double r) {
  // قلب داخل مربع نصف قطره r (العرض 2r تقريبًا، والارتفاع 1.84r)
  Offset p(double x, double y) =>
      Offset(c.dx + (x - .5) * 2 * r, c.dy + (y - .46) * 2 * r);
  return Path()
    ..moveTo(p(.5, .92).dx, p(.5, .92).dy)
    ..cubicTo(p(.5, .92).dx, p(.5, .92).dy, p(.02, .6).dx, p(.02, .6).dy,
        p(.02, .3).dx, p(.02, .3).dy)
    ..cubicTo(p(.02, .12).dx, p(.02, .12).dy, p(.16, 0).dx, p(.16, 0).dy,
        p(.3, 0).dx, p(.3, 0).dy)
    ..cubicTo(p(.4, 0).dx, p(.4, 0).dy, p(.47, .06).dx, p(.47, .06).dy,
        p(.5, .16).dx, p(.5, .16).dy)
    ..cubicTo(p(.53, .06).dx, p(.53, .06).dy, p(.6, 0).dx, p(.6, 0).dy,
        p(.7, 0).dx, p(.7, 0).dy)
    ..cubicTo(p(.84, 0).dx, p(.84, 0).dy, p(.98, .12).dx, p(.98, .12).dy,
        p(.98, .3).dx, p(.98, .3).dy)
    ..cubicTo(p(.98, .6).dx, p(.98, .6).dy, p(.5, .92).dx, p(.5, .92).dy,
        p(.5, .92).dx, p(.5, .92).dy)
    ..close();
}

/// كانت نجمة ثمانية، أصبحت قلبًا (الاسم محفوظ حتى لا تتغير بقية الاستدعاءات)
Path _star8(Offset c, double r, [double ratio = .62]) => _heart(c, r);

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
  final Color? stroke;
  const _StarPainter(this.color, [this.stroke]);
  @override
  void paint(Canvas canvas, Size size) {
    final path = _star8(size.center(Offset.zero), size.width / 2);
    canvas.drawPath(path, Paint()..color = color);
    if (stroke != null) {
      canvas.drawPath(
          path,
          Paint()
            ..color = stroke!
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4);
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter old) =>
      old.color != color || old.stroke != stroke;
}

/// فاصل مزخرف بين الأبيات: خط - معيّن - قلب - معيّن - خط
class OrnamentDivider extends StatelessWidget {
  const OrnamentDivider({super.key});
  @override
  Widget build(BuildContext context) {
    Widget line(bool strongAtEnd) => Expanded(
          child: Container(
            height: 1.2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: AlignmentDirectional.centerStart,
                end: AlignmentDirectional.centerEnd,
                colors: strongAtEnd
                    ? [accentGold.withOpacity(0), accentGold]
                    : [accentGold, accentGold.withOpacity(0)],
              ),
            ),
          ),
        );
    Widget diamond() => Transform.rotate(
          angle: math.pi / 4,
          child: Container(width: 5, height: 5, color: accentGold),
        );
    return Row(
      children: [
        line(true),
        const SizedBox(width: 8),
        diamond(),
        const SizedBox(width: 7),
        CustomPaint(size: const Size(16, 16), painter: _StarPainter(accentGold)),
        const SizedBox(width: 7),
        diamond(),
        const SizedBox(width: 8),
        line(false),
      ],
    );
  }
}

/// خلفية مزخرفة خفيفة (قلوب متكررة)
class _PatternPainter extends CustomPainter {
  final double k; // معامل شدّة النقش
  const _PatternPainter({this.k = 1.0});
  @override
  void paint(Canvas canvas, Size size) {
    const cell = 46.0;
    final stroke = Paint()
      ..color = accentGold.withOpacity((.16 * k).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final fill = Paint()
      ..color = accentGold.withOpacity((.10 * k).clamp(0.0, 1.0));
    for (var y = 0.0; y < size.height + cell; y += cell) {
      for (var x = 0.0; x < size.width + cell; x += cell) {
        canvas.drawPath(_star8(Offset(x, y), 13), stroke);
        canvas.drawPath(_star8(Offset(x + cell / 2, y + cell / 2), 5), fill);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter old) => true;
}

/// الإطار: خطوط مذهّبة مزدوجة + أقواس زخرفية في الزوايا + نجوم
class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint line(Color c, double w) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w;

    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(1.5, 1.5, size.width - 3, size.height - 3),
            const Radius.circular(12)),
        line(accentGold, 2.4));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(5.5, 5.5, size.width - 11, size.height - 11),
            const Radius.circular(9)),
        line(accentGold.withOpacity(.5), .8));
    final r = Rect.fromLTWH(10, 10, size.width - 20, size.height - 20);
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(5)),
        line(brown.withOpacity(.65), 1.2));

    // أقواس زخرفية داخل الزوايا
    final corners = [r.topLeft, r.topRight, r.bottomRight, r.bottomLeft];
    final starts = [0.0, math.pi / 2, math.pi, 3 * math.pi / 2];
    for (var i = 0; i < 4; i++) {
      canvas.drawArc(Rect.fromCircle(center: corners[i], radius: 30),
          starts[i], math.pi / 2, false, line(accentGold.withOpacity(.85), 1.4));
      canvas.drawArc(Rect.fromCircle(center: corners[i], radius: 23),
          starts[i], math.pi / 2, false, line(brown.withOpacity(.6), 1));
    }

    for (final c in corners) {
      _drawMedallion(canvas, c, 14);
    }
    _drawMedallion(canvas, Offset(r.center.dx, r.top), 9);
    _drawMedallion(canvas, Offset(r.center.dx, r.bottom), 9);
    _drawMedallion(canvas, Offset(r.left, r.center.dy), 7);
    _drawMedallion(canvas, Offset(r.right, r.center.dy), 7);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

/// إطار القصيدة
class PoemFrame extends StatelessWidget {
  final Widget child;
  const PoemFrame({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: paperColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(.22),
                blurRadius: 16,
                offset: const Offset(0, 6)),
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
                padding: const EdgeInsets.fromLTRB(28, 40, 28, 32),
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
  final (Color, Color)? colors; // لون الديوان (اختياري)
  const PoemHeader(
      {super.key, required this.title, required this.diwan, this.colors});
  @override
  Widget build(BuildContext context) {
    const archRadius = BorderRadius.only(
      topLeft: Radius.circular(110),
      topRight: Radius.circular(110),
      bottomLeft: Radius.circular(18),
      bottomRight: Radius.circular(18),
    );
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors?.$1 ?? brown, colors?.$2 ?? brownDark]),
        borderRadius: archRadius,
        border: Border.all(color: accentGold, width: 2),
        boxShadow: _softShadow(.28),
      ),
      child: ClipRRect(
        borderRadius: archRadius,
        child: Stack(
          children: [
            Positioned.fill(
                child: RepaintBoundary(
                    child: CustomPaint(painter: _PatternPainter(k: .8)))),
            // قوس داخلي رفيع
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(104),
                      topRight: Radius.circular(104),
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    border:
                        Border.all(color: accentGold.withOpacity(.5), width: .9),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 30, 22, 22),
              child: Column(
                children: [
                  CustomPaint(
                      size: const Size(24, 24),
                      painter: _StarPainter(accentGold)),
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
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accentGold.withOpacity(.5)),
                    ),
                    child: Text(diwan,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Color(0xFFE8D9BC), fontSize: 13.5, height: 1.4)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════
// 3) صفحة إعدادات الخط
// ════════════════════════════════════════════════

const _sample = Poem('معاينة', [
  Verse('قلبي للهادي مشتاقٌ', 'وبنبضِ فؤادي أشواقٌ'),
  Verse('لحبيبي بَلِّغْ آهاتي', 'وحنينَ القلبِ ودمعاتي'),
]);

class FontSettingsPage extends StatelessWidget {
  /// salawat = true: إعدادات خط الصلوات (مستقلة عن القصائد)
  final bool salawat;
  const FontSettingsPage({super.key, this.salawat = false});

  FontSet get f => salawat ? salawatFonts : poemFonts;

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: Text(t,
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.bold, color: brown)),
      );

  Widget _optionButton(
          {required IconData icon,
          required String title,
          required Widget trailing,
          required VoidCallback onTap}) =>
      Material(
        color: cream,
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

  Future<void> _pickFont(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cream,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * .8,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('نوع الخط',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: brown)),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: fontChoices.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final c = fontChoices[i];
                    final sel = f.familyIndex.value == i;
                    return ListTile(
                      title: Text(c.label,
                          style: TextStyle(
                              fontSize: 12,
                              color: sel ? brown : inkSoft,
                              fontWeight:
                                  sel ? FontWeight.bold : FontWeight.normal)),
                      subtitle: Text('بسم الله الرحمن الرحيم',
                          textDirection: TextDirection.rtl,
                          style: applyFontChoice(
                              c,
                              TextStyle(
                                  fontSize: 22,
                                  height: 1.6,
                                  color: ink,
                                  fontWeight: f.weight))),
                      trailing: sel
                          ? Icon(Icons.check_circle, color: brown)
                          : null,
                      onTap: () {
                        f.familyIndex.value = i;
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickColor(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: cream,
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
                    f.color.value = c.color;
                    Navigator.pop(ctx);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: c.color,
                        child: f.color.value == c.color
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
            title: Text(salawat ? 'إعدادات خط الصلوات' : 'إعدادات خط القصائد',
                style: const TextStyle(fontSize: 17))),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
          children: [
            salawat
                ? const PoemFrame(child: SalawatSample())
                : const PoemFrame(child: PoemBody(poem: _sample)),

            // ── حجم الخط ──
            _title('حجم الخط'),
            ListenableBuilder(
              listenable: f.size,
              builder: (_, __) {
                final v = f.size.value;
                return Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                            backgroundColor: brown,
                            padding: const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: v > minPoemFont
                            ? () => f.size.value =
                                (v - 1).clamp(minPoemFont, maxPoemFont).toDouble()
                            : null,
                        icon: const Icon(Icons.remove_rounded),
                        label: const Text('تصغير'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(arDigits(v.round()),
                          style: TextStyle(
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
                            ? () => f.size.value =
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

            // ── نوع الخط ──
            _title('نوع الخط'),
            ListenableBuilder(
              listenable: f.familyIndex,
              builder: (_, __) => _optionButton(
                icon: Icons.font_download_rounded,
                title: 'اختيار نوع الخط',
                trailing: Text(
                    fontChoices[f.familyIndex.value].label,
                    style: TextStyle(fontSize: 13, color: brown)),
                onTap: () => _pickFont(context),
              ),
            ),

            // ── لون الخط ──
            _title('لون الخط'),
            ListenableBuilder(
              listenable: f.color,
              builder: (_, __) => _optionButton(
                icon: Icons.palette_rounded,
                title: 'اختيار لون الخط',
                trailing: CircleAvatar(
                    radius: 11, backgroundColor: f.color.value),
                onTap: () => _pickColor(context),
              ),
            ),

            // ── سُمك الخط ──
            _title('سُمك الخط'),
            ListenableBuilder(
              listenable: f.weightIndex,
              builder: (_, __) {
                final sel = f.weightIndex.value;
                return Row(
                  children: [
                    for (var i = 0; i < weightChoices.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(
                        child: sel == i
                            ? FilledButton(
                                style: FilledButton.styleFrom(
                                    backgroundColor: brown,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14)),
                                onPressed: () {},
                                child: Text(weightChoices[i].label,
                                    style: TextStyle(
                                        fontWeight: weightChoices[i].weight)))
                            : OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                    foregroundColor: brown,
                                    side: BorderSide(color: brown),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14)),
                                onPressed: () =>
                                    f.weightIndex.value = i,
                                child: Text(weightChoices[i].label,
                                    style: TextStyle(
                                        fontWeight: weightChoices[i].weight))),
                      ),
                    ],
                  ],
                );
              },
            ),

            // ── التشكيل ──
            _title('التشكيل'),
            ListenableBuilder(
              listenable: f.noTashkeel,
              builder: (_, __) {
                final off = f.noTashkeel.value;
                ButtonStyle filled() => FilledButton.styleFrom(
                    backgroundColor: brown,
                    padding: const EdgeInsets.symmetric(vertical: 14));
                ButtonStyle outlined() => OutlinedButton.styleFrom(
                    foregroundColor: brown,
                    side: BorderSide(color: brown),
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
                              onPressed: () => f.noTashkeel.value = true,
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
                              onPressed: () => f.noTashkeel.value = false,
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

/// مجموعة إعدادات خط كاملة (حجم / لون / نوع / سُمك / تشكيل) تُحفظ بمفاتيح خاصة بها.
/// عندنا مجموعتان مستقلتان: القصائد [poemFonts] والصلوات [salawatFonts].
class FontSet {
  final String prefix; // بادئة مفاتيح الحفظ على الهاتف
  final String tashkeelKey;
  final ValueNotifier<double> size = ValueNotifier<double>(22);
  final ValueNotifier<Color> color =
      ValueNotifier<Color>(const Color(0xFF3E2723));
  final ValueNotifier<int> familyIndex = ValueNotifier<int>(0);
  final ValueNotifier<int> weightIndex = ValueNotifier<int>(0);
  final ValueNotifier<bool> noTashkeel = ValueNotifier<bool>(false);
  FontSet(this.prefix, {required this.tashkeelKey});

  late final Listenable listenable =
      Listenable.merge([size, color, weightIndex, familyIndex, noTashkeel]);

  TextStyle withFont(TextStyle s) =>
      applyFontChoice(fontChoices[familyIndex.value], s);
  FontWeight get weight => weightChoices[weightIndex.value].weight;
  String display(String s) => noTashkeel.value ? stripTashkeel(s) : s;
}

/// إعدادات خط القصائد (كما كانت تمامًا)
final FontSet poemFonts = FontSet('poem', tashkeelKey: 'removeTashkeel');

/// إعدادات خط الصلوات (مستقلة عن القصائد)
final FontSet salawatFonts =
    FontSet('salawat', tashkeelKey: 'salawatRemoveTashkeel');

/// حجم خط القصيدة
final ValueNotifier<double> poemFontSize = poemFonts.size;

/// لون خط القصيدة
final ValueNotifier<Color> poemFontColor = poemFonts.color;

/// نوع خط القصيدة (فهرس في fontChoices، 0 = الخط الافتراضي)
final ValueNotifier<int> poemFontFamilyIndex = poemFonts.familyIndex;

class FontChoice {
  final String label;
  final String? family; // اسم family كما في pubspec.yaml (null = الافتراضي)
  const FontChoice(this.label, [this.family]);
}

const fontChoices = [
  FontChoice('الخط الافتراضي'),
  FontChoice('ثلث ونسوفت', 'WinsoftThuluth'),
  FontChoice('ثلث ديكوتايب', 'DecoThuluth'),
  FontChoice('ثلث المشرف', 'Amoshref'),
  FontChoice('رقعة عارف حبر', 'ArefRuqaa'),
  FontChoice('جالاكسي', 'AAGalaxy'),
  FontChoice('توباز ثلاثي الأبعاد', 'Topaz3D'),
  FontChoice('مثنى', 'Mothanna'),
  FontChoice('رقعة عارف', 'ArefRuqaaBold'),
  FontChoice('فلسطين', 'Palestine'),
  FontChoice('ثلث ديكوتايب الأصلي', 'DTThuluth'),
  FontChoice('ثلث سلس', 'UKIJSulus'),
  FontChoice('ثلث ديمة', 'DimaThulth'),
  FontChoice('أبو حميدة', 'Abuhmeda'),
  FontChoice('كاكست الزخرفي', 'KacstDecorative'),
];

/// يطبّق نوع الخط المختار على ستايل
TextStyle applyFontChoice(FontChoice c, TextStyle s) =>
    c.family == null ? s : s.copyWith(fontFamily: c.family);

TextStyle withPoemFont(TextStyle s) =>
    applyFontChoice(fontChoices[poemFontFamilyIndex.value], s);

/// سُمك خط القصيدة (فهرس في weightChoices)
final ValueNotifier<int> poemFontWeightIndex = poemFonts.weightIndex;

class WeightChoice {
  final String label;
  final FontWeight weight;
  const WeightChoice(this.label, this.weight);
}

const weightChoices = [
  WeightChoice('عادي', FontWeight.w500),
  WeightChoice('سميك', FontWeight.w700),
  WeightChoice('سميك جدًا', FontWeight.w900),
];

FontWeight get poemFontWeight => weightChoices[poemFontWeightIndex.value].weight;

/// true = بدون تشكيل، false = التشكيل كما هو
final ValueNotifier<bool> removeTashkeel = poemFonts.noTashkeel;

/// يتغيّر عند تغيّر أي إعداد
final Listenable poemSettings = poemFonts.listenable;

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

// ───────────── اختصارات خط الصلوات ─────────────
TextStyle withSalawatFont(TextStyle s) => salawatFonts.withFont(s);
FontWeight get salawatFontWeight => salawatFonts.weight;
String salawatDisplayText(String s) => salawatFonts.display(s);

// ───────────── الحفظ والاسترجاع ─────────────
/// يقرأ إعدادات مجموعة خط من الهاتف ويبدأ حفظ أي تغيير فيها.
/// [fallback]: لو لم يوجد حفظ سابق للمجموعة تبدأ بقيم المجموعة الأخرى
/// (فلا يتغيّر شكل الصلوات عند أول تشغيل بعد التحديث).
void _loadFontSet(SharedPreferences p, FontSet f, {FontSet? fallback}) {
  final k = f.prefix;
  final size = p.getDouble('${k}FontSize');
  if (size != null) {
    f.size.value = size.clamp(minPoemFont, maxPoemFont).toDouble();
  } else if (fallback != null) {
    f.size.value = fallback.size.value;
  }
  final ci = p.getInt('${k}FontColorIndex');
  if (ci != null && ci >= 0 && ci < colorChoices.length) {
    f.color.value = colorChoices[ci].color;
  } else if (fallback != null) {
    f.color.value = fallback.color.value;
  }
  final wi = p.getInt('${k}FontWeightIndex');
  if (wi != null && wi >= 0 && wi < weightChoices.length) {
    f.weightIndex.value = wi;
  } else if (fallback != null) {
    f.weightIndex.value = fallback.weightIndex.value;
  }
  final fi = p.getInt('${k}FontFamilyIndex');
  if (fi != null && fi >= 0 && fi < fontChoices.length) {
    f.familyIndex.value = fi;
  } else if (fallback != null) {
    f.familyIndex.value = fallback.familyIndex.value;
  }
  final tk = p.getBool(f.tashkeelKey);
  if (tk != null) {
    f.noTashkeel.value = tk;
  } else if (fallback != null) {
    f.noTashkeel.value = fallback.noTashkeel.value;
  }

  f.size.addListener(() => p.setDouble('${k}FontSize', f.size.value));
  f.color.addListener(() {
    final i = colorChoices.indexWhere((c) => c.color == f.color.value);
    if (i >= 0) p.setInt('${k}FontColorIndex', i);
  });
  f.familyIndex
      .addListener(() => p.setInt('${k}FontFamilyIndex', f.familyIndex.value));
  f.weightIndex
      .addListener(() => p.setInt('${k}FontWeightIndex', f.weightIndex.value));
  f.noTashkeel
      .addListener(() => p.setBool(f.tashkeelKey, f.noTashkeel.value));
}

Future<void> loadFontSettings() async {
  try {
    final p = await SharedPreferences.getInstance();
    _loadFontSet(p, poemFonts);
    _loadFontSet(p, salawatFonts, fallback: poemFonts);
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

// ───────────── تمييز نص البحث (هايلايت) ─────────────

bool _ignorableUnit(int r) =>
    (r >= 0x064B && r <= 0x065F) ||
    r == 0x0670 ||
    r == 0x0640 ||
    (r >= 0x06D6 && r <= 0x06ED);

/// نفس تطبيع [normalizeArabic] لكن مع خريطة ترجع بكل حرف إلى مكانه في النص الأصلي
(String, List<int>) _normalizeWithMap(String s) {
  final b = StringBuffer();
  final map = <int>[];
  for (var i = 0; i < s.length; i++) {
    final r = s.codeUnitAt(i);
    if (_ignorableUnit(r)) continue;
    String ch;
    switch (r) {
      case 0x0622:
      case 0x0623:
      case 0x0625:
      case 0x0671:
        ch = 'ا';
        break;
      case 0x0649:
        ch = 'ي';
        break;
      case 0x0629:
        ch = 'ه';
        break;
      default:
        ch = String.fromCharCode(r);
    }
    if (RegExp(r'\s').hasMatch(ch)) {
      if (map.isEmpty || b.toString().endsWith(' ')) continue;
      ch = ' ';
    }
    b.write(ch);
    map.add(i);
  }
  var out = b.toString();
  if (out.endsWith(' ')) {
    out = out.substring(0, out.length - 1);
    map.removeLast();
  }
  return (out, map);
}

/// يضمّ التشكيل والتطويل الذي يلي آخر حرف مطابق
int _extendEnd(String text, int end) {
  while (end < text.length && _ignorableUnit(text.codeUnitAt(end))) {
    end++;
  }
  return end;
}

/// نطاقات (بداية، نهاية) التي يظهر فيها [q] (نص بحث مُطبَّع) داخل [text]
List<(int, int)> findMatchRanges(String text, String q) {
  if (q.isEmpty) return const [];
  final (norm, map) = _normalizeWithMap(text);
  final out = <(int, int)>[];
  var from = 0;
  while (true) {
    final i = norm.indexOf(q, from);
    if (i < 0) break;
    final j = i + q.length;
    out.add((map[i], _extendEnd(text, map[j - 1] + 1)));
    from = j;
  }
  return out;
}

/// نطاقات التمييز في الصدر والعجز، مع حالة أن تمتدّ العبارة بينهما
(List<(int, int)>, List<(int, int)>) verseMatchRanges(
    String sadr, String ajz, String q) {
  final s = findMatchRanges(sadr, q);
  final a = findMatchRanges(ajz, q);
  if (q.contains(' ')) {
    final (sn, sm) = _normalizeWithMap(sadr);
    final (an, am) = _normalizeWithMap(ajz);
    for (var k = 1; k < q.length - 1; k++) {
      if (q[k] != ' ') continue;
      final pre = q.substring(0, k);
      final post = q.substring(k + 1);
      if (post.isEmpty || !sn.endsWith(pre) || !an.startsWith(post)) continue;
      final si = sn.length - pre.length;
      s.add((sm[si], _extendEnd(sadr, sm[sn.length - 1] + 1)));
      a.add((am[0], _extendEnd(ajz, am[post.length - 1] + 1)));
    }
  }
  return (s, a);
}

/// لون خلفية التمييز
Color get highlightColor =>
    const Color(0xFFFFD600).withOpacity(appDarkMode.value ? .38 : .6);

/// يقسم [text] إلى أجزاء ويميّز النطاقات [ranges] بلون خلفية
InlineSpan highlightSpan(String text, List<(int, int)> ranges,
    {TextStyle? style}) {
  if (ranges.isEmpty) return TextSpan(text: text, style: style);
  final sorted = [...ranges]..sort((x, y) => x.$1.compareTo(y.$1));
  final children = <InlineSpan>[];
  var pos = 0;
  for (final (st, en) in sorted) {
    if (st < pos || en > text.length || st >= en) continue;
    if (st > pos) children.add(TextSpan(text: text.substring(pos, st)));
    children.add(TextSpan(
        text: text.substring(st, en),
        style: TextStyle(backgroundColor: highlightColor)));
    pos = en;
  }
  if (pos < text.length) children.add(TextSpan(text: text.substring(pos)));
  return TextSpan(style: style, children: children);
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
Justified justifyHemistich(String text, TextStyle style, double target,
    {int maxPerSlot = 6, double maxWordSpacing = 14}) {
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
  if (spaces > 0 && residual > 0.3) ws = math.min(residual / spaces, maxWordSpacing);
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

