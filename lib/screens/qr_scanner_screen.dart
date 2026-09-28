import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:lifeos/models/task.dart';
import 'package:lifeos/services/ai_enhancer.dart';
import 'package:lifeos/services/qr_types.dart';
import 'package:lifeos/services/tree_text_parser.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/beautified_tree_card.dart';
import 'package:lifeos/widgets/note_chooser_sheet.dart';
import 'package:lifeos/screens/qr_history_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode, BarcodeFormat.code128, BarcodeFormat.upcA, BarcodeFormat.ean13],
    detectionSpeed: DetectionSpeed.normal,
  );

  bool _torch = false;
  double _zoom = 0.0;
  bool _scanLocked = false;
  bool _showSensitive = false;
  String? _lastValue;
  TreeBlueprint? _qrTree;
  bool _qrTreeLoading = false;
  String? _qrAiText;
  bool _qrAiLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanLocked) return;
    for (final b in capture.barcodes) {
      final value = b.rawValue;
      if (value != null && value.isNotEmpty) {
        _register(value);
        break;
      }
    }
  }

  Future<void> _register(String value) async {
    setState(() {
      _scanLocked = true;
      _lastValue = value;
    });
    await _controller.stop();
    Hive.box('qr_history').add({'text': value, 'time': DateTime.now().toIso8601String()});
  }

  Future<void> _pickFromGallery() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    try {
      final capture = await _controller.analyzeImage(file.path);
      final value = capture?.barcodes
          .map((b) => b.rawValue)
          .whereType<String>()
          .where((v) => v.isNotEmpty)
          .firstOrNull;
      if (value != null) {
        await _register(value);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR পাওয়া যায়নি'), backgroundColor: Colors.black87),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('পড়া যায়নি: $e'), backgroundColor: Colors.black87),
        );
      }
    }
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
      setState(() => _torch = !_torch);
    } catch (_) {}
  }

  void _resume() {
    setState(() {
      _scanLocked = false;
      _lastValue = null;
    });
    _controller.start();
  }

  void _copy(String value) {
    Clipboard.setData(ClipboardData(text: value));
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('কপি হয়েছে'), backgroundColor: Colors.green));
    }
  }

  Future<void> _makeTask(String value) async {
    final c = AppTheme.of(context);
    final ctrl = TextEditingController(text: value);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: c.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('QR → কাজ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.textPrimary)),
              const SizedBox(height: 14),
              TextField(
                controller: ctrl,
                style: TextStyle(color: c.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: c.cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (ctrl.text.isNotEmpty) {
                      Hive.box<Task>('tasks').add(Task(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: ctrl.text,
                        createdAt: DateTime.now(),
                        priority: 1,
                      ));
                    }
                    Navigator.pop(context);
                    _resume();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('যোগ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _genQrTree(String value) async {
    if (_qrTree != null) {
      setState(() => _qrTree = null);
      return;
    }
    setState(() => _qrTreeLoading = true);
    try {
      final r = await AiEnhancer.enhance(value, allowOnline: true)
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;
      setState(() {
        _qrTree = r.tree;
        _qrTreeLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _qrTreeLoading = false);
    }
  }

  Future<void> _genQrAi(String value) async {
    if (_qrAiText != null) {
      setState(() => _qrAiText = null);
      return;
    }
    if (_qrAiLoading) return;
    setState(() => _qrAiLoading = true);
    try {
      final r = await AiEnhancer.enhance(value, allowOnline: true)
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;
      setState(() {
        _qrAiText = r.normalized.text;
        _qrAiLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _qrAiLoading = false);
    }
  }

  Future<void> _openExternal(String uri) async {
    try {
      if (uri.startsWith('https://') || uri.startsWith('http://')) {
        await AndroidIntent(action: 'android.intent.action.VIEW', data: uri)
            .launch();
      } else if (uri.startsWith('tel:')) {
        await AndroidIntent(action: 'android.intent.action.DIAL', data: uri)
            .launch();
      } else if (uri.startsWith('mailto:')) {
        await AndroidIntent(action: 'android.intent.action.SENDTO', data: uri)
            .launch();
      } else if (uri.startsWith('geo:')) {
        await AndroidIntent(action: 'android.intent.action.VIEW', data: uri)
            .launch();
      }
    } catch (_) {}
  }

  Future<void> _openWifiSettings() async {
    try {
      await AndroidIntent(action: 'android.settings.WIFI_SETTINGS').launch();
    } catch (_) {}
  }

  Future<void> _openHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const QrHistoryScreen()),
    );
    _resume();
  }

  Widget _resultPanel(AppColors c, String value) {
    final scan = QrScan.parse(value);
    return Positioned(
      left: 10,
      right: 10,
      bottom: 10,
      child: SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.62),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.surfaceColor.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.primary.withValues(alpha: 0.25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${scan.typeLabel} সনাক্ত',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c.primary),
                  ),
                  const Spacer(),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _genQrAi(value),
                    tooltip: 'AI খোলাসা',
                    icon: Icon(
                      _qrAiLoading
                          ? Icons.hourglass_top_rounded
                          : (_qrAiText != null
                              ? Icons.auto_awesome_rounded
                              : Icons.auto_awesome_outlined),
                      size: 18,
                      color: _qrAiText != null ? c.glow : c.textSecondary,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => _showSensitive = !_showSensitive),
                    icon: Icon(
                      _showSensitive ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      size: 18,
                      color: c.textSecondary,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: _resume,
                    icon: Icon(Icons.close_rounded, color: c.textSecondary),
                  ),
                ],
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      QrTypeCard(
                        scan: scan,
                        showSensitive: _showSensitive,
                        onOpenUrl: (u) => _openExternal(u),
                      ),
                      if (scan.type == QrType.wifi) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _actionChip(
                                c,
                                Icons.password_rounded,
                                scan.fields['Password']?.isNotEmpty == true
                                    ? 'পাসওয়ার্ড কপি'
                                    : 'ওপেন নেটওয়ার্ক',
                                () {
                                  final p = scan.fields['Password'] ?? '';
                                  if (p.isNotEmpty) {
                                    _copy(p);
                                  } else {
                                    _openWifiSettings();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _actionChip(c, Icons.wifi_rounded, 'কানেক্ট করুন', () {
                                _copy(scan.fields['SSID'] ?? scan.raw);
                                _openWifiSettings();
                              }),
                            ),
                          ],
                        ),
                      ],
                      if (_qrAiText != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: c.glow.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: c.glow.withValues(alpha: 0.25)),
                          ),
                          child: SelectableText(
                            _qrAiText!,
                            style: TextStyle(fontSize: 12.5, height: 1.5, color: c.textPrimary),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: c.glow,
                              side: BorderSide(color: c.glow.withValues(alpha: 0.5)),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () => _copy(_qrAiText!),
                            icon: const Icon(Icons.copy_all_rounded, size: 15),
                            label: const Text('সব কপি',
                                style: TextStyle(
                                    fontSize: 11.5, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: c.cardColor, borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          scan.raw,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: c.textSecondary),
                        ),
                      ),
                      if (_qrTree != null) ...[
                        const SizedBox(height: 8),
                        BeautifiedTreeCard(
                          raw: scan.raw,
                          blueprint: _qrTree!,
                          animate: false,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 52,
                child: Row(
                  children: [
                    _actionChip(c, Icons.copy_rounded, 'কপি', () => _copy(value)),
                    const SizedBox(width: 8),
                    _actionChip(c, Icons.event_note_rounded, 'কাজ', () => _makeTask(value)),
                    const SizedBox(width: 8),
                    _actionChip(c, Icons.note_add_rounded, 'নোটে', () => _addToNote(scan)),
                    const SizedBox(width: 8),
                    _actionChip(
                      c,
                      _qrTreeLoading ? Icons.hourglass_top_rounded : Icons.auto_awesome_rounded,
                      'গাছ',
                      () => _genQrTree(value),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addToNote(QrScan scan) async {
    final dest = await NoteChooser.pick(context);
    if (dest == null) {
      _resume();
      return;
    }
    NoteChooser.appendTo(
      noteId: dest['id'] as String?,
      title: dest['title'] as String?,
      block: scan.toNoteBlock(),
    );
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('নোটে যোগ হয়েছে: ${dest['title']}'), backgroundColor: Colors.green));
    }
    _resume();
  }

  Widget _actionChip(AppColors c, IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: c.cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: c.primary),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

 @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            overlayBuilder: (context, constraints) => _buildOverlay(color: c.primary),
            errorBuilder: (context, error) => Center(
              child: Text(
                'ক্যামেরা চালু হয়নি: $error',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(backgroundColor: Colors.black38),
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    ),
                    const Spacer(),
                    _topBtn(Icons.photo_library_rounded, _pickFromGallery, 'গ্যালারি'),
                    const SizedBox(width: 8),
                    _topBtn(Icons.history_rounded, _openHistory, 'ইতিহাস'),
                    const SizedBox(width: 8),
                    _topBtn(
                      _torch ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                      _toggleTorch,
                      _torch ? 'টর্চ অন' : 'টর্চ',
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _resume(),
                      style: IconButton.styleFrom(backgroundColor: Colors.black38),
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                    ),
                  ],
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.zoom_in_rounded, size: 18, color: Colors.white70),
                      Expanded(
                        child: Slider(
                          value: _zoom,
                          activeColor: c.primary,
                          onChanged: (v) {
                            setState(() => _zoom = v);
                            _controller.setZoomScale(v);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_lastValue != null)
            _resultPanel(c, _lastValue!)
          else
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'QR ঘুরিয়ে স্ক্যান করো',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _topBtn(IconData icon, VoidCallback onTap, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onTap,
        style: IconButton.styleFrom(backgroundColor: Colors.black38),
        icon: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _buildOverlay({required Color color}) {
    const scanWindowFraction = 0.65;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth * scanWindowFraction;
        final height = constraints.maxHeight * scanWindowFraction * 0.6;
        final left = (constraints.maxWidth - width) / 2;
        final top = (constraints.maxHeight - height) / 2;

        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              width: width,
              height: height,
              child: CustomPaint(
                painter: _ScanWindowPainter(color: color),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ScanWindowPainter extends CustomPainter {
  final Color color;
  _ScanWindowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.saveLayer(rect, Paint());
    final windowPath = Path()
      ..moveTo(rect.left, rect.top)
      ..lineTo(rect.right, rect.top)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..close();
    canvas.drawPath(windowPath, Paint()..color = Colors.transparent);

    final c = color;
    final hair = 3.0;
    final len = 26.0;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = hair
      ..strokeCap = StrokeCap.round
      ..color = c;

    final corners = <Offset, Offset>{
      rect.topLeft: Offset(len + hair, hair),
      rect.topRight: Offset(-len - hair, hair),
      rect.bottomLeft: Offset(len + hair, -hair),
      rect.bottomRight: Offset(-len - hair, -hair),
    };
    corners.forEach((origin, delta) {
      final line = Path()
        ..moveTo(origin.dx, origin.dy)
        ..lineTo(origin.dx + delta.dx, origin.dy)
        ..moveTo(origin.dx, origin.dy)
        ..lineTo(origin.dx, origin.dy + delta.dy);
      canvas.drawPath(line, p);
    });

    canvas.drawLine(
      Offset(rect.left + 8, rect.top + size.height / 2),
      Offset(rect.right - 8, rect.top + size.height / 2),
      Paint()
        ..color = c.withValues(alpha: 0.7)
        ..strokeWidth = 2,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ScanWindowPainter oldDelegate) =>
      oldDelegate.color != color;
}