# 🌙 DEEN — Islamic Knowledge + Arabic Learning Platform

> মূল লক্ষ্য: **আরবি পড়তে শেখা, কুরআন শেখা।**
> ইবাদাত (নামাজ/যিকির/দুয়া) থেকে শুরু — এখন এটাকে পুরো Knowledge Platform বানানো হচ্ছে।
> নীতি: offline-first, source-first ("source নেই" → বেজ "source নেই", কখনো "হাদিস অনুযায়ী" নয়), কোনো স্কোর/গিল্টি নয় (রেকর্ড — বিচার নয়), কোনো অ্যানিমেশন নয়। Content সব সময় JSON → bundle → runtime-এ isLoading। লোকাল progress শুধু Hive-তে।

---

## ১. পুরো সিস্টেম

```text
                    🌙 DEEN
                       │
       ┌───────────────┼────────────────┐
       ↓               ↓                ↓
    🕌 IBADAH       📖 QURAN       🟢 ARABIC
       │               │                │
    Salah           Surah             Learn
    Dhikr           Ayah              Read (মূল লক্ষ্য)
    Dua             Tafsir            Word-by-word
    Hadith          Translation       Build
```

সবcontent জোড়া থাকে `id`, `source`, `version`, `language`, `relatedIds`, `rootWord`, `topicId` — দিয়ে। ফলে
একটা Arabic word → কুরআন আয়াত → vocabulary lesson → memorization → Note — সব connected।

---

## ২. Content Repository (GitHub-model)

**আজ:** সবcontent অ্যাপের বাইরে — `github.com/mdtouajhasanshountoparsonal/islamic_data` (public)। প্রথম খোলায় download-screen → manifest + ফাইল strict-validate → Hive ক্যাশ (`content_meta`/`content_data`) → তারপর সম্পূর্ণ offline। `assets/deen/` মুছে ফেলা হয়েছে। রিপো এখনো GitHub-এ push হয়নি (user ওয়েবে repo বানালে হবে)।

**M9 (বাকি):** রিপো push + প্রথম-run ডাউনলোড টেস্ট। Update-এ শুধু changed file (version tracking) — `content_store_screen`-এ "আবার নামাও"।

```text
islamic_data/
├── manifest.json            # version tracking
├── quran/  surahs.json + surah_001..114.json
├── hadith/ books.json + bukhari_*.json ...
├── dua/    daily / salah / morning / evening / protection
├── adhkar/ after_salah / morning / evening
├── arabic/ alphabet, harakat, vocabulary, grammar, verbs, sentences, lessons
└── metadata/ versions, sources
```

**app → content pipeline:**
```text
GitHub JSON → Downloader → Validator → Local DB → Repository → Offline UI
```

---

## ৩. রোডম্যাপ (milestone)

