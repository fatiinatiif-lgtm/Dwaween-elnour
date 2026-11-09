import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'main.dart';

// ════════════════════════════════════════════════
// الملفات المحفوظة داخل التطبيق (PDF + صور)
// كل ملف يُنشأ يُحفظ هنا تلقائيًا، وتقدري تفتحيه أو تحفظي نسخة منه
// في الموبايل أو تحذفيه من صفحة "الملفات".
// ════════════════════════════════════════════════

enum SavedKind { pdf, image }

class SavedFile {
  final File file;
  final SavedKind kind;
  final String title;
  final DateTime date;
  final int size;
  const SavedFile(this.file, this.kind, this.title, this.date, this.size);

  String get ext => kind == SavedKind.pdf ? 'pdf' : 'png';

  /// اسم فريد للحفظ في الموبايل وللمشاركة: العنوان + التاريخ والوقت
  /// (فلا يتكرر اسم ملفين أبدًا ويتحفظ كل ملف مستقلًا)
  String get uniqueBase {
    String two(int n) => n.toString().padLeft(2, '0');
    final stamp = '${date.year}${two(date.month)}${two(date.day)}_'
        '${two(date.hour)}${two(date.minute)}${two(date.second)}';
    final name =
        SavedFiles._clean(title, kind == SavedKind.pdf ? 'قصيدة' : 'بيت');
    return '${name}_$stamp';
  }

  String get dateLabel {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${arDigits(date.day)} ${gregorianMonths[date.month - 1]} '
        '${arDigits(date.year)} - ${arDigits('${two(date.hour)}:${two(date.minute)}')}';
  }

  String get sizeLabel {
    if (size < 1024 * 1024) return '${arDigits((size / 1024).ceil())} ك.ب';
    return '${arDigits((size / (1024 * 1024)).toStringAsFixed(1))} م.ب';
  }
}

void _toast(ScaffoldMessengerState m, String text) => m
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(
      content: Text(text, textAlign: TextAlign.center),
      duration: const Duration(seconds: 3)));

