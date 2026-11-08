import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'main.dart';

// ════════════════════════════════════════════════
// قسم «الصلوات»
//  • صفحة فيها ثلاث بطاقات (SalawatPage)
//  • صفحة قراءة: كل صيغة في سطر مستقل، كل الأسطر مضبوطة بالكشيدة،
//    بين كل صيغة والتي تليها فاصل القلوب، والتمرير سلس.
//  • النصوص في ملفات txt داخل assets/salawat/
// ════════════════════════════════════════════════

enum SalawatKind {
  numbered, // صلوات مرقّمة بصيغة {1} {2} ...
  letters, // مرتّبة على الحروف (حرف الهمزة، حرف الباء ...)
  munajat, // مناجاة
}

class SalawatBook {
  final String title;
  final String blurb;
  final String asset;
  final SalawatKind kind;
  final IconData icon;
  const SalawatBook({
    required this.title,
    required this.blurb,
    required this.asset,
    required this.kind,
    required this.icon,
  });
}

/// الأقسام الثلاثة. لتغيير الاسم أو مكان الملف عدّلي هنا فقط.
const salawatBooks = <SalawatBook>[
  SalawatBook(
    title: 'صلوات الأنوار على سيد الأبرار',
    blurb: 'صلوات مرقّمة',
    asset: 'assets/salawat/salawat_anwar.txt',
    kind: SalawatKind.numbered,
    icon: Icons.light_mode_rounded,
  ),
  SalawatBook(
    title: 'الصلوات المباركات على سيد السادات',
    blurb: 'مرتّبة على حروف الهجاء',
    asset: 'assets/salawat/salawat_mubarakat.txt',
    kind: SalawatKind.letters,
    icon: Icons.auto_awesome_rounded,
  ),
  SalawatBook(
    title: 'مناجاة الأشواق',
    blurb: 'مناجاة وسلام',
    asset: 'assets/salawat/munajat_ashwaq.txt',
    kind: SalawatKind.munajat,
    icon: Icons.favorite_rounded,
  ),
];

// ───────────── قراءة الملفات وتقسيمها إلى صيغ ─────────────

class SBlock {
  final String text;
  final int? number; // رقم الصلاة (للمرقّمة فقط)
  final bool heading; // عنوان (مثل: حرف الهمزة)
  const SBlock(this.text, {this.number, this.heading = false});
}

final Map<String, List<SBlock>> _salawatCache = {};

