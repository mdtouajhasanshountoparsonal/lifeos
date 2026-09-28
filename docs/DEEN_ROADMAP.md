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
| M12 | Speaking/Listening | বাক্য বলো → Gemini/পরিবেশে চেক, dashnote: dedicated speech tech ছাড়া pronunciation judge নয় | ⏳ |

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
- `lib/services/arabic_teacher.dart` + `arabic_teacher_screen` — offline প্রশ্ন-উত্তর: হরকত / অক্ষর / শব্দভাণ্ডার / মূলধাতু / পথনির্দেশনা / ফাতিহা / ব্যাকরণ intent। Online `Gemini` চালু থাকলে (`AiSettings.onlineEnabled` + `LIFEOS_GEMINI_KEY`) ফ্রি-প্রশ্নেও উত্তর; না থাকলে নিজেই offline-এ নামে।
- রিপো `manifest.json` + `content_store_screen` — কোন কোন সম্পদ আছে (version, count, source) + "আবার নামাও" (force re-download)। Loader: `ContentRepository` (`content_repository.dart`) — GitHub → strict-JSON validate → Hive ক্যাশ → offline।

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