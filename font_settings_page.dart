import 'package:flutter/material.dart';
import 'arabic_text.dart';
import 'constants.dart';
import 'font_settings.dart';
import 'poem_view.dart';
import 'poems_data.dart';

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
                fontSize: 17, fontWeight: FontWeight.bold, color: appGreen)),
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
          side: BorderSide(color: appGold.withOpacity(.6)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: Row(
              children: [
                Icon(icon, color: appGreen, size: 28),
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
    final choice = await showModalBottomSheet<FontChoice>(
      context: context,
      backgroundColor: const Color(0xFFFFFBF2),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 10),
          children: [
            for (final c in fontChoices)
              ListTile(
                title: Text(c.label),
                trailing: poemFontFamily.value == c.family
                    ? const Icon(Icons.check_circle, color: appGreen)
                    : null,
                onTap: () => Navigator.pop(ctx, c),
              ),
          ],
        ),
      ),
    );
    if (choice == null) return;
    poemFontFamily.value = choice.family;
  }

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
                            backgroundColor: appGreen,
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
                              color: appGreen)),
                    ),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                            backgroundColor: appGreen,
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

            // ── نوع الخط ──
            _title('نوع الخط'),
            ListenableBuilder(
              listenable: poemFontFamily,
              builder: (_, __) => _optionButton(
                icon: Icons.font_download_rounded,
                title: 'اختيار نوع الخط',
                trailing: Text(
                    fontChoices
                        .firstWhere((c) => c.family == poemFontFamily.value,
                            orElse: () => fontChoices.first)
                        .label,
                    style: const TextStyle(color: Colors.black54)),
                onTap: () => _pickFont(context),
              ),
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
                    backgroundColor: appGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14));
                ButtonStyle outlined() => OutlinedButton.styleFrom(
                    foregroundColor: appGreen,
                    side: const BorderSide(color: appGreen),
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
