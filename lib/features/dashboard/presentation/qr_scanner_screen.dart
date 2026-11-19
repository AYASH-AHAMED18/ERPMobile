import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../app/theme/app_colors.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  late final MobileScannerController _controller;
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.noDuplicates,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final barcode = capture.barcodes.isEmpty ? null : capture.barcodes.first;
    final value = barcode?.rawValue;
    if (value == null || value.trim().isEmpty) return;
    _handled = true;
    await _controller.stop();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _ScanResultSheet(
        value: value,
        format: barcode?.format.name ?? 'QR code',
      ),
    );
    if (!mounted) return;
    setState(() => _handled = false);
    await _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.35),
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Scan QR code',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, state, _) {
              final torchOn = state.torchState == TorchState.on;
              return IconButton(
                tooltip: torchOn ? 'Turn off flashlight' : 'Turn on flashlight',
                onPressed: state.torchState == TorchState.unavailable
                    ? null
                    : () => _controller.toggleTorch(),
                icon: Icon(
                  torchOn
                      ? Icons.flashlight_off_rounded
                      : Icons.flashlight_on_rounded,
                  color: Colors.white,
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => _ScannerError(error: error),
            placeholderBuilder: (context) => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          IgnorePointer(child: CustomPaint(painter: _ScannerOverlayPainter())),
          Positioned(
            left: 28,
            right: 28,
            bottom: 42,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Align the QR code inside the frame to scan it automatically.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'SpeedCode Labs secure scanner',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanResultSheet extends StatelessWidget {
  const _ScanResultSheet({required this.value, required this.format});

  final String value;
  final String format;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.qr_code_2_rounded,
                  size: 21,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'QR code detected',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.canvas,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.line),
            ),
            child: SelectableText(
              value,
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: context.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Format: $format',
            style: TextStyle(fontSize: 10, color: context.textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: value));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('QR value copied.')),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                  label: const Text('Scan again'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScannerError extends StatelessWidget {
  const _ScannerError({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                size: 40,
                color: Colors.white70,
              ),
              const SizedBox(height: 12),
              const Text(
                'Camera unavailable',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                error.errorCode == MobileScannerErrorCode.permissionDenied
                    ? 'Camera permission was denied. Enable camera access in '
                          'system settings to scan QR codes.'
                    : 'The camera could not be started on this device. '
                          'Close other camera apps and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 11.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white30),
                ),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final frameSize = size.width * 0.68;
    final left = (size.width - frameSize) / 2;
    final top = (size.height - frameSize) / 2 - 28;
    final frame = Rect.fromLTWH(left, top, frameSize, frameSize);

    final overlay = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(frame, const Radius.circular(18)));
    canvas.drawPath(
      overlay,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.48)
        ..style = PaintingStyle.fill
        ..blendMode = BlendMode.srcOver,
    );

    final borderPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    const corner = 24.0;
    final path = Path()
      ..moveTo(frame.left, frame.top + corner)
      ..lineTo(frame.left, frame.top)
      ..lineTo(frame.left + corner, frame.top)
      ..moveTo(frame.right - corner, frame.top)
      ..lineTo(frame.right, frame.top)
      ..lineTo(frame.right, frame.top + corner)
      ..moveTo(frame.right, frame.bottom - corner)
      ..lineTo(frame.right, frame.bottom)
      ..lineTo(frame.right - corner, frame.bottom)
      ..moveTo(frame.left + corner, frame.bottom)
      ..lineTo(frame.left, frame.bottom)
      ..lineTo(frame.left, frame.bottom - corner);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
