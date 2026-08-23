import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:replicaz/app/theme/app_colors.dart';
import 'package:replicaz/app/theme/app_type.dart';
import 'package:replicaz/core/bootstrap/app_bootstrap.dart';
import 'package:replicaz/core/widgets/replicaz_bottom_sheet.dart';
import 'package:replicaz/features/identities/bloc/identities_bloc.dart';
import 'package:replicaz/features/receipts/bloc/receipts_bloc.dart';
import 'package:replicaz/features/receipts/domain/receipt.dart';
import 'package:uuid/uuid.dart';

/// Full-screen capture: QR scan + photo for handwritten / POS / delivery slips.
class ReceiptCaptureScreen extends StatefulWidget {
  const ReceiptCaptureScreen({super.key, this.initialKind});

  final ReceiptKind? initialKind;

  @override
  State<ReceiptCaptureScreen> createState() => _ReceiptCaptureScreenState();
}

class _ReceiptCaptureScreenState extends State<ReceiptCaptureScreen>
    with WidgetsBindingObserver {
  MobileScannerController? _scanner;
  final _title = TextEditingController();
  final _merchant = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();

  late ReceiptKind _kind;
  String _qrPayload = '';
  String? _imagePath;
  bool _handling = false;
  bool _torch = false;
  bool _cameraBlocked = false;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _kind = widget.initialKind ??
        AppBootstrap.receiptService.lastKind() ??
        ReceiptKind.handwritten;
    _scanner = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      formats: const [BarcodeFormat.qrCode],
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // User may grant Camera in Settings then return.
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {
        _cameraBlocked = false;
        _cameraError = null;
      });
      _restartScanner();
    }
  }

  Future<void> _restartScanner() async {
    final c = _scanner;
    if (c == null) return;
    try {
      await c.start();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cameraBlocked = true;
        _cameraError = e.toString();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanner?.dispose();
    _title.dispose();
    _merchant.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    final raw = capture.barcodes
        .map((b) => b.rawValue)
        .whereType<String>()
        .firstWhere((e) => e.trim().isNotEmpty, orElse: () => '');
    if (raw.isEmpty) return;
    _handling = true;
    HapticFeedback.mediumImpact();
    try {
      await _scanner?.stop();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _qrPayload = raw.trim();
      if (_title.text.trim().isEmpty) {
        _title.text = _defaultTitleFromQr(raw);
      }
      if (_merchant.text.trim().isEmpty) {
        _merchant.text = _guessMerchant(raw);
      }
      // QR found → default POS if still handwritten with empty fields
      if (_kind == ReceiptKind.handwritten && _qrPayload.isNotEmpty) {
        _kind = ReceiptKind.pos;
      }
    });
    await _openReviewSheet();
    _handling = false;
    if (mounted) await _restartScanner();
  }

  String _defaultTitleFromQr(String raw) {
    final short = raw.length > 28 ? '${raw.substring(0, 28)}…' : raw;
    return '${_kind.labelZh} · $short';
  }

  String _guessMerchant(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri != null && uri.host.isNotEmpty) return uri.host;
    if (raw.contains('|')) {
      final parts = raw.split('|');
      if (parts.first.trim().isNotEmpty) return parts.first.trim();
    }
    return '';
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1600,
      );
      if (file == null || !mounted) return;
      HapticFeedback.selectionClick();
      final saved = await _persistImage(File(file.path));
      setState(() => _imagePath = saved);
      if (_title.text.trim().isEmpty) {
        _title.text = '${_kind.labelZh} · photo';
      }
      await _openReviewSheet();
    } on PlatformException catch (e) {
      if (!mounted) return;
      final denied = (e.code.toLowerCase().contains('photo') ||
              e.code.toLowerCase().contains('camera') ||
              e.code.toLowerCase().contains('permission')) ||
          (e.message?.toLowerCase().contains('denied') ?? false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            denied
                ? 'No camera/photos access. iOS Settings → Replicaz → allow Camera & Photos, then retry.'
                : 'Could not open camera/photos: ${e.message ?? e.code}',
          ),
          action: SnackBarAction(
            label: 'Manual',
            onPressed: () {
              if (_title.text.trim().isEmpty) {
                _title.text = '${_kind.labelZh} · manual';
              }
              _openReviewSheet();
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo failed: $e')),
      );
    }
  }

  Future<String> _persistImage(File src) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/receipts');
    if (!folder.existsSync()) folder.createSync(recursive: true);
    final name = 'rcpt_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final dest = File('${folder.path}/$name');
    await src.copy(dest.path);
    return dest.path;
  }

  Future<void> _openReviewSheet() async {
    await ReplicazBottomSheet.show<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                4,
                20,
                16 + MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Save slip', style: AppType.titleLg()),
                    const SizedBox(height: 4),
                    Text(
                      'Stored only in this life — not mixed with others.',
                      style: AppType.caption(),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: ReceiptKind.values.map((k) {
                        final on = _kind == k;
                        return ChoiceChip(
                          label: Text(k.labelZh),
                          selected: on,
                          onSelected: (_) => setModal(() => _kind = k),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _title,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _merchant,
                      decoration: const InputDecoration(
                        labelText: 'Merchant / supplier',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _amount,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Amount (optional)',
                        hintText: 'e.g. 128.00',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _note,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Note (optional)',
                      ),
                    ),
                    if (_qrPayload.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text('QR payload', style: AppType.overline()),
                      const SizedBox(height: 4),
                      Text(
                        _qrPayload,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.caption(),
                      ),
                    ],
                    if (_imagePath != null) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_imagePath!),
                          height: 120,
                          fit: BoxFit.cover,
                          cacheWidth: 800,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => _save(sheetContext),
                      child: const Text('Save to this life'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('Keep scanning'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _save(BuildContext sheetContext) async {
    final identityId =
        context.read<IdentitiesBloc>().state.activeIdentityId;
    if (identityId == null) return;
    final title = _title.text.trim().isEmpty
        ? '${_kind.labelZh} slip'
        : _title.text.trim();
    final now = DateTime.now().toUtc();
    final receipt = Receipt(
      id: const Uuid().v4(),
      identityId: identityId,
      kind: _kind,
      title: title,
      merchant: _merchant.text.trim(),
      amountText: _amount.text.trim(),
      note: _note.text.trim(),
      qrPayload: _qrPayload,
      imagePath: _imagePath ?? '',
      createdAt: now,
      updatedAt: now,
    );
    context.read<ReceiptsBloc>().add(ReceiptsSaveRequested(receipt));
    await AppBootstrap.receiptService.rememberKind(_kind);
    HapticFeedback.lightImpact();
    if (sheetContext.mounted) Navigator.pop(sheetContext);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved · ${receipt.kind.labelZh}')),
      );
      context.pop();
    }
  }

  Widget _cameraDeniedPanel(Color accent) {
    return ColoredBox(
      color: const Color(0xFF0B0D10),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.no_photography_outlined, size: 48, color: accent),
            const SizedBox(height: 16),
            Text(
              'Camera not available',
              style: AppType.titleMd(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'QR scan needs Camera. Allow in iOS Settings → Replicaz → Camera, then come back.\n\n'
              'Handwritten / POS without QR: use Photo, Library, or Manual below — still works.',
              style: AppType.bodySm(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            if (_cameraError != null) ...[
              const SizedBox(height: 10),
              Text(
                _cameraError!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppType.caption(color: Colors.white38),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: accent),
              onPressed: () {
                setState(() {
                  _cameraBlocked = false;
                  _cameraError = null;
                });
                _restartScanner();
              },
              child: const Text('Retry camera'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent =
        context.watch<IdentitiesBloc>().state.activeIdentity?.color ??
            AppColors.accent;
    final life =
        context.watch<IdentitiesBloc>().state.activeIdentity?.name ?? 'life';
    final scanner = _scanner;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          'Scan slip · $life',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Torch',
            onPressed: _cameraBlocked
                ? null
                : () async {
                    await scanner?.toggleTorch();
                    setState(() => _torch = !_torch);
                  },
            icon: Icon(
              _torch ? Icons.flash_on_rounded : Icons.flash_off_rounded,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _cameraBlocked || scanner == null
                ? _cameraDeniedPanel(accent)
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      MobileScanner(
                        controller: scanner,
                        onDetect: _onDetect,
                        errorBuilder: (context, error) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted || _cameraBlocked) return;
                            setState(() {
                              _cameraBlocked = true;
                              _cameraError = error.errorDetails?.message ??
                                  error.errorCode.name;
                            });
                          });
                          return _cameraDeniedPanel(accent);
                        },
                      ),
                      IgnorePointer(
                        child: Center(
                          child: Container(
                            width: 240,
                            height: 240,
                            decoration: BoxDecoration(
                              border: Border.all(color: accent, width: 2.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Text(
                          _kind == ReceiptKind.handwritten
                              ? 'Handwritten? Prefer Photo below.\nQR still works if the slip has one.'
                              : 'Aim at QR on POS / delivery slip.\nNo QR? Photo or Manual.',
                          textAlign: TextAlign.center,
                          style: AppType.caption(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
          ),
          Container(
            color: const Color(0xFF111418),
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              12 + MediaQuery.paddingOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Slip type', style: AppType.overline(color: accent)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final k in ReceiptKind.values)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: ChoiceChip(
                            label: Text(
                              k.labelZh,
                              style: const TextStyle(fontSize: 11),
                            ),
                            selected: _kind == k,
                            onSelected: (_) async {
                              setState(() => _kind = k);
                              await AppBootstrap.receiptService
                                  .rememberKind(k);
                            },
                            selectedColor: accent.withValues(alpha: 0.35),
                            labelStyle: TextStyle(
                              color:
                                  _kind == k ? Colors.white : Colors.white70,
                            ),
                            backgroundColor: Colors.white10,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                        ),
                        onPressed: () => _pickPhoto(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera_outlined, size: 18),
                        label: const Text('Photo'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                        ),
                        onPressed: () => _pickPhoto(ImageSource.gallery),
                        icon:
                            const Icon(Icons.photo_library_outlined, size: 18),
                        label: const Text('Library'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: accent),
                        onPressed: () {
                          if (_title.text.trim().isEmpty) {
                            _title.text = '${_kind.labelZh} · manual';
                          }
                          _openReviewSheet();
                        },
                        icon: const Icon(Icons.edit_note_rounded, size: 18),
                        label: const Text('Manual'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
