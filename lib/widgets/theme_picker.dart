import 'package:flutter/material.dart';

import '../services/theme_controller.dart';

/// Lembar pilihan tema: warna Material 3 + mode terang/gelap/sistem.
Future<void> showThemePicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _ThemePickerSheet(),
  );
}

class _ThemePickerSheet extends StatelessWidget {
  const _ThemePickerSheet();

  @override
  Widget build(BuildContext context) {
    final ctrl = ThemeController.instance;
    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, _) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Tema Aplikasi',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                const Text('Pilihan disimpan dan dipakai saat aplikasi dibuka kembali.'),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (var i = 0; i < ThemeController.options.length; i++)
                      _Swatch(
                        option: ThemeController.options[i],
                        selected: ctrl.index == i,
                        onTap: () => ctrl.setIndex(i),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Mode tampilan',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('Sistem'),
                        icon: Icon(Icons.brightness_auto),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Terang'),
                        icon: Icon(Icons.light_mode),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Gelap'),
                        icon: Icon(Icons.dark_mode),
                      ),
                    ],
                    selected: {ctrl.mode},
                    onSelectionChanged: (s) => ctrl.setMode(s.first),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Swatch extends StatelessWidget {
  final AppThemeOption option;
  final bool selected;
  final VoidCallback onTap;

  const _Swatch({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 96,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? option.seed
                : Theme.of(context).colorScheme.outlineVariant,
            width: selected ? 2.5 : 1,
          ),
        ),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: option.seed,
              child: selected
                  ? const Icon(Icons.check, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 6),
            Text(
              option.nama,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
