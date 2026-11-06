import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main.dart';
import 'poems_extra.dart';

// ════════════════════════════════════════════════
// ملحوظاتي: أقسام، وداخل كل قسم عناصر (قصيدة من التطبيق أو نص نثر)
// تُحفظ تلقائيًا على الموبايل.
// ════════════════════════════════════════════════

class NoteItem {
  final String id;
  final bool isPoem; // قصيدة من التطبيق، أو نص كتبتِه بنفسك
  String title;
  String body; // للنص: المحتوى
  String diwan; // للقصيدة: اسم الديوان
  NoteItem({
    required this.id,
    required this.isPoem,
    required this.title,
    this.body = '',
    this.diwan = '',
  });

  Map<String, dynamic> toJson() =>
      {'id': id, 'poem': isPoem, 'title': title, 'body': body, 'diwan': diwan};

  static NoteItem fromJson(Map<String, dynamic> m) => NoteItem(
        id: '${m['id']}',
        isPoem: m['poem'] == true,
        title: '${m['title'] ?? ''}',
        body: '${m['body'] ?? ''}',
        diwan: '${m['diwan'] ?? ''}',
      );
}

class NoteSection {
  final String id;
  String name;
  List<NoteItem> items;
  NoteSection({required this.id, required this.name, List<NoteItem>? items})
      : items = items ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'items': items.map((e) => e.toJson()).toList(),
      };

  static NoteSection fromJson(Map<String, dynamic> m) => NoteSection(
        id: '${m['id']}',
        name: '${m['name'] ?? ''}',
        items: [
          for (final e in (m['items'] as List? ?? const []))
            NoteItem.fromJson(Map<String, dynamic>.from(e as Map)),
        ],
      );
}

final ValueNotifier<List<NoteSection>> notesSections =
    ValueNotifier<List<NoteSection>>([]);

int _idSeq = 0;
String _newId() => '${DateTime.now().microsecondsSinceEpoch}${_idSeq++}';

Future<void> loadNotes() async {
  try {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('notes_v1');
    if (raw == null || raw.isEmpty) return;
    final list = jsonDecode(raw) as List;
    notesSections.value = [
      for (final e in list)
        NoteSection.fromJson(Map<String, dynamic>.from(e as Map)),
    ];
  } catch (_) {
    // لو فشل التحميل يبدأ بدون ملحوظات
  }
}

Future<void> _persist() async {
  try {
    final p = await SharedPreferences.getInstance();
    await p.setString('notes_v1',
        jsonEncode(notesSections.value.map((s) => s.toJson()).toList()));
  } catch (_) {}
}

/// نسخة جديدة من القائمة ليتم الإشعار، ثم الحفظ
void _commit() {
  notesSections.value = List<NoteSection>.of(notesSections.value);
  _persist();
}

NoteSection? _sec(String id) {
  for (final s in notesSections.value) {
    if (s.id == id) return s;
  }
  return null;
}

void _addSection(String name) {
  notesSections.value.add(NoteSection(id: _newId(), name: name));
  _commit();
}

void _renameSection(String id, String name) {
  final s = _sec(id);
  if (s == null) return;
  s.name = name;
  _commit();
}

void _deleteSection(String id) {
  notesSections.value.removeWhere((s) => s.id == id);
  _commit();
}

void _addItem(String sectionId, NoteItem it) {
  _sec(sectionId)?.items.add(it);
  _commit();
}

void _removeItem(String sectionId, String itemId) {
  _sec(sectionId)?.items.removeWhere((i) => i.id == itemId);
  _commit();
}

void _moveItem(String fromId, String toId, NoteItem it) {
  final from = _sec(fromId), to = _sec(toId);
  if (from == null || to == null) return;
  from.items.removeWhere((i) => i.id == it.id);
  to.items.add(it);
  _commit();
}

bool _hasPoem(String sectionId, String diwan, String title) =>
    _sec(sectionId)
        ?.items
        .any((i) => i.isPoem && i.diwan == diwan && i.title == title) ??
    false;

