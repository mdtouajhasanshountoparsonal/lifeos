/// কুরআন লিপির শেয়ারড সহায়ক — সূরার ১ নং আয়াতের শুরুতে বসা বিসমিল্লাহকে
/// আলাদা করে চেনা ও বাদ দেওয়া (৯ নং সূরা তওবাহ বাদে প্রতিটি সূরাতেই আছে)।
library;

/// আরবি (আয়াত) টেক্সটে ব্যবহৃত ফন্ট — কুরআনী লিপি + তাশকিল সঠিকভাবে দেখায়।
const kQuranFont = 'Amiri';

/// বিসমিল্লাহ — কুরআনের লিপিতে (৯ নং সূরা তওবাহ বাদে প্রতিটি সূরার ১ নং
/// আয়াতের শুরুতে থাকে); নিজের লাইনে আলাদা করে দেখানো হয়।
const basmalaAr =
    '\u0628\u0650\u0633\u06e1\u0645\u0650\u0020\u0671\u0644\u0644\u0651\u064e\u0647\u0650\u0020\u0671\u0644\u0631\u0651\u064e\u062d\u06e1\u0645\u064e\u0640\u0670\u0646\u0650\u0020\u0671\u0644\u0631\u0651\u064e\u062d\u0650\u06cc\u0645\u0650';

/// বিসমিল্লাহ-এর বাংলা-বানানে পড়া (ট্রান্সলিটারেটর নির্ধারিত রূপ)।
const basmalaTl = 'বিস-মি আল-লা-হি আর-রাহ-মা-নি আর-রা-হি-মি';

/// আরবি তাশকিল/কুরআন-চিহ্ন (নরমালাইজ করে বাদ দেওয়া হয়)।
final arMarks = RegExp(
  r'[\u0610-\u061a\u0640\u064b-\u0652\u0656-\u065f\u0670\u06d6-\u06ed\u08d3-\u08ff]',
);

/// আলিফের রূপ (ا أ إ آ ٱ) — সবকে এক বলে ধরি।
final alefForms = RegExp(r'[\u0622\u0623\u0625\u0671]');

/// `ar`-এর শুরু থেকে পুরো বিসমিল্লাহ (যেকোনো লিপি-ভ্যারিয়েন্টসহ) কত অক্ষর
/// দখল করে তা-বেরে — ম্যাচ না পেলে 0। তাওবাহ (৯)-তে নেই → 0।
int stripBasmalaLen(String ar) {
  final target = basmalaAr
      .replaceAll(arMarks, '')
      .replaceAll(alefForms, '\u0627')
      .replaceAll(' ', '');
  final buf = StringBuffer();
  var len = 0;
  for (var i = 0; i < ar.length; i++) {
    buf.write(ar[i]);
    final n = buf
        .toString()
        .replaceAll(arMarks, '')
        .replaceAll(alefForms, '\u0627')
        .replaceAll(' ', '');
    if (n == target) {
      len = i + 1;
      break;
    }
  }
  if (len == 0) return 0;
  while (len < ar.length && arMarks.hasMatch(ar[len])) {
    len++;
  }
  return len;
}

/// বিসমিল্লাহ বাদে অবশিষ্ট আয়াত-টেক্সট ও তার বাংলা-পড়া। বাসমালা না থাকলে
/// যেমন ছিল তেমনই।
({String ar, String tl, String basmalaAr, String basmalaTl}) stripBasmala(
  String ar,
  String tl, {
  required bool isFirstAyah,
}) {
  if (!isFirstAyah) return (ar: ar, tl: tl, basmalaAr: '', basmalaTl: '');
  final len = stripBasmalaLen(ar);
  if (len <= 0) return (ar: ar, tl: tl, basmalaAr: '', basmalaTl: '');
  final bAr = ar.substring(0, len);
  final rest = ar.substring(len).trim();
  var restTl = tl;
  var bTl = '';
  if (tl.startsWith(basmalaTl)) {
    bTl = basmalaTl;
    restTl = tl.substring(basmalaTl.length).trim();
  }
  return (ar: rest, tl: restTl, basmalaAr: bAr, basmalaTl: bTl);
}
