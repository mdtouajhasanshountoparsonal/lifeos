import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lifeos/theme/app_theme.dart';

enum QrType { url, wifi, phone, email, location, event, contact, text }

/// A structured interpretation of a raw QR payload.
class QrScan {
  final QrType type;
  final String raw;
  final Map<String, String> fields;

  const QrScan(this.type, this.raw, [this.fields = const {}]);

  String get typeLabel {
    switch (type) {
      case QrType.url:
        return 'লিংক';
      case QrType.wifi:
        return 'ওয়াই-ফাই';
      case QrType.phone:
        return 'ফোন';
      case QrType.email:
        return 'ইমেইল';
      case QrType.location:
        return 'লোকেশন';
      case QrType.event:
        return 'ইভেন্ট';
      case QrType.contact:
        return 'কন্টাক্ট';
      case QrType.text:
        return 'টেক্সট';
    }
  }

  static QrScan parse(String raw) {
    final v = raw.trim();
    // Wi-Fi
    final wifi = RegExp(r'^WIFI:(.*)$', caseSensitive: false).firstMatch(v);
    if (wifi != null) {
      final body = wifi.group(1)!;
      final f = <String, String>{};
      for (final part in body.split(';')) {
        final eq = part.indexOf(':');
        if (eq > 0) f[part.substring(0, eq).toUpperCase()] = part.substring(eq + 1);
      }
      return QrScan(
        QrType.wifi,
        v,
        {
          'SSID': f['S'] ?? '',
          'Password': f['P'] ?? '',
          'Security': f['T'] ?? 'nopass',
        },
      );
    }
    // Phone
    final tel = RegExp(r'^TEL:([^;]+)', caseSensitive: false).firstMatch(v);
    if (tel != null) {
      return QrScan(QrType.phone, v, {'Number': tel.group(1)!});
    }
    // Email
    final mail = RegExp(r'^MATMSG:TO:([^;]+)', caseSensitive: false).firstMatch(v);
    if (mail != null) {
      return QrScan(QrType.email, v, {'Email': mail.group(1)!});
    }
    // Geo
    final geo = RegExp(r'^GEO:([\d.\-]+),([\d.\-]+)', caseSensitive: false).firstMatch(v);
    if (geo != null) {
      return QrScan(QrType.location, v, {'Latitude': geo.group(1)!, 'Longitude': geo.group(2)!});
    }
    // MECARD
    final mecard = RegExp(r'^MECARD:(.*)$', caseSensitive: false).firstMatch(v);
    if (mecard != null) {
      return QrScan(QrType.contact, v, _contactFromRaw(mecard.group(1)!));
    }
    // vCard
    if (v.toUpperCase().contains('BEGIN:VCARD') || v.toUpperCase().startsWith('VCARD')) {
      return QrScan(QrType.contact, v, _contactFromVcf(v));
    }
    // Event
    if (v.toUpperCase().contains('BEGIN:VEVENT') || v.toUpperCase().contains('BEGIN:VEVENT')) {
      return QrScan(QrType.event, v, _eventFromRaw(v));
    }
    // URL
    if (v.startsWith('http://') || v.startsWith('https://')) {
      return QrScan(QrType.url, v, {'Link': v});
    }
    return QrScan(QrType.text, v, {'Text': v});
  }

  // MECARD:N:Name;ORG:..;TEL:..;EMAIL:..;URL:..;  (items joined by ; but values may contain commas)
  static Map<String, String> _contactFromRaw(String s) {
    final f = <String, String>{};
    for (final item in s.split(';')) {
      final idx = item.indexOf(':');
      if (idx <= 0) continue;
      final key = item.substring(0, idx);
      final val = item.substring(idx + 1);
      final k = key.toUpperCase();
      if (k == 'N') {
        f['Name'] = val;
      } else if (k == 'FN') {
        f['Name'] = (f['Name'] ?? '').isEmpty ? val : f['Name']!;
      } else if (k == 'TEL') {
        f['Phone'] = val;
      } else if (k == 'EMAIL') {
        f['Email'] = val;
      } else if (k == 'ORG') {
        f['Organization'] = val;
      } else if (k == 'URL' && !f.containsKey('Website')) {
        f['Website'] = val;
      } else if (k == 'ADR') {
        f['Address'] = f.containsKey('Address') ? '${f['Address']}, $val' : val;
      }
    }
    return f;
  }

