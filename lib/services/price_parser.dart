import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/services/market_parser.dart' show marketEmoji;
import 'package:lifeos/services/tree_text_parser.dart';
import 'package:lifeos/services/text_normalizer.dart';

/// 🧾 বাজার ডায়েরি — "১ হালি ডিম ৫০ টাকা" বোঝা, হিসাব, tree-বানানো।
/// সব অফলাইন (Hive) — কিছুই ক্লাউডে যায় না।

/// ইউনিট → কয়টা (per-unit রূপান্তরের জন্য)।
const Map<String, double> unitQty = {
  'হালি': 4,
  'ডজন': 12,
  'জোড়া': 2,
  'কুড়ি': 20,
  'আধা ডজন': 6,
  'শ': 100,
  'আধা শ': 50,
  'কেজি': 1,
  'আধা কেজি': 0.5,
  'লিটার': 1,
  'পিস': 1,
  'টা': 1,
  'টুকরা': 1,
  'বোতল': 1,
  'প্যাকেট': 1,
  'প্যাক': 1,
  'মিটার': 1,
  'ভরি': 1,
  'তোলা': 1,
  'মন': 40,
};

/// ভগ্নাংশ সংখ্যা-শব্দ → মান (দেড় কেজি = 1.5 কেজি)।
const Map<String, double> _fractionParts = {
  'আধা': 0.5,
  'সোয়া': 1.25,
  'দেড়': 1.5,
  'আড়াই': 2.5,
};

const List<String> _unitWords = [
  'আধা ডজন', 'আধা কেজি', 'আধা শ', 'হালি', 'ডজন', 'জোড়া', 'কুড়ি', 'কেজি', 'শ', 'লিটার',
  'পিস', 'টুকরা', 'টা', 'বোতল', 'প্যাকেট', 'প্যাক', 'মিটার', 'ভরি', 'তোলা', 'মন'
];

const List<String> _priceWords = [
  'টাকা', '৳', 'দাম', 'দরে', 'মূল্য', 'মুল্য', 'বায়', 'বিড়া', 'টাকার',
  'বাজার', 'বাজারের', 'দর', 'দার', 'রে', 'আছে', 'হবে', 'দিয়ার', 'নেট'
];

const List<String> _queryWords = [
  'কিনব', 'কিনি', 'কিনবো', 'কেনা', 'কেনো', 'কত', 'খাবে', 'খাবো', 'মোরে', 'দেবেন'
];

/// নোট-প্রসঙ্গের আবর্জনা (আজ/গতকাল/থেকে...) — item-এ যেন না ঢোকে।
const List<String> kContextWords = [
  'আজ', 'গতকাল', 'পরশু', 'কাল', 'বাজারে', 'বাজার থেকে', 'থেকে', 'সাথে', 'নিয়ে',
  'নিচ্ছি', 'করে', 'দিয়ে', 'একদম', 'গিয়ে', 'হইছে', 'হবে', 'আছে', 'দিয়েছি', 'পড়েছে'
];

/// কেনা/প্রশ্ন নির্দেশক শব্দ (দাম-শব্দ ছাড়া বাক্য → estimate)।
const List<String> kBuyWords = [
  'কিনলাম', 'কিনেছি', 'কিনে', 'কিনব', 'কিনবো', 'কিনি', 'কেনা', 'কেনো', 'নিলাম',
  'নিয়েছি', 'নিলে', 'নেবো', 'নেব', 'নিব', 'নিতে', 'লাগবে', 'লাগলে', 'লাগে', 'দরকার',
  'আনলাম', 'এনেছি', 'আনব', 'এনে', 'নাখি', 'নেবে'
];

const List<String> kUnitWords = _unitWords;

/// টাকা-চিহ্ন নিয়ে আসা দাম (moneyRe)।
final RegExp kMoneyRx =
    RegExp(r'(\d+(\.\d+)?)\s*(টাকা|৳|দাম|দরে|টাকার|বায়|মূল্য|মুল্য)');

