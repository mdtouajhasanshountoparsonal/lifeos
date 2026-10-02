import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `'$foo(...)'` Dart-এ `$_foo` (ফাংশন) + বাকি লেখা হিসেবে পড়ে, ফলে UI-তে
/// "Closure: (String) => ..." দেখায় — অথচ analyzer চুপ থাকে।
/// আসল ঘটনা: lib/screens/deen/adhkar_screen.dart — ঘুম রুটিন কার্ডে
/// '$_bnNum(finished.toString())' লেখা ছিল, ফলে "Closure: (String) => ..."
/// দেখাচ্ছিল। তাই পুরো lib/ স্ক্যান করে এই প্যাটার্ন ঠেকাতে হয়।
///
/// যেসব জায়গায় ইন্টারপোলেট করা আইডেন্টিফায়ার আসলেই String, সেগুলো
/// নিচে কারণসহ তালিকাভুক্ত — নতুন কোনো জায়গা এলে টেস্ট লাল হবে।
const _knownStringInterpolations = <String, String>{
  'lib/nova/nova_engine.dart:219': "name হলো String প্যারামিটার",
  'lib/nova/nova_engine.dart:231': "name হলো String প্যারামিটার",
  'lib/nova/nova_engine.dart:238': "name হলো String প্যারামিটার",
  'lib/nova/nova_mods_calc.dart:102': 'f হলো String',
  'lib/services/text_normalizer.dart:148': 'esc হলো String (রেগেক্স)',
  'lib/widgets/screenshot_review_sheet.dart:119':
      'photo ও stamp দুটোই String',
};

void main() {
  test('no unlisted bare \$identifier( interpolation in lib/', () {
    final lib = Directory('lib');
    expect(lib.existsSync(), true, reason: 'lib/ পাওয়া যায়নি');

    // '$' + আইডেন্টিফায়ার + সরাসরি '(' — `${...}` বাদ যায়
    final bad = RegExp(r'\$[A-Za-z_][A-Za-z0-9_]*\(');
    final offenders = <String>[];

    for (final f in lib.listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final rel = f.path.replaceAll('\\', '/');
      final lines = f.readAsLinesSync(encoding: utf8);
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        // raw string-এ '$' ইন্টারপোলেশন নয়
        final withoutRaw = line.replaceAll(RegExp(r"r'[^']*'"), "''");
        if (!bad.hasMatch(withoutRaw)) continue;
        final at = '$rel:${i + 1}';
        if (_knownStringInterpolations.containsKey(at)) continue;
        offenders.add('$at: ${line.trim()}');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'এখানে \${...} ব্রেস দরকার, নইলে ফাংশন Closure: (String) => ... '
          'হয়ে UI-তে দেখাবে:\n${offenders.join('\n')}',
    );
  });
}
