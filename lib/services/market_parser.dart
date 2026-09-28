import 'package:flutter/foundation.dart';

/// P0-1: আইটেম → আইকন ডিকশনারি (offline)
///
/// প্রতিটি বাজার আইটেমের নিজস্ব emoji icon। বাংলা + ইংরেজি দুই ভাষাতেই চেনে।
/// ক্রম গুরুত্বপূর্ণ: long/key বেশি specific আগে, যেন `মিষ্টি আলু` 🍠 পায়,
/// plain `আলু` 🥔 পায় (longest-key-first matching)।
@immutable
class MarketIconEntry {
  final String emoji;
  final List<String> keys;

  const MarketIconEntry(this.emoji, this.keys);
}

const List<MarketIconEntry> kMarketIconEntries = [
  // 🥔 আলু
  MarketIconEntry('🥔', ['মিষ্টি আলু', 'sweet potato']),
  MarketIconEntry('🥔', [
    'আলু',
    'alu',
    'aalu',
    'potato',
    'potatoes',
    'potatoe',
  ]),
  // 🍆 বেগুন
  MarketIconEntry('🍆', [
    'বেগুন',
    'begun',
    'begoon',
    'eggplant',
    'brinjal',
    'aubergine',
  ]),
  // 🎃 কুমড়া
  MarketIconEntry('🎃', [
    'কুমড়া',
    'kumra',
    'pumpkin',
    'misti kumra',
    'dudh kumra',
    'sweet gourd',
  ]),
  MarketIconEntry('🥒', ['লাউ', 'lau', 'bottle gourd', 'lauki']),
  MarketIconEntry('🥒', ['শসা', 'shosha', 'cucumber', 'khira']),
  // 🧅 পেঁয়াজ
  MarketIconEntry('🧅', [
    'পেঁয়াজ',
    'peyaj',
    'piaj',
    'piyaz',
    'onion',
    'onions',
  ]),
  MarketIconEntry('🧄', ['রসুন', 'roshun', 'garlic', 'lashun']),
  // 🌶️ মরিচ
  MarketIconEntry('🌶️', [
    'মরিচ',
    'morich',
    'chili',
    'chilli',
    'chile',
    'pepper',
  ]),
  MarketIconEntry('🌶️', ['ঢেঁড়স', 'dherosh', 'okra', 'bhindi']),
  // 🍅 টমেটো
  MarketIconEntry('🍅', ['টমেটো', 'tomato', 'tometo']),
  // 🥬 শাক/সবুজ
  MarketIconEntry('🥬', [
    'শাক',
    'shak',
    'spinach',
    'palong',
    'পালং',
    'সসেজ',
    'cabbage',
    'বাঁধাকপি',
    'bandhakopi',
    'ফুলকপি',
    'phulkopi',
    'cauliflower',
    'broccoli',
    'ব্রকলি',
    'সালাদ',
    'salad',
    'lettuce',
    'lace',
    'লেটুস',
  ]),
  // 🍠 মিষ্টি আলু
  MarketIconEntry('🍠', ['খেজুর', 'khejur', 'date fruit', 'dates']),
  // 🌽 ভুট্টা
  MarketIconEntry('🌽', ['ভুট্টা', 'bhutta', 'corn', 'maize']),
  // 🥕 গাজর
  MarketIconEntry('🥕', ['গাজর', 'gajor', 'carrot', 'মুলা', 'mula', 'radish']),
  // 🔵 বরবটি/শিম
  MarketIconEntry('🫛', [
    'বরবটি',
    'borboti',
    'bean',
    'beans',
    'শিম',
    'sheem',
    'সীম',
  ]),
  // 🥗 সালাদ
  MarketIconEntry('🥗', ['সালাদ', 'salad']),
  // 🍄 মাশরুম
  MarketIconEntry('🍄', ['মাশরুম', 'mushroom', 'ছত্রাক']),
  // 🫒 জলপাই
  MarketIconEntry('🫒', ['জলপাই', 'olive']),
  // 🌿 ধনিয়া/পুদিনা/পাতা
  MarketIconEntry('🌿', [
    'ধনিয়া',
    'dhonia',
    'dhaniya',
    'coriander',
    'cilantro',
    'পুদিনা',
    'pudina',
    'mint',
    'তেজপাতা',
    'tejpata',
    'bay leaf',
  ]),
  MarketIconEntry('🫚', ['আদা', 'ada', 'ginger', 'adrak']),
  // 🍌 কলা
  MarketIconEntry('🍌', ['কলা', 'kola', 'kela', 'banana']),
  // 🍏 আপেল
  MarketIconEntry('🍏', ['আপেল', 'apple', 'সবুজ আপেল', 'green apple']),
  MarketIconEntry('🍎', ['লাল আপেল', 'red apple']),
  // 🥭 আম
  MarketIconEntry('🥭', ['আম', 'aam', 'am', 'mango', 'mangoes']),
  // 🍉 তরমুজ
  MarketIconEntry('🍉', ['তরমুজ', 'tormuj', 'watermelon']),
  // 🍊 কমলা
  MarketIconEntry('🍊', [
    'কমলা',
    'kamola',
    'kamala',
    'orange',
    'মাল্টা',
    'malta',
    'কিনু',
    'kinu',
  ]),
  // 🍋 লেবু
  MarketIconEntry('🍋', [
    'লেবু',
    'lebu',
    'lemon',
    'lime',
    'কাগজি লেবু',
    'kagji',
  ]),
  // 🍇 আঙুর
  MarketIconEntry('🍇', ['আঙুর', 'angur', 'grapes', 'grape']),
  // 🍓 স্ট্রবেরি
  MarketIconEntry('🍓', ['স্ট্রবেরি', 'strawberry', 'strawberries']),
  // 🍐 নাশপাতি
  MarketIconEntry('🍐', ['নাশপাতি', 'nashpati', 'pear']),
  // 🍑 পীচ
  MarketIconEntry('🍑', ['পীচ', 'peach', 'peaches']),
  // 🍍 আনারস
  MarketIconEntry('🍍', ['আনারস', 'anarosh', 'anaras', 'pineapple']),
  // 🫐 ব্লুবেরি
  MarketIconEntry('🫐', ['ব্লুবেরি', 'blueberry', 'blueberries']),
  // 🍈 কাচা ফল
  MarketIconEntry('🍈', [
    'সফেদা',
    'sofeda',
    'sapodilla',
    'কাঁঠাল',
    'kathal',
    'jackfruit',
  ]),
  // 🥑 অ্যাভোকাডো
  MarketIconEntry('🥑', ['অ্যাভোকাডো', 'avocado']),
  // 🥥 নারকেল
  MarketIconEntry('🥥', ['নারকেল', 'narikel', 'coconut', 'কোরা', 'kora']),
  // 🍒 চেরি
  MarketIconEntry('🍒', ['চেরি', 'cherry', 'cherries']),
  // 🍎 ডিফল্ট ফল
  MarketIconEntry('🍎', ['ফল', 'phol', 'fruit']),
  // 🐟 মাছ
  MarketIconEntry('🐟', [
    'ইলিশ',
    'ilish',
    'hilsa',
    'রুই',
    'rui',
    'কাতলা',
    'katla',
    'মৃগেল',
    'mirgel',
    'তেলাপিয়া',
    'tilapia',
    'পাঙাশ',
    'pangash',
    'pangas',
    'কই',
    'koi',
    'মাছ',
    'mach',
    'fish',
    'সিলভার',
    'silver carp',
    'গ্রাস কার্প',
    'tuna',
    'টুনা',
    'sardine',
    'সার্ডিন',
    'salmon',
    'স্যামন',
  ]),
  MarketIconEntry('🦐', [
    'চিংড়ি',
    'chingri',
    'shrimp',
    'prawn',
    'গলদা',
    'galda',
    'bagda',
    'বাগদা',
  ]),
  MarketIconEntry('🦀', ['কাঁকড়া', 'kankra', 'crab', 'আড়ি']),
  MarketIconEntry('🐙', [
    'অক্টোপাস',
    'octopus',
    'squid',
    'রূপচাঁদা',
    'rupchanda',
    'pomfret',
    'কই মাছ',
  ]),
  // 🥚 ডিম
  MarketIconEntry('🥚', ['ডিম', 'dim', 'egg', 'eggs']),
  // 🍖 মাংস
  MarketIconEntry('🍖', [
    'মাংস',
    'mangsho',
    'meat',
    'beef',
    'গরু',
    'goru',
    'লাল মাংস',
    'খাসি',
    'khasi',
    'mutton',
    'গোশত',
    'gosht',
  ]),
  MarketIconEntry('🍗', [
    'মুরগি',
    'murgi',
    'chicken',
    'broiler',
    'সোনালি',
    'গরিবের মুরগি',
  ]),
  MarketIconEntry('🍗', ['টার্কি', 'turkey']),
  MarketIconEntry('🥓', ['বেকন', 'bacon']),
  // 🧀 পনির
  MarketIconEntry('🧀', ['পনির', 'ponir', 'cheese', 'মোজারেলা', 'mozzarella']),
  // 🥛 দুধ/দই
  MarketIconEntry('🥛', [
    'দুধ',
    'dudh',
    'doodh',
    'milk',
    'দই',
    'doi',
    'curd',
    'yogurt',
    'লাচ্ছি',
    'lassi',
    'ছানা',
    'chhana',
    'পনির',
  ]),
  MarketIconEntry('🧈', ['মাখন', 'makhan', 'butter', 'ঘি', 'ghee', 'ঘৃত']),
  // 🧴 তেল
  MarketIconEntry('🧴', [
    'তেল',
    'tel',
    'oil',
    'সয়াবিন',
    'soyabin',
    'soyabean',
    'সূর্যমুখী',
    'sunflower',
    'সরিষার তেল',
    'mustard oil',
    'palmoil',
    'পাম তেল',
  ]),
  MarketIconEntry('🫒', ['অলিভ অয়েল', 'olive oil']),
  // 🍚 চাল/আটা
  MarketIconEntry('🍚', [
    'চাল',
    'chaal',
    'chal',
    'rice',
    'মিনিকেট',
    'miniket',
    'নাজিরশাইল',
    'najirshail',
    'বাসমতি',
    'basmati',
    'আটার',
    'atta',
    'ময়দা',
    'maida',
    'flour',
    'সুজি',
    'suji',
    'semolina',
  ]),
  // 🫘 ডাল
  MarketIconEntry('🫘', [
    'ডাল',
    'daal',
    'dal',
    'lentil',
    'মসুর',
    'musur',
    'মুগ',
    'moog',
    'ছোলার',
    'cholar',
    'boot',
    'বুট',
    'মটর',
    'motor',
    'peas',
    'মটরশুঁটি',
  ]),
  // 🌾 গম
  MarketIconEntry('🌾', ['গম', 'gom', 'wheat', 'ধান', 'dhan', 'paddy']),
  // 🧂 চিনি/নুন
  MarketIconEntry('🧂', [
    'চিনি',
    'chini',
    'sugar',
    'নুন',
    'nun',
    'লবণ',
    'labon',
    'salt',
    'গুড়',
    'gur',
    'gud',
    'jaggery',
  ]),
  MarketIconEntry('🧂', [
    'সয়াসস',
    'soy sauce',
    'সস',
    'sauce',
    'কেচাপ',
    'ketchup',
    'ভিনেগার',
    'vinegar',
  ]),
  // 🍬 মিষ্টি/মিঠাই
  MarketIconEntry('🍬', [
    'মিষ্টি',
    'mishti',
    'sweet',
    'মিঠাই',
    'mithai',
    'রসগোল্লা',
    'roshogolla',
    'গোলাপজাম',
    'জিলাপি',
    'jilapi',
    'মোয়া',
    'moa',
  ]),
  MarketIconEntry('🍭', ['ক্যান্ডি', 'candy', 'ললিপপ', 'lollipop']),
  // 🍫 চকলেট
  MarketIconEntry('🍫', ['চকলেট', 'chocolate', 'chuklet']),
  // 🍪 বিস্কুট
  MarketIconEntry('🍪', [
    'বিস্কুট',
    'biscuit',
    'biskyut',
    'cookie',
    'কুকিজ',
    'ক্রিম স্যাণ্ডউইচ',
    'cream biscuit',
  ]),
  // 🍦 আইসক্রিম
  MarketIconEntry('🍦', [
    'আইসক্রিম',
    'icecream',
    'ice cream',
    'কুলফি',
    'kulfi',
  ]),
  // 🍜 নুডলস
  MarketIconEntry('🍜', [
    'নুডলস',
    'noodles',
    'noodle',
    'ম্যাগি',
    'maggi',
    'রেডি',
    'ready to eat',
  ]),
  MarketIconEntry('🍝', [
    'পাস্তা',
    'pasta',
    'spaghetti',
    'ম্যাকারনি',
    'macaroni',
  ]),
  MarketIconEntry('🍲', ['স্যুপ', 'soup', 'স্ট্যু', 'stew', 'ঝোল']),
  MarketIconEntry('🥫', ['টিন', 'tin', 'canned', 'ক্যানড']),
  // 🧃 জুস
  MarketIconEntry('🧃', ['জুস', 'juice', 'রস', ' শেক', 'shake']),
  MarketIconEntry('🧃', [
    'কোমল পানীয়',
    'cold drink',
    'কোক',
    'coke',
    'পেপসি',
    'pepsi',
    'স্প্রাইট',
    'sprite',
    'মিনারেল ওয়াটার',
    'mineral water',
  ]),
  MarketIconEntry('💧', ['পানি', 'pani', 'water', 'জল', 'jol']),
  // 🫖 চা/☕ কফি
  MarketIconEntry('🫖', [
    'চা',
    'cha',
    'tea',
    'চায়ের',
    'কামরাঙ্গা',
    'লিপটন',
    'lipton',
    'সাদা পানি দিয়ে চা',
  ]),
  MarketIconEntry('☕', ['কফি', 'coffee', 'নেসক্যাফে', 'nescafe']),
  MarketIconEntry('🍯', ['মধু', 'madhu', 'honey']),
  // 🌰/🥜 বাদাম
  MarketIconEntry('🌰', [
    'বাদাম',
    'badam',
    'nuts',
    'কাজু',
    'kaju',
    'cashew',
    'পেস্তা',
    'pista',
    'pistachio',
    'আখরোট',
    'walnut',
  ]),
  MarketIconEntry('🥜', [
    'চিনাবাদাম',
    'chinabadam',
    'peanut',
    'চানা',
    'chana',
    'chickpea',
    'কাবলি',
    'kabuli',
  ]),
  // 🧻 টিস্যু
  MarketIconEntry('🧻', [
    'টিস্যু',
    'tissue',
    'tisu',
    'টয়লেট পেপার',
    'toilet paper',
    'ন্যাপকিন',
    'napkin',
    'পেপার',
  ]),
  // 🧼 সাবান
  MarketIconEntry('🧼', [
    'সাবান',
    'shaban',
    'soap',
    'ডিটারজেন্ট',
    'detergent',
    'ওয়াশিং পাউডার',
    'washing powder',
    'সারফ',
    'surf',
    'টিয়ার',
    'teer',
    'বাইথ্রু',
    'bath soap',
  ]),
  // 🧴 শ্যাম্পু (তেলের সাথে conflict - করুন পরে)
  MarketIconEntry('🧴', [
    'শ্যাম্পু',
    'shampoo',
    'কন্ডিশনার',
    'conditioner',
    'হেয়ার অয়েল',
    'hair oil',
    'বডি ওয়াশ',
    'body wash',
    'হ্যান্ডওয়াশ',
    'handwash',
  ]),
  MarketIconEntry('🪥', [
    'টুথপেস্ট',
    'toothpaste',
    'দাঁতের',
    'টুথব্রাশ',
    'toothbrush',
  ]),
  MarketIconEntry('🧽', [
    'স্পঞ্জ',
    'sponge',
    'স্কাউরার',
    'scourer',
    'ক্লিনার',
    'cleaner',
    'ফিনাইল',
    'phenyle',
  ]),
  MarketIconEntry('🧺', ['লন্ড্রি', 'laundry', 'ডিটারজেন্ট সাবান']),
  MarketIconEntry('🪣', ['বালতি', 'bucket', 'মগ', 'mug', 'বেসিন', 'basin']),
  MarketIconEntry('🧹', ['ঝাড়ু', 'jharu', 'broom', 'কাচামাছি', 'vetri']),
  // 🎁 গিফট
  MarketIconEntry('🎁', ['গিফট', 'gift', 'উপহার', 'upohar']),
  // 💊 ওষুধ
  MarketIconEntry('💊', [
    'ওষুধ',
    'oshudh',
    'medicin',
    'medicine',
    'ট্যাবলেট',
    'tablet',
    'সিরাপ',
    'syrup',
    'ভিটামিন',
    'vitamin',
  ]),
  MarketIconEntry('🩹', [
    'ব্যান্ডেজ',
    'bandage',
    'প্লাস্টার',
    'plaster',
    'প্রাথমিক চিকিৎসা',
    'first aid',
  ]),
  // 📦 ডিফল্ট
  MarketIconEntry('🥖', [
    'পাউরুটি',
    'pauroti',
    'bread loaf',
    'বন',
    'bun',
    'রুটি',
    'ruti',
    'রুটি',
    'ছাতা রুটি',
  ]),
  MarketIconEntry('🍞', [
    'ব্রেড',
    'bread',
    'পাউরুটি',
    'স্যান্ডউইচ',
    'sandwich',
    'পিঠা',
    'pitha',
  ]),
  MarketIconEntry('🥟', ['সমুচা', 'samosa', 'সিঙ্গারা', 'singara', 'সামোসা']),
];