/// ইংরেজি/বাংলিশ শব্দ → বাংলা (ঢালাওভাবে লেখা "1 hali dimer dam 50 taka"-ও কাজ করবে)।
const Map<String, String> _enMap = {
  // লম্বা → ছোট ক্রমে replace হয় (হালি-er আগে হালি)।
  'hali-er': 'হালির', 'halir': 'হালির', 'haler': 'হালির', 'hali': 'হালি',
  'aadha dozen': 'আধা ডজন', 'dozener': 'ডজন', 'dozen': 'ডজন',
  'kilogram': 'কেজি', 'killo': 'কেজি', 'kilo': 'কেজি', 'kg': 'কেজি', 'keg': 'কেজি',
  'litre': 'লিটার', 'liter': 'লিটার', 'ltr': 'লিটার',
  'pieces': 'পিস', 'piece': 'পিস', 'pcs': 'পিস', 'pc': 'পিস', 'pike': 'পিস',
  'taker': 'টাকার', 'taka': 'টাকা', 'tks': 'টাকা', 'tk': 'টাকা',
  'damer': 'দাম', 'dam': 'দাম', 'price': 'দাম', 'dar': 'দাম', 'dore': 'দরে',
  'kinbo': 'কিনব', 'kinb': 'কিনব', 'kenbo': 'কিনব', 'keno': 'কেনো', 'kena': 'কেনা',
  'koto': 'কত', 'kot': 'কত',
  'shoti': 'শ', 'sh': 'শ', 'so': 'শ',
  // বাংলিশ খাদ্য-নাম (offline-ই ঠিক হবে)
  'dimer': 'ডিম', 'dim': 'ডিম', 'anda': 'ডিম', 'dayim': 'ডিম',
  'murgir': 'মুরগির', 'murgi': 'মুরগি', 'gorur': 'গরুর', 'goru': 'গরু',
  'khasir': 'খাসির', 'masher': 'মাছের', 'mach': 'মাছ', 'macher': 'মাছ',
  'kola': 'কলা', 'apple': 'আপেল', 'lebu': 'লেবু', 'pape': 'পেঁপে',
  'alu': 'আলু', 'begun': 'বেগুন', 'tomato': 'টমেটো', 'piyaj': 'পেঁয়াজ',
  'chal': 'চাল', 'chawal': 'চাল', 'dal': 'ডাল', 'chini': 'চিনি', 'lobon': 'লবণ',
};

String _enToBn(String s) {
  var out = s;
  final keys = _enMap.keys.toList()..sort((a, b) => b.length - a.length);
  for (final k in keys) {
    out = out.replaceAll(RegExp('\\b${RegExp.escape(k)}\\b'), _enMap[k]!);
  }
  return out;
}

String _enDigits(String s) => s.replaceAllMapped(RegExp('[০-৯]'),
    (m) => String.fromCharCode(m.group(0)!.codeUnitAt(0) - 0x09e6));

String _trimPunct(String s) =>
    s.replaceAll(RegExp(r"[,:।.!?()xX×–—`'-]"), ' ');

/// একটি সংরক্ষিত দর।
class PriceEntry {
  final String id;
  final String item;
  final double qty;
  final String unit;
  final double total;
  final int time;
  final String src;

  const PriceEntry({
    required this.id,
    required this.item,
    required this.qty,
    required this.unit,
    required this.total,
    required this.time,
    this.src = '',
  });

  double get per => qty > 0 ? total / qty : total;

  Map<String, dynamic> toMap() => {
        'id': id,
        'item': item,
        'qty': qty,
        'unit': unit,
        'total': total,
        'time': time,
        'src': src,
      };

  factory PriceEntry.fromMap(dynamic src) {
    final m = src is Map ? src : const <dynamic, dynamic>{};
    return PriceEntry(
      id: '${m['id'] ?? DateTime.now().millisecondsSinceEpoch}',
      item: '${m['item'] ?? ''}',
      qty: (m['qty'] is num) ? (m['qty'] as num).toDouble() : 1,
      unit: '${m['unit'] ?? 'পিস'}',
      total: (m['total'] is num) ? (m['total'] as num).toDouble() : 0,
      time: (m['time'] is num) ? (m['time'] as num).toInt() : 0,
      src: '${m['src'] ?? ''}',
    );
  }
}

/// Parse-ফলাফল — সেভ না হলে query।
class PriceResult {
  final String item;
  final double qty;
  final String unit;
  final double total;
  final bool isQuery;
  final bool ok;
  const PriceResult({
    required this.item,
    required this.qty,
    required this.unit,
    required this.total,
    required this.isQuery,
    required this.ok,
  });
}

