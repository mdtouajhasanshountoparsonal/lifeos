# LifeOS — Advanced Note Feature Ideas (L1 Notes)

> সব "টেক্সটের ভেতরে টানাটানি" আইডিয়া এক জায়গায়।
> This document collects the advanced note-editor feature ideas — what's done now and what's planned.

## ✅ সম্পন্ন (Implemented)

### 1. Live Formatting — WYSIWYG-ish editing
- **Bold** (`**`) / *Italic* (`*`) / **Underline** (`__`) / <big>big</big> / <small>small</small> render **live while typing** — markers `**`, `*`, `__` hidden, text looks Word-like.
- Toolbar B / I / U / A+ / A- wrap the selection (or place markers at the cursor).
- `#`/`##`/`###` = headings, `> ` quote, `- ` bullet, `1. ` numbered, `☐ ` checklist work in both edit & preview.

### 2. Auto-continue lists (Numbered → 1, 2, 3 …)
- Press **Enter** inside a numbered / bullet / checklist / quote line:
  - `1. …` → next line auto becomes `2. `
  - `- …` → next line auto becomes `- `
  - `☐ …` → next line auto becomes `☐ ` (or `[ ] `)
  - `> …` → next line auto becomes `> `
- Press Enter on an **empty** list item → the list ends (no more markers).

### 3. Checklist toggle
- In **preview** mode the `☐`/`[ ]` boxes are **tappable** — tap to check/uncheck (☑). Same toggle works in the tree view.

### 4. Shopping / বাজার auto-total 🧮
- Write `দুধ 50`, `আলু ২০`, `৳120`, `ডিম 12` style lines → a live strip shows **মোট ৳ X (Nটি আইটেম)**.
- Tap the strip → itemized breakdown sheet with the running total.
- Works in edit AND preview; updates as you type.

### 5. Tree / Outline (গাছ)
- ⋮ → **🌳 গাছ/আউটলাইন** builds a heading tree (`#`, `##`, `###`).
- Each heading is an expandable branch; expand to read part-of-note (tree-view reading).
- Write notes part-by-part using headings — each `# ` becomes a collapsible section.

### 6. Keyboard fix
- Editor sheet now **rises above the keyboard** (`viewInsets` padding) — what you type stays visible.

## 🔜 Planned / Ideas (future)

### 7. Word-like, even stronger
- True rich-text (bold/italic/underline applied to selected words, no marker chars at all, selection-aware).
- Font size / color picker, highlight, alignment (left/center/right), horizontal ruler.
- Copy-paste rich content across apps (span-based clipboard).

### 8. Smart nested lists & indentation
- Tab / Shift-Tab to indent bullets, sub-numbering `1.1`, `1.2`.
- Drag to reorder list items; drag sections in the tree.

### 9. Sections as blocks (Dashboard-style notes)
- Make each `# section` its own movable "block" (drag handles), like Notion.
- Collapse a whole section in edit mode to focus.

### 10. Templates
- Quick templates: shopping list, meeting notes, diary, homework, recipe.
- `/command` slash menu to insert template blocks.

### 11. Math
- `$a^2 + b^2$` / `$$\sum$$` inline math render (simple parser, offline).

### 12. Tables
- Type `|col1|col2|` rows → auto table formatting with sum column for money.

### 13. Smarter shopping
- Per-item price tags: `দুধ 2×50` (qty × price) → auto multiply, show `100`.
- Tax / discount rows: `ছাড় 5%`, `ডেলিভারি 20` → add to total.
- Tap item in breakdown → jump back to that line in editor.

### 14. Natural-language capture wiring
- "Add to Note" flows from QR (`নোটে`), Smart Clipboard, Screenshot review — writing these blocks as styled sections + source stamp.

### 15. Export / backup
- Export a note (or the whole vault) to `.md` / `.txt` via share sheet; import back.
- Auto-save draft on every keystroke (already versioned on save).

### 16. Readability & focus
- Focus mode: dim everything but the current paragraph; word count + reading time bar.

---

## 🧠 VISION — Visual Smart Note (Block-based programmable workspace)

