# 🟢 আরবি পড়া — কুরআন মডিউল: বিশ্লেষণ ও ব্যাখ্যা

> ফোকাস: **আরবি পড়তে শেখা → কুরআন পড়া**। এই ফাইলটি শুধু বর্তমান বাস্তবায়নের ব্যাখ্যা/বিশ্লেষণ (কোনো কোড পরিবর্তনের রেকর্ড নয়), পরের ফেজের কাজ বুঝতে।
> ভিত্তি: `docs/DEEN_ROADMAP.md`-এর M6–M12। অবস্থা: এই লেখার সময় M1–M11.2 + M12 v1 + সূরা list/reader উন্নতি ✅।

---

## ১. পুরো ডেটা-ফ্লো (end-to-end)

```text
GitHub রিপো (islamic_data, public)
   │  manifest.json + 50 content files, raw.githubusercontent
   ▼
ContentRepository._sync()          lib/services/content_repository.dart:104
   │  HTTP → strict-JSON decode (_strictDecode, line 197) → fail হলে state=error
   ▼
Hive ক্যাশ
   ├── content_data   (key = ফাইল path, value = raw JSON string)   main.dart:49-50
   └── content_meta   (ready, downloadedAt, bundleVersion, v:<path> per-file version)
   ▼
Seeder (লোডার)          একমাত্র JSON-পাঠের জায়গা — UI সরাসরি পড়ে না
   ├── DeenSeed    (dua/hadith/adhkar/post_prayer/surahs/memPool)  lib/services/deen_seed.dart
   └── ArabicSeed  (letters/harakat/words/quran/vocab/roots/grammar/manifest)  lib/services/arabic_seed.dart
   ▼
Screens (কেবলমাত্র Seeder থেকে)
```

- প্রথম খোলা: `ContentGate` (`lib/widgets/content_gate.dart`) → `ContentRepository.ensureReady()` → manifest + সব ফাইল download → validate → cache → `ready`।
- এরপর **সম্পূর্ণ offline**। Update: content_store-এ "আবার নামাও" → `ensureReady(force: true)` → meta/data মুছে → re-download।
- version tracking: `content_meta['v:<path>'] >= manifest version` হলে ঐ ফাইল skip (`content_repository.dart:145-155`) — network বাঁচায়।

---

## ২. কনটেন্ট-ইনভেন্টরি (আরবি-কুরআন অংশ)

`islamic_data/` (manifest.json = 50 files, bundleVersion 2):

| folder/module | file | item count | মন্তব্য |
|---|---|---|---|
| আরবি অক্ষর | `arabic/letters.json` | ২৮ | নাম, উচ্চারণ, ৪ রূপ, example |
| হরকত | `arabic/harakat.json` | ১১ | ফতহা…মাদ, `ب`-demo |
| শব্দ পড়া | `arabic/words.json` | ৩৭ | ছোট শব্দ + পড়া + অর্থ |
| শব্দভাণ্ডার | `arabic/vocab.json` | ১৯ | কুরআন ভোকাব, occurrence |
| মূলধাতু | `arabic/roots.json` | ৬ | এক শিকড় → শাখা-শব্দ |
| ব্যাকরণ | `arabic/grammar.json` | ৭ | নাম-বাক্য…বাক্য গড়া |
| ফাতিহা word-by-word | `quran/fatiha_words.json` | ১ সূরা/৭ আয়াত | শব্দ-ধরে-ধরে + পূর্ণ অনুবাদ |
| সূরা-সূচি | `quran/surahs_index.json` | **১১৪** (v2) | সব সূরার মেটা |
| পূর্ণ সূরা পাঠ | `quran/001_fatiha.json` + `quran/078_naba.json` … `114_nas.json` | **৩৮টি** | এগুলোরই পূর্ণ আরবি+বাংলা+পড়া |

