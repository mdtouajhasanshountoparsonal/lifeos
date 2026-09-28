/// EmojiIntent — P2: কোনো লাইনের "মানে" বুঝে একটি এমোজি/আইকন বাছাই।
///
/// - প্রথমে online-AI-এর শেখা `learned` ম্যাপ মিলানো হয়।
/// - তারপর offline keyword→emoji নিয়ম (activity > time priority)।
/// - কিছু না পেলে 📌।
class EmojiIntent {
  EmojiIntent._();

  static String pick(String text, {Map<String, String>? learned}) {
    final seg = text.trim().toLowerCase();
    if (seg.isEmpty) return '📌';

    if (learned != null) {
      for (final e in learned.entries) {
        if (seg.contains(e.key.toLowerCase())) return e.value;
      }
    }

    if (_has(seg, ['ঘুম', 'sleep'])) return '😴';
    if (_has(seg, ['ব্যায়াম', 'দৌড়', 'জিম', 'yoga', 'সাঁতার', 'walking']))
      return '🏋️';
    if (_has(seg, [
      'মিটিং', 'অফিস', 'project', 'office', 'meeting', 'রিপোর্ট',
      'প্রজেক্ট', 'জরুরি', 'urgent', 'ডেডলাইন',
    ]))
      return '💼';
    if (_has(seg, [
      'পড়', 'শেখ', 'শিখ', 'study', 'exam', 'পরীক্ষা', 'টিউটোরিয়াল',
      'english', 'গণিত', 'math', 'ক্লাস', 'লেকচার', 'ভিডিও', 'book',
    ]))
      return '📚';
    if (_has(seg, [
      'ডাক্তার', 'হাসপাতাল', 'ওষুধ', 'medicine', 'চেকআপ', 'clinic',
      'ভ্যাকসিন', 'চিকিৎসা', 'রোগ',
    ]))
      return '💊';
    if (_has(seg, [
      'বাজার', 'কিন', 'কেনা', 'ক্রয়', 'shopping', 'buy', 'মার্কেট', 'সামান',
    ]))
      return '🛒';
    if (_has(seg, [
      'লন্ড্রি', 'পরিষ্কার', 'clean', 'ধোয়া', 'সাবান', 'ঝাড়ু', 'মুছ', 'waste',
    ]))
      return '🧺';
    if (_has(seg, ['রান্না', 'রাঁধ', 'খাবার', 'খাওয়া', 'খেতে', 'চা বান', 'ডিনার']))
      return '🍳';
    if (_has(seg, ['কল', 'ফোন', 'call', 'sms', 'মেসেজ', 'message', 'কনফারেন্স']))
      return '📞';
    if (_has(seg, [
      'টাকা', 'বিল', 'পেমেন্ট', 'payment', 'বাজেট', 'ইউটিলিটি', 'রিচার্জ',
      'খরচ',
    ]))
      return '💰';
    if (_has(seg, [
      'যাবো', 'যেতে', 'যাওয়া', 'ভ্রমণ', 'বেড়াতে', 'টিকেট', 'বাস', 'train',
      'flight', 'রিকশা',
    ]))
      return '🚗';

    // সময় স্লট
    if (_has(seg, ['সকাল'])) return '🌅';
    if (_has(seg, ['দুপুর'])) return '☀️';
    if (_has(seg, ['সন্ধ্যা', 'বিকাল'])) return '🌇';
    if (_has(seg, ['রাত'])) return '🌙';

    return '📌';
  }

  static bool _has(String seg, List<String> keys) =>
      keys.any(seg.contains);
}