> মূল ধারণা: Note লেখা নয় — প্রতিটি Note-এর ভেতরে ছোট একটা **programmable workspace**।

### 1. Smart Calculation Blocks (এডিটেবল)
`বেগুন 20` → **৳20** হিসেবে বোঝে; রাশি বদলালে `20 → 30` → total **অটো** বদলায়।
- **qty × price**: `আলু 10 × 5 kg` → `আলু 10 × 5 = ৳50`
- `Total = ৳490` стек auto-sum; প্রতিটি আইটেমের পাশে Edit।
- **Linked calculation**: এক Note-এর total অন্য Note-এ `[Linked]` — উৎস বদলালে দুই জায়গাই update।

### 2. 🌳 Multi-Part Tree Note
- Note-এর ভেতরে unlimited branch: `বাজার ▸ আলু/বেগুন/মাছ`, `যাতায়াত ▸ বাস/রিকশা...`
- প্রতিটি branch **collapse/expand** (`▼`/`▶`)।
- একই data → Tree, Table, List view-এ (ডেটা এক, ভিউ আলাদা)।

### 3. 🎨 Paint / Drawing System
- Note-এর ভেতরে Canvas: আঁকা, circle, arrow, handwritten annotation, highlight, diagram, measurement — finger/stylus দিয়ে।

### 4. 🧩 Multi-Part Blocks
| Block | কাজ |
| --- | --- |
| 📝 Description | লিখিত অংশ |
| 💰 Calculation | auto-sum/qty×price |
| ☑ Checklist | tap করে টগল |
| 🌳 Tree | branch/collapse |
| 🎨 Drawing | canvas |
| 📷 Image | ছবি |
| 🔗 Link | @সংযোগ |
| 📋 Clipboard | smart clipboard থেকে insert |
| 📱 QR | QR ফলাফল |
| 🎙️ Voice | ভয়েস নোট |
| 📊 Table | item rows + মোট |
| 🧠 AI | stored-data বিশ্লেষণ |

### 5. View Mode
একই Note → `▦ Blocks / 🌳 Tree / 📊 Table / 🎨 Canvas / 📋 List / 🧮 Calculation` — user যেভাবে চায় সেভাবে দেখে।

### 6. Ecosystem সংযোগ
Clipboard → Screenshot → QR → Note → অর্থ: সবকিছু একই Note-এ **editable + calculatable + visual + tree-based** data হিসেবে আসে।

---

## ✨ NEW — আজকের বাজার: Colorful Part-Tree + Animated `}`-Brace Math

> এই আপডেটে Note-এর সবচেয়ে প্রিয় কাজটা — **"part-ভিত্তিক লেখা"** — এখন একটা colorful, date-aware, calculatable ওয়ার্কস্পেস।

### A. 🌳 Part-Tree (multi-level colorful)
- `# আজকের বাজার` → শিরোনাম, `## মাছের হাট`, `## সবজি` — প্রতিটি অংশ আলাদা **ডাল** (branch)।
- **প্রতিটি লেভেলের আলাদা রং**: `#`(primary) → `##`(secondary) → `###`(mediumPriority) → বেশিক্ষণের অংশ(glow)।
- **Headings-এ তারিখ চিপ**: শিরোনামে থাকলে `আজ`, `কাল`, `আগামীকাল` → তারিখের chip বের হয় (যেমন `আজ • 18 Sep`)।
- লেভেল-১ শিরোনাম **বড় & বোল্ড (17px/w900)** — পুরো নোট এক নজরে।
- প্রতিটি ডাল **tap করে collapse/expand (AnimatedSize)**, content-এর বাঁয়ে level-এর রঙের border।

### B. 🧮 Animated `}`-Brace Calculation
- বাজারের আইটেম (`আলু ৫০`, `বেগুন ৩০`) লেখা মাত্রই নিচে **রসিদ-স্টাইলের গ্র্যাডিয়েন্ট ব্লক**:
  - উপরে আইটেম list (ম্যাক্স ৪টি + "+n আরো") — প্রতিটিতে ৳ দাম।
  - ডান পাশে **বড় `}` বন্ধনী (৫৪px, thin, income→glow গ্র্যাডিয়েন্ট)**, ধীরে ধীরে **pulsing glow**।
  - নিচে `মোট ৳ ৮০` — টোটাল বদলালে **animated scale/switcher**।