/// P0-1 fallback: চেনা না গেলে ক্যাটাগরি ধরে icon
String marketCategoryEmoji(String label) {
  final n = label.toLowerCase();
  if (n.contains('মাছ') || n.contains('fish')) return '🐟';
  if (n.contains('মাংস') || n.contains('মুরগি') || n.contains('meat'))
    return '🍖';
  if (n.contains('সবজি') || n.contains('সব্জি') || n.contains('vegetable'))
    return '🥬';
  if (n.contains('ফল') || n.contains('fruit')) return '🍎';
  if (n.contains('মশলা') || n.contains('মসলা') || n.contains('spice'))
    return '🌶️';
  if (n.contains('পানীয়') || n.contains('drink')) return '🧃';
  return '🛍️';
}

const String kDefaultItemIcon = '🛍️';

/// আইটেম নাম থেকে আইকন বের করে। Longest-key-first (বিশেষ ম্যাচ আগে)।
String marketEmoji(String label) {
  final n = label.toLowerCase().trim().replaceAll(RegExp(r'[।।‘’"",!?]+'), ' ');

  // 1) exact + longest-first substring match
  MarketIconEntry? best;
  var bestLen = 0;
  for (final e in kMarketIconEntries) {
    for (final k in e.keys) {
      final key = k.trim();
      if (key.isEmpty) continue;
      if (n == key) {
        return e.emoji;
      }
      if (n.contains(key) && key.length > bestLen) {
        best = e;
        bestLen = key.length;
      }
    }
  }
  if (best != null) return best.emoji;

  // 2) category fallback
  final cat = marketCategoryEmoji(n);
  if (cat != kDefaultItemIcon) return cat;

  return kDefaultItemIcon;
}

