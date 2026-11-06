import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

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

  /// حفظ نسخة في الموبايل (تختارين المكان)
  static Future<void> exportCopy(BuildContext context, SavedFile f) async {
    final m = ScaffoldMessenger.of(context);
    try {
      final bytes = await f.file.readAsBytes();
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'حفظ نسخة في الموبايل',
        fileName: '${f.title}.${f.ext}',
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: [f.ext],
      );
      if (path != null) _toast(m, 'تم حفظ النسخة في الموبايل');
    } catch (_) {
      _toast(m, 'تعذّر حفظ النسخة');
    }
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
  const SavedFilesPage({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
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

  void _reload() {
    if (!mounted) return;
    setState(() => _future = SavedFiles.list(widget.kind));
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
          if (widget.kind == SavedKind.pdf) {
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              itemCount: items.length,
              itemBuilder: (_, i) => _pdfTile(context, items[i]),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 420 / 594,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) => _imageTile(context, items[i]),
          );
        },
      );

  Widget _pdfTile(BuildContext context, SavedFile f) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: cream,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentGold.withOpacity(.5)),
        ),
        child: ListTile(
          onTap: () => SavedFiles.open(context, f),
          leading: Container(
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
          trailing: PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: brown),
            onSelected: (v) async {
              if (v == 'open') {
                await SavedFiles.open(context, f);
              } else if (v == 'save') {
                await SavedFiles.exportCopy(context, f);
              } else if (v == 'del') {
                await SavedFiles.confirmAndDelete(context, f);
              }
            },
            itemBuilder: (_) => const [
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
        ),
      );

  Widget _imageTile(BuildContext context, SavedFile f) => GestureDetector(
        onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => _ImageViewer(f))),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accentGold.withOpacity(.6)),
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