- Tap → itemized breakdown sheet; আনলিমিটেড আইটেম।

### C. 🔮 NEW Advanced Idea — «বাজার live-card + tree↔editor sync»
1. **মোতত্ব লাইভ কার্ড (Dashboard)**: Dashboard-এ "বাজার লাইভ" কার্ড — সপ্তাহে যতবার `# বাজার` নোট লেখা, কার্ডে auto মোট + সব অংশের চেকলিস্ট progress ring। উৎস নোট edit করলেই কার্ড live update (নোটটি **বাজার ভল্ট** হিসেবে চিহ্নিত)।
2. **Tree → Editor sync**: 🌳 গাছে কোনো ডালে tap (দীর্ঘ) → **সেই অংশের লাইনেই editor scroll + cursor** — লেখা "কোথায়" সেটা জানা যায়।
3. **Part সরাসরি type করে branch rename**: গাছের ডালের title edit করলে source-এর `# heading` auto-আপডেট।
4. **মনিপাওয়ার একীকরণ**: `# বাজার` নোটের আইটেমগুলোর মোট, Money আপ্লিকেশনের `খরচ` হিসেবে "প্রস্তাব": বাজার নোট save করার সময় screenshot-receipt-এর মতো **খরচ এন্ট্রি বানানোর autocab**।

---

## 🤔 আমার মতামত — «আইটেম ট্রি + আইকন»: কী ভালো হবে, কী লাগবে না

> তুমি লিখলে `আলু ১০ kg ৫০ টাকা` → অ্যাপ এমন বানাবে:
> ```
> ├── 🥔 আলু
> │   ├── Quantity: 10 kg
> │   ├── Price: ৳50/kg
> │   └── Total: ৳500
> ```
> abar `ডিম ১২` → `🥚 ডিম → Total ৳১২`। নিচে আমার সাজানো মতামত — **কী বানালে মূল্য** আর **কী বানালে সময় নষ্ট**।

### ✅ যা বানালে সত্যিই ভালো হবে (High value)

1. **আইটেম → আইকন ডিকশনারি 🧠 (offline)** — সবচেয়ে দারুণ জিনিস:
   - `আলু → 🥔`, `বেগুন → 🍆`, `কুমড়া → 🎃`, `কাঁচা মরিচ → 🌶️`, `পেঁয়াজ → 🧅`, `মাছ → 🐟`, `ডিম → 🥚`, `চাল → 🍚`, `ডাল → 🫘`, `তেল → 🧴`, `দুধ → 🥛`, `রুটি → 🍞`, `কলা → 🍌`, `মাংস → 🍖`, `চিনি → 🧂`
   - বাংলা + ইংরেজি দুইভাবে (`আলু`, `alu`, `potato`) চেনা।
   - ডিকশনারিতে না থাকলে ডিফল্ট আইকন `🛍️` + টাইপ অনুযায়ী (সবজি গেলে `🥬`, মাছ হলে `🐟`)।
   - **কেন দারুণ**: লেখা ছাড়াই এক নজরে "কী কিনতে হবে" বোঝা যায় — Note2-এর ক্ষুদে `🥔 আলু` structure-এর জাদু এটাই।
2. **স্মার্ট নম্বর পারসার 🔢** — একটা লাইন থেকে Quantity/Unit/Price/Total বের করবে:
   - `আলু 10 kg 50` → qty 10, unit kg, price ৳50/kg → total ৳500
   - `আলু ৫০` → শুধু দাম → total ৳50
   - `ডিম 12` → count item (unitless) → total ৳12
   - বাংলা অঙ্ক (`০ ৯`) + ইংরেজি অঙ্ক (`0 9`) দুটোই বুঝবে
   - `kg/kgs/কেজি`, `gr/গ্রাম`, `pc/টা/ডজন` — ইউনিট সমার্থক শব্দ