String _itemsLabel(int n) {
  if (n == 0) return 'فارغ';
  if (n == 1) return 'عنصر واحد';
  if (n == 2) return 'عنصران';
  if (n <= 10) return '${arDigits(n)} عناصر';
  return '${arDigits(n)} عنصرًا';
}

String _preview(String body) {
  final t = body.replaceAll(RegExp(r'\s+'), ' ').trim();
  return t.length > 80 ? '${t.substring(0, 80)}…' : t;
}

String _firstLine(String body) {
  for (final l in body.split('\n')) {
    final t = l.trim();
    if (t.isNotEmpty) return t.length > 40 ? '${t.substring(0, 40)}…' : t;
  }
  return 'بدون عنوان';
}

// ───────────── حوارات صغيرة ─────────────

class _PromptDialog extends StatefulWidget {
  final String title;
  final String hint;
  final String initial;
  const _PromptDialog(
      {required this.title, required this.hint, this.initial = ''});
  @override
  State<_PromptDialog> createState() => _PromptDialogState();
}

class _PromptDialogState extends State<_PromptDialog> {
  late final TextEditingController _c =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.title),
        content: TextField(
          controller: _c,
          autofocus: true,
          decoration: InputDecoration(hintText: widget.hint),
          onSubmitted: (v) => Navigator.pop(context, v.trim()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(context, _c.text.trim()),
              child: const Text('حفظ')),
        ],
      );
}

Future<String?> _askText(BuildContext context,
    {required String title, required String hint, String initial = ''}) async {
  final r = await showDialog<String>(
    context: context,
    builder: (_) => _PromptDialog(title: title, hint: hint, initial: initial),
  );
  if (r == null || r.isEmpty) return null;
  return r;
}

Future<bool> _confirm(BuildContext context, String title, String msg) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(msg),
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
  return r ?? false;
}

// ───────────── المحتوى (يظهر داخل تبويب «ملحوظاتي» في المفضلة) ─────────────

class NotesContent extends StatefulWidget {
  const NotesContent({super.key});
  @override
  State<NotesContent> createState() => _NotesContentState();
}

class _NotesContentState extends State<NotesContent> {
  final Set<String> _collapsed = {};

  Future<void> _newSection() async {
    final name = await _askText(context,
        title: 'قسم جديد', hint: 'اسم القسم (مثال: قصائد أحبها)');
    if (name != null) _addSection(name);
  }

  Future<void> _sectionMenu(String v, NoteSection s) async {
    if (v == 'rename') {
      final name = await _askText(context,
          title: 'تعديل اسم القسم', hint: 'اسم القسم', initial: s.name);
      if (name != null) _renameSection(s.id, name);
    } else if (v == 'del') {
      final ok = await _confirm(context, 'حذف القسم',
          'سيُحذف القسم «${s.name}» وكل ما بداخله. هل أنتِ متأكدة؟');
      if (ok) _deleteSection(s.id);
    }
  }

