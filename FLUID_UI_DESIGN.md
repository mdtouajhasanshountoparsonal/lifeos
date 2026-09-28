# 🌊 LifeOS — Fluid Workspace Design

> **“Data is liquid. Structure appears when you interact with it.”**

আমার বোঝা অনুযায়ী এই idea-র সারমর্ম:

UI-কে শুধু "পানির animation" না ভাবলে, বরং **UI নিজেই তরল** ভাবলে — data সবসময় branch-এ জমাট থাকবে না। তথ্য ছোট ছোট **bubble/node/island** হিসেবে ভাসবে; তুমি কাছে গেলে (tap/drag) তা সংগঠিত হয়ে tree/card হয়ে যাবে। একই database — শুধু ভিজ্যুয়াল আলাদা।

---

## 🧭 চারটা চোখ (মূল আর্কিটেকচার)

```
            🧠 LIFEOS
                │
     ┌──────────┼──────────┐
     ▼          ▼          ▼
  🌊 FLUID   🌳 TREE    🕸 GRAPH
   Explore    Organize   Connect
     └──────────┼──────────┘
                ▼
            🎨 CANVAS (create)
                │  →  🤖 Command Brain
                ▼
        ↳ সবকিছুই Node (Task/Note/Money/Clipboard/QR...)
```

**গুরুত্বপূর্ণ:** ৪টা ভিজ্যুয়াল, ১টা database। মোড বদলালেই view বদলায়, data থাকে।

---

## ✅ যা যোগ করলে ভালো

| ফিচার | কেন ভালো | Status |
|---|---|---|
| **বাবল-বোর্ড হোম (Fluid Home)** | একটা বড় wow plus real quick-access; সব module count-সহ floating | ✅ ইমপ্লিমেন্টেড |
| **সাবটল drift/breathing** | একটাই `AnimationController` + `Transform` → ৬০fps-এ অতি সস্তা | ✅ |
| **Tap → bubble pulse + navigate** | morph-এর হালকা version (FAB/dock-এর সাথে সুসংগত) | ✅ |
| **প্রতি module-এ live count** | Notes/Tasks/Money সব Hive-বোx থেকে অটো-আপডেট | ✅ |
| **নিচে স্থির wave line** | পানির feel; কিন্তু animate নয় → ০ পারফরম্যান্স খরচ | ✅ |
| **🐟 fish = ambient decoration** | AppBackground-এ আছেই (আলাদা class এ) | ✅ |
| Mode toggle 🌊/☁️ | Fluid ↔ Classic ড্যাশবোর্ড — এক ট্যাপে রিভার্ট | ✅ |

## ❌ যা না করাই ভালো (এই ফোনে)

1. **রিয়েল ড্র্যাগ-ফিজিক্স (drag = liquid physics / node টেনে connection)** — পূর্ণ physics-ইঞ্জিন ছাড়া জ্যাংক; ২৪০dp পর্দায় টার্গেট মিস হবে।
2. **Bubble merge (drag করে auto-merge suggestion)** — আলগা + ভুল merge-এ data নষ্টের ঝুঁকি। বরং Command → link/merge manual করুন।
3. **Cat-তোলা shared-element screen transition** — প্রতিটা screen-এ স্থাপন করা ভারী + lag; আগে এক-দুইটা screen-এ।
4. **প্রতি node-এ আলাদা AnimationController** — ৩০+ controller = lag। একটাই controller, সব node সেই তালে ছন্দ বাঁধবে।
5. **Water current-এ node constant drift** — সারা দিন সরাতে গেলে আরাম হারায়, focus-এ বাধা। খুবই ধীর ±৪px-এর বেশি না।
6. **Fluid view-এ scroll নিষেধ** — fluid surface non-scroll হতে হবে; স্ক্রল দিলে যুদ্ধ হয়।
7. **Money bubble-এর size = amount** — accessibility + layout বিস্ফোরণ। actual amount সংখ্যাটাই দেখান।
8. **Zoom-out galaxy (১০%→LIFEOS)** — আলাদা "overview" widget-এ থাকানো ভালো, dock-কে বিশাল নেবড় না।

---

## 🛠️ ইমপ্লিমেন্ট (অর্ডার) — ধাপে ধাপে রাখা

- [x] **ধাপ ১ — Fluid Home board**: ৯টা module-bubble, drift+breathing, tap→pulse, live count, static wave. টগল দিয়ে Classic ড্যাশবোর্ডও আছে।
- [ ] **ধাপ ২ — Workflow আরও fluid**: Command brain-এর উত্তর bubble scan ( ট্রি → বাবল)।
- [ ] **ধাপ ৩ — Clipboard action-sphere**: item select → ৪কে-৫টা action bubble-রিজন।
- [ ] **ধাপ ৪ — Money fluid size**: বড়-expense bubble বড়, সাথে amount text।
- [ ] **ধাপ ৫ — Search connection-map**: result + তার লিংক।

> এখন পর্যায়ে ১টাই বাস্তবায়িত; বাকিগুলো ডিজাইন থেকে আলাদা ধাপে, পারফরম্যান্স মেপে Adding।

---

## 🔄 আগের ডিজাইন ফিরিয়ে আনা

- **এক ট্যাপে:** Home হেডারের 🌊/☁️ আইকনে চাপ দিলে যেকোনো সময় **Classic dashboard** ফিরবে (settings-এ `home_mode` মনে থাকে)।
- **কোড-স্তরে:** পুরনো `DashboardScreen` (progress ring, clock, focus list, TOOLS tree) সবই **রয়ে গেছে** — শুধু `_fluidMode == false`-এ render হয়। Fluid স্তর `fluid_home.dart`-এ আলাদা; না চাইলে সেই ১টা ফাইল মুছে দিলেই Classic ফিরে যাবে।

---

## ⚡ পারফরম্যান্স নিয়ম (smooth রাখার তড়িৎ-নিয়ম)

1. **১টা controller, সব node** — `AnimatedBuilder` ছোট্ট bubble-layer-কে ঘোরায়; বাকিটা static।
2. **Transform/scale শুধু** — Layout-এ কখনো `setState` প্রতি-tick নয় (চোরা)।
3. bubbles ওপরে বড় দেড় ডুজন widget, সব `const`/inline।
4. Wave ও fish static/আলাদা-light; fluid surface চলবে না।
5. তা সত্ত্বেও ফোন lag দিলে: `drift referenceSample` কমিয়ে দেবে (`_amp` ∈ 0–4px)।