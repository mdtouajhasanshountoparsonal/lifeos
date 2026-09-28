import 'package:flutter/material.dart';
import 'package:lifeos/services/arabic_seed.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/moon_background.dart';

class ContentStoreScreen extends StatefulWidget {
  const ContentStoreScreen({super.key});

  @override
  State<ContentStoreScreen> createState() => _ContentStoreScreenState();
}

class _ContentStoreScreenState extends State<ContentStoreScreen> {
  List<ContentFileItem>? _files;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final files = await ArabicSeed.manifest();
    if (!mounted) return;
    setState(() => _files = files);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final files = _files;
    return AppBackground(
      child: Stack(
        children: [
          const MoonBackground(),
          SafeArea(
            child: files == null
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    children: [
                      Text('🗂️ কনটেন্ট-স্টোর', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.textPrimary)),
                      const SizedBox(height: 4),
                      Text('সব শিখা-সম্পদ এই বান্ডলে আছে — অফলাইনে কাজ করে।', style: TextStyle(fontSize: 12, height: 1.5, color: c.textSecondary)),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: c.cardColor, borderRadius: BorderRadius.circular(14)),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 22),
                            const SizedBox(width: 10),
                            Text('কনটেন্ট-বান্ডল v1 — ${files.length}টি ফাইল', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c.textPrimary)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      for (final f in files)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: c.cardColor, borderRadius: BorderRadius.circular(14)),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(f.kind, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: c.textPrimary)),
                                    const SizedBox(height: 2),
                                    Text('${f.count}টি • ${f.source} • v${f.version}', style: TextStyle(fontSize: 11, color: c.textSecondary)),
                                  ],
                                ),
                              ),
                              Icon(Icons.cloud_done_rounded, size: 18, color: c.glow),
                            ],
                          ),
                        ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: c.secondary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                        child: Text('ভবিষ্যৎ (M9.2): GitHub-এ একটি কনটেন্ট-রিপো বাঁধা হলে ইন্টারনেটে নতুন শব্দ/পাঠ ডাউনলোড করা যাবে। সেটা এখনো বাঁধা হয়নি — তাই এখন সব বান্ডলেই আছে।', style: TextStyle(fontSize: 11.5, height: 1.6, color: c.secondary)),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}