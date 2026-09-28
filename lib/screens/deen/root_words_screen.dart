import 'package:flutter/material.dart';
import 'package:lifeos/services/arabic_seed.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/moon_background.dart';

class RootWordsScreen extends StatefulWidget {
  const RootWordsScreen({super.key});

  @override
  State<RootWordsScreen> createState() => _RootWordsScreenState();
}

class _RootWordsScreenState extends State<RootWordsScreen> {
  List<RootItem>? _roots;
  final Set<int> _open = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final roots = await ArabicSeed.roots();
    if (!mounted) return;
    setState(() => _roots = roots);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final roots = _roots;
    return AppBackground(
      child: Stack(
        children: [
          const MoonBackground(),
          SafeArea(
            child: roots == null
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    itemCount: roots.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('🌱 মূলধাতু (Root Words)', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.textPrimary)),
                              const SizedBox(height: 4),
                              Text('একই শিকড় থেকে কেমন উৎপন্ন হয় নানা শব্দ — বুঝতে পারলে শব্দ ধরে যাবে', style: TextStyle(fontSize: 12, height: 1.5, color: c.textSecondary)),
                            ],
                          ),
                        );
                      }
                      return _rootCard(c, roots[i - 1], i - 1);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _rootCard(AppColors c, RootItem r, int idx) {
    final open = _open.contains(idx);
    return Container(
      decoration: BoxDecoration(color: c.cardColor, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => setState(() {
                if (open) {
                  _open.remove(idx);
                } else {
                  _open.add(idx);
                }
              }),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: c.secondary.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(14)),
                      child: Text(r.root, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.secondary)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('মূল অর্থ: ${r.rootMeaning}', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: c.textPrimary)),
                          const SizedBox(height: 3),
                          Text('${r.derived.length}টি শাখা', style: TextStyle(fontSize: 11.5, color: c.textSecondary)),
                        ],
                      ),
                    ),
                    Icon(open ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: c.textSecondary),
                  ],
                ),
              ),
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  for (final d in r.derived)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(color: c.glow.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(9)),
                            child: const Center(child: Text('🌿', style: TextStyle(fontSize: 10))),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(d.arabic, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.textPrimary, height: 1.3)),
                                    const SizedBox(width: 8),
                                    Text(d.reading, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.glow)),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text('${d.bangla} — ${d.type}', style: TextStyle(fontSize: 12, height: 1.4, color: c.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}