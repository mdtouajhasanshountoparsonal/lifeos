import 'package:lifeos/services/arabic_quran_text.dart';
import 'package:lifeos/services/arabic_seed.dart';
import 'package:lifeos/services/deen_seed.dart';
import 'package:lifeos/services/deen_store.dart';

/// কঠিন ⚠️-চিহ্নিত আরবি এককগুলোকে এক জায়গায় নিয়ে আসা — যাত্রা ড্যাশবোর্ড আর
/// দুর্বলতা-চ্যালেঞ্জ দুই-ই এখান থেকে খায় (একই হিসাব, একই ক্রম নয়)।
/// শুধুই ব্যবহারকারীর নিজের চিহ্ন থেকে — কোনো কল্পিত তথ্য নয়।
class WeakItem {
  final String hardKey;
  final String knownKey;
  final String ar;
  final String reading;
  final String label;
  final String emoji;

  const WeakItem({
    required this.hardKey,
    required this.knownKey,
    required this.ar,
    required this.reading,
    required this.label,
    required this.emoji,
  });
}

class WeaknessService {
  WeaknessService._();

  /// বর্তমানে কঠিন-লিস্টে থাকা সব একক (শুধু জেনুইন/রেজোলভ-যোগ্য)।
  static Future<List<WeakItem>> load() async {
    final letters = await ArabicSeed.letters();
    final words = await ArabicSeed.words();
    final vocab = await ArabicSeed.vocab();
    final harakat = await ArabicSeed.harakat();
    final surahs = await DeenSeed.surahs();

    final byId = {for (final l in letters) l.id: l};
    final wordMap = {for (final w in words) w.id: w};
    final vocabMap = {for (final v in vocab) v.id: v};
    final harakMap = {for (final h in harakat) h.id: h};
    final surahByIndex = {for (final s in surahs) s.index: s};

    final weak = <WeakItem>[];
    for (final hk in DeenStore.arabicHard()) {
      if (hk.startsWith('hard:read:')) {
        final m = RegExp(r'^hard:read:(\d+):(\d+)$').firstMatch(hk);
        if (m == null) continue;
        final i = int.parse(m.group(1)!);
        final n = int.parse(m.group(2)!);
        final s = surahByIndex[i];
        if (s == null) continue;
        for (final ay in s.ayahs) {
          if (ay.n == n) {
            final stripped = stripBasmala(ay.ar, ay.tl, isFirstAyah: ay.n == 1);
            weak.add(
              WeakItem(
                hardKey: hk,
                knownKey: 'read:$i:$n',
                ar: stripped.ar,
                reading: stripped.tl,
                label: 'সূরা ${s.name} · আয়াত ${_bn(n)}',
                emoji: '🕌',
              ),
            );
            break;
          }
        }
      } else if (hk.startsWith('hard:vocab:')) {
        final v = vocabMap[hk.substring('hard:vocab:'.length)];
        if (v == null) continue;
        weak.add(
          WeakItem(
            hardKey: hk,
            knownKey: 'vocab:${v.id}',
            ar: v.arabic,
            reading: v.reading,
            label: 'কুরআন শব্দভাণ্ডার',
            emoji: '🗝️',
          ),
        );
      } else if (hk.startsWith('hard:')) {
        final w = wordMap[hk.substring('hard:'.length)];
        if (w == null) continue;
        weak.add(
          WeakItem(
            hardKey: hk,
            knownKey: w.id,
            ar: w.arabic,
            reading: w.reading,
            label: 'শব্দ চর্চা',
            emoji: '📖',
          ),
        );
      } else if (hk.startsWith('harak:')) {
        final h = harakMap[hk.substring('harak:'.length)];
        if (h == null) continue;
        weak.add(
          WeakItem(
            hardKey: hk,
            knownKey: hk,
            ar: h.mark,
            reading: '${h.name} — ${h.reading}',
            label: 'হরকত চেনা',
            emoji: '➰',
          ),
        );
      } else if (hk.startsWith('join')) {
        final parts = hk
            .substring(hk.startsWith('join0:') ? 6 : 5)
            .split(':')
            .map((p) => byId[p])
            .toList();
        if (parts.any((p) => p == null)) continue;
        final ls = parts.cast<ArabicLetterItem>();
        weak.add(
          WeakItem(
            hardKey: hk,
            knownKey: hk,
            ar: ls.map((l) => l.letter).join(),
            reading: ls.map((l) => l.reading).join(' · '),
            label: ls.length == 1 ? 'অ-যুক্ত অক্ষর' : 'জোড়া-যোগ',
            emoji: '🔗',
          ),
        );
      } else if (hk.startsWith('a:')) {
        final l = byId[hk.substring(2)];
        if (l == null) continue;
        weak.add(
          WeakItem(
            hardKey: hk,
            knownKey: hk,
            ar: l.letter,
            reading: l.reading,
            label: 'অক্ষর চেনা',
            emoji: '🔤',
          ),
        );
      }
    }
    return weak;
  }

  static String _bn(int n) {
    const bn = '০১২৩৪৫৬৭৮৯';
    return n.toString().split('').map((c) {
      final i = c.codeUnitAt(0);
      return i >= 0x30 && i <= 0x39 ? bn[i - 0x30] : c;
    }).join();
  }
}
