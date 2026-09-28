import 'package:flutter/material.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'nova_mods_calc.dart' show CalcTab;
import 'nova_mods_b.dart' show PhysicsTab, MatrixTab, ChemTab, UnitsTab;
import 'nova_mods_c.dart' show StatsTab, ConstantsTab, SimTab, HistoryTab;
import 'nova_mods_calculus.dart' show CalculusTab;
import 'nova_mods_graph.dart' show GraphTab;
import 'nova_mods_sketch.dart' show SimpleCalcTab;

const List<(String, IconData)> _modules = [
  ('মূল', Icons.calculate_outlined),
  ('সিম্পল ক্যালকুলেটর', Icons.draw_rounded),
  ('গ্রাফ', Icons.stacked_line_chart),
  ('ক্যালকুলাস', Icons.functions),
  ('ম্যাট্রিক্স', Icons.grid_on),
  ('ফিজিক্স', Icons.speed),
  ('রসায়ন', Icons.science_outlined),
  ('ইউনিট', Icons.straighten),
  ('পরিসংখ্যান', Icons.bar_chart),
  ('সিমুলেশন', Icons.rocket_launch_outlined),
  ('ধ্রুবক', Icons.data_array),
  ('ইতিহাস', Icons.history),
];

class NovaScreen extends StatefulWidget {
  const NovaScreen({super.key});
  @override
  State<NovaScreen> createState() => _NovaScreenState();
}

class _NovaScreenState extends State<NovaScreen> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: c.glow.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: c.glow.withValues(alpha: 0.5)),
                          ),
                          child: Text('NOVA', style: TextStyle(color: c.primary, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2)),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.of(context).maybePop(),
                          child: Icon(Icons.close, color: c.textSecondary, size: 22),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('সায়েন্স ওয়ার্কস্পেস', style: TextStyle(color: c.textPrimary, fontSize: 26, fontWeight: FontWeight.w900)),
                    Text('Calculate → Understand → Visualize → Simulate',
                        style: TextStyle(color: c.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (int i = 0; i < _modules.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => index = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: index == i ? c.primary : c.cardColor.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(20),
                              border: index == i ? null : Border.all(color: c.primary.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              children: [
                                Icon(_modules[i].$2, size: 16, color: index == i ? Colors.black : c.primary),
                                const SizedBox(width: 6),
                                Text(_modules[i].$1,
                                    style: TextStyle(
                                        color: index == i ? Colors.black : c.textPrimary,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: IndexedStack(
                  index: index,
                  children: const [
                    CalcTab(),
                    SimpleCalcTab(),
                    GraphTab(),
                    CalculusTab(),
                    MatrixTab(),
                    PhysicsTab(),
                    ChemTab(),
                    UnitsTab(),
                    StatsTab(),
                    SimTab(),
                    ConstantsTab(),
                    HistoryTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}