import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lifeos/phonex/device_api.dart';
import 'package:lifeos/phonex/phonex_engine.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  bool _loading = true;
  bool _access = false;
  List<InstalledApp> _apps = [];
  List<String> _locked = [];
  Map<String, int> _attempts = {};
  final _query = TextEditingController();

  Future<void> _load() async {
    setState(() => _loading = true);
    final apps = await DeviceApi.installedApps();
    final locked = await DeviceApi.lockedApps();
    final access = await DeviceApi.accessibilityEnabled();
    final attempts = <String, int>{};
    for (final p in locked) {
      attempts[p] = await DeviceApi.failedAttempts(p);
    }
    if (!mounted) return;
    setState(() {
      _apps = apps.map(InstalledApp.fromMap)
          .where((a) => a.pkg != 'com.lifeos.lifeos' && !a.pkg.contains('.launcher'))
          .toList()
        ..sort((a, b) => a.label.compareTo(b.label));
      _locked = locked;
      _attempts = attempts;
      _access = access;
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final filtered = _apps.where((a) {
      if (_query.text.isEmpty) return true;
      return a.label.toLowerCase().contains(_query.text.toLowerCase()) ||
          a.pkg.toLowerCase().contains(_query.text.toLowerCase());
    }).toList();

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('🔐 App Lock'),
          actions: [
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
          ],
        ),
        body: _loading
            ? Center(child: CircularProgressIndicator(color: c.primary))
            : RefreshIndicator(
                color: c.primary,
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _accessCard(context, c),
                    const SizedBox(height: 14),
                    _lockedSection(context, c),
                    const SizedBox(height: 14),
                    _searchRow(c),
                    const SizedBox(height: 10),
                    for (final a in filtered) _appRow(context, c, a),
                    const SizedBox(height: 10),
                    _privacyCard(c),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _accessCard(BuildContext context, AppColors c) {
    final ok = _access;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: ok ? [c.lowPriority.withValues(alpha: 0.2), c.surfaceColor]
              : [c.mediumPriority.withValues(alpha: 0.18), c.surfaceColor],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (ok ? c.lowPriority : c.mediumPriority).withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ok ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                  color: ok ? c.lowPriority : c.mediumPriority),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ok ? 'App Lock Service চালু' : 'Accessibility Service অন',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            ok
                ? 'লক করা অ্যাপ খুললে PIN স্ক্রিন দেখাবে। সেটিংসে গিয়ে LifeOS → যেতে toggle বন্ধ/চালু করতে পারো।'
                : 'লক কাজ করতে Accessibility Service দিন। নিচের বাটনে চাপলে সেটিংস খুলবে — সেখানে LifeOS অ্যাপ বেছে "Allow" করো। কোনো ব্যক্তিগত তথ্য পড়া হয় না, শুধু কোন অ্যাপ ফোরগ্রাউন্ডে আছে তা দেখা হয়।',
            style: TextStyle(fontSize: 12.5, color: c.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: ok ? null : () => DeviceApi.openAccessibilitySettings(),
              icon: const Icon(Icons.settings_rounded, size: 18),
              label: Text(ok ? 'কাজ করছে ✔' : 'Accessibility দিন'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lockedSection(BuildContext context, AppColors c) {
    if (_locked.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.cardColor.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_open_rounded, color: c.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text('নিচে কোনো অ্যাপ ট্যাপ করলে লক বসবে — আলাদা PIN দিন।',
                  style: TextStyle(fontSize: 13, color: c.textSecondary)),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surfaceColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('চালু লক — ${_locked.length}টি',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1, color: c.textPrimary)),
          const SizedBox(height: 10),
          for (final pkg in _locked)
            _lockedRow(context, c, pkg),
        ],
      ),
    );
  }

  Widget _lockedRow(BuildContext context, AppColors c, String pkg) {
    final label = _apps.firstWhere((a) => a.pkg == pkg,
        orElse: () => InstalledApp(pkg: pkg, label: medianLabel(pkg))).label;
    final attempts = _attempts[pkg] ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          _miniAvatar(c, label),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.textPrimary)),
                Text(
                  attempts > 0 ? '🚨 $attemptsটি ভুল চেষ্টা' : 'PIN সুরক্ষিত',
                  style: TextStyle(
                      fontSize: 11,
                      color: attempts > 0 ? c.highPriority : c.lowPriority),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _unlockContext(context, c, pkg),
            style: TextButton.styleFrom(
              foregroundColor: c.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            child: const Text('খুলে দাও'),
          ),
          IconButton(
            onPressed: () => _confirmRemove(context, c, pkg),
            icon: Icon(Icons.delete_outline_rounded, size: 20, color: c.textSecondary),
          ),
        ],
      ),
    );
  }

  Future<void> _unlockContext(BuildContext context, AppColors c, String pkg) async {
    final minutes = await _minutesDialog(context, c, title: 'কতক্ষণ খোলা রাখবে? (test)');
    if (minutes == null) return;
    await DeviceApi.unlockNow(pkg, minutes);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$pkg এখন খোলা (test)'), behavior: SnackBarBehavior.floating,
      backgroundColor: c.surfaceColor,
    ));
  }

  Widget _searchRow(AppColors c) {
    return TextField(
      controller: _query,
      onChanged: (_) => setState(() {}),
      style: TextStyle(color: c.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'অ্যাপ খুঁজো…  (যেমন bKash, Gallery)',
        hintStyle: TextStyle(color: c.textSecondary, fontSize: 13),
        prefixIcon: Icon(Icons.search_rounded, color: c.textSecondary, size: 20),
        filled: true,
        fillColor: c.surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _appRow(BuildContext context, AppColors c, InstalledApp app) {
    final isLocked = _locked.contains(app.pkg);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => isLocked ? _confirmRemove(context, c, app.pkg)
              : _setupLock(context, c, app),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: c.cardColor.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _miniAvatar(c, app.label),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(app.label,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.textPrimary)),
                      Text(app.pkg,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10, color: c.textSecondary)),
                    ],
                  ),
                ),
                Icon(isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                    size: 18, color: isLocked ? c.primary : c.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniAvatar(AppColors c, String label) {
    final ch = label.isEmpty ? '?' : label.substring(0, 1).toUpperCase();
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [c.primary, c.secondary],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(ch,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
    );
  }

  Future<void> _setupLock(BuildContext context, AppColors c, InstalledApp app) async {
    final pinCtrl = TextEditingController();
    final smartValue = ValueNotifier<int>(0);
    final pin = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: c.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${app.label} — লক করুন',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.textPrimary)),
              const SizedBox(height: 4),
              Text('4 ডিজিটের PIN দিন। প্রতি অ্যাপ-এ আলাদা PIN দেওয়া যায়।',
                  style: TextStyle(fontSize: 12, color: c.textSecondary)),
              const SizedBox(height: 14),
              TextField(
                controller: pinCtrl,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                style: TextStyle(color: c.textPrimary, fontSize: 18, letterSpacing: 8),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: '••••',
                  hintStyle: TextStyle(color: c.textSecondary, letterSpacing: 8),
                  filled: true,
                  fillColor: c.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<int>(
                valueListenable: smartValue,
                builder: (_, smart, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('স্মার্ট লক', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.textPrimary)),
                    const SizedBox(height: 6),
                    Wrap(spacing: 8, children: [
                      _smartChip(dialogCtx, c, smartValue, 0, 'প্রতিবার'),
                      _smartChip(dialogCtx, c, smartValue, 5, '৫ মিনিট'),
                      _smartChip(dialogCtx, c, smartValue, 15, '১৫ মিনিট'),
                      _smartChip(dialogCtx, c, smartValue, 30, '৩০ মিনিট'),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final p = pinCtrl.text.trim();
                    if (p.length != 4) {
                      ScaffoldMessenger.of(dialogCtx).showSnackBar(const SnackBar(
                          content: Text('4 ডিজিটের PIN দিন'),
                          behavior: SnackBarBehavior.floating));
                      return;
                    }
                    Navigator.pop(dialogCtx, p);
                  },
                  child: const Text('লক বন্ধ করো 🔒'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (pin == null) return;
    await DeviceApi.setLock(app.pkg, int.parse(pin), smartValue.value);
    await _load();
  }

  Widget _smartChip(BuildContext context, AppColors c, ValueNotifier<int> value, int v, String label) {
    return ChoiceChip(
      selected: value.value == v,
      onSelected: (_) => value.value = v,
      label: Text(label, style: TextStyle(fontSize: 12, color: c.textPrimary)),
      selectedColor: c.primary.withValues(alpha: 0.35),
      backgroundColor: c.cardColor,
      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
      visualDensity: VisualDensity.compact,
    );
  }

  Future<void> _confirmRemove(BuildContext context, AppColors c, String pkg) async {
    final label = _apps.firstWhere((a) => a.pkg == pkg,
        orElse: () => InstalledApp(pkg: pkg, label: medianLabel(pkg))).label;
    final yes = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: c.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('লক খুলবেন?', style: TextStyle(color: c.textPrimary, fontSize: 17)),
        content: Text('$label আর লক করা থাকবে না।', style: TextStyle(color: c.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('না')),
          FilledButton(onPressed: () => Navigator.pop(d, true),
              style: FilledButton.styleFrom(backgroundColor: c.highPriority),
              child: const Text('হ্যাঁ, খুলে দাও')),
        ],
      ),
    );
    if (yes == true) {
      await DeviceApi.removeLock(pkg);
      await _load();
    }
  }

  Future<int?> _minutesDialog(BuildContext context, AppColors c, {required String title}) async {
    final v = ValueNotifier<int>(5);
    final minutes = await showDialog<int>(
      context: context,
      builder: (d) => Dialog(
        backgroundColor: c.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.textPrimary)),
              const SizedBox(height: 12),
              ValueListenableBuilder<int>(
                valueListenable: v,
                builder: (_, val, _) => Wrap(spacing: 8, children: [
                  _smartChip(d, c, v, 1, '১ মিনিট'),
                  _smartChip(d, c, v, 5, '৫ মিনিট'),
                  _smartChip(d, c, v, 15, '১৫ মিনিট'),
                  _smartChip(d, c, v, 60, '১ ঘণ্টা'),
                ]),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(d), child: const Text('বাতিল')),
                  FilledButton(onPressed: () => Navigator.pop(d, v.value), child: const Text('ঠিক আছে')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return minutes;
  }

  Widget _privacyCard(AppColors c) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.mediumPriority.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.privacy_tip_rounded, color: c.mediumPriority, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'PIN লোকালে SHA-256 হ্যাশ হিসেবে রাখা হয় — কোথাও পাঠানো হয় না।\nবিকাশ/নগদ: LifeOS-এর লক অতিরিক্ত বাধা; অ্যাপের নিজের সিকিউরিটির বিকল্প নয়।',
              style: TextStyle(fontSize: 11.5, color: c.textSecondary, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}