import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/services/pray_times.dart';

PrayerTimeResult make(DateTime d) => PrayerTimeResult(
  fajr: DateTime(d.year, d.month, d.day, 5),
  sunrise: DateTime(d.year, d.month, d.day, 6),
  dhuhr: DateTime(d.year, d.month, d.day, 12),
  asr: DateTime(d.year, d.month, d.day, 16),
  maghrib: DateTime(d.year, d.month, d.day, 18),
  isha: DateTime(d.year, d.month, d.day, 19),
);

void main() {
  final day = DateTime(2026, 3, 14);
  final base = make(day);

  test('override খালি হলে হিসাবের সময়ই থাকে', () {
    final r = PrayTimesEngine.withCustomTimes(base, day);
    expect(r.dhuhr, base.dhuhr);
    expect(r.isha, base.isha);
  });

  test('শুধু সেট করা ওয়াক্তের সময় বদলায়, বাকি অপরিবর্তিত', () {
    final r = PrayTimesEngine.withCustomTimes(
      base,
      day,
      customMinutes: {PrayerKind.dhuhr: 13 * 60 + 45},
    );
    expect(r.dhuhr, DateTime(2026, 3, 14, 13, 45));
    expect(r.fajr, base.fajr);
    expect(r.isha, base.isha);
  });

  test('সব ওয়াক্ত একসাথে override করা যায়', () {
    final r = PrayTimesEngine.withCustomTimes(
      base,
      day,
      customMinutes: {
        PrayerKind.fajr: 4 * 60,
        PrayerKind.dhuhr: 13 * 60 + 30,
        PrayerKind.asr: 17 * 60,
        PrayerKind.maghrib: 18 * 60 + 15,
        PrayerKind.isha: 19 * 60 + 30,
      },
    );
    expect(r.fajr, DateTime(2026, 3, 14, 4));
    expect(r.asr, DateTime(2026, 3, 14, 17));
    expect(r.maghrib, DateTime(2026, 3, 14, 18, 15));
    expect(r.isha, DateTime(2026, 3, 14, 19, 30));
  });

  test('তারিখ অদলবদল হলেও override সেই তারিখেই বসে', () {
    final other = DateTime(2026, 12, 1);
    final r = PrayTimesEngine.withCustomTimes(
      base,
      other,
      customMinutes: {PrayerKind.maghrib: 17 * 60 + 20},
    );
    expect(r.maghrib, DateTime(2026, 12, 1, 17, 20));
  });

  test('সীমার বাইরের মিনিট clamp হয় (24 ঘণ্টার মধ্যে থাকে)', () {
    final r = PrayTimesEngine.withCustomTimes(
      base,
      day,
      customMinutes: {PrayerKind.fajr: 99999},
    );
    expect(r.fajr, DateTime(2026, 3, 14, 23, 59));
  });

  test('nextFrom override-করা সময় মেনে চলে', () {
    final r = PrayTimesEngine.withCustomTimes(
      base,
      day,
      customMinutes: {PrayerKind.dhuhr: 23 * 60 + 30},
    );
    // ভাগলে দুপুরকে ১১:৩০-এ নামিয়ে দিলে ১০:০০-এ আসবে দুপুর, ১২:০০-এ আসবে আসর
    final pulled = PrayTimesEngine.withCustomTimes(
      base,
      day,
      customMinutes: {PrayerKind.dhuhr: 11 * 60 + 30},
    );
    expect(pulled.nextFrom(DateTime(2026, 3, 14, 10)), PrayerKind.dhuhr);
    expect(pulled.nextFrom(DateTime(2026, 3, 14, 12)), PrayerKind.asr);
    // দুপুর ভাগলে ২৩:৩০ হয়ে গেলে ১২:০০-এ এখন আসর আসবে
    expect(r.nextFrom(DateTime(2026, 3, 14, 12)), PrayerKind.asr);
    // সব সেরে গেছে → null (পরেরটা আগামীকাল ফজর)
    expect(r.nextFrom(DateTime(2026, 3, 14, 23, 59)), isNull);
  });
}