3. **প্রতি আইটেমে Inline Edit ✏️** — টোটাল অটো বদলায়:
   - `Price: ৳50/kg`-তে tap → `50 → 70` → item Total `৳500 → ৳700`, GRAND TOTAL-ও।
   - **Save বাটন দরকার নেই** — write-complete হলে autosave (Note2 point 5)।
4. **সেকশন-সাবটোটাল 🌳** — Note2-এর মতো nested:
   - `## সবজি` → আলু/বেগুন/কুমড়া (সাবটোটাল)
   - `## মাছের হাট` → ইলিশ/রুই (সাবটোটাল)
   - নিচে `GRAND TOTAL ৳...` — সব child-এর data থেকে calculate (হাতে লেখা নয়)।
5. **দুই ভিউ একই data 🧮⇄🌳**: Tree (আইটেম-আইকন) ⇄ রসিদ `}`-braid ⇄ টেবিল — Data এক, চেহারা কয়েকটা।
6. **টাইপ করার সময় সাজেশন 📝**: `আ` লিখলেই chip আসবে `🥔 আলু — qty ১০`... লেখা দ্রুত হবে।

### ❌ যা এই ধাপে লাগবে না (Skip — পরে যদি দরকার হয় তবেই)

1. **Formula Node** (`Length × Width = Area`, cross-node variables) — Note2 point 6। **লাগবে না**: বাজারে শুধুই `qty × price`; জটিল ফর্মুলা অফলাইনে বানানো খরচ বেশি, মোবাইলে ব্যবহার কম। পরে আলাদা "🗂 হিসাব নোট" হবে।
2. **Linked Node / live reference** (এক note-এর total অন্য note-এ) — Note2 point 7। **লাগবে না**: এখন খুব কম জন ব্যবহার করবে; বাগ-ঝুঁকি বেশি। সহজ কাজ প্রথমে — বাজার নোটের total-কে **Money-তে manual "খরচ পড়ুন"** বাটনে।
3. **Tree Time Machine / version history** — Note2 point 16। **লাগবে না**: offline snapshot পরে; এখন শুধু "শেষ edit undo"।
4. **সবকিছু node** (QR/Clipboard/Screenshot সব tree-এর child) — Note2 point 21। **লাগবে না**: এগুলো নিজেদের মডিউলে থাক, notes-এ আসে **result মাত্র** (current flow-ই যথেষ্ট)।
5. **AI ট্রি বুঝে summarize/edit** — Note2 point 14। **লাগবে না**: online AI লাগবে, অফলাইন প্রথমে। পরে optional plug-in।
6. **Canvas/paint** — Note2 point 9। **লাগবে না**: calc + tree আগে নিখুঁত করো; paint একদম শেষে।
7. **Desktop ৩-pane UI** — Note2 point 19। **লাগবে না**: আগে phone UI।
8. **Drag-reorder + animated branch drawing** — সুন্দর, কিন্তু **মাঝারি priority**; আগে up/down arrow + section move।

### 🎯 করতে হবে ঠিক যে ক্রমে (Priority)

- **P0 (এখনই)**: আইকন ডিকশনারি + নম্বর পারসার (বাংলা অঙ্ক সাপোর্ট) + Quantity/Price/Total per-item + tap-এ edit + GRAND TOTAL + autosave।
- **P1 (পরের)**: `## section` sub-total; ডিফল্ট-আইকন fallback; ইউনিট সমার্থক (`কেজি`,`কেজা`,`kg`); টেবিল ভিউ।
- **P2 (পরে)**: সাজেশন chip; tree↔editor sync; Money-তে খরচ-প্রস্তাব।
- **পরে (যদি দরকার হয়)**: formula node, linked value, minimal canvas, version history।

> **মূল কথা**: এখন কার্যকরি সবচেয়ে বেশি হয় — **স্মার্ট আইকন + পারসার + editable self-total** এটুকুই। Nice-to-have বাকিগুলো বাদ রেখে ২-৩ ধাপে একটা ব্যবহার-উপযোগী "বাজার ট্রি নোট" দিয়ে দেয়া যায়।