  Future<void> _itemMenu(String v, NoteSection s, NoteItem it) async {
    if (v == 'edit') {
      _openEditor(s.id, it);
    } else if (v == 'move') {
      final others =
          notesSections.value.where((x) => x.id != s.id).toList();
      final to = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('نقل إلى قسم'),
          children: [
            for (final o in others)
              SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, o.id),
                  child: Text(o.name, style: const TextStyle(fontSize: 16))),
          ],
        ),
      );
      if (to != null) _moveItem(s.id, to, it);
    } else if (v == 'del') {
      final ok = await _confirm(context, 'حذف', 'حذف «${it.title}»؟');
      if (ok) _removeItem(s.id, it.id);
    }
  }

  void _openEditor(String sectionId, NoteItem? item) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => NoteEditorPage(sectionId: sectionId, item: item)));
  }

  void _openItem(NoteSection s, NoteItem it) {
    if (!it.isPoem) {
      _openEditor(s.id, it);
      return;
    }
    final list = poems[it.diwan];
    final idx = list?.indexWhere((p) => p.title == it.title) ?? -1;
    if (list == null || idx < 0) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
            content: Text('تعذّر العثور على القصيدة', textAlign: TextAlign.center)));
      return;
    }
    markLastRead(it.diwan, list[idx]);
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PoemPage(poem: list[idx], diwan: it.diwan)));
  }

  Widget _empty() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
        decoration: BoxDecoration(
          color: cream,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accentGold.withOpacity(.5)),
        ),
        child: Column(
          children: [
            Icon(Icons.edit_note_rounded, size: 56, color: accentGold),
            const SizedBox(height: 12),
            Text('ملحوظاتي',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: brown)),
            const SizedBox(height: 8),
            Text(
                'اعملي أقسامًا، وأضيفي فيها أي قصيدة من التطبيق أو أي كلام نثر تكتبينه.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.6, color: inkSoft)),
          ],
        ),
      );

  Widget _itemTile(NoteSection s, NoteItem it) {
    final sub = it.isPoem ? it.diwan : _preview(it.body);
    return InkWell(
      onTap: () => _openItem(s, it),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 8, 4, 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: it.isPoem ? brown : accentGold,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                  it.isPoem ? Icons.menu_book_rounded : Icons.notes_rounded,
                  color: Colors.white,
                  size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(it.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: ink)),
                  if (sub.isNotEmpty)
                    Text(sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: inkSoft)),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: brown),
              onSelected: (v) => _itemMenu(v, s, it),
              itemBuilder: (_) => [
                if (!it.isPoem)
                  const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                if (notesSections.value.length > 1)
                  const PopupMenuItem(value: 'move', child: Text('نقل إلى قسم')),
                const PopupMenuItem(value: 'del', child: Text('حذف')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(NoteSection s) {
    final open = !_collapsed.contains(s.id);
    return Container(
      key: ValueKey(s.id),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentGold.withOpacity(.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => setState(() {
                if (!_collapsed.remove(s.id)) _collapsed.add(s.id);
              }),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 4, 10),
                child: Row(
                  children: [
                    Icon(
                        open
                            ? Icons.folder_open_rounded
                            : Icons.folder_rounded,
                        color: accentGold,
                        size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name,
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: brown)),
                          Text(_itemsLabel(s.items.length),
                              style:
                                  TextStyle(fontSize: 12.5, color: inkSoft)),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert_rounded, color: brown),
                      onSelected: (v) => _sectionMenu(v, s),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'rename', child: Text('تعديل الاسم')),
                        PopupMenuItem(value: 'del', child: Text('حذف القسم')),
                      ],
                    ),
                    Icon(open
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            if (open) ...[
              Divider(height: 1, color: accentGold.withOpacity(.35)),
              for (final it in s.items) _itemTile(s, it),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    _PoemPickerPage(sectionId: s.id))),
                        icon: const Icon(Icons.menu_book_rounded, size: 19),
                        label: const Text('إضافة قصيدة'),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: brown,
                            side: BorderSide(
                                color: accentGold.withOpacity(.7))),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openEditor(s.id, null),
                        icon: const Icon(Icons.edit_note_rounded, size: 21),
                        label: const Text('إضافة نص'),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: brown,
                            side: BorderSide(
                                color: accentGold.withOpacity(.7))),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<List<NoteSection>>(
        valueListenable: notesSections,
        builder: (context, secs, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (secs.isEmpty) _empty() else for (final s in secs) _sectionCard(s),
            const SizedBox(height: 4),
            Center(
              child: FilledButton.icon(
                onPressed: _newSection,
                icon: const Icon(Icons.create_new_folder_rounded),
                label: const Text('قسم جديد'),
                style: FilledButton.styleFrom(
                    backgroundColor: brown, foregroundColor: Colors.white),
              ),
            ),
          ],
        ),
      );
}

// ───────────── اختيار قصائد من التطبيق ─────────────