class PriceParser {
  PriceParser._();

  static String normalize(String raw) => _trimPunct(
          _enDigits(_enToBn(raw.trim().toLowerCase())))
      .replaceAll(RegExp(r'(\d)টি(র)?'), r'$1 টা');

  static PriceResult parse(String raw) {
    final src = normalize(raw);
    final isQuery = _queryWords.any(src.contains) || RegExp(r'কত').hasMatch(src);
    final nums = RegExp(r'\d+(\.\d+)?')
        .allMatches(src)
        .map((m) => double.parse(m.group(0)!))
        .toList();

    // ইউনিট খোঁজো — কিন্তু "টাকা"-র ভেতরের "টা" যেন না ধরে (আগে price-শব্দ সরাই)
    String unit = '';
    final noPrice = src.replaceAll(
        RegExp('(${[..._priceWords, ...kBuyWords, ...kContextWords].join('|')})'), ' ');
    for (final u in _unitWords) {
      if (noPrice.contains(u)) {
        unit = u;
        break;
      }
    }

    // দাম: যেই সংখ্যাটার ঠিক পরে টাকা/৳/দাম আছে — সেটাই দাম।
    double total = 0;
    final mm = kMoneyRx.firstMatch(src);
    if (mm != null) {
      total = double.parse(mm.group(1)!);
    } else if (nums.isNotEmpty) {
      total = nums.last; // নাহলে শেষ সংখ্যাটাই দাম
    }

    // পরিমাণ: ইউনিটের ঠিক আগের সংখ্যা (না থাকলে ভগ্নাংশ-শব্দ: দেড়/আধা/সোয়া/আড়াই)
    double qty = 1;
    if (unit.isNotEmpty) {
      final ut = src.indexOf(unit);
      final before = _trimPunct(src.substring(0, ut));
      final qnum = RegExp(r'\d+(\.\d+)?').allMatches(before).toList();
      if (qnum.isNotEmpty) {
        qty = double.parse(qnum.last.group(0)!);
      } else {
        final fr =
            _fractionParts.keys.toList()..sort((a, b) => b.length - a.length);
        for (final f in fr) {
          if (before.contains(f)) {
            qty = _fractionParts[f]!;
            break;
          }
        }
      }
    } else if (!isQuery && nums.length >= 2) {
      // ইউনিট লেখা হয়নি, কিন্তু ২টি সংখ্যা আছে — আগেরটা = পরিমাণ, শেষটা = দাম
      qty = nums.first;
    }

    // item: বাকি শব্দগুলো জোগাড়
    var rest = src;
    for (final w in [..._priceWords,
        ..._unitWords,
        ..._queryWords,
        ...kContextWords,
        ...kBuyWords]) {
      rest = rest.replaceAll(w, ' ');
    }
    rest = _trimPunct(rest)
        .replaceAll(RegExp(r'\d+(\.\d+)?'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    var item = rest.isEmpty ? 'জিনিস' : rest;
    // "ডিমের" → "ডিম", "আলুর" → "আলু" — পরিষ্কার নাম
    while (item.length > 2 &&
        (item.endsWith('ের') || item.endsWith('এর') || item.endsWith('েরের'))) {
      item = item.substring(0, item.length - 2);
    }

    if (total <= 0 && !isQuery) {
      return PriceResult(
          item: item, qty: qty, unit: unit, total: 0, isQuery: false, ok: false);
    }
    return PriceResult(
        item: item,
        qty: qty,
        unit: unit.isEmpty ? 'পিস' : unit,
        total: total,
        isQuery: isQuery,
        ok: true);
  }
}

class PriceStore {
  PriceStore._();

  static Box box() => Hive.box('prices');

  static List<PriceEntry> all() {
    final b = box();
    final out = b.values
        .map<PriceEntry>(PriceEntry.fromMap)
        .toList()
      ..sort((a, b2) => b2.time.compareTo(a.time));
    return out;
  }

  static void add(PriceResult r) {
    box().add(PriceEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      item: r.item,
      qty: r.qty,
      unit: r.unit,
      total: r.total,
      time: DateTime.now().millisecondsSinceEpoch,
    ).toMap());
  }

  static void addEntry(PriceEntry e) => box().add(e.toMap());

  static void update(PriceEntry e) {
    final b = box();
    final idx = b.values.toList().indexWhere((x) =>
        (x is Map) && '${x['id']}' == e.id);
    if (idx >= 0) b.putAt(idx, e.toMap());
  }

  static void delete(PriceEntry e) {
    final b = box();
    final idx = b.values.toList().indexWhere((x) =>
        (x is Map) && '${x['id']}' == e.id);
    if (idx >= 0) b.deleteAt(idx);
  }

  static bool hasSource(String src) =>
      box().values.any((v) => v is Map && '${v['src']}' == src);

  /// এক নোটের (src) সব এন্ট্রি মুছে — নোট আবার সম্পাদনা করলে sync।
  static void deleteBySource(String src) {
    final b = box();
    var i = 0;
    for (final v in b.values.toList()) {
      if (v is Map && '${v['src']}' == src) {
        b.deleteAt(i);
      } else {
        i++;
      }
    }
  }

  /// item-মিল filter (উভয়দিকে contains)।
  static List<PriceEntry> forItem(String anyKey) {
    final k = anyKey.toLowerCase();
    return all().where((e) =>
        e.item.toLowerCase().contains(k) || k.contains(e.item.toLowerCase())).toList();
  }
}

class PriceFmt {
  PriceFmt._();

  static String _groupAscii(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      b.write(s[i]);
      final rem = s.length - 1 - i;
      if (rem > 0 && rem % 3 == 0) b.write(',');
    }
    return b.toString();
  }

  static String tk(double v) => '৳${TextNormalizer.banglaDigits(_groupAscii(v.round()))}';

  /// ভগ্নাংশসহ (per-unit): ট্রেলিং শূন্য কাটা ২ দশমিক।
  static String tk2(double v) {
    var s = v.toStringAsFixed(2);
    while (s.endsWith('0') && s.contains('.')) {
      s = s.substring(0, s.length - 1);
    }
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    final neg = s.startsWith('-');
    if (neg) s = s.substring(1);
    final parts = s.split('.');
    final g = _groupAscii(int.parse(parts[0]));
    final out = parts.length > 1 && parts[1].isNotEmpty ? '$g.${parts[1]}' : g;
    final b = TextNormalizer.banglaDigits(out);
    return '৳${(neg ? '-' : '')}$b';
  }
}

/// একটি এন্ট্রির "বেস" (একটা/এক kg) দাম: ইউনিট×পরিমাণ দিয়ে ভাগ।
/// হালি: qty=1 → 4টা → per = total/4; কেজি: qty=1 → 1 kg → per kg।
double perBase(String unit, double total, double qty) {
  final eff = qty * (unitQty[unit] ?? 1);
  return eff > 0 ? total / eff : total;
}

/// ওজন/ভর/দৈর্ঘ্য ইউনিটে "১টা" বোঝায় না — বাদ গণনা
bool isCountable(String u) =>
    u != 'কেজি' && u != 'আধা কেজি' && u != 'লিটার' && u != 'মিটার';

/// ইউনিট-বুঝে "প্রতি" দেখানো: ১টা (গণনার), ১০০ গ্রাম/মি.লি./সেমি (ওজন-ভরের)।
String perDisplay(String unit, double total, double qty) {
  final per = perBase(unit, total, qty);
  switch (unit) {
    case 'কেজি':
    case 'আধা কেজি':
      return '১০০ গ্রাম = ${PriceFmt.tk2(per / 10)}';
    case 'লিটার':
      return '১০০ মি.লি. = ${PriceFmt.tk2(per / 10)}';
    case 'মিটার':
      return '১০ সেমি = ${PriceFmt.tk2(per / 10)}';
    default:
      return isCountable(unit) ? '১টা = ${PriceFmt.tk2(per)}' : '১ $unit = ${PriceFmt.tk2(per)}';
  }
}

