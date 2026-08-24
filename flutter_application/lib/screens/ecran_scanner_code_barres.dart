import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class EcranScannerCodeBarres extends StatefulWidget {
  const EcranScannerCodeBarres({super.key});

  @override
  State<EcranScannerCodeBarres> createState() => _EcranScannerCodeBarresState();
}

class _EcranScannerCodeBarresState extends State<EcranScannerCodeBarres> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.code93,
      BarcodeFormat.ean8,
      BarcodeFormat.ean13,
      BarcodeFormat.itf14,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
  );

  bool _codeRetourne = false;

  Future<void> _traiterDetection(BarcodeCapture capture) async {
    if (_codeRetourne) return;

    String? codeBarres;
    for (final code in capture.barcodes) {
      final valeur = code.rawValue?.trim();
      if (valeur != null && valeur.isNotEmpty) {
        codeBarres = valeur;
        break;
      }
    }

    if (codeBarres == null) return;
    _codeRetourne = true;
    await _scannerController.stop();

    if (mounted) Navigator.pop(context, codeBarres);
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scanner un code-barres'),
        backgroundColor: const Color(0xFF063D77),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Lampe torche',
            onPressed: _scannerController.toggleTorch,
            icon: const Icon(Icons.flashlight_on_outlined),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _traiterDetection,
            errorBuilder: (context, error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  error.errorCode == MobileScannerErrorCode.permissionDenied
                      ? 'Autorisez l’accès à la caméra pour scanner.'
                      : 'La caméra ne peut pas être ouverte.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 17),
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 310,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.lightBlueAccent, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const Positioned(
            left: 24,
            right: 24,
            bottom: 48,
            child: Text(
              'Placez le code-barres dans le cadre',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(color: Colors.black, blurRadius: 6)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
