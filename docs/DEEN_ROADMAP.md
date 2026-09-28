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

## ২. Content Repository (GitHub-model, ভবিষ্যৎ)

**আজ:** content bundle-এ (`assets/deen/*.json`), আগের ফার্স্ট-রান সব ঠিক।

**M9 (ভবিষ্যৎ):** প্রতিটি বিষয় আলাদা JSON → GitHub repo → প্রথমবার download → local DB → offline। Update-এ শুধু changed file।

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
| M9 | Content updater | Content manifest (bundled inventory) — GitHub download/diff update | 🚧 M9.1 শেষ, M9.2 রিপো লাগবে |
| **M10** | **Grammar** | Noun/Verb/Particle → Gender → Number → Case → Sentence role, বাংলায় | ✅ |
| **M11** | **AI Teacher** | offline প্রশ্ন-উত্তর (সেভ করা content), Gemini চালু থাকলে আরও (M11.1 শেষ; grading/ব্যক্তিগত প্রগ্রেস M11.2) | 🚧 |
| M12 | Speaking/Listening | বাক্য বলো → Gemini/পরিবেশে চেক, dashnote: dedicated speech tech ছাড়া pronunciation judge নয় | ⏳ |

---

## ৪. M6 — আরবি পড়া (এখন যা বানাচ্ছি)

কুরআন পড়ার জন্য ধাপ-ধাপ:

```text
🔤 Alphabet → 🪄 Harakat → ✍️ যোগের রূপ → 📖 শব্দ পড়া → 📖 কুরআনের শব্দ
```

- `assets/deen/arabic_letters.json` — ২৮ অক্ষর: নাম, বাংলা উচ্চারণ, isolated/initial/medial/final রূপ, উদাহরণ।
- `assets/deen/arabic_harakat.json` — ফতহা, কাসরা, দাম্মা, সুকুন, শাদ্দা, তানউইন (৩), মাদ (ا / ى / و)। প্রতিটাতে `ب`-এর ওপর demo।
- `assets/deen/arabic_words.json` — শুরুতে পড়ার সহজ শব্দ (بَاب, بَيْت, قَلَم…), পড়া+অর্থ, "জানি ✓" মার্ক।
- `assets/deen/quran_words.json` — সূরা ফাতিহা word-by-word: প্রতিটি শব্দের আরবি + বাংলা; পুরো আয়াত ধরে পড়া-চর্চা।
- Screens: `arabic_home_screen` (hub) → `arabic_alphabet_screen` → `arabic_harakat_screen` → `arabic_words_screen` → `quran_words_screen`।
- progress: Hive box `deen_arabic` (কে কোনটা "জানি ✓" করেছে), কোনো স্কোর নেই।

---

## ৪.১ M7–M11 — শব্দভাণ্ডার → মূলধাতু → ব্যাকরণ → শিক্ষক

- `assets/deen/quran_vocab.json` — ১৯টি শব্দ (রব্ব, রাহমাহ, ইলম…): অর্থ, মূলধাতু, "কুরআনে কোথায় এসেছে" (সূরা:আয়াত + আরবি + বাংলা)। Screen: `vocabulary_screen` + "জানি ✓" (`vocab:<id>`)।
- `assets/deen/root_words.json` — ৬টি মূলধাতু (كتب, رحم, علم, صبر, سلم, نور): এক শিকড় থেকে বড় হওয়া শব্দের তালিকা। Screen: `root_words_screen` (ট্যাপে শাখা খোলে)।
- `assets/deen/arabic_grammar.json` — ৭টি পাঠ: নাম, আল-, নামবাক্য, ক্রিয়াবাক্য, অবস্থা-শব্দ, সর্বনাম, বাক্য গড়া — সব উদাহরণ কুরআন থেকে। Screen: `grammar_screen`। Loader: `ArabicSeed.grammar()`।
- `lib/services/arabic_teacher.dart` + `arabic_teacher_screen` — offline প্রশ্ন-উত্তর: হরকত / অক্ষর / শব্দভাণ্ডার / মূলধাতু / পথনির্দেশনা / ফাতিহা / ব্যাকরণ intent। Online `Gemini` চালু থাকলে (`AiSettings.onlineEnabled` + `LIFEOS_GEMINI_KEY`) ফ্রি-প্রশ্নেও উত্তর; না থাকলে নিজেই offline-এ নামে।
- `assets/deen/content_manifest.json` + `content_store_screen` — কোন কোন সম্পদ বান্ডলে আছে (path, version, count, source)। `repo: null` → GitHub update (M9.2) বাঁধার জায়গা প্রস্তুত।

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
3. Offline first — content bundle থেকে; internet চাই না রান-টাইম।
4. Content JSON একজায়গায় (assets/deen), loader সেন্ট্রাল (services), UI কখনো সরাসরি JSON পড়ে না।