String _clean(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();

/// النص بلا تشكيل ولا تطويل (للمقارنة فقط)
String _plain(String s) => stripTashkeel(s).replaceAll(kTatweel, '').trim();

Future<List<SBlock>> loadSalawat(SalawatBook book) async {
  final cached = _salawatCache[book.asset];
  if (cached != null) return cached;
  var raw = await rootBundle.loadString(book.asset);
  if (raw.startsWith('\uFEFF')) raw = raw.substring(1);
  final lines = raw.split(RegExp(r'\r\n|\r|\n'));
  final blocks = switch (book.kind) {
    SalawatKind.numbered => _parseNumbered(lines),
    SalawatKind.letters => _parseLetters(lines),
    SalawatKind.munajat => _parseMunajat(lines),
  };
  _salawatCache[book.asset] = blocks;
  return blocks;
}

final RegExp _numRe = RegExp(r'^\s*\{\s*(\d+)\s*\}\s*(.*)$');

/// كل سطر في الملف = صيغة مستقلة بنفس الترتيب، بدون أي دمج.
/// السطر اللي يبدأ بـ {رقم} يحمل رقمه، وسطر العنوان ((...)) يُتجاهل.
List<SBlock> _parseNumbered(List<String> lines) {
  final out = <SBlock>[];
  for (final raw in lines) {
    final line = _clean(raw);
    if (line.isEmpty || line.startsWith('((')) continue;
    final m = _numRe.firstMatch(line);
    if (m != null) {
      out.add(SBlock(_clean(m.group(2)!), number: int.parse(m.group(1)!)));
    } else {
      out.add(SBlock(line));
    }
  }
  return out;
}

/// «حرف ...» و«صيغة الحروف...» عناوين، وكل سطر غيرهم صيغة مستقلة.
List<SBlock> _parseLetters(List<String> lines) {
  final out = <SBlock>[];
  for (final raw in lines) {
    final line = _clean(raw);
    if (line.isEmpty || line.startsWith('((')) continue;
    final p = _plain(line);
    if (p.startsWith('حرف ') || p.startsWith('صيغة الحروف')) {
      out.add(SBlock(line, heading: true));
    } else {
      out.add(SBlock(line));
    }
  }
  return out;
}

/// سطر العنوان الأول يُتجاهل (موجود في الترويسة)، وكل سطر بعده صيغة مستقلة.
List<SBlock> _parseMunajat(List<String> lines) {
  final out = <SBlock>[];
  var first = true;
  for (final raw in lines) {
    final line = _clean(raw);
    if (line.isEmpty) continue;
    if (first) {
      first = false;
      final p = _plain(line);
      if (p.length <= 30 && !p.startsWith('اللهم')) continue; // العنوان
    }
    out.add(SBlock(line));
  }
  return out;
}

// ───────────── كسر الصيغة إلى أسطر متقاربة الامتلاء ─────────────

List<String> _breakLines(String text, TextStyle st, double width) {
  final words = text.trim().split(RegExp(r'\s+'));
  if (words.length <= 1) return [text.trim()];

  final cache = <String, double>{};
  double wOf(String s) => cache.putIfAbsent(s, () => measureText(s, st));
  final sp = math.max(1.0, measureText('ا ا', st) - measureText('اا', st));

  final n = words.length;
  final ww = [for (final w in words) wOf(w)];
  final best = List<double>.filled(n + 1, double.infinity);
  final nxt = List<int>.filled(n + 1, n);
  best[n] = 0;
  for (var i = n - 1; i >= 0; i--) {
    var w = 0.0;
    for (var j = i; j < n; j++) {
      w += ww[j] + (j > i ? sp : 0);
      if (w > width && j > i) break;
      final slack = (width - w) / width;
      final cost = slack < 0 ? 1e6 : slack * slack;
      final c = cost + best[j + 1];
      if (c < best[i]) {
        best[i] = c;
        nxt[i] = j + 1;
      }
    }
  }

  final lines = <List<String>>[];
  var i = 0;
  while (i < n) {
    final j = nxt[i];
    lines.add(words.sublist(i, j));
    i = j;
  }

  // تأكيد بالقياس الفعلي: لو زاد سطر عن العرض ننقل آخر كلمة للسطر التالي
  for (var k = 0; k < lines.length; k++) {
    while (lines[k].length > 1 &&
        measureText(lines[k].join(' '), st) > width + 0.3) {
      final moved = lines[k].removeLast();
      if (k + 1 < lines.length) {
        lines[k + 1].insert(0, moved);
      } else {
        lines.add([moved]);
      }
    }
  }
  return [for (final l in lines) l.join(' ')];
}

// ───────────── صفحة القسم (التبويب) ─────────────

class SalawatPage extends StatelessWidget {
  const SalawatPage({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SectionHeading('الصلوات'),
            for (var i = 0; i < salawatBooks.length; i++)
              _SalawatTile(book: salawatBooks[i], index: i),
          ],
        ),
      );
}

class _SalawatTile extends StatelessWidget {
  final SalawatBook book;
  final int index;
  const _SalawatTile({required this.book, required this.index});