class SavedFiles {
  /// يتغيّر رقمه كلما أُضيف ملف أو حُذف (لتتحدّث الصفحة)
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static Future<Directory> _dir(SavedKind k) async {
    final base = await getApplicationDocumentsDirectory();
    final d = Directory(
        '${base.path}${Platform.pathSeparator}${k == SavedKind.pdf ? 'saved_pdfs' : 'saved_images'}');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  static String _clean(String t, String fallback) {
    var n = t
        .replaceAll(RegExp(r'[\\/:*?"<>|\n\r]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'_{2,}'), '_')
        .trim();
    if (n.length > 60) n = n.substring(0, 60).trim();
    return n.isEmpty ? fallback : n;
  }

  /// يحفظ الملف داخل التطبيق. يرجع الملف أو null لو فشل.
  static Future<File?> save(
      SavedKind kind, String title, Uint8List bytes) async {
    try {
      final d = await _dir(kind);
      final ext = kind == SavedKind.pdf ? 'pdf' : 'png';
      final name = _clean(title, kind == SavedKind.pdf ? 'قصيدة' : 'بيت');
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final f = File('${d.path}${Platform.pathSeparator}${name}__$stamp.$ext');
      await f.writeAsBytes(bytes, flush: true);
      changes.value++;
      return f;
    } catch (_) {
      return null;
    }
  }

  static Future<List<SavedFile>> list(SavedKind kind) async {
    final out = <SavedFile>[];
    try {
      final d = await _dir(kind);
      final ext = kind == SavedKind.pdf ? '.pdf' : '.png';
      await for (final e in d.list()) {
        if (e is! File) continue;
        final fileName = e.path.split(Platform.pathSeparator).last;
        if (!fileName.toLowerCase().endsWith(ext)) continue;
        final base = fileName.substring(0, fileName.length - ext.length);
        var title = base;
        DateTime? date;
        final i = base.lastIndexOf('__');
        if (i > 0) {
          title = base.substring(0, i);
          final stamp = int.tryParse(base.substring(i + 2));
          if (stamp != null) date = DateTime.fromMillisecondsSinceEpoch(stamp);
        }
        date ??= (await e.lastModified());
        out.add(SavedFile(e, kind, title, date, await e.length()));
      }
    } catch (_) {}
    out.sort((a, b) => b.date.compareTo(a.date));
    return out;
  }

  static Future<void> open(BuildContext context, SavedFile f) async {
    final m = ScaffoldMessenger.of(context);
    try {
      final r = await OpenFilex.open(f.file.path);
      if (r.type != ResultType.done) {
        _toast(m, 'لا يوجد تطبيق على الموبايل لفتح ملفات PDF');
      }
    } catch (_) {
      _toast(m, 'تعذّر فتح الملف');
    }
  }

  /// مشاركة الملف (واتساب وغيره): تفتح قائمة المشاركة الخاصة بالموبايل.
  /// يُنسخ الملف مؤقتًا باسم القصيدة النظيف (بدون الرقم الخفي) قبل المشاركة.
  static Future<void> share(BuildContext context, SavedFile f) async {
    final m = ScaffoldMessenger.of(context);
    try {
      final tmp = await getTemporaryDirectory();
      final dir = Directory('${tmp.path}${Platform.pathSeparator}share');
      if (!await dir.exists()) await dir.create(recursive: true);
      final clean = f.uniqueBase;
      final copy = await f.file
          .copy('${dir.path}${Platform.pathSeparator}$clean.${f.ext}');
      await Share.shareXFiles(
        [
          XFile(copy.path,
              name: '$clean.${f.ext}',
              mimeType: f.kind == SavedKind.pdf ? 'application/pdf' : 'image/png')
        ],
        text: f.title,
      );
    } catch (_) {
      _toast(m, 'تعذّرت المشاركة');
    }
  }

  /// حفظ نسخة في الموبايل (تختارين المكان)
  static Future<void> exportCopy(BuildContext context, SavedFile f) async {
    final m = ScaffoldMessenger.of(context);
    try {
      final bytes = await f.file.readAsBytes();
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'حفظ نسخة في الموبايل',
        fileName: '${f.uniqueBase}.${f.ext}',
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: [f.ext],
      );
      if (path != null) _toast(m, 'تم حفظ النسخة في الموبايل');
    } catch (_) {
      _toast(m, 'تعذّر حفظ النسخة');
    }
  }

  /// اسم فريد داخل مجموعة (لو تكرر الاسم في نفس الثانية يُضاف رقم)
  static String _uniqueName(SavedFile f, Set<String> used) {
    final base = f.uniqueBase;
    var name = '$base.${f.ext}';
    var n = 2;
    while (!used.add(name)) {
      name = '${base}_$n.${f.ext}';
      n++;
    }
    return name;
  }

  /// مشاركة عدة ملفات دفعة واحدة، كل ملف باسم مختلف
  static Future<void> shareMany(
      BuildContext context, List<SavedFile> files) async {
    if (files.isEmpty) return;
    final m = ScaffoldMessenger.of(context);
    try {
      final tmp = await getTemporaryDirectory();
      final dir = Directory('${tmp.path}${Platform.pathSeparator}share_multi');
      if (await dir.exists()) await dir.delete(recursive: true);
      await dir.create(recursive: true);
      final used = <String>{};
      final xs = <XFile>[];
      for (final f in files) {
        final name = _uniqueName(f, used);
        final c = await f.file.copy('${dir.path}${Platform.pathSeparator}$name');
        xs.add(XFile(c.path,
            name: name,
            mimeType: f.kind == SavedKind.pdf ? 'application/pdf' : 'image/png'));
      }
      await Share.shareXFiles(xs);
    } catch (_) {
      _toast(m, 'تعذّرت المشاركة');
    }
  }

  /// حفظ عدة ملفات في الموبايل: تختارين مجلدًا مرة واحدة وتُحفظ كلها فيه
  /// (كل ملف باسم مختلف). لو رفض النظام المجلد نحفظ الباقي واحدًا واحدًا.
  static Future<void> saveMany(
      BuildContext context, List<SavedFile> files) async {
    if (files.isEmpty) return;
    if (files.length == 1) return exportCopy(context, files.first);
    final m = ScaffoldMessenger.of(context);
    String? dirPath;
    try {
      dirPath = await FilePicker.platform
          .getDirectoryPath(dialogTitle: 'اختاري مكان حفظ الملفات');
    } catch (_) {}
    if (dirPath == null) return;

    final used = <String>{};
    var saved = 0;
    try {
      for (final f in files) {
        final name = _uniqueName(f, used);
        await f.file.copy('$dirPath${Platform.pathSeparator}$name');
        saved++;
      }
      _toast(m, 'تم حفظ ${arDigits(saved)} ملف في الموبايل');
    } catch (_) {
      try {
        for (final f in files.sublist(saved)) {
          final name = _uniqueName(f, used);
          final p = await FilePicker.platform.saveFile(
            dialogTitle: 'حفظ نسخة في الموبايل',
            fileName: name,
            bytes: await f.file.readAsBytes(),
            type: FileType.custom,
            allowedExtensions: [f.ext],
          );
          if (p == null) break;
          saved++;
        }
        _toast(m, 'تم حفظ ${arDigits(saved)} ملف في الموبايل');
      } catch (_) {
        _toast(m, 'تعذّر حفظ الملفات');
      }
    }
  }

  /// حذف عدة ملفات بعد التأكيد
  static Future<bool> confirmAndDeleteMany(
      BuildContext context, List<SavedFile> files) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الملفات'),
        content:
            Text('هل تريدين حذف ${arDigits(files.length)} ملف من التطبيق؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف')),
        ],
      ),
    );
    if (ok != true) return false;
    for (final f in files) {
      try {
        if (await f.file.exists()) await f.file.delete();
      } catch (_) {}
    }
    changes.value++;
    return true;
  }

  /// يسأل ثم يحذف. يرجع true لو تم الحذف.
  static Future<bool> confirmAndDelete(
      BuildContext context, SavedFile f) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الملف'),
        content: Text('هل تريدين حذف «${f.title}» من التطبيق؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف')),
        ],
      ),
    );
    if (ok != true) return false;
    try {
      if (await f.file.exists()) await f.file.delete();
      changes.value++;
      return true;
    } catch (_) {
      return false;
    }
  }
}

