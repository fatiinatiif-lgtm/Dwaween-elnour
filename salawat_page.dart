import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'main.dart';
import 'pdf_export.dart';

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
List<String> salawatBreakLines(String text, TextStyle st, double width) {
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

  // وضع اختيار الصيغ لحفظها كصورة (من 1 إلى 3)
  bool _selecting = false;
  final Set<int> _selected = {};

  String get _sub {
    final b = _blocks ?? const <SBlock>[];
    return widget.book.kind == SalawatKind.numbered
        ? '${arDigits(b.where((x) => x.number != null).length)} صلاة'
        : widget.book.blurb;
  }

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

  void _toggle(int i) {
    if (_selected.contains(i)) {
      setState(() => _selected.remove(i));
    } else if (_selected.length >= 3) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('الحد الأقصى ثلاث صيغ', textAlign: TextAlign.center),
          duration: Duration(seconds: 2),
        ));
    } else {
      setState(() => _selected.add(i));
    }
  }

  void _cancelSelect() => setState(() {
        _selecting = false;
        _selected.clear();
      });

  Future<void> _saveImage() async {
    final blocks = _blocks;
    if (blocks == null || _selected.isEmpty) return;
    final idx = _selected.toList()..sort();
    final items = [for (final i in idx) blocks[i]];
    final done = await showSalawatImageSheet(context, widget.book.title, items);
    if (done && mounted) _cancelSelect();
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
          PopupMenuButton<String>(
            tooltip: 'خيارات',
            icon: const Icon(Icons.more_vert_rounded),
            color: cream,
            onSelected: (v) {
              final blocks = _blocks;
              if (blocks == null) return;
              if (v == 'pdf') {
                showSalawatPdfSheet(context, book, blocks, _sub);
              } else if (v == 'image') {
                setState(() {
                  _selecting = true;
                  _selected.clear();
                });
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'pdf',
                child: Row(children: [
                  Icon(Icons.picture_as_pdf_rounded, color: brown),
                  const SizedBox(width: 10),
                  const Text('تحويل القسم إلى PDF'),
                ]),
              ),
              PopupMenuItem(
                value: 'image',
                child: Row(children: [
                  Icon(Icons.image_rounded, color: brown),
                  const SizedBox(width: 10),
                  const Text('حفظ صيغة أو أكثر كصورة'),
                ]),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _selecting
          ? Material(
              color: cream,
              elevation: 8,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selected.isEmpty
                              ? 'اضغطي على الصيغ (حتى ٣)'
                              : 'تم اختيار ${arDigits(_selected.length)} من ٣',
                          style: TextStyle(
                              color: brownDark, fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: _cancelSelect,
                        child: Text('إلغاء', style: TextStyle(color: brown)),
                      ),
                      const SizedBox(width: 6),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                            backgroundColor: brown,
                            foregroundColor: Colors.white),
                        onPressed: _selected.isEmpty ? null : _saveImage,
                        icon: const Icon(Icons.image_rounded),
                        label: const Text('حفظ كصورة'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
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
          return SalawatList(
            title: book.title,
            sub: _sub,
            colors: dc,
            blocks: blocks,
            selecting: _selecting,
            selected: _selected,
            onToggle: _toggle,
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
  final bool selecting;
  final Set<int> selected;
  final void Function(int) onToggle;
  const SalawatList({
    super.key,
    required this.title,
    required this.sub,
    required this.colors,
    required this.blocks,
    this.selecting = false,
    this.selected = const <int>{},
    required this.onToggle,
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
    final lines = salawatBreakLines(t, _style, _w);
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

  Widget _paragraph(_Laid l, int index) {
    final numbered = l.block.number != null;
    final col = Column(
      children: [
        for (var k = 0; k < l.lines.length; k++) ...[
          if (k > 0) SizedBox(height: _size * .62),
          _line(l.lines[k], numberedFirst: numbered && k == 0),
        ],
      ],
    );
    if (!widget.selecting) return col;
    // وضع الاختيار: الضغط على الصيغة يختارها (تتلوّن بالذهبي)
    final sel = widget.selected.contains(index);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onToggle(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: sel ? accentGold.withOpacity(.22) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: sel ? accentGold : accentGold.withOpacity(.3),
              width: sel ? 1.8 : 1),
        ),
        child: col,
      ),
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
          : _paragraph(_laidAt(i), i));
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