  @override
  Widget build(BuildContext context) {
    final dc = diwanColors(index + 1);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: cream,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: accentGold.withOpacity(.6), width: 1.2),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(.16),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => SalawatReadPage(book: book))),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 120),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // الكعب الملوّن وعليه الأيقونة
                      Container(
                        width: 84,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [dc.$1, dc.$2],
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(.18),
                              border: Border.all(color: accentGold, width: 1.4),
                            ),
                            child:
                                Icon(book.icon, color: accentGold, size: 27),
                          ),
                        ),
                      ),
                      Container(
                        width: 4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color.lerp(accentGold, Colors.white, .4)!,
                              accentGold,
                              Color.lerp(accentGold, Colors.black, .3)!,
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(book.title,
                                  style: TextStyle(
                                      color: ink,
                                      fontSize: 17.5,
                                      height: 1.55,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              const OrnamentDivider(),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 11, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: accentGold.withOpacity(.16),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: accentGold.withOpacity(.6)),
                                    ),
                                    child: Text(book.blurb,
                                        style: TextStyle(
                                            color: ink,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                  const Spacer(),
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                          begin: Alignment.topRight,
                                          end: Alignment.bottomLeft,
                                          colors: [dc.$1, dc.$2]),
                                      border: Border.all(
                                          color: accentGold, width: 1.3),
                                    ),
                                    child: Icon(Icons.chevron_left_rounded,
                                        color: accentGold, size: 24),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────── صفحة القراءة ─────────────

class SalawatReadPage extends StatefulWidget {
  final SalawatBook book;
  const SalawatReadPage({super.key, required this.book});
  @override
  State<SalawatReadPage> createState() => _SalawatReadPageState();
}

class _SalawatReadPageState extends State<SalawatReadPage> {
  List<SBlock>? _blocks;
  late final Future<List<SBlock>> _future =
      loadSalawat(widget.book).then((b) => _blocks = b);

  String get _fullText {
    final b = StringBuffer()..writeln(widget.book.title)..writeln();
    for (final x in _blocks ?? const <SBlock>[]) {
      final t = displayText(x.text);
      if (x.heading) {
        b.writeln(t);
      } else if (x.number != null) {
        b..writeln('(${arDigits(x.number!)}) $t')..writeln();
      } else {
        b..writeln(t)..writeln();
      }
    }
    return b.toString().trim();
  }

  Future<void> _copy() async {
    if (_blocks == null) return;
    await Clipboard.setData(ClipboardData(text: _fullText));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        content: Text('تم النسخ', textAlign: TextAlign.center),
        duration: Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final dc = diwanColors(salawatBooks.indexOf(book) + 1);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: dc.$1,
        title: Text(book.title, style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
              tooltip: 'نسخ النص',
              icon: const Icon(Icons.copy_rounded),
              onPressed: _copy),
        ],
      ),
      body: FutureBuilder<List<SBlock>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final blocks = snap.data;
          if (snap.hasError || blocks == null || blocks.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Text(
                  'لم يُعثر على نص هذا القسم.\n'
                  'تأكدي أن الملف ${book.asset} موجود وأنه مضاف في assets داخل pubspec.yaml.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: inkSoft, height: 1.8),
                ),
              ),
            );
          }
          final sub = book.kind == SalawatKind.numbered
              ? '${arDigits(blocks.where((b) => b.number != null).length)} صلاة'
              : book.blurb;
          return SalawatList(
            title: book.title,
            sub: sub,
            colors: dc,
            blocks: blocks,
          );
        },
      ),
    );
  }
}

// ───────────── قائمة الصيغ: تُبنى عند الحاجة فقط (تمرير سلس) ─────────────

class _Laid {
  final SBlock block;
  final List<Justified> lines;
  const _Laid(this.block, this.lines);
}

class SalawatList extends StatefulWidget {
  final String title;
  final String sub;
  final (Color, Color) colors;
  final List<SBlock> blocks;
  const SalawatList({
    super.key,
    required this.title,
    required this.sub,
    required this.colors,
    required this.blocks,
  });
  @override
  State<SalawatList> createState() => _SalawatListState();
}

class _SalawatListState extends State<SalawatList> {
  static const _perPage = 8; // عدد الصيغ في كل إطار

  String? _key;
  int _gen = 0;
  final Map<int, _Laid> _cache = {};
  double _w = 0, _size = 22;
  TextStyle _style = const TextStyle();

  @override
  void dispose() {
    _gen++;
    super.dispose();
  }

  TextStyle _styleFor(BuildContext ctx, double size) =>
      withPoemFont(DefaultTextStyle.of(ctx).style.merge(TextStyle(
            fontSize: size,
            height: 1.0,
            color: poemInk(poemFontColor.value),
            fontWeight: poemFontWeight,
          )));