➡️ **৩৮টি সূরা** (ফাতিহা + জুয' আম্মা ৭৮–১১৪) full text-সহ; বাকি **৭৬টি** শুধু মেটা ("পাঠ আসবে")।

---

## ৩. শেখার পথ (screen chain)

```text
🟢 আরবি হোম (arabic_home_screen — hub)
 ├── 🔤 AlphabetScreen          অক্ষরের ৪ রূপ
 ├── 🪄 ArabicHarakatScreen     স্বরচিহ্ন
 ├── 📖 ArabicWordsScreen       শব্দ পড়া + "জানি ✓"   (id: bare যেমন bab)
 ├── 🌟 QuranWordsScreen        ফাতিহা word-by-word + "🎯 নিজে বলো"
 ├── 📚 VocabularyScreen        vocab + "জানি ✓"       (id: vocab:<id>)
 ├── 🌱 RootWordsScreen         মূলধাতু → শাখা
 ├── 📖 GrammarScreen           ব্যাকরণ পাঠ
 ├── 🗣️ SpeakDrillScreen        M12 self-check read-aloud  (id: said:<kind>:<id>)
 ├── 🧑🏫 ArabicTeacherScreen    offline+Gemini প্রশ্ন-উত্তর, M11.2 proগ্রেস
 └── 🗂️ ContentStoreScreen      কোন ফাইল/version আছে + "আবার নামাও"
📖 কুরআন (deen_home → SurahListScreen ১১৪-তালিকা + 🔍খোঁজ)
 └── SurahReaderScreen          এক সূরার পূর্ণ পাঠ + আগের/পরের
```

সূরা list → `DeenSeed.surahs()`; যার `arabic` খালি → "✓ পাঠ আছে" না, "পাঠ আসবে" + snackbar। Reader-এ নিচের "আগের/পরের" পরের সূরাতে নেভিগেট করে (পাঠ না থাকলে snackbar, থেমে থাকে)।

---

## ৪. ডেটা-মডেল ও লোডিং নিয়ম

- **সব ফিল্ড mandatory trim + type-safe** fallback ('' বা 0), যেন একটা খারাপ entry বাকি সব নষ্ট না করে।
- `surahs()` দুই-স্তর: `surahs_index.json` (মেটা) → per-file `quran/NNN_id.json`; ফাইল নেই/নির্দিষ্ট ফিল্ড খালি → index মেটাই দেখায় (`deen_seed.dart:287-321`)।
- `memPool()` (`deen_seed.dart:324`): memorization-এ দেখানোর তালিকা = dua + surahs যাদের `arabic` আছে — মেটা-only সূরা বাদ।
- **রেকর্ড (`deen_arabic` box, key `known`):** শুধু ইতিবাচক — `bab`, `vocab:rabb`, `said:ayah:fatiha:1` ইত্যাদি। টগল unmark-ও করে। কোনো স্কোর/গিল্টি নেই।
- Hive boxes main.dart:৪৭-৫০ খোলা — `deen_arabic`, `memorization`, `content_meta`, `content_data`।

---

## ৫. শিক্ষক (M11) + প্রগ্রেস (M11.2)

- `ArabicTeacher.ask()`: online+Gemini key থাকলে Gemini, ব্যর্থ/বন্ধে offline। **প্রতিটি প্রশ্ন count** (`DeenProgress.recordQuestion` → `teacher_count` দিন-কি)।
- offline intent (string-match, ক্রম): হরকত → অক্ষর → শব্দভাণ্ডার → মূলধাতু → **প্রগ্রেস** → দিকনির্দেশনা → ফাতিহা → ব্যাকরণ → শেষ রক্ষা।
- `DeenProgress.summary()`: মডিউল-ভিত্তিক `known/total` + মুখস্থ count + আজকের প্রশ্ন + পরের ধাপ-সাজেশন। শিক্ষক স্ক্রিনের হেডার-নিচে লাইভ প্রগ্রেস স্ট্রিপ।

---

## ৬. মুখস্থ রুটিন

- Box `memorization`; `MemorizationEntry` (SM-2-স্টাইল): `level 1..5`, `nextReview`, `streak`, `wrong` (`deen_store.dart:403-513`)।
- Success → level+1, interval ১/৩/৭/১৫/৩০ দিন; ভুল → level 1, ৪ ঘণ্টা পরে রিভিউ। এটা "ব্যক্তিগত পুনরাবৃত্তি রেকর্ড" — বিচার নয়।
- পুল: `memPool()` (সূরা+দুআ)।

---

## ৭. সূরা-পড়া UX

- **List**: ১১৪ সূরা; 🔍 খোঁজ (নাম/অর্থ/আরবি নাম/মাক্কী-মাদানী/নাম্বার); "Xটি দেখানো হচ্ছে"; খালি অবস্থা message। `surah_list_screen.dart`
- **Reader**: আরবি (ডান-সারি, বড়) → বাংলা পড়া → অর্থ → source footer; নিচে **আগের/পরের** + "n / 114"। `surah_reader_screen.dart`

---

## ৮. বিশ্লেষণ — gগ্যাপ ও ছোট bugs (যাচাই করা)

1. **manifest mojibake (নিশ্চিত bug):** ৩৭টি সূরা-ফাইলের `kind` double-encoded — `"à¦¸à§‚à¦°à¦¾ ফাতিহা"` হওয়া উচিত `"সূরা ফাতিহা"` (শুধু `surahs_index`-এর `kind="সূরা-সূচি"` ঠিক)। কনটেন্ট-স্টোরে দেখালে garbled। → `manifest.json:86-345`।
2. **৭৬টি সূরা মেটা-only** — সবচেয়ে বড় কনটেন্ট গ্যাপ। Reader/list যা দেখায় সেটা ঠিকই, কিন্তু "পাঠ নেই"।
3. **bundle version-এ auto-update নেই** — রিপোতে নতুন ফাইল add করলেও user-কে "আবার নামাও" চাপতে হয় (offline-first নীতি, deliberate)।
4. **"জানি ✓" শুধু শব্দ + vocab-এ** — অক্ষর/হরকত/মূলধাতু/ব্যাকরণে মার্ক-বাটন নেই; `DeenProgress` ঐ prefix ধরতে পারে কিন্তু runtime-এ কেউ produce করে না (রেকর্ড সেটা ০ দেখায়)।
5. **প্রগ্রেস-হাব কার্ড মাপ নয়** — `arabic_home`-এর "আমার রেকর্ড" `known`-এর total length ধরে; `vocab:`/`said:` entry যোগ হলে শব্দ-রেশিও একটু off (pre-existing আচরণ)।
6. **Listening/pronunciation-judge** — audio content/TTS/স্পিচ-tech ছাড়া অসম্ভব (M12 নোট)।

---

## ৯. পরবর্তী কাজের দিকনির্দেশনা (আগামী ফেজ → আরবি পড়া-কুরআন)

1. **manifest kind-এর mojibake ঠিক করা** (রিপোতেই, content ফাইল) — content_store গন্ডগোল সেরে যাবে।
2. **"জানি ✓" বাটন** অক্ষর/হরকত/মূলধাতু/ব্যাকরণ screen-এ (ধরন `letter:`, `harakat:`, `root:`, `grammar:`), যেন M11.2 প্রগ্রেস সত্যিকারের সব মডিউল ধরতে পারে।
3. **বাকি ৭৬ সূরা-content**: পূর্ণ আরবি + বাংলা + পড়া যোগ করা — সবচেয়ে বড় দরকারি কাজ; source-নীতি মেনে ধাপে ধাপে।
4. **আয়াত-স্তরের ঘটনা** — এতক্ষণ শুধু ফাতিহা word-by-word; ৩৮ সূরার আয়াতে word-স্তর এলে vocabulary/occurrence গভীর হয়।
5. **শিক্ষক intent আরও কঠিন** (string-match → আরও গোছানো); প্রগ্রেস স্ট্রিপে অক্ষর/হরকতও দেখালে।