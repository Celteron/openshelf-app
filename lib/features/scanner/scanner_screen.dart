import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:openreads/features/scanner/scanner_cubit.dart';
import 'package:openreads/l10n/app_localizations.dart';

/// Continuous batch barcode scanner with a staging shelf and "save all" CTA
/// (spec §6.2, US5). On platforms without a camera implementation (e.g. Linux
/// desktop) the preview degrades gracefully to a notice.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  MobileScannerController? _controller;

  static bool get _supportsCamera =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    if (_supportsCamera) {
      _controller = MobileScannerController(
        formats: const [BarcodeFormat.ean13],
        detectionSpeed: DetectionSpeed.noDuplicates,
      );
    }
    context.read<ScannerCubit>().start();
  }

  @override
  void dispose() {
    _controller?.dispose();
    context.read<ScannerCubit>().stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.scannerTitle)),
      body: Column(
        children: [
          Expanded(
            child: _supportsCamera
                ? Semantics(
                    label: l10n.scannerTitle,
                    image: true,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        MobileScanner(
                          controller: _controller!,
                          onDetect: (capture) {
                            for (final barcode in capture.barcodes) {
                              final raw = barcode.rawValue;
                              if (raw != null) {
                                context.read<ScannerCubit>().onScanned(raw);
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l10n.scannerUnsupported,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
          ),
          _StagingShelf(),
        ],
      ),
    );
  }
}

class _StagingShelf extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<ScannerCubit, ScannerState>(
      builder: (context, state) {
        if (state is! ScannerActive) return const SizedBox.shrink();
        return Container(
          constraints: const BoxConstraints(maxHeight: 200),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.stagedCount(state.staged.length)),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final book in state.staged)
                      ListTile(
                        dense: true,
                        leading: book.duplicate
                            ? const Icon(Icons.warning, color: Colors.orange)
                            : const Icon(Icons.book),
                        title: Text(book.metadata?.title ?? book.isbn13),
                        subtitle: book.duplicate
                            ? Text(l10n.alreadyInLibrary)
                            : Text(book.isbn13),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: state.saving
                      ? null
                      : () => context.read<ScannerCubit>().saveAll(),
                  child: Text(state.saving ? l10n.saving : l10n.saveAll),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