// ─────────────────────────────────────────────────────────────────────────────
// P0-2: স্মার্ট নম্বর পারসার
// ─────────────────────────────────────────────────────────────────────────────

/// এক লাইনের market item (parsed)
@immutable
class MarketItem {
  final String label;
  final String emoji;
  final double? qty;
  final String? unit;
  final double? unitPrice;
  final double total;
  final int line;

  const MarketItem({
    required this.label,
    required this.emoji,
    required this.qty,
    required this.unit,
    required this.unitPrice,
    required this.total,
    required this.line,
  });

  bool get hasQty => qty != null;

  String get qtyText {
    final q = qty;
    if (q == null) return '';
    return marketNumText(q) + (unit == null ? '' : ' $unit');
  }

  String get priceText {
    final p = unitPrice;
    if (p == null) return '';
    return '৳${marketNumText(p)}${_perUnit()}';
  }

  String _perUnit() {
    final u = unit;
    return u == null ? '' : '/$u';
  }

  String get totalText => '৳${marketNumText(total)}';
}

String marketNumText(double v) {
  if (v == v.roundToDouble()) {
    return v.toStringAsFixed(0);
  }
  // দুই দশমিক পর্যন্ত ছোট করে (ট্রেলিং শূন্য বাদ)
  var s = v.toStringAsFixed(2);
  s = s.replaceFirst(RegExp(r'\.?0+$'), '');
  return s;
}