  static Map<String, String> _contactFromVcf(String s) {
    final f = <String, String>{};
    for (final line in s.split('\n')) {
      final idx = line.indexOf(':');
      if (idx <= 0) continue;
      final key = line.substring(0, idx).toUpperCase();
      final val = line.substring(idx + 1).trim();
      if (key == 'FN' || key == 'N') {
        f['Name'] = f['Name'] == null ? val.replaceAll(';', ' ') : f['Name']!;
      } else if (key == 'TEL') {
        f['Phone'] = val;
      } else if (key == 'EMAIL' && !f.containsKey('Email')) {
        f['Email'] = val;
      } else if (key == 'ORG') {
        f['Organization'] = val;
      } else if (key == 'URL' && !f.containsKey('Website')) {
        f['Website'] = val;
      }
    }
    return f;
  }

  static Map<String, String> _eventFromRaw(String s) {
    final f = <String, String>{};
    for (final line in s.split('\n')) {
      final idx = line.indexOf(':');
      if (idx <= 0) continue;
      final key = line.substring(0, idx).toUpperCase();
      final val = line.substring(idx + 1).trim();
      if (val.isEmpty) continue;
      final k = key;
      if (k == 'SUMMARY') {
        f['Event'] = val;
      } else if (k == 'DTSTART') {
        f['Start'] = _fmtIcs(val.split('T').last.split('Z').first);
      } else if (k == 'DTEND') {
        f['End'] = _fmtIcs(val.split('T').last.split('Z').first);
      } else if (k == 'LOCATION') {
        f['Location'] = val;
      } else if (k == 'DESCRIPTION' && !f.containsKey('Description')) {
        f['Description'] = val;
      }
    }
    return f;
  }

  static String _fmtIcs(String v) {
    if (v.length == 6) return '${v.substring(0, 2)}:${v.substring(2, 4)}:${v.substring(4, 6)}';
    if (v.length == 8) return '${v.substring(0, 4)}-${v.substring(4, 6)}-${v.substring(6, 8)}';
    return v;
  }

  /// Serializes this scan into note markup blocks.
  String toNoteBlock() {
    final b = StringBuffer()
      ..writeln('# 📶 $typeLabel')
      ..writeln()
      ..writeln('> $raw');
    for (final e in fields.entries) {
      b.writeln('- **${e.key}:** ${e.value}');
    }
    return b.toString();
  }
}

/// A compact structured card rendered for a scanned/typed QR value.
/// Sensitive values are hidden behind a tap and get **long-press → auto-copy**.
class QrTypeCard extends StatelessWidget {
  final QrScan scan;
  final bool showSensitive;
  final ValueChanged<String> onOpenUrl;

  const QrTypeCard({super.key, required this.scan, this.showSensitive = false, required this.onOpenUrl});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final hiddenKeys = {'Password', 'Phone', 'Email', 'Address'};
    final entries = scan.fields.entries.toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.cardColor.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_iconFor(scan.type), size: 18, color: c.primary),
              const SizedBox(width: 8),
              Text(scan.typeLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c.primary)),
            ],
          ),
          const SizedBox(height: 10),
          for (final e in entries) _field(context, c, e.key, e.value, hiddenKeys.contains(e.key)),
          if (scan.type == QrType.url)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: FilledButton.tonalIcon(
                onPressed: () => onOpenUrl(scan.fields['Link'] ?? scan.raw),
                icon: const Icon(Icons.open_in_browser_rounded, size: 16),
                label: const Text('ওপেন'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _field(BuildContext context, AppColors c, String key, String value, bool sensitive) {
    final icon = Icon(Icons.copy_rounded, size: 14, color: c.textSecondary);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 74,
            child: Text(key, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.textSecondary)),
          ),
          Expanded(
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(const SnackBar(content: Text('কপি হয়েছে'), backgroundColor: Colors.green));
              },
              child: Text(
                sensitive && !showSensitive ? '••••••••' : value,
                style: TextStyle(
                  fontSize: 13,
                  color: c.textPrimary,
                  fontWeight: sensitive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(const SnackBar(content: Text('কপি হয়েছে'), backgroundColor: Colors.green));
            },
            child: icon,
          ),
        ],
      ),
    );
  }

  IconData _iconFor(QrType t) {
    switch (t) {
      case QrType.url:
        return Icons.language_rounded;
      case QrType.wifi:
        return Icons.wifi_rounded;
      case QrType.phone:
        return Icons.phone_rounded;
      case QrType.email:
        return Icons.mail_rounded;
      case QrType.location:
        return Icons.place_rounded;
      case QrType.event:
        return Icons.event_rounded;
      case QrType.contact:
        return Icons.contact_page_rounded;
      case QrType.text:
        return Icons.notes_rounded;
    }
  }
}