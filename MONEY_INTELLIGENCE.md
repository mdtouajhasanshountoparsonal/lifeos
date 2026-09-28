# LifeOS — Money Intelligence (Personal Finance Intelligence System)

> অফলাইন, হিরিস্টিক ইন্টেলিজেন্স — সব বিশ্লেষণ শুধু তোমার saved data থেকে (অনুমান নয়)।

## ✅ Phase 1 — Money Dashboard (সম্পন্ন)

### Dashboard (অর্থ tab নতুন রূপ)
- মাস নেভিগেশন ‹ সেপ্টেম্বর ২০২৬ › (আগের/পরের মাস ধরে দেখার সুযোগ)
- **বড় বাকি-রাখা কার্ড**: অবশিষ্ট বড় সংখ্যা + আয়/খরচ/বাজেট + গত মাসের সাথে % তুলনা (↓ 12% কম / ↑ 8% বেশি)
- **দ্রুত পরিসংখ্যান**: আজ / এই সপ্তাহ / এই মাস / গড়-প্রতিদিন
- **📈 গত ৩০ দিন বার চার্ট** (custom painter, কোনো package নেই); আজকের বারে লাল highlight

### 📅 মাসের মানচিত্র (Calendar heatmap)
- সপ্তাহ হেডার সহ দিন-গ্রিড
- প্রতিদিনের খরচ অনুযায়ী **রঙের intensity** (কম খরচ → বেশি খরচ)
- আজকের দিন গ্লো বর্ডার দিয়ে চিহ্নিত
- দিনে চাপ → দিনের বিস্তারিত sheet (খরচ + ক্যাটাগরি চিপ), প্রতিটি লেনদেন tap → edit/delete

### 🔥 কোথায় যাচ্ছে? (Category breakdown)
- ১০টি ক্যাটাগরি: খাবার, যাতায়াত, ইন্টারনেট, শপিং, গেমিং, শিক্ষা, বাড়ি, স্বাস্থ্য, বিল, অন্যান্য
- % + প্রগ্রেস বার; ক্যাটাগরি tap → লেনদেন ফিল্টার

### 🔁 প্রতি মাসে (Recurring expenses)
- একই title গ্রুপ করে (≥২ বার, ২০–৪০ দিনের ব্যবধান, পরিমাণ ~সমান) → "পরের: d MMM" প্রেডিকশন

### ⚠️ অস্বাভাবিক খরচ (Anomaly)
- আজকের খরচ vs গত ১৪ দিনের গড় → ১.৮× বেশি ও ≥ ৳৫০০ হলে সতর্কতা
- কারণ লেখা যায় (planned purchase হিসেবে সংরক্ষিত)

### 🎯 বাজেট (Budget)
- প্রতিটি ক্যাটাগরিতে মাসিক বাজেট সেট; ব্যবহৃত/অবশিষ্ট + % বার
- ≥৮০% → হলুদ, >১০০% → লাল

### লেনদেন ব্যবস্থাপনা
- ক্যাটাগরি ফিল্টার চিপ, edit/delete (tap), আয়/খরচ toggle
- **Smart add** ⚡: `আজ ৩০০ টাকা বাজার` / `120 tk lunch` → অ্যাপ নিজে amount/category/date ভর্তি করে (CommandParser), তারপর confirm
- তারিখ পিকার (পেছনের কোনো দিনও এন্ট্রি)

### 🧾 Screenshot → Expense (Receipt)
- Screenshot Inbox-এর OCR-এ টাকা পেলে (৳/Total/মোট) **সংরক্ষণ** চাপলে সরাসরি expense হিসেবে সংরক্ষণ; store, amount, category, date auto-ভর্তি

## 📦 Storage
- `expenses` (Hive) — আগেরই; ক্যাটাগরি এখন ১০টি
- `money_settings` (নতুন): `budgets` (Map), `anomaly_note` (String)

## 🔜 Phase 2 — Planned (আইডিয়া / পরবর্তী ধাপ)

- **💳 Bills & Financial Calendar**: আগামী প্রিডিক্টেড খরচ date-wise (`18 Sep Internet -৳600`, `25 Sep +৳30,000`)
- **🔎 Search**: "এই মাসে খাবারে ৫০০-এর বেশি কোন দিন?", "গত ৩ মাসে ট্রান্সপোর্ট মোট কত" — NL query → result
- **🖥️ Month vs Month তুলনা কার্ড** (প্রতিটি ক্যাটাগরিতে ↑/↓)
- **💾 Export/Backup**: all transactions → share .csv/.json; import
- **🔐 Money Lock**: PIN/fingerprint (notes-এর মতো) + amount blur toggle
- **📍 Location / 첨부 files** per transaction
- **🎬 Money Replay**: মাস-জুড়ে animated financial playback (income/category flow playback)

## ️🎯 নীতি
- **নো অনুমান**: AI-সারাংশও শুধু stored data থেকে ব্যাখ্যা।
- **অফলাইন**: কোনো cloud/API নেই।
- **পর্যায়ক্রম**: Phase 1 live → Phase 2 ধাপে ধাপে।