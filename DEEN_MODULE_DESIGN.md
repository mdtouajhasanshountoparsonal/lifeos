# 🌙 DEEN / IBADAH Module — ডিজাইন ও Implement প্ল্যান

> **মূল নীতি:** এই module-এ সবচেয়ে দামী হলো **নির্ভরযোগ্যিতা**।
> UI যত advanced, AI যত smart — **source verification তার চেয়ে বেশি গুরুত্বপূর্ণ**।
> একটা জিনিস পাকা থাকবে: **আমাদের মডেল কখনো নিজের থেকে হাদিস/আয়াত বানাবে না।**

---

## ০) নন-নেগোশিয়েবল নিয়ম (প্রথমেই স্থির)

| # | নিয়ম | কারণ |
|---|---|---|
| ১ | **হাদিসের যেকোনো text → book + number + grade (Sahih/Hasan/Da'if/Unknown) থাকতেই হবে** | অনলাইনে দুর্বল/ভুয়া হাদিস অনেক; source ছাড়া কখনো "হাদিস" হিসেবে দেখানো যাবে না |
| ২ | **দোয়ার প্রতিটায় `📚 Source` লাইন বাধ্যতামূলক** | source না থাকলে "হাদিসের দোয়া" লেবেল দেবো না, "সাধারণ দোয়া" লেখা থাকবে |
| ৩ | **AI (Gemini) কখনো নিজের থেকে হাদিস/আয়াত/ফতোয়া বানাবে না** | শুধু verified DB থেকে content নিয়ে **ব্যাখ্যা/সারসংক্ষেপ** করবে |
| ৪ | **App নিজে থেকে "তুমি নামাজ পড়োনি" ভাববে না** | শুধু reminder দেবে; "আদায় করেছি" চাপবে **ব্যবহারকারী নিজেই** |
| ৫ | **গেমিফিকেশন নয় — personal record** | "৫/৫" বোঝায় রেকর্ড, "তুমি খারাপ = ০ স্কোর" এমন guilt-মেশন নেই |
| ৬ | **সব ডেটা ডিভাইসে (Hive), offline-first** | নামাজের সময় হিসাবের জন্য লোকেশন দরকার, কিন্তু ক্লাউড/সার্ভারে কিছুই যায় না |
| ৭ | **নামাজের সময় / Arabic text পড়ার জায়গায় animation লাগবে না** | এখানে মনোযোগ দরকার — fluid-এর ব্যাকগ্রাউন্ড আলাদাভাবে gate করা |

---

## ১) আর্কিটেকচার — কীভাবে Life OS-এ বসবে

```text
                    🧠 LIFE OS (main_screen → IndexedStack)
                         │
        ┌────────────────┼────────────────┐
        ↓                ↓                ↓
   📝 নোট / কাজ      🛒 বাজার         💰 অর্থ / দেনা
        │                │                │
        └────────────────┼────────────────┘
                         ↓
                    🌙 DEEN (নতুন tab)
                         │
       ┌────────────┬────┴────┬───────────┐
       ↓            ↓         ↓           ↓
   🕌 নামাজ     📿 যিকির     📖 দোয়া/হাদিস   🧠 মুখস্থ/শেখা
```

- `main_screen.dart`-এ আবার `_Entry` যোগ না করে — DEEN-কে **Workspace hub** + **Dashboard chip** + (চাইলে) নিজের tab-এর মতো entry। কারণ মূল ফ্লো যাতে না বদলায়, আমরা নতুন জায়গায় বসাই।

---

## ২) ডেটা — Hive boxes (পুরোনো কোনো box-এ হাত নেই)

```text
deen_settings     Map   { method, madhab(asr), lat/lng, offsets, enabled_prayers,
                         notif_toggles, hijri_cal (ummalqura/tabular) }
salah_log         Map   yyyy-MM-dd → { fajr: {status, mode, ts}, ... }   // 5 ওয়াক্ত
amal_log          Map   yyyy-MM-dd → { morning_adkhar, evening_adkhar, quran_min,
                         quran_ayat, istighfar, salawat, memorized: [ids] }
tasbih_session    Map   { preset, count, saved_runs }
memorization      Map   itemId → { level 1..5, nextReview, streak, wrong }
deen_meta         Map   { daily_learn_date, last_recall, ramadan_override }
```

**Content DB (seed):** `assets/deen/`-এ versioned JSON — একবার bundle, runtime-এ parse করে সরাসরি দেখাই (Hive-এ কপি নয়, যাতে update-এ ভুল না হয়):

```text
assets/deen/
├── hadith.json        // { id, arabic, bangla, book, number, grade }
├── dua.json           // { id, section, arabic, transliteration, bangla, source, type }
├── adhkar.json        // { id, time: morning|evening, arabic, bangla, meaning, source, repeat }
├── post_prayer.json   // step list (33/33/34 + istighfar 3 + ayat kursi) + source
├── surahs.json        // [Future] surah list
└── hijri_days.json    // special days (রমজান, ঈদ, আশুরা... month/day mapping)
```

নিয়ম: প্রতিটা item-এ **source field missing হলে UI-তে "source নেই" ব্যাজ** এবং তা কখনো "হাদিস অনুযায়ী" লেবেল পায় না।

---

## ৩) ফাইল স্ট্রাকচার (new — পুরোনো ফাইল স্পর্শ না করে)

```text
lib/services/pray_times.dart        // offline সময় গণনা (Sun-position algorithm)
lib/services/deen_store.dart        // boxes read/write + helpers (like debt_store)
lib/services/deen_ai.dart           // AI ব্যাখ্যা — শুধু retrieved DB থেকে
lib/services/deen_seed.dart         // assets/deen/*.json load + validate
lib/services/deen_notifications.dart// zonedSchedule + action buttons + payload
lib/screens/deen/deen_home_screen.dart     // 🌙 DEEN hub (fluid tree)
lib/screens/deen/salah_screen.dart         // tracker + post-prayer flow
lib/screens/deen/tasbih_screen.dart
lib/screens/deen/dua_screen.dart
lib/screens/deen/hadith_screen.dart
lib/screens/deen/memorize_screen.dart
lib/screens/deen/learning_card.dart
lib/screens/deen/ramadan_screen.dart
lib/screens/deen/hijri_calendar_screen.dart
lib/screens/deen/amal_screen.dart           // 📊 আমার আমল
lib/widgets/moon_background.dart           // subtle চাঁদ-আলো (deen tab-এর পেছনে, gate করা)
```

`main.dart`-এ শুধু নতুন boxes `openBox` → বাকি app logic একদম অপরিবর্তিত।

---

## ৪) 🕌 নামাজ Tracker — implement flow

```text
TODAY                            আজ 6:05 PM
🌅 Fajr    5:11 AM   ✓ জামাতে
☀️ Dhuhr   12:40 PM  ✓ একা
🌇 Asr     4:10 PM   ○  [Tap → আদায় করেছি]
🌆 Maghrib 6:14 PM   ○
🌙 Isha    7:35 PM   ○
```

- ৫টা row, প্রতিটায় engine-এর সময়টা দেখায়; ট্যাপ → bottom sheet:
  - **"আদায় করেছি"** → mode: `জামাতে / একা / কাজা` → `salah_log`-এ save → **Post-Prayer flow চালু হয়**
  - **"এখনো করিনি"** → কিছুই change হয় না (app কখনো assumption নেয় না)
- History tab: সপ্তাহ grid (৭ দিন × ৫ ওয়াক্ত dots) — `salah_log` থেকে গুনে।

### ⏰ Prayer Times Engine (`pray_times.dart`)
- **Offline math** (standard Sun-position algorithm — pure math, ধর্মীয় রায় নয়):
  - `zoned` calculation: dawn/sunrise/noon/asr/sunset/night → ৫ ওয়াক্ত
  - `method` (MWL / Karachi / ISNA / Egyptian…) — Bangladesh-এর জন্য default **Karachi**
  - `asr` juristic: **১ = Shafi'i/Hanbali, ২ = Hanafi** → user pick
  - `highLat` rule (angle/one-seventh/middle) + manual `offsets` (± মিনিট)
- **Location:** GPS (permission হলে `geolocator`) → shared_preferences-এ lat/lng; নাহলে manual city + offset। লোকেশন কখনো আপলোড হয় না।
- UI-তে ছোট নোট: **"সময় আনুমানিক — জামাতের নির্ভুল সময় আপনার মসজিদের রুটিন অনুযায়ী মিলিয়ে নিন"** (অভ্রান্তের দাবি নেই)।

---

## ৫) 🔔 Notification Engine

`flutter_local_notifications` + `timezone` (+ exact alarms — Android 12+ permission):

- ঘণ্টা হওয়ার **ঠিক সময়ে**: `🕌 আসরের সময় হয়েছে। এখন নামাজ আদায়ের সময়।` (শিক্ষামূলক সুর)
- সবক্ষণ নয়: user-নিয়ন্ত্রিত toggle, প্রতিটি ওয়াক্ত আলাদা।
- Deep link payload → ট্যাপ করলে সরাসরি `salah_screen` খোলে (& post-prayer চালু করলে যেন অবস্থা ধরা যায়)।
- **কোনো guilt-message নেই**, কখনো "বাকি X ওয়াক্ত পড়েনি" বলে না।
- Permission না দিলে degrade: in-app banner "আজ Fajr হয়ে গেছে" — অ্যাপ ভাঙে না।

---

## ৬) 📿 Post-Prayer Mode (নামাজের পর step-by-step)

নামাজ ✅ করার পরই ফুল-স্ক্রিন ফ্লো (একটা `PageView`):

```text
🕌 FAJR COMPLETED ✓  →  [১] সُبْحَانَ اللَّهِ 33× (ট্যাপ কাউন্টার, ট্যাপে haptic)
                     →  [২] الْحَمْدُ لِلَّهِ 33×
                     →  [৩] الله أَكْبَرُ 34×
                     →  [৪] أَسْتَغْفِرُ اللهَ 3×
                     →  [৫] 📖 آية الكرسي  [Read → উচ্চারণ + বাংলা অর্থ]
```

- **প্রতিটা ধাপের পাশে 📚 source chip** — যেমন "সহিহ মুসলিম ৫৯৭" — সংখ্যা/ফজিলত কোথা থেকে, সেটা দেখানো।
- শেষে সম্পূর্ণ কার্যক্রম **`amal_log`-এ** save (আজ-এর নামাজের সাথে)।
- focus-ভিত্তিক flow; বন্ধ করা গেলে mid-done রেখে পরে resume করা যায় (Hive quick save)।

---

## ৭) 📿 Smart Tasbih

```text
        سُبْحَانَ اللَّهِ
             17
     ────────────────
   [ TAP TO COUNT ]   ← পুরো কার্ড ট্যাপে count, প্রতি ট্যাপ haptic
```

- Preset chips: SubhanAllah / Alhamdulillah / Allahu Akbar / Astaghfirullah / Salawat / **Custom (নাম+লক্ষ্য)**।
- Post-prayer flow থেকে গেলে **অটো-preset** (Subhanallah 33) লোড হয়।
- Session count Hive-এ থাকে, "সংরক্ষিত রান" হিস্ট্রি (`tasbih_session`), reset button।

---

## ৮) 🤲 Dua Library + 📜 Hadith Library

দুটো আলাদা screen, একই **verified DB ভিত্তি**:

```text
DUA                     HADITH
├── ঘুমানোর আগে          ├── Authenticity: Sahih / Hasan / Da'if / Unknown (filter)
├── ঘুম থেকে ওঠা         ├── Topics
├── খাবারের আগে/পরে       └── Saved (bookmark)
├── বের হওয়া/প্রবেশে
├── সফর/বিপদ/অসুস্থ/বৃষ্টি
├── ক্ষমা/বাবা-মা
└── অন্যান্য
```

প্রতিটা detail view:
```text
Arabic (বড়, font-সহ)
──────
বাংলা উচ্চারণ
──────
বাংলা অর্থ
──────
📚 Source: {book + number}      বা  "সাধারণ দোয়া (হাদিস নয়)"
```
- search bar (বাংলা/আরবি/keyboard), bookmark → `deen_meta` saved list।
- **AI নয়, সবটাই curated local JSON** — v1 ~৫০টি হাদিস (Bukhari/Muslim/Abu Dawud… authentic-number-সহ) + ~৬০টি দোয়া।

---

## ৯) 🧠 Memorization System (spaced repetition)

```text
🧠 AYATUL KURSI   Progress 65%
[পড়ো] [Arabic লুকাও] [Recall] [Quiz]

Level 1  → পুরোটা দেখে পড়া
Level 2  → Arabic দেখে বাংলা অর্থ মনে করা
Level 3  → কিছু শব্দ hide:  الله لَا ______ إِلَّا هُوَ
Level 4  → সব hide, নিজে বলার চেষ্টা
Level 5  → পরের দিন আবার recall
```

- `memorization` box-এ `{level, nextReview, streak}`।
- **Recurrence:** spaced repetition (SM-2-স্টাইল): পরের দিন, ৩ দিন, ১ সপ্তাহ… (নিয়মিত `nextReview` চালিয়ে যাও)।
- Daily **QUICK RECALL** card (নিচে) — due item টেনে নিয়ে "প্রথম অংশ কী?" → যাচাই করে level ঠিক।
- item গুলো হয়: দুআ, কুলমা/খুমছা, ছোট সুরা, আয়াত — সব DB-থেকে।

---

## ১০) 🌅 Morning / Evening Adhkar + "আজকের আমল"

```text
🌅 সকালের যিকির                     🌙 TODAY'S IBADAH (record, score নয়)
  ○ Dhikr 1 (repeat 3×)             Salah       5/5
  ○ Dhikr 2 (repeat 7×)             Dhikr       ✅ সম্পন্ন
  ○ Ayatul Kursi                    Quran       10 min
  ○ ... (source + repeat)           Memorize    1 verse
```

- প্রতিটা যিকিরে **Arabic → উচ্চারণ → অর্থ → repeat → source**; ট্যাপ করলে মালা-স্টাইল টিক।
- **"আজকের আমল"** = নম্বর/মিনিট-ভিত্তিক ব্যক্তিগত রেকর্ড — খেলা/স্কোর নয়।

---

## ১১) 📚 "আজ কী শিখব?" → পরের দিন RECALL

```text
📚 TODAY'S LEARNING              🧠 QUICK RECALL
আজ: একটি ছোট দোয়া               গতকাল যে দোয়া শিখেছিলে...
সময়: ২ মিনিট                     তার প্রথম অংশ কী?  [উত্তর দিন]
[পড়ুন] [মুখস্থ শুরু করুন]
```

- দৈনিক ঘূর্ণায়মান: `(date % duaList.length)` → daily learning card (offline, reproducible)।
- পড়লেই **সম্পন্ন**; "মুখস্থ শুরু" চাপলে `memorization` item তৈরি → পরের দিন recall আসে।
- `deen_meta.daily_learn_date` + `last_recall` ট্র্যাক।

---

## ১২) 🌙 Ramadan Mode + 📅 Hijri Calendar + Zakat

**Hijri calendar:**
- Offline **Umm al-Qura** (বা tabular) অ্যালগরিদম → কিন্তু UI-তে ডিসক্লেইমার:
  "হিজরি তারিখ/ঈদ প্রকৃত চাঁদ দেখার ওপর নির্ভরশীল — এটি আনুমানিক।"
- বিশেষ দিন (রমজান শুরু/শেষ, ঈদুল ফিতর/ঈদুল আজহা, আশুরা) highlight + reminder চিপ।

**Ramadan Mode:**
```text
Suhoor 04:12   Fajr 04:28   Iftar 06:17
Today: Salah 5/5 · Quran 8 পেজ · Dhikr ✓ · Charity ○
[শেষ দশ রাতের personal tracking ট্যাব]
```
- Suhoor/Iftar = engine থেকে (fajr − offset, maghrib) — অ্যানিমেশন নয়, static readable।
- **Zakat calculator:** local নিয়ম + স্পষ্ট `নিয়ম-উৎস` + "এটি ফতোয়া নয় — স্থানীয় আলেমের পরামর্শ নিন" note। নেসাব (সোনা/রুপা) user-set।

---

## ১৩) 🤖 AI — সীমিত ভূমিকা (সবচেয়ে জোর দেয়ার জায়গা)

```text
প্রশ্ন (ইউজার)
   ↓
Search verified DB (dua/hadith/adhkar)   ← একমাত্র উৎস
   ↓
Gemini: শুধু সাজানো/ব্যাখ্যা/summarize — content নিজে তৈরি নয়
   ↓
উত্তর = DB passage + source chips + সংক্ষিপ্ত বাংলা ব্যাখ্যা
```

- **Hard guard:**
  - হাদিস/আয়াত/ফতোয়া **generate নিষেধ** — code-level check (`deen_ai.dart`-এ);
  - DB-তে না পাওয়া প্রশ্নে: "এই বিষয়ের নির্ভরযোগ্য উৎস আমাদের সংগ্রহে এখনো নেই" — যেমন "আমি জানি না" বলা।
- Gemini call যাবে **বিদ্যমান `AiEnhancer`**-এর মতো same infra (`LIFEOS_GEMINI_KEY`), কিন্তু `deen_ai` ডেডিকেটেড prompt/guard দিয়ে।

---

## ১৪) 🔗 Life OS-এর সাথে সংযোগ (বিদ্যমান লজিক অপরিবর্তিত)

| জায়গা | সংযোগ (add-on, বদলানো নয়) |
|---|---|
| **Dashboard MorningSnapshot** | নতুন chip: "আজ নামাজ ৫/৫ · 🌙 দোয়া দেখো" → deen hub |
| **Notes** | «দোয়া মুখস্থ করব» → নোটের নিচে "🧠 memorize প্ল্যান" shortcut chip (অপশনাল) |
| **More/Workspace** | "LIFE INTELLIGENCE"-এর পাশে **DEEN section** (চাইলে নিজের tab) |
| **CommandSheet** | কোনো existing command পরিবর্তন নয়; [Future] আলাদা `dhikr` intent-ও আলোচনা করা যায় |

---

## ১৫) 🎨 Hollow 느낌 — Fluid UI

- DEEN tab-এর পেছনে **`moon_background.dart`** — খুব subtle চাঁদ-আলো + soft particles, slow motion (`app_background`-এর ফিশ-গেটের মতো `show_moon` setting → default on এখানে শুধু)।
- **নামাজের সময়, Arabic text, Quran পড়া, যিকির কাউন্ট** — এ জায়গাগুলোতে **কোনো animation নয়**, static focus।
- কার্ড/চিপ স্টাইল বিদ্যমান `GlassCard`-এরই (blur এখন ০ → normal card, যেটা smooth-এর জন্য ঠিক আছে)।

---

## ১৬) 📦 বাস্তবায়ন Milestones (isolated, কোনো regression নেই)

| ধাপ | Scope | কখন "রিলিজ-রেডি" |
|---|---|---|
| **M1** | `pray_times` engine + `salah_screen` (tracker/history) + `deen_settings` (method/asr/লোকেশন) | নিজের শহর/বিদেশে ব্যবহার করে validate |
| **M2** | Notification engine + action button + permission handling + deep link | ২-৩ দিন চালিয়ে দেখে |
| **M3** | Post-prayer flow + Smart Tasbih + haptic + resume | নামাজের পর daily use |
| **M4** | Seed DB (dua/hadith/adhkar JSON, source বাধ্যতামূলক) + ২ library screen + bookmark | content review (চাইলে আলেম দিয়ে) |
| **M5** | Memorization (level 1-5) + Today's Learning + Quick Recall | ১ সপ্তাহ daily |
| **M6** | Hijri calendar + Ramadan mode + zakat calc | রমজান-আগে |
| **M7** | `deen_ai` (bounded Q&A) + Life OS chips | সবশেষে |

প্রতিটা ধাপে: নতুন বক্স/ফাইল, পুরোনো কোডে হাত নেই → **"এত দিনের কষ্ট" অক্ষত** থাকবে।

---

## ১৭) ⚠️ ঝুঁকি ও সতর্কতা

1. **Content accuracy** — সবচেয়ে বড় ঝুঁকি। প্রতিরোধ: curated DB, source field বাধ্যতামূলক, দুর্বল/অজানা হাদিস কখনো "Sahih" লাগবে না, AI-কে content generate করার সুযোগ নেই। চাইলে একজন আলেম দিয়ে ভালোভাবে review করানো যাবে (M4-এ pause)।
2. **Prayer time নির্ভুলতা** — method/asr/offset আলাদা করে দেওয়া; UI-তে "আনুমানিক" নোট; জামাতের চূড়ান্ত সময়-উৎস আমাদের নয় বলে disclaimer।
3. **Notification permission** — Android 13+ runtime + exact alarm; না দিলে in-app fallback, app ভাঙে না।
4. **Hijri date vs moon-sighting** — Umm al-Qura আনুমানিক; ঈদের দিন আসলে চাঁদ দেখার ওপর নির্ভরশীল — তাই ডিসক্লেইমার।
5. **Privacy** — lat/lng শুধু লোকেল, ক্লাউড নয়; parent ফ্লোতে কিছুই বদলায় না।

---

## ১৮) রিভার্ট (কোনো একটা ধাপ ভালো না লাগলে)

- DEEN সম্পূর্ণ আলাদা: `screens/deen/` + `services/deen_*.dart` + ২-৩টা new box।
- সরাতে: ফাইলগুলো delete + `main.dart`-এর `openBox` line + entry/chip remove → সবকিছু আগের মতো।
- পুরোনো বক্স (`notes/tasks/expenses/prices/...`) **কখনো স্পর্শ করা হয়নি** — data-safe।

---

**সংক্ষেপে:** আমি প্রথমে **M1 (নামাজ ট্র্যাকার + pray-times engine)** থেকে শুরু করবো — কারণ এটাই সবচেয়ে দৈনন্দিন প্রয়োজন আর বাকি সব তার ওপর দাঁড়ায় (post-prayer, log, notifications)। Content-বিষয়ক সবকিছুতে **source-first** policy মেনে চলবো। তুমি M1 অনুমোদন করলে সেখান থেকেই বাস্তবায়ন শুরু হবে — আপাতত শুধু এই ডিজাইন ডক।