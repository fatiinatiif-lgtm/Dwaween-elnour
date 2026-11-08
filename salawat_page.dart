import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'main.dart';

// ════════════════════════════════════════════════
// قسم «الصلوات»
//  • صفحة فيها ثلاث بطاقات (SalawatPage)
//  • صفحة قراءة (SalawatReadPage): نص نثري مضبوط الأسطر بالكشيدة
//    فكل سطر يبدأ من أول العرض وينتهي بآخره، بلا فراغات.
//  • النصوص نفسها في ملفات txt داخل assets/salawat/ (انظري الشرح في الأسفل)
// ════════════════════════════════════════════════

enum SalawatKind {
  numbered, // صلوات مرقّمة بصيغة {1} {2} ...
  letters, // مرتّبة على الحروف (حرف الهمزة، حرف الباء ...)
  munajat, // مناجاة: سطور قصيرة تُدمج في فقرة واحدة متصلة
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

// ───────────── قراءة الملفات وتقسيمها إلى فقرات ─────────────

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

/// كل سطر يبدأ بـ {رقم} فقرة مستقلة بنفس رقمها.
/// سطر العنوان ((...)) يُتجاهل، وأي سطر بلا رقم يُلحق بالفقرة التي قبله.
List<SBlock> _parseNumbered(List<String> lines) {
  final out = <SBlock>[];
  for (final raw in lines) {
    final line = _clean(raw);
    if (line.isEmpty) continue;
    final m = _numRe.firstMatch(line);
    if (m != null) {
      out.add(SBlock(_clean(m.group(2)!), number: int.parse(m.group(1)!)));
    } else if (line.startsWith('((')) {
      continue;
    } else if (out.isNotEmpty) {
      final last = out.removeLast();
      out.add(SBlock('${last.text} $line', number: last.number));
    }
  }
  return out;
}

/// «حرف ...» و«صيغة الحروف...» عناوين.
/// كل سطر يبدأ بـ «اللهم» يفتح فقرة جديدة، وأسطر «وصلّ وسلّم...» التي بعده
/// تتصل به في نفس الفقرة (لأن الأسطر القصيرة لا تُضبط بالكشيدة بشكل جميل).
List<SBlock> _parseLetters(List<String> lines) {
  final out = <SBlock>[];
  final cur = StringBuffer();
  void flush() {
    if (cur.isNotEmpty) {
      out.add(SBlock(cur.toString().trim()));
      cur.clear();
    }
  }

  for (final raw in lines) {
    final line = _clean(raw);
    if (line.isEmpty || line.startsWith('((')) continue;
    final p = _plain(line);
    if (p.startsWith('حرف ') || p.startsWith('صيغة الحروف')) {
      flush();
      out.add(SBlock(line, heading: true));
    } else if (p.startsWith('اللهم')) {
      flush();
      cur.write(line);
    } else {
      if (cur.isNotEmpty) cur.write(' ');
      cur.write(line);
    }
  }
  flush();
  return out;
}

/// سطر العنوان الأول يُتجاهل (العنوان موجود في الترويسة).
/// أسطر «الصلاة والسلام عليك يا ...» القصيرة تُدمج في فقرة واحدة متصلة،
/// والأسطر الطويلة (الافتتاح والخاتمة) كل واحد منها فقرة مستقلة.
const int _shortLineMax = 80; // عدد الحروف (بلا تشكيل) الفاصل بين القصير والطويل

List<SBlock> _parseMunajat(List<String> lines) {
  final out = <SBlock>[];
  final run = StringBuffer();
  void flush() {
    if (run.isNotEmpty) {
      out.add(SBlock(run.toString().trim()));
      run.clear();
    }
  }

  var first = true;
  for (final raw in lines) {
    final line = _clean(raw);
    if (line.isEmpty) continue;
    final p = _plain(line);
    if (first) {
      first = false;
      if (p.length <= 30 && !p.startsWith('اللهم')) continue; // العنوان
    }
    if (p.length <= _shortLineMax && p.startsWith('الصلاة والسلام عليك')) {
      if (run.isNotEmpty) run.write(' ');
      run.write(line);
    } else {
      flush();
      out.add(SBlock(line));
    }
  }
  flush();
  return out;
}

// ───────────── كسر الفقرة إلى أسطر متقاربة الامتلاء ─────────────

/// يقسم الفقرة إلى أسطر بحيث تكون الفراغات المتبقية في الأسطر كلها
/// أقل ما يمكن (فتحتاج الكشيدة إلى مدّ بسيط في كل سطر، لا مدّ كبير في سطر واحد).
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
              ? '${arDigits(blocks.length)} صلاة'
              : book.blurb;
          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 30),
            children: [
              PoemHeader(title: book.title, diwan: sub, colors: dc),
              const SizedBox(height: 16),
              PoemFrame(child: SalawatBody(blocks: blocks)),
            ],
          );
        },
      ),
    );
  }
}

// ───────────── جسم النص: فقرات مضبوطة بالكشيدة ─────────────

class _Laid {
  final SBlock block;
  final List<Justified> lines;
  const _Laid(this.block, this.lines);
}

class SalawatBody extends StatefulWidget {
  final List<SBlock> blocks;
  const SalawatBody({super.key, required this.blocks});
  @override
  State<SalawatBody> createState() => _SalawatBodyState();
}

class _SalawatBodyState extends State<SalawatBody> {
  String? _key;
  int _gen = 0;
  int _next = 0;
  List<_Laid> _laid = [];
  double _w = 0, _size = 22;
  TextStyle _style = const TextStyle();

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
        justifyHemistich(l, _style, _w, maxPerSlot: 10, maxWordSpacing: 22),
    ]);
  }

  void _step(int count) {
    final end = math.min(widget.blocks.length, _next + count);
    for (; _next < end; _next++) {
      _laid.add(_layout(widget.blocks[_next]));
    }
  }

  /// أول دفعة تُحسب فورًا، والباقي على دفعات صغيرة حتى لا تتجمّد الشاشة
  void _restart(BuildContext ctx, double avail, double base) {
    _gen++;
    _w = avail;
    _size = base;
    _style = _styleFor(ctx, base);
    _laid = [];
    _next = 0;
    _step(10);
    if (_next < widget.blocks.length) _pump(_gen);
  }

  Future<void> _pump(int gen) async {
    while (mounted && gen == _gen && _next < widget.blocks.length) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
      if (!mounted || gen != _gen) return;
      _step(8);
      setState(() {});
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

  Widget _heading(String t) {
    final p = currentPalette;
    return Column(
      children: [
        const OrnamentDivider(),
        const SizedBox(height: 10),
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
            _restart(ctx, c.maxWidth, base);
          }
          final gap = _size * .95;
          return Column(
            children: [
              for (var i = 0; i < _laid.length; i++) ...[
                if (i > 0) SizedBox(height: gap),
                _laid[i].block.heading
                    ? _heading(_laid[i].block.text)
                    : _paragraph(_laid[i]),
              ],
              if (_next < widget.blocks.length)
                const Padding(
                  padding: EdgeInsets.only(top: 18),
                  child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4)),
                )
              else
                SizedBox(height: gap * .4),
            ],
          );
        },
      ),
    );
  }
}