| Phase | নাম | কাজ | অবস্থা |
|---|---|---|---|
| M1–M4 | ইবাদাত base | নামাজ, তাসবিহ, দুয়া, হাদিস, post-prayer | ✅ |
| M5 | আমল + মুখস্থ | আজকার, আজকের আমল, মুখস্থ ধাপ ১→৫, আজকের শিক্ষা + **সব ছোট সুরা (৩৮টি)** + Bengali পড়া (transliteration) | ✅ |
| **M6** | **আরবি পড়া — কুরআন** (মূল লক্ষ্য) | Alphabet → Harakat → শব্দ পড়া → কুরআন শব্দ (ফাতিহা word-by-word) | ✅ |
| M7 | শব্দভাণ্ডার | কুরআন vocabulary (رَبّ, رَحْمَة…), "শব্দ কোথায় এসেছে" | ✅ |
| **M8** | **Root word system** | ক-ত-ব → كتب/كتاب/كاتب… tree | ✅ |
| M9 | Content updater | অ্যাপ-বাইরে GitHub রিপো (`islamic_data`) → first-run ডাউনলোড → offline Hive | 🚧 রিপো push ও first-run টেস্ট বাকি |
| **M10** | **Grammar** | Noun/Verb/Particle → Gender → Number → Case → Sentence role, বাংলায় | ✅ |
| **M11** | **AI Teacher** | offline প্রশ্ন-উত্তর (সেভ করা content), Gemini চালু থাকলে আরও (M11.1 ✅; M11.2 ✅ — ব্যক্তিগত প্রগ্রেস রেকর্ড: কোন ধাপে কতটুকু "জানি ✓", পরের ধাপের পরামর্শ, আজকের প্রশ্ন-সংখ্যা, রেকর্ড — স্কোর নয়) | ✅ |
| M12 | Speaking/Listening | বাক্য বলো → **(v1 ✅)** "🗣️ বলে পড়ো" self-check: শব্দ/শব্দভাণ্ডার/ফাতিহা আয়াত — আরবি দেখে নিজে পড়ে বলো, পড়া/অর্থ পরে খুলো, `said:*` লোকাল রেকর্ড (রেকর্ড, বিচার নয়)। **Listening (audio content/TTS) ও pronunciation-judge এখনো নেই** — dedicated speech tech ছাড়া সম্ভব নয় | 🚧 |
| **M13** | **কুরআন পড়ার মূল ফেজ** ("শুধু কুরআন পড়াই শিখি") | **(✅ কনটেন্ট)** সব ১১৪ সূরার আয়াত-ধরে-আয়াত (রাসম-ই-উসমানি লিপি, alquran.cloud quran-academy, যাচাই: ৬২৩৬ আয়াত) + প্রতি আয়াতের বাংলা অনুবাদ (Muhiuddin Khan) + **প্রতি আয়াতের বাংলা-বানানে পড়া `tl`** (স্বয়ংক্রিয় মেকানিক্যাল ট্রান্সলিটারেশন, ৬২৩৬ আয়াত) → `quran/NNN_id.json` `ayahs:[{n,ar,bn,tl}]`; `arabic/letters_quran.json` (প্রতি অক্ষরের কুরআন থেকে বাস্তব শব্দ-উদাহরণ, ২৮×৪=১৬৮)। **(✅ App)** reader: আয়াত-কার্ডে **৩ লাইন সবসময় দেখা** (স্পষ্ট আরবি ২১px → "🔤 বাংলা-বানানে পড়া" → "💬 অর্থ"), টিক ২টি — **"মুখস্থ ✓"** (`mem:<i>:<n>`, ★) + **"পড়া শেষ ✓"** (`read:<i>:<n>`, ✓) — সাথে "কঠিন ⚠️" (hard); পড়া-টগল সরানো; সূরার ভেতরে প্রগ্রেস-কার্ড (পড়া X/Y · মুখস্থ A/B) + সূরা-তালিকার শীর্ষে **সার্বিক % (পড়া ও মুখস্থ, /৬২৩৬)**; সূরা-লেভেল `transliteration` ডেটা-বাগ ফিক্স (০৭৯–১১৪-এ পরের সূরার টেক্সট ছিল → মুছে ফেলা); `${_bn(...)}` closure-bug ফিক্স | ✅ |

---

## ৪. M6 — আরবি পড়া (এখন যা বানাচ্ছি)

কুরআন পড়ার জন্য ধাপ-ধাপ:

```text
🔤 Alphabet → 🪄 Harakat → ✍️ যোগের রূপ → 📖 শব্দ পড়া → 📖 কুরআনের শব্দ
```

- রিপো `islamic_data/arabic/letters.json` — ২৮ অক্ষর: নাম, বাংলা উচ্চারণ, isolated/initial/medial/final রূপ, উদাহরণ।
- `arabic/harakat.json` — ফতহা, কাসরা, দাম্মা, সুকুন, শাদ্দা, তানউইন (৩), মাদ (ا / ى / و)। প্রতিটাতে `ب`-এর ওপর demo।
- `arabic/words.json` — শুরুতে পড়ার সহজ শব্দ (بَاب, بَيْت, قَلَم…), পড়া+অर्थ, "জানি ✓" মার্ক।
- `quran/fatiha_words.json` + ৩৮টি `quran/NNN_id.json` — সূরা শব্দ-শব্দ + পূর্ণ অনুবাদ।
- Screens: `arabic_home_screen` (hub) → `arabic_alphabet_screen` → `arabic_harakat_screen` → `arabic_words_screen` → `quran_words_screen`।
- progress: Hive box `deen_arabic` (কে কোনটা "জানি ✓" করেছে), কোনো স্কোর নেই।