const String kBnDigits = '০১২৩৪৫৬৭৮৯';

/// বাংলা অঙ্ক → ইংরেজি অঙ্ক। মিশ্র/দশমিক কমা supported।
double? parseNumber(String s) {
  var str = s.trim().replaceAll(',', '.').replaceAll(' ', '');
  if (str.isEmpty) return null;
  final sb = StringBuffer();
  for (final unit in str.split('')) {
    final idx = kBnDigits.indexOf(unit);
    sb.write(idx >= 0 ? '$idx' : unit);
  }
  return double.tryParse(sb.toString());
}

const Map<String, String> kUnitAliases = {
  'কেজি': 'kg',
  'কেজা': 'kg',
  'কেজে': 'kg',
  'কিলোগ্রাম': 'kg',
  'কিলো': 'kg',
  'kilo': 'kg',
  'kilos': 'kg',
  'kg': 'kg',
  'kgs': 'kg',
  'gr': 'g',
  'গ্রাম': 'g',
  'grm': 'g',
  'gm': 'g',
  'g': 'g',
  'লিটার': 'L',
  'লি': 'L',
  'lt': 'L',
  'ltr': 'L',
  'litre': 'L',
  'liter': 'L',
  'l': 'L',
  'মিলি': 'ml',
  'ml': 'ml',
  'পিস': 'pc',
  'পিচ': 'pc',
  'টা': 'pc',
  'টি': 'pc',
  'pc': 'pc',
  'pcs': 'pc',
  'ডজন': 'dozen',
  'dozen': 'dozen',
  'dz': 'dozen',
  'মিটার': 'm',
  'মি': 'm',
  'm': 'm',
  'ফুট': 'ft',
  'feet': 'ft',
  'ft': 'ft',
  'সেমি': 'cm',
  'cm': 'cm',
  'আউন্স': 'oz',
  'ounce': 'oz',
  'oz': 'oz',
  'প্যাক': 'pack',
  'প্যাকে': 'pack',
  'pack': 'pack',
  'জন': 'pc',
  'গাদা': 'heap',
  'পোয়া': 'poa',
  'সের': 'ser',
  'মণ': 'mon',
  'বোতল': 'bot',
  'বোতলে': 'bot',
  'bottle': 'bot',
  'ডাব': 'dab',
};

