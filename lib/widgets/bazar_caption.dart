import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/services/bazar_note.dart';
import 'package:lifeos/theme/app_theme.dart';

/// 🛒 নোটের নিচে ছোট্ট "বাজার-বুঝলাম" caption — icon + tree-র মতো, লাইভ।
/// Note-এর আসল লেখা বদলায় না; যেটা বুঝল, সেটাই দেখায়।
class BazarCaption extends StatelessWidget {
  final String noteId;
  final String content;

  const BazarCaption({super.key, required this.noteId, required this.content});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return ValueListenableBuilder(
      valueListenable: Hive.box('prices').listenable(),
      builder: (context, Box box, _) {
        final lines = understandNote(content);
        if (lines.isEmpty) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
          decoration: BoxDecoration(
            color: c.cardColor.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.glow.withValues(alpha: 0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🛒', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 5),
                  Text('বাজার-বুঝলাম',
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: c.glow)),
                ],
              ),
              for (var i = 0; i < lines.length; i++)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lines[i].icon, style: const TextStyle(fontSize: 12.5)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(lines[i].main,
                                style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: c.textPrimary)),
                            Text(lines[i].sub,
                                style: TextStyle(
                                    fontSize: 10.5,
                                    color: c.textSecondary.withValues(
                                        alpha: 0.9))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}