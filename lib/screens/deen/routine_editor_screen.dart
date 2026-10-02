import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/services/amal_routine.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/entrance_item.dart';
import 'package:lifeos/widgets/glass_card.dart';
import 'package:lifeos/widgets/moon_background.dart';

/// ⚙️ আমার রুটিন — ব্যবহারকারীর নিজের দৈনিক আমল-পরিকল্পনা সম্পাদনা।
///
/// নীতি:
///  • app সংখ্যা চাপিয়ে দেয় না — sourceRef থাকলে "source-ভিত্তিক" ব্যাজ,
///    নয়তো "আমার লক্ষ্য" ব্যাজ।
///  • Delete না করে enabled টগল — আইটেম সাময়িক বাদ দিলেও ডেটা থাকে।
class RoutineEditorScreen extends StatefulWidget {
  const RoutineEditorScreen({super.key});

  @override
  State<RoutineEditorScreen> createState() => _RoutineEditorScreenState();
}

class _RoutineEditorScreenState extends State<RoutineEditorScreen> {
  late List<AmalItem> _items;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _items = AmalRoutineStore.load();
  }

  void _markDirty() => _dirty = true;

  Future<void> _save() async {
    AmalRoutineStore.save(_items);
    _dirty = false;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('✓ রুটিন সংরক্ষিত'),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppTheme.of(context).surfaceColor,
      duration: const Duration(milliseconds: 900),
    ));
    Navigator.of(context).pop();
  }

  // ─── টগল / এডিট ─────────────────────────────────────────────────────────
  void _toggle(int index) {
    HapticFeedback.selectionClick();
    setState(() => _items[index] =
        _items[index].copyWith(enabled: !_items[index].enabled));
    _markDirty();
  }

  Future<void> _editItem(int index) async {
    final it = _items[index];
    final result = await showDialog<_ItemEdit>(
      context: context,
      builder: (_) => _ItemDialog(item: it),
    );
    if (result == null) return;
    setState(() {
      if (result.deleted) {
        _items.removeAt(index);
      } else {
        _items[index] = it.copyWith(
          title: result.title,
          target: result.target,
          clearReminder: true,
        );
      }
    });
    _markDirty();
  }

  Future<void> _addItem() async {
    final result = await showDialog<_ItemEdit>(
      context: context,
      builder: (_) => const _ItemDialog(),
    );
    if (result == null || result.title.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _items = [
        ..._items,
        AmalItem(
          id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
          type: AmalType.custom,
          title: result.title,
          target: result.target,
          isCounted: result.target > 1,
          emoji: '✦',
        ),
      ];
    });
    _markDirty();
  }

  void _move(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final it = _items.removeAt(oldIndex);
      _items.insert(newIndex, it);
    });
    _markDirty();
  }

  // ─── UI ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final enabledCount = [for (final i in _items) if (i.enabled) i].length;
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _confirmDiscard();
        if (leave == true && context.mounted) Navigator.of(context).pop();
      },
      child: AppBackground(
        child: Stack(
          children: [
            const MoonBackground(),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () async {
                            if (!_dirty) return Navigator.of(context).pop();
                            final leave = await _confirmDiscard();
                            if (leave == true && context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                          icon: Icon(Icons.arrow_back_rounded,
                              color: c.textSecondary),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            '⚙️ আমার রুটিন',
                            style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: c.textPrimary),
                          ),
                        ),
                        if (_dirty)
                          TextButton(
                            onPressed: _save,
                            style: TextButton.styleFrom(
                                foregroundColor: c.glow,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10)),
                            child: const Text('সংরক্ষণ',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
                    child: Text(
                      'তোমার নিজের বাছাই — কোনো সংখ্যা ধর্মীয় বাধ্যবাধকতা নয়।',
                      style: TextStyle(
                          fontSize: 11.5, color: c.textSecondary),
                    ),
                  ),
                  Expanded(
                    child: ListenableBuilder(
                      listenable: Hive.box('amal_routines').listenable(),
                      builder: (context, _) => ReorderableListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                        itemCount: _items.length,
                        onReorderItem: (oldIndex, newIndex) => _move(oldIndex, newIndex),
                        proxyDecorator: (child, index, animation) =>
                            AnimatedBuilder(
                          animation: animation,
                          builder: (context, _) => Material(
                            color: Colors.transparent,
                            elevation: 0,
                            child: child,
                          ),
                        ),
                        itemBuilder: (context, i) {
                          final it = _items[i];
                          return Padding(
                            key: ValueKey(it.id),
                            padding: const EdgeInsets.only(bottom: 8),
                            child: EntranceItem(
                              order: i,
                              child: _itemCard(c, i, it),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // নিচের ভাসমান Save + Add বার
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: c.glow,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _save,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        _dirty
                            ? 'সংরক্ষণ ($enabledCount আইটেম)'
                            : 'রুটিন সংরক্ষিত ($enabledCount আইটেম)',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: c.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _addItem,
                      child: Padding(
                        padding: const EdgeInsets.all(13),
                        child:
                            Icon(Icons.add_rounded, color: c.textPrimary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemCard(AppColors c, int i, AmalItem it) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderRadius: BorderRadius.circular(16),
      child: Row(
        children: [
          // checkbox = রুটিনে থাকবে কি না
          Checkbox(
            value: it.enabled,
            activeColor: c.glow,
            tristate: false,
            onChanged: (_) => _toggle(i),
          ),
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.glow.withValues(alpha: it.enabled ? 0.14 : 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              it.emoji ?? (it.isCounted ? '📿' : '✓'),
              style: TextStyle(
                  fontSize: 19,
                  color: it.enabled ? null : c.textSecondary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  it.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: it.enabled
                        ? c.textPrimary
                        : c.textSecondary.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (it.isCounted)
                      Text(
                        'লক্ষ্য ${_bn(it.target.toString())}',
                        style: TextStyle(
                            fontSize: 11, color: c.textSecondary),
                      )
                    else
                      Text(
                        'একবার করলেই সম্পন্ন',
                        style: TextStyle(
                            fontSize: 11, color: c.textSecondary),
                      ),
                    const SizedBox(width: 8),
                    _sourceBadge(c, it),
                  ],
                ),
              ],
            ),
          ),
          // Reorder handle
          ReorderableDragStartListener(
            index: i,
            child: Icon(Icons.drag_indicator_rounded,
                size: 18, color: c.textSecondary.withValues(alpha: 0.5)),
          ),
          IconButton(
            onPressed: () => _editItem(i),
            icon: Icon(Icons.edit_rounded,
                size: 18, color: c.textSecondary.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

  Widget _sourceBadge(AppColors c, AmalItem it) {
    final hasSource = it.sourceRef != null && it.sourceRef!.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: hasSource
            ? c.lowPriority.withValues(alpha: 0.14)
            : c.textSecondary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        hasSource ? 'source-ভিত্তিক · ${it.sourceRef}' : 'আমার লক্ষ্য',
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: hasSource ? c.lowPriority : c.textSecondary,
        ),
      ),
    );
  }

  Future<bool?> _confirmDiscard() {
    final c = AppTheme.of(context);
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.surfaceColor,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Text(
          'অসংরক্ষিত পরিবর্তন আছে — বন্ধ করব?',
          style: TextStyle(fontSize: 14, color: c.textPrimary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('না')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: c.expense),
            child: const Text('বাদ দাও'),
          ),
        ],
      ),
    );
  }
}

// ─── আইটেম এডিট/তৈরির ডায়ালগ ─────────────────────────────────────────────
class _ItemEdit {
  final String title;
  final int target;
  final bool deleted;
  const _ItemEdit(this.title, this.target, {this.deleted = false});
}

class _ItemDialog extends StatefulWidget {
  final AmalItem? item; // null = নতুন
  const _ItemDialog({this.item});

  @override
  State<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<_ItemDialog> {
  late final TextEditingController _name;
  late final TextEditingController _target;
  bool _counted = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.item?.title ?? '');
    _target = TextEditingController(
        text: (widget.item?.target ?? 33).toString());
    _counted = widget.item?.isCounted ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final isNew = widget.item == null;
    return AlertDialog(
      backgroundColor: c.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(isNew ? 'নতুন আমল' : 'আমল সম্পাদনা',
          style: const TextStyle(fontSize: 16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: isNew,
            style: TextStyle(color: c.textPrimary),
            decoration: InputDecoration(
              hintText: 'নাম (যেমন: দরূদ শরীফ)',
              hintStyle: TextStyle(
                  fontSize: 13,
                  color: c.textSecondary.withValues(alpha: 0.7)),
              filled: true,
              fillColor: c.cardColor,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _modeChip(c, '☑ চেকলিস্ট', !_counted),
              const SizedBox(width: 8),
              _modeChip(c, '🔢 গণনা', _counted),
            ],
          ),
          if (_counted) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _target,
              keyboardType: TextInputType.number,
              style: TextStyle(color: c.textPrimary),
              decoration: InputDecoration(
                hintText: 'লক্ষ্য সংখ্যা',
                hintStyle: TextStyle(
                    fontSize: 13,
                    color: c.textSecondary.withValues(alpha: 0.7)),
                filled: true,
                fillColor: c.cardColor,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (!isNew)
          TextButton(
            onPressed: () =>
                Navigator.pop(context, const _ItemEdit('', 1, deleted: true)),
            style: TextButton.styleFrom(foregroundColor: c.expense),
            child: const Text('মুছুন'),
          ),
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('বাতিল')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: c.glow),
          onPressed: () {
            final t = int.tryParse(_target.text.trim()) ?? 1;
            Navigator.pop(
              context,
              _ItemEdit(_name.text.trim(), t.clamp(1, 100000)),
            );
          },
          child: const Text('ঠিক আছে'),
        ),
      ],
    );
  }

  Widget _modeChip(AppColors c, String label, bool selected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _counted = label.contains('গণনা')),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? c.glow : c.cardColor,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.black : c.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

String _bn(String s) {
  const bn = '০১২৩৪৫৬৭৮৯';
  return s.split('').map((ch) {
    final i = ch.codeUnitAt(0);
    return i >= 0x30 && i <= 0x39 ? bn[i - 0x30] : ch;
  }).join();
}