/// ইউনিট চেনা: "kg." → "kg", "কেজি" → "kg"
String? matchUnit(String token) {
  var t = token
      .toLowerCase()
      .trim()
      .replaceAll('.', '')
      .replaceAll('×', '')
      .trim();
  return kUnitAliases[t];
}

/// মার্কার স্ট্রিপ — existing `_shoppingItems`-এর মতোই
final RegExp kMarketMarkerRe = RegExp(
  r'^\s*(?:[-*+]|[\d]+[.)]|☐|☑|\[\s?\]|\[x\]|>\s)?\s*',
);

/// এক লাইন পারস করে MarketItem বানায় (না পারলে null)
///
/// shapes:
/// - `আলু 10 kg 50`   → qty=10 kg, price=৳50/kg, total=৳500
/// - `ডিম 12 x 10`     → qty=12 pc, price=৳10, total=৳120
/// - `আলু ৫০`          → price=৳৫০, total=৳৫০
MarketItem? parseMarketLine(String raw, int lineIndex) {
  var rest = raw.replaceFirst(kMarketMarkerRe, '').trim();
  if (rest.isEmpty || rest.startsWith('#')) return null;

  // glued token: "10kg" → "10 kg", "১২x" → "১২ x", "৫০গ্রাম" → "৫০ গ্রাম"
  rest = rest.replaceAllMapped(
    RegExp(r'([0-9০-৯]+(?:[.,][0-9০-৯]+)?)([^\s0-9০-৯.,]+)'),
    (m) => '${m.group(1)} ${m.group(2)}',
  );

  final tokens = rest.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  if (tokens.isEmpty) return null;

  // numeric token index list
  final numIdx = <int>[];
  for (var i = 0; i < tokens.length; i++) {
    if (parseNumber(tokens[i]) != null) numIdx.add(i);
  }
  if (numIdx.isEmpty) return null;

  final firstN = numIdx.first;
  var label = tokens.sublist(0, firstN).join(' ').trim();
  label = label.replaceFirst(RegExp(r'[:：\-—–]+$'), '').trim();
  if (label.isEmpty) label = 'আইটেম';

  final v0 = parseNumber(tokens[firstN])!;
  double? qty;
  String? unit;
  double? unitPrice;
  double total;

  if (numIdx.length >= 2) {
    // qty ↔ price: দুই সংখ্যার মাঝে unit / x থাকতে পারে
    qty = v0;
    final secondN = numIdx[1];
    final v1 = parseNumber(tokens[secondN])!;
    unitPrice = v1;
    total = qty * unitPrice;
    // unit খুঁজি প্রথম-দ্বিতীয় সংখ্যার মাঝে
    for (var i = firstN + 1; i < secondN; i++) {
      final u = matchUnit(tokens[i]);
      if (u != null) {
        unit = u;
        break;
      }
    }
    // 'x' চিহ্ন থাকলে unit ছাড়াও qty×price
  } else {
    // single number → price
    unitPrice = v0;
    total = v0;
  }

  return MarketItem(
    label: label,
    emoji: marketEmoji(label),
    qty: qty,
    unit: unit,
    unitPrice: unitPrice,
    total: total,
    line: lineIndex,
  );
}