  _Laid _layout(SBlock b) {
    if (b.heading) return _Laid(b, const []);
    var t = displayText(b.text);
    if (b.number != null) t = '(${arDigits(b.number!)}) $t';
    final lines = _breakLines(t, _style, _w);
    return _Laid(b, [
      for (final l in lines)
        justifyHemistich(l, _style, _w, maxPerSlot: 16, maxWordSpacing: 24),
    ]);
  }

  _Laid _laidAt(int i) => _cache.putIfAbsent(i, () => _layout(widget.blocks[i]));

  /// يحسب الصيغ مقدّمًا في الخلفية (بدون إعادة بناء الشاشة) حتى لا يتقطّع التمرير
  Future<void> _warm(int gen) async {
    for (var i = 0; i < widget.blocks.length; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 12));
      if (!mounted || gen != _gen) return;
      _laidAt(i);
    }
  }

  Widget _line(Justified j, {required bool numberedFirst}) {
    InlineSpan span = TextSpan(text: j.text);
    if (numberedFirst) {
      final i = j.text.indexOf(' ');
      if (i > 0) {
        span = TextSpan(children: [
          TextSpan(
              text: j.text.substring(0, i),
              style: TextStyle(color: currentPalette.accent)),
          TextSpan(text: j.text.substring(i)),
        ]);
      }
    }
    return SizedBox(
      width: _w,
      child: Text.rich(
        span,
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
    );
  }

  Widget _heading(String t, {required bool withTop}) {
    final p = currentPalette;
    return Column(
      children: [
        if (withTop) ...[
          const OrnamentDivider(),
          const SizedBox(height: 10),
        ],
        Text(displayText(t),
            textAlign: TextAlign.center,
            style: withPoemFont(TextStyle(
                color: p.dark ? p.ink : p.primary,
                fontSize: _size * .95,
                height: 1.3,
                fontWeight: FontWeight.bold))),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _paragraph(_Laid l) {
    final numbered = l.block.number != null;
    return Column(
      children: [
        for (var k = 0; k < l.lines.length; k++) ...[
          if (k > 0) SizedBox(height: _size * .62),
          _line(l.lines[k], numberedFirst: numbered && k == 0),
        ],
      ],
    );
  }

  /// محتوى إطار واحد: عدة صيغ بينها فاصل القلوب
  Widget _page(int k) {
    final start = k * _perPage;
    final end = math.min(widget.blocks.length, start + _perPage);
    final gap = _size * .95;
    final kids = <Widget>[];
    for (var i = start; i < end; i++) {
      final isHead = widget.blocks[i].heading;
      if (i > start) {
        final prevHead = widget.blocks[i - 1].heading;
        kids.add(isHead || prevHead
            ? SizedBox(height: gap)
            : Padding(
                padding: EdgeInsets.symmetric(vertical: gap * .6),
                child: const OrnamentDivider(),
              ));
      }
      kids.add(isHead
          ? _heading(widget.blocks[i].text, withTop: i > start)
          : _paragraph(_laidAt(i)));
    }
    return Column(children: kids);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: poemSettings,
      builder: (ctx, _) => LayoutBuilder(
        builder: (ctx, c) {
          final base = poemFontSize.value;
          final key =
              '${c.maxWidth.toStringAsFixed(1)}|$base|${poemFontColor.value}|${poemFontWeightIndex.value}|${poemFontFamilyIndex.value}|${removeTashkeel.value}|${appDarkMode.value}';
          if (key != _key) {
            _key = key;
            _gen++;
            _cache.clear();
            _w = c.maxWidth - 28 - 56; // هامش القائمة + هامش الإطار
            _size = base;
            _style = _styleFor(ctx, base);
            _warm(_gen);
          }
          final pages = (widget.blocks.length + _perPage - 1) ~/ _perPage;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 30),
            cacheExtent: 900,
            itemCount: pages + 1,
            itemBuilder: (ctx, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: PoemHeader(
                      title: widget.title,
                      diwan: widget.sub,
                      colors: widget.colors),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: PoemFrame(child: _page(i - 1)),
              );
            },
          );
        },
      ),
    );
  }
}