// ════════════════════════════════════════════════
// صفحة "الملفات"
// ════════════════════════════════════════════════

class SavedFilesPage extends StatelessWidget {
  /// 0 = ملفات PDF، 1 = الصور
  final int initialTab;
  const SavedFilesPage({super.key, this.initialTab = 0});

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        initialIndex: initialTab,
        child: Scaffold(
          backgroundColor: beige,
          appBar: AppBar(
            title: const Text('الملفات',
                style: TextStyle(fontWeight: FontWeight.bold)),
            bottom: TabBar(
              indicatorColor: accentGold,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              dividerColor: Colors.transparent,
              labelStyle:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(
                    icon: Icon(Icons.picture_as_pdf_rounded),
                    text: 'ملفات PDF'),
                Tab(icon: Icon(Icons.image_rounded), text: 'الصور'),
              ],
            ),
          ),
          body: const TabBarView(children: [
            _SavedTab(SavedKind.pdf),
            _SavedTab(SavedKind.image),
          ]),
        ),
      );
}

class _SavedTab extends StatefulWidget {
  final SavedKind kind;
  const _SavedTab(this.kind);
  @override
  State<_SavedTab> createState() => _SavedTabState();
}

class _SavedTabState extends State<_SavedTab> {
  late Future<List<SavedFile>> _future = SavedFiles.list(widget.kind);

  // وضع التحديد (للمشاركة أو الحفظ في الموبايل أو الحذف)
  bool _selecting = false;
  final Set<String> _sel = {};

  bool _isSel(SavedFile f) => _sel.contains(f.file.path);

  void _toggle(SavedFile f) => setState(() {
        if (!_sel.remove(f.file.path)) _sel.add(f.file.path);
      });

  void _begin(SavedFile f) => setState(() {
        _selecting = true;
        _sel.add(f.file.path);
      });

  void _exitSelect() => setState(() {
        _selecting = false;
        _sel.clear();
      });

