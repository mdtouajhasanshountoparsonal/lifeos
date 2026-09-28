import 'package:flutter/material.dart';
import 'package:lifeos/services/content_repository.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/moon_background.dart';

/// প্রথম রানে (বা নেট না থাকলে) কনটেন্ট ডাউনলোড-গেট।
/// সব deen/arabic কনটেন্ট GitHub `islamic_data` রিপো থেকে আসে — অ্যাপে bundle নেই।
class ContentGate extends StatefulWidget {
  final Widget child;

  const ContentGate({super.key, required this.child});

  @override
  State<ContentGate> createState() => _ContentGateState();
}

class _ContentGateState extends State<ContentGate> {
  late Future<void> _future;

  @override
  void initState() {
    super.initState();
    _future = ContentRepository.ensureReady();
  }

  Future<void> _retry() async {
    setState(() {
      _future = ContentRepository.ensureReady(force: true);
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return ValueListenableBuilder<ContentRepoState>(
      valueListenable: ContentRepository.state,
      builder: (context, st, _) {
        if (st.ready) return widget.child;
        return FutureBuilder<void>(
          future: _future,
          builder: (context, snap) {
            final err = st.error;
            return AppBackground(
              child: Stack(
                children: [
                  const MoonBackground(),
                  SafeArea(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🕌', style: TextStyle(fontSize: 44)),
                            const SizedBox(height: 14),
                            Text(
                              st.busy ||
                                      snap.connectionState ==
                                          ConnectionState.waiting
                                  ? 'কনটেন্ট নামছে…'
                                  : 'কনটেন্ট লাগবে',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: c.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              st.busy
                                  ? '${st.done} / ${st.total} — প্রথম রানে একবার ইন্টারনেট লাগবে; তারপর সম্পূর্ণ offline।'
                                  : 'দুআ, সূরা, আরবি লেসন — সব অ্যাপের বাইরে রাখা হয়েছে (রিপো থেকে নামে)।',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.55,
                                color: c.textSecondary,
                              ),
                            ),
                            if (st.busy) ...[
                              const SizedBox(height: 18),
                              LinearProgressIndicator(
                                value: st.total > 0 ? st.done / st.total : null,
                                minHeight: 6,
                                backgroundColor: c.surfaceColor,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  c.glow,
                                ),
                              ),
                            ],
                            if (err != null) ...[
                              const SizedBox(height: 14),
                              Text(
                                err,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.5,
                                  color: c.highPriority,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextButton.icon(
                                onPressed: _retry,
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: 18,
                                ),
                                label: const Text('আবার চেষ্টা করুন'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