/// পুরো কনটেন্ট থেকে market items list
List<MarketItem> parseMarketItems(String content) {
  final items = <MarketItem>[];
  final lines = content.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final it = parseMarketLine(lines[i], i);
    if (it != null) items.add(it);
  }
  return items;
}

double marketTotal(List<MarketItem> items) =>
    items.fold(0, (a, it) => a + it.total);

String marketTotalText(List<MarketItem> items) =>
    '৳${marketNumText(marketTotal(items))}';

// ─────────────────────────────────────────────────────────────────────────────
// P1-1: ## section → সাবটোটাল গ্রুপ
// ─────────────────────────────────────────────────────────────────────────────

/// `## সবজি` heading-এর নিচের items একসাথে (নেস্টেড ট্রির branch)
@immutable
class MarketSection {
  final String? title;
  final int line;
  final List<MarketItem> items;

  const MarketSection({
    required this.title,
    required this.line,
    required this.items,
  });

  bool get hasTitle => title != null;

  String get emoji => title == null ? '🧺' : marketEmoji(title!);

  double get subtotal => marketTotal(items);

  String get subtotalText => '৳${marketNumText(subtotal)}';
}

/// ## heading ধরা হয়; যতক্ষণ পর পরবর্তী heading না আসে items তাদের section-এ।
/// কোনো heading ছাড়া শুরু হলে আগের items `title: null` section-এ থাকে।
List<MarketSection> parseMarketSections(String content) {
  final sections = <MarketSection>[];
  final lines = content.split('\n');
  final headingRe = RegExp(r'^#{1,6}\s+(.+?)\s*$');
  List<MarketItem>? current;

  void flush() {
    if (current != null && current!.isNotEmpty) {
      sections.last.items.addAll(current!);
    }
    current = null;
  }

  for (var i = 0; i < lines.length; i++) {
    final h = headingRe.firstMatch(lines[i]);
    if (h != null) {
      flush();
      sections.add(
        MarketSection(title: _plainText(h.group(1)!), line: i, items: []),
      );
      continue;
    }
    final it = parseMarketLine(lines[i], i);
    if (it == null) continue;
    if (sections.isEmpty) {
      sections.add(MarketSection(title: null, line: -1, items: <MarketItem>[]));
    }
    sections.last.items.add(it);
  }
  flush();

  return sections.where((s) => s.items.isNotEmpty).toList();
}

/// Heading-এর markup (bold/italic/#) ছেঁটে plain না করেন
String _plainText(String s) {
  var out = s.replaceAllMapped(
    RegExp(r'(\*{2}|_{2})(.*?)\1', multiLine: true),
    (m) => m.group(2) ?? '',
  );
  out = out
      .replaceAllMapped(RegExp(r'\*(.*?)\*'), (m) => m.group(1) ?? '')
      .replaceAll(RegExp(r'</?(big|small)>'), '')
      .replaceAll(RegExp(r'</?[biu]>'), '')
      .replaceFirst(RegExp(r'^#{1,6}\s+'), '')
      .trim();
  return out;
}