---

## ৪.১ M7–M11 — শব্দভাণ্ডার → মূলধাতু → ব্যাকরণ → শিক্ষক

- `arabic/vocab.json` — ১৯টি শব্দ (রব্ব, রাহমাহ, ইলম…): অর্থ, মূলধাতু, "কুরআনে কোথায় এসেছে" (সূরা:আয়াত + আরবি + বাংলা)। Screen: `vocabulary_screen` + "জানি ✓" (`vocab:<id>`)।
- `arabic/roots.json` — ৬টি মূলধাতু (كتب, رحم, علم, صبر, سلم, نور): এক শিকড় থেকে বড় হওয়া শব্দের তালিকা। Screen: `root_words_screen` (ট্যাপে শাখা খোলে)।
- `arabic/grammar.json` — ৭টি পাঠ: নাম, আল-, নামবাক্য, ক্রিয়াবাক্য, অবস্থা-শব্দ, সর্বনাম, বাক্য গড়া — সব উদাহরণ কুরআন থেকে। Screen: `grammar_screen`। Loader: `ArabicSeed.grammar()`।
- `lib/services/arabic_teacher.dart` + `arabic_teacher_screen` — offline প্রশ্ন-উত্তর: হরকত / অক্ষর / শব্দভাণ্ডার / মূলধাতু / পথনির্দেশনা / ফাতিহা / ব্যাকরণ intent। Online `Gemini` চালু থাকলে (`AiSettings.onlineEnabled` + `LIFEOS_GEMINI_KEY`) ফ্রি-প্রশ্নেও উত্তর; না থাকলে নিজেই offline-এ নামে। M11.2: `lib/services/deen_progress.dart` — ব্যক্তিগত প্রগ্রেস রেকর্ড (কোন ধাপে কতটুকু "জানি ✓", পরের ধাপ, আজকের প্রশ্ন-সংখ্যা; রেকর্ড — স্কোর নয়) + শিক্ষক স্ক্রিনে লাইভ প্রগ্রেস স্ট্রিপ।
- `lib/screens/deen/speak_drill_screen.dart` + হাব কার্ড — M12 v1 "🗣️ বলে পড়ো" (self-check read-aloud): শব্দ / শব্দভাণ্ডার / ফাতিহা আয়াত; আরবি দেখে নিজে পড়ে বলা, পড়া/অর্থ পরেই খোলা, `said:<kind>:<id>` লোকাল রেকর্ড।
- রিপো `manifest.json` + `content_store_screen` — কোন কোন সম্পদ আছে (version, count, source) + "আবার নামাও" (force re-download)। Loader: `ContentRepository` (`content_repository.dart`) — GitHub → strict-JSON validate → Hive ক্যাশ → offline।

---

## ৪.২ M13 — কুরআন পড়ার মূল ফেজ (আয়াত-ধরে-আয়াত)