  void _reload() {
    if (!mounted) return;
    setState(() {
      _sel.removeWhere((p) => !File(p).existsSync());
      _future = SavedFiles.list(widget.kind);
    });
  }

  Widget _toolbar(List<SavedFile> items, List<SavedFile> chosen) {
    final all = chosen.length == items.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          if (!_selecting) ...[
            Text(
                '${arDigits(items.length)} ${widget.kind == SavedKind.pdf ? 'ملف' : 'صورة'}',
                style: TextStyle(color: inkSoft, fontWeight: FontWeight.w600)),
            const Spacer(),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                  foregroundColor: brown,
                  side: BorderSide(color: accentGold.withOpacity(.7))),
              onPressed: () => setState(() => _selecting = true),
              icon: const Icon(Icons.checklist_rounded, size: 20),
              label: const Text('تحديد'),
            ),
          ] else ...[
            Expanded(
              child: Text(
                chosen.isEmpty
                    ? 'اضغطي على الملفات لتحديدها'
                    : 'تم تحديد ${arDigits(chosen.length)} من ${arDigits(items.length)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: brownDark, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: () => setState(() {
                if (all) {
                  _sel.clear();
                } else {
                  _sel
                    ..clear()
                    ..addAll(items.map((f) => f.file.path));
                }
              }),
              child: Text(all ? 'إلغاء الكل' : 'تحديد الكل',
                  style: TextStyle(color: brown)),
            ),
            TextButton(
                onPressed: _exitSelect,
                child: Text('إلغاء', style: TextStyle(color: brown))),
          ],
        ],
      ),
    );
  }

  Widget _actionBar(List<SavedFile> chosen) {
    final none = chosen.isEmpty;
    final style = FilledButton.styleFrom(
        backgroundColor: brown, foregroundColor: Colors.white);
    return Material(
      color: cream,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: style,
                  onPressed:
                      none ? null : () => SavedFiles.shareMany(context, chosen),
                  icon: const Icon(Icons.share_rounded, size: 20),
                  label: const Text('مشاركة'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  style: style,
                  onPressed:
                      none ? null : () => SavedFiles.saveMany(context, chosen),
                  icon: const Icon(Icons.download_rounded, size: 20),
                  label: const Text('حفظ في الموبايل'),
                ),
              ),
              IconButton(
                tooltip: 'حذف المحدد',
                icon: Icon(Icons.delete_outline_rounded, color: brown),
                onPressed: none
                    ? null
                    : () async {
                        final ok =
                            await SavedFiles.confirmAndDeleteMany(context, chosen);
                        if (ok && mounted) _exitSelect();
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    SavedFiles.changes.addListener(_reload);
  }

  @override
  void dispose() {
    SavedFiles.changes.removeListener(_reload);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<SavedFile>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? const <SavedFile>[];
          if (items.isEmpty) return _EmptySaved(widget.kind);
          final chosen = [for (final f in items) if (_isSel(f)) f];
          final Widget body = widget.kind == SavedKind.pdf
              ? ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  itemCount: items.length,
                  itemBuilder: (_, i) => _pdfTile(context, items[i]),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 420 / 594,
                  ),
                  itemCount: items.length,
                  itemBuilder: (_, i) => _imageTile(context, items[i]),
                );
          return Column(
            children: [
              _toolbar(items, chosen),
              Expanded(child: body),
              if (_selecting) _actionBar(chosen),
            ],
          );
        },
      );

  Widget _pdfTile(BuildContext context, SavedFile f) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: cream,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: _isSel(f) ? brown : accentGold.withOpacity(.5),
              width: _isSel(f) ? 2 : 1),
        ),
        child: ListTile(
          onTap: () => _selecting ? _toggle(f) : SavedFiles.open(context, f),
          onLongPress: () => _selecting ? _toggle(f) : _begin(f),
          leading: _selecting
              ? Checkbox(
                  value: _isSel(f),
                  activeColor: brown,
                  onChanged: (_) => _toggle(f))
              : Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: brown, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.picture_as_pdf_rounded,
                color: Colors.white),
          ),
          title: Text(f.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.bold, color: ink)),
          subtitle: Text('${f.dateLabel}  •  ${f.sizeLabel}',
              style: TextStyle(color: inkSoft, fontSize: 12.5)),
          trailing: _selecting
              ? null
              : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'مشاركة',
                icon: Icon(Icons.share_rounded, color: brown),
                onPressed: () => SavedFiles.share(context, f),
              ),
              PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: brown),
            onSelected: (v) async {
              if (v == 'open') {
                await SavedFiles.open(context, f);
              } else if (v == 'share') {
                await SavedFiles.share(context, f);
              } else if (v == 'save') {
                await SavedFiles.exportCopy(context, f);
              } else if (v == 'del') {
                await SavedFiles.confirmAndDelete(context, f);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: 'share',
                  child: Row(children: [
                    Icon(Icons.share_rounded, size: 20),
                    SizedBox(width: 10),
                    Text('مشاركة'),
                  ])),
              PopupMenuItem(
                  value: 'open',
                  child: Row(children: [
                    Icon(Icons.open_in_new_rounded, size: 20),
                    SizedBox(width: 10),
                    Text('فتح'),
                  ])),
              PopupMenuItem(
                  value: 'save',
                  child: Row(children: [
                    Icon(Icons.download_rounded, size: 20),
                    SizedBox(width: 10),
                    Text('حفظ نسخة في الموبايل'),
                  ])),
              PopupMenuItem(
                  value: 'del',
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
      );

  Widget _imageTile(BuildContext context, SavedFile f) => GestureDetector(
        onTap: () => _selecting
            ? _toggle(f)
            : Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => _ImageViewer(f))),
        onLongPress: () => _selecting ? _toggle(f) : _begin(f),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: _isSel(f) ? brown : accentGold.withOpacity(.6),
                width: _isSel(f) ? 2.5 : 1),
            color: cream,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                f.file,
                fit: BoxFit.cover,
                cacheWidth: 500,
                errorBuilder: (_, __, ___) => Center(
                    child: Icon(Icons.broken_image_rounded, color: inkSoft)),
              ),
              if (_selecting)
                Positioned.fill(
                    child: Container(
                        color: _isSel(f)
                            ? accentGold.withOpacity(.28)
                            : Colors.black12)),
              if (_selecting)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(
                      _isSel(f)
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: _isSel(f) ? accentGold : Colors.white,
                      size: 28),
                ),
              if (!_selecting)
              Positioned(
                top: 6,
                right: 6,
                child: Material(
                  color: Colors.black45,
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'مشاركة',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.share_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () => SavedFiles.share(context, f),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 18, 8, 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black54],
                    ),
                  ),
                  child: Text(f.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );
}

class _EmptySaved extends StatelessWidget {
  final SavedKind kind;
  const _EmptySaved(this.kind);
  @override
  Widget build(BuildContext context) {
    final pdf = kind == SavedKind.pdf;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(pdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                size: 64, color: accentGold),
            const SizedBox(height: 14),
            Text(pdf ? 'لا توجد ملفات PDF محفوظة بعد' : 'لا توجد صور محفوظة بعد',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold, color: ink)),
            const SizedBox(height: 8),
            Text(
                pdf
                    ? 'أي قصيدة تحفظينها كملف PDF تظهر هنا تلقائيًا'
                    : 'أي بيت تحفظينه كصورة يظهر هنا تلقائيًا',
                textAlign: TextAlign.center,
                style: TextStyle(color: inkSoft)),
          ],
        ),
      ),
    );
  }
}

class _ImageViewer extends StatelessWidget {
  final SavedFile f;
  const _ImageViewer(this.f);

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text(f.title, overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(
              tooltip: 'مشاركة',
              icon: const Icon(Icons.share_rounded),
              onPressed: () => SavedFiles.share(context, f),
            ),
            IconButton(
              tooltip: 'حفظ نسخة في الموبايل',
              icon: const Icon(Icons.download_rounded),
              onPressed: () => SavedFiles.exportCopy(context, f),
            ),
            IconButton(
              tooltip: 'حذف',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () async {
                final done = await SavedFiles.confirmAndDelete(context, f);
                if (done && context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
        body: Center(
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 5,
            child: Image.file(f.file),
          ),
        ),
      );
}
