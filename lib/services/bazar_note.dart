import 'package:lifeos/services/market_parser.dart' show marketEmoji;
import 'package:lifeos/services/price_parser.dart';
import 'package:lifeos/services/text_normalizer.dart';

/// 🛒 নোট → বাজার বোঝা (offline)। Note-ই entry point:
/// দাম-লাইনে (আজ ১ কেজি ইলিশ ১২০০ টাকা) → price এন্ট্রি + tree caption
/// প্রশ্ন/কেনা-লাইনে (আজ ৩টা ডিম কিনলাম / ৭টা ডিমের দাম কত) → আনুমানিক দর
class BazarLine {
  final String icon;
  final String item;
  final String main;
  final String sub;

  const BazarLine({
    required this.icon,
    required this.item,
    required this.main,
    required this.sub,
  });
}

final RegExp _clauseSplit = RegExp(r'\s*(তাহলে|তবে|তারপর|সুতরাং|হলে\s+কত)\s*');
final RegExp _dandaSplit = RegExp(r'[।!?]');
final RegExp _numRx = RegExp(r'\d+(\.\d+)?');

String _bd(double v) => v == v.roundToDouble()
    ? TextNormalizer.banglaDigits(v.toInt().toString())
    : TextNormalizer.banglaDigits(v.toString());

String _unitLabel(String u) => u == 'টা' || u == 'পিস' ? 'টা' : ' $u';

List<BazarLine> understandNote(String content, {bool save = false, String? noteId}) {
  final out = <BazarLine>[];
  final lines = content
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  if (save && noteId != null) {
    PriceStore.deleteBySource(noteId); // পুনরায় সম্পাদনা → sync
  }

  var clauseIdx = 0;
  for (var ln = 0; ln < lines.length; ln++) {
    final clauses = <String>[];
    for (final seg in lines[ln].split(_dandaSplit)) {
      clauses.addAll(seg.split(_clauseSplit).map((s) => s.trim()).where((s) => s.isNotEmpty));
    }
    for (final clause in clauses) {
      final got = _understandClause(clause,
          save: save, noteId: noteId, clauseIdx: clauseIdx++);
      if (got != null) out.add(got);
    }
  }
  return out;
}

BazarLine? _understandClause(
  String clause, {
  required bool save,
  String? noteId,
  required int clauseIdx,
}) {
  final norm = PriceParser.normalize(clause);
  if (norm.isEmpty) return null;

  final r = PriceParser.parse(clause);
  final item = r.item.trim();
  if (item.isEmpty || r.item == 'জিনিস') return null;
  if (item.length < 2) return null;

  final bojak = marketEmoji(item);
  final hasPriceWord = kMoneyRx.hasMatch(norm);
  final hasNum = _numRx.hasMatch(norm);
  final isQuery = r.isQuery;
  final isBuy = kBuyWords.any(norm.contains);

  // দাম-লাইন: টাকা/৳/দাম-শব্দসহ → price এন্ট্রি
  if (hasPriceWord && r.ok && r.total > 0) {
    final srcKey = noteId == null ? '' : '$noteId:$clauseIdx';
    if (save && noteId != null && !PriceStore.hasSource(srcKey)) {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      PriceStore.addEntry(PriceEntry(
        id: '$id$clauseIdx',
        item: item,
        qty: r.qty,
        unit: r.unit,
        total: r.total,
        time: DateTime.now().millisecondsSinceEpoch,
        src: srcKey,
      ));
    }
    return BazarLine(
      icon: bojak,
      item: item,
      main: '${_bd(r.qty)}${_unitLabel(r.unit)} $item = ${PriceFmt.tk2(r.total)}',
      sub: perDisplay(r.unit, r.total, r.qty),
    );
  }

  // প্রশ্ন/কেনা: দাম নেই → বাজার current দর থেকে আনুমানিক/জানানো
  if (!hasPriceWord && (isQuery || isBuy)) {
    final entries = PriceStore.forItem(item);
    if (entries.isEmpty) {
      if (!hasNum) {
        return BazarLine(
          icon: bojak,
          item: item,
          main: '$item — দর এখনো লেখা হয়নি',
          sub: 'লিখো: "১ কেজি $item ৫০ টাকা"',
        );
      }
      return BazarLine(
        icon: bojak,
        item: item,
        main: '${_bd(r.qty)}${_unitLabel(r.unit)} $item',
        sub: 'দর এখনো নেই — আনুমানিক দেখানো যাবে না',
      );
    }
    return estimateItemLine(item, qty: r.qty, unit: r.unit);
  }

  return null;
}

/// আইটেম+পরিমাণ → current সেরা দর থেকে আনুমানিক — Shopping List ও বাজার
/// (query) দুটোই এই একই অফলাইন হিসাব ব্যবহার করে।
BazarLine estimateItemLine(String item, {required double qty, required String unit}) {
  final entries = PriceStore.forItem(item);
  if (entries.isEmpty) {
    return BazarLine(
      icon: marketEmoji(item),
      item: item,
      main: '$item — দর এখনো লেখা হয়নি',
      sub: 'লিখো: "১ $unit $item ৫০ টাকা"',
    );
  }
  final sameUnit = entries.where((e) => e.unit == unit).toList();
  final ref = (sameUnit.isNotEmpty ? sameUnit : entries).first;
  final per = perBase(ref.unit, ref.total, ref.qty);
  return BazarLine(
    icon: marketEmoji(item),
    item: item,
    main: '${_bd(qty)}${_unitLabel(unit)} $item ≈ ${PriceFmt.tk2(qty * per)}',
    sub: 'দর: ${perDisplay(ref.unit, ref.total, ref.qty)}',
  );
}

/// আইটেমের আনুমানিক মোট (৳) — list-total হিসাবে; দর না থাকলে null।
double? estimateAmount(String item, {required double qty, required String unit}) {
  final entries = PriceStore.forItem(item);
  if (entries.isEmpty) return null;
  final sameUnit = entries.where((e) => e.unit == unit).toList();
  final ref = (sameUnit.isNotEmpty ? sameUnit : entries).first;
  final per = perBase(ref.unit, ref.total, ref.qty);
  return qty * per;
}