/// item-এর সব দর থেকে একটি সুন্দর TreeBlueprint (এমোজি সহ)।
/// খোঁজ (query): আস্তে-আস্তে মিল খোঁজে; না মিললে "আনুমানিক" দেখায়।
/// এক item এর নানা "ধরন" (মুরগির মাংস / গরুর মাংস) আলাদা আলাদা ডাল (branch) হয়।
TreeBlueprint priceTree(String item, List<PriceEntry> entries, {double? wantQty, String? wantUnit}) {
  String bd(double v) => v == v.roundToDouble()
      ? TextNormalizer.banglaDigits(v.toInt().toString())
      : TextNormalizer.banglaDigits(v.toString());
  String unitWd(String u) => u == 'পিস' ? 'টা' : ' $u';
  final nodes = <TreeNode>[];

  if (entries.isEmpty) {
    nodes.add(TreeNode(
      text: 'দর এখনো লেখা হয়নি — লিখো: «১ ${wantUnit ?? ''} $item ৫০ টাকা»',
      emoji: '✍️',
    ));
    return TreeBlueprint(
        title: item, titleEmoji: marketEmoji(item), nodes: nodes, fixCount: 0);
  }

  // খোঁজের মূল-হিসাব (যেমন: "১ হালি ডিম কিনব")
  if (wantQty != null) {
    PriceEntry? exact;
    for (final e in entries) {
      if (e.unit == wantUnit && e.qty == wantQty) {
        exact = e;
        break;
      }
    }
    final base = exact ?? entries.first;
    final per = perBase(base.unit, base.total, base.qty);
    final header = exact != null
        ? '${bd(wantQty)}${unitWd(wantUnit ?? 'পিস')} $item = ${PriceFmt.tk2(base.total)}'
        : '$item (এখনকার হিসাব: ${bd(base.qty)}${unitWd(base.unit)} = ${PriceFmt.tk2(base.total)})';
    nodes.add(TreeNode(
      text: header,
      emoji: '💰',
      children: [
        TreeNode(text: perDisplay(base.unit, base.total, base.qty), emoji: '🔢'),
        if (exact != null && (unitQty[wantUnit] ?? 1) > 1)
          TreeNode(
              text: '১ ${wantUnit} = ${TextNormalizer.banglaDigits(unitQty[wantUnit]!.round().toString())}টা',
              emoji: '📦'),
        if (exact == null)
          TreeNode(
              text: 'একই ধরে নিয়ে ১ ${base.unit} = ${PriceFmt.tk2(base.per)}',
              emoji: '🧮'),
        if (isCountable(base.unit))
          TreeNode(text: '১০টা আনলে ${PriceFmt.tk2(per * 10)}', emoji: '🛒'),
      ],
    ));
  }

  // প্রতিদর আলাদা আলাদা ডাল (branch)।
  for (final e in entries) {
    if (wantQty != null && e.unit == wantUnit && e.qty == wantQty) continue; // উপরে দেখানো হয়েছে
    final per = perBase(e.unit, e.total, e.qty);
    final qityLabel = bd(e.qty);
    final unitLabel = unitWd(e.unit);
    final kids = <TreeNode>[
      TreeNode(text: perDisplay(e.unit, e.total, e.qty), emoji: '🔢'),
    ];
    if ((unitQty[e.unit] ?? 1) > 1) {
      kids.add(TreeNode(
        text: '১ ${e.unit} (${TextNormalizer.banglaDigits(unitQty[e.unit]!.round().toString())}টা) = ${PriceFmt.tk2(e.total)}',
        emoji: '📦',
      ));
    }
    if (e.qty > 1) {
      kids.add(TreeNode(
        text: '${qityLabel}$unitLabel = ${PriceFmt.tk2(e.total)} (তাই ${perDisplay(e.unit, e.total, e.qty)})',
        emoji: '🧮',
      ));
    }
    if (isCountable(e.unit)) {
      kids.add(TreeNode(text: '১০টা আনলে ${PriceFmt.tk2(per * 10)}', emoji: '🛒'));
    }
    nodes.add(TreeNode(
      text: '${qityLabel}$unitLabel = ${PriceFmt.tk2(e.total)}',
      emoji: marketEmoji(e.item),
      children: kids,
    ));
  }
  return TreeBlueprint(
    title: item,
    titleEmoji: marketEmoji(item),
    nodes: nodes,
    fixCount: 0,
    wasEmpty: false,
  );
}