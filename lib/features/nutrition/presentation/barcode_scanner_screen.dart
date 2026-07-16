import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cupertino_helpers.dart';
import '../../../models/enums.dart';
import '../../../providers/nutrition_providers.dart';

class BarcodeScannerScreen extends ConsumerStatefulWidget {
  const BarcodeScannerScreen({super.key, required this.mealType});

  final MealType mealType;

  @override
  ConsumerState<BarcodeScannerScreen> createState() =>
      _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null || barcode.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final result =
          await ref.read(barcodeLookupProvider(barcode).future);

      if (!mounted) return;

      if (result != null) {
        context.go(
          '/nutrition/food/${widget.mealType.name}',
          extra: result,
        );
      } else {
        showCupertinoToast(context, 'Product not found. Try another.');
        setState(() => _isProcessing = false);
      }
    } catch (_) {
      if (mounted) {
        showCupertinoToast(context, 'Lookup failed. Check your connection.');
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: CupertinoNavigationBar(
        middle: const Text('Scan Barcode'),
        backgroundColor: AppColors.of(context).background.withValues(alpha: 0.8),
        border: null,
        trailing: CupertinoButton(
          padding: const EdgeInsets.all(8),
          onPressed: () => _controller.toggleTorch(),
          child: ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, state, _) {
              return Icon(
                state.torchState == TorchState.on
                    ? CupertinoIcons.bolt_fill
                    : CupertinoIcons.bolt_slash,
                size: 22,
                semanticLabel: state.torchState == TorchState.on
                    ? 'Turn torch off'
                    : 'Turn torch on',
              );
            },
          ),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Looking up product...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          // Scan overlay guide
          if (!_isProcessing)
            Builder(builder: (context) {
              final guideSize = MediaQuery.of(context).size.shortestSide * 0.6;
              return Center(
              child: Container(
                width: guideSize,
                height: guideSize,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: colorScheme.primary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            );
            }),
        ],
      ),
    );
  }
}