class _PoemPickerPage extends StatefulWidget {
  final String sectionId;
  const _PoemPickerPage({required this.sectionId});
  @override
  State<_PoemPickerPage> createState() => _PoemPickerPageState();
}

class _PoemPickerPageState extends State<_PoemPickerPage> {
  final _q = TextEditingController();
  late final List<(String, Poem)> _all = [
    for (final e in poems.entries)
      for (final p in e.value) (e.key, p),
  ];

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  void _toggle(String diwan, Poem p) {
    if (_hasPoem(widget.sectionId, diwan, p.title)) {
      final sec = _sec(widget.sectionId);
      final it = sec?.items.firstWhere(
          (i) => i.isPoem && i.diwan == diwan && i.title == p.title);
      if (it != null) _removeItem(widget.sectionId, it.id);
    } else {
      _addItem(widget.sectionId,
          NoteItem(id: _newId(), isPoem: true, title: p.title, diwan: diwan));
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = normalizeArabic(_q.text);
    final shown = q.isEmpty
        ? _all
        : _all
            .where((e) =>
                normalizeArabic(e.$2.title).contains(q) ||
                normalizeArabic(e.$1).contains(q))
            .toList();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: brown,
        foregroundColor: Colors.white,
        title: const Text('إضافة قصائد', style: TextStyle(fontSize: 18)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: TextField(
              controller: _q,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'ابحثي بعنوان القصيدة أو الديوان',
                prefixIcon: Icon(Icons.search_rounded, color: brown),
                filled: true,
                fillColor: cream,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: accentGold.withOpacity(.6))),
              ),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<List<NoteSection>>(
              valueListenable: notesSections,
              builder: (context, _, __) => ListView.builder(
                itemCount: shown.length,
                itemBuilder: (_, i) {
                  final (diwan, p) = shown[i];
                  final on = _hasPoem(widget.sectionId, diwan, p.title);
                  return ListTile(
                    onTap: () => _toggle(diwan, p),
                    title: Text(p.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: ink)),
                    subtitle: Text(diwan,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: inkSoft)),
                    trailing: Icon(
                        on
                            ? Icons.check_circle_rounded
                            : Icons.add_circle_outline_rounded,
                        color: on ? Colors.green : accentGold),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────── كتابة / تعديل نص نثر ─────────────

class NoteEditorPage extends StatefulWidget {
  final String sectionId;
  final NoteItem? item;
  const NoteEditorPage({super.key, required this.sectionId, this.item});
  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late final TextEditingController _t =
      TextEditingController(text: widget.item?.title ?? '');
  late final TextEditingController _b =
      TextEditingController(text: widget.item?.body ?? '');

  @override
  void dispose() {
    _t.dispose();
    _b.dispose();
    super.dispose();
  }

  void _save() {
    final t = _t.text.trim();
    final b = _b.text.trim();
    if (t.isEmpty && b.isEmpty) {
      Navigator.pop(context);
      return;
    }
    final title = t.isNotEmpty ? t : _firstLine(b);
    final it = widget.item;
    if (it == null) {
      _addItem(widget.sectionId,
          NoteItem(id: _newId(), isPoem: false, title: title, body: b));
    } else {
      it.title = title;
      it.body = b;
      _commit();
    }
    Navigator.pop(context);
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: cream,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: accentGold.withOpacity(.6))),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: brown,
          foregroundColor: Colors.white,
          title: Text(widget.item == null ? 'نص جديد' : 'تعديل النص',
              style: const TextStyle(fontSize: 18)),
          actions: [
            TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded, color: Colors.white),
              label: const Text('حفظ', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              TextField(
                controller: _t,
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold, color: ink),
                decoration: _dec('العنوان (اختياري)'),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextField(
                  controller: _b,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline,
                  style: TextStyle(fontSize: 17, height: 1.8, color: ink),
                  decoration: _dec('اكتبي هنا: قصيدة، نثر، أي كلام…'),
                ),
              ),
            ],
          ),
        ),
      );
}