- **কনটেন্ট (`islamic_data`)**: সব ১১৪ সূরার ফাইল আপডেট/নতুন — `ayahs:[{n, ar, bn}]` = রাসম-ই-উসমানি (কুরআনের আসল লিপি, alquran.cloud `quran-academy` edition) + বাংলা অনুবাদ (Muhiuddin Khan)। ৭৬টি সূরা আগে metadata-only ছিল → এখন পূর্ণ পাঠ। মোট ৬২৩৬ আয়াত (উৎস-সহ যাচাই)। `manifest.json` — ১২৭টা ফাইল, sunra kind-এর double-encoded mojibake ফিক্স (`সূরা <নাম>`), নতুন ফাইল যোগ। `arabic/letters_quran.json` — ২৮ অক্ষরের কুরআন-উদাহরণ (isolated/initial/medial/final)।
- **App**: `SurahItem.ayahs` (new `SurahAyah` + `tl`) → reader-এ লাইন-লাইন আয়াত কার্ড: **৩ লাইন সবসময়** — স্পষ্ট আরবি (২১px, রাসম-ই-উসমানি) → "🔤 বাংলা-বানানে পড়া" (স্বয়ংক্রিয় মেকানিক্যাল ট্রান্সলিটারেশন, সুন্ন-ল্যাম/শদ্দা/তানউইন/মাদ-সিপ ম্যানেজ করা) → "💬 অর্থ" (অর্থ-টগল সরানো — সবসময় দেখানো)। টিক ২টি: "মুখস্থ ✓" (`mem:<i>:<n>`) দিয়ে নিজের মুখস্থ মার্ক + "পড়া শেষ ✓" (`read:<i>:<n>`)। সূরার প্রগ্রেস-কার্ড + সূরা-তালিকার শীর্ষে সার্বিক "পড়া শেষ X% · মুখস্থ Y%"। "কঠিন ⚠️" (`hard:*`) আগের মতো। `DeenStore`-এ `mem` লিস্ট (`quranMemMark/Unmark`, `quranMems`) + `quranReads()` (শুধু `read:*` কিগুলো)। **Data bug-fix**: `001_fatiha` বাদে সব সূরার লেভেল `transliteration` এখন খালি (০৭৯–১১৪-এ পরের সূরার টেক্সট বসানো ছিল — পুরনো জেনারেটর বাগ); এখন পড়া প্রতিটি আয়াতে `tl`-এ।
- **ব্যবহার**: অ্যাপ আপডেটের পর Content Store → "আবার নামাও" (নতুন ১২৭-ফাইল বান্ডল) → সব ১১৪ সূরা লাইন-লাইন পড়া যায়, offline-এ।
- **আগামী (M12 listening/pronunciation)**: শুধু স্পিচ-টেক (TTS/audio) বাকি — তাই এখানে নয়।

---

## ৫. প্রতিটা learning unit-এর pattern

```json
{
  "id": "rabb",
  "letter": "ر",
  "arabic": "بَاب",
  "reading": "বা-ব",
  "bangla": "দরজা",
  "rootWord": "ب و ب",
  "source": "ভাণ্ডার",
  "examples": ["بَاب", "بَابٌ"]
}
```

UI-তে যে নিয়ম:
- আরবি text **সবসময়** বড় + right-aligned।
- Reading (বাংলা পড়া) → সব item-এর সাথে calculate করে দেওয়া (আমরা নিজে writer; মেশিন الن)।
- "জানি ✓" → সবুজ, কোন খারাপ mark নেই। (`কেন ভুল হয়েছে` শুধু shadow, blame নয়।)
- source-হীন হলে: "source নেই" badge।

---

## ৬. Notes/Knowledge-Graph ফিট

- Note-এ লিখলে `الْحَمْدُ لِلَّهِ মানে কী?` → AI Arabic-leaning query।
- "আজ رحمه শব্দটা শিখলাম" → Arabic vocabulary-তে save।
- "এই দুআ মুখস্থ করব" → Deen → Memorization-এ save।
- Knowledge Graph: word → ayah → lesson → memorization → Note।

---

## ৭. architecture rules (যা মেনে চলব)

1. App-এর existing logic কখনো change নয় — শুধু নতুন file/box/entry।
2. AI-কে content database বানাবো না — local verified content-এর ওপর teacher/explainer।
3. Offline first — প্রথমবার একবার ইন্টারনেট (রিপো থেকে ডাউনলোড), তারপর সম্পূর্ণ offline।
4. Content JSON একজায়গায় (GitHub `islamic_data` রিপো), loader সেন্ট্রাল (`ContentRepository`), UI কখনো সরাসরি JSON পড়ে না।