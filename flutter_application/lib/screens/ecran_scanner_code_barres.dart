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

  // Taille du cadre bleu : un simple repère de visée, il ne limite pas la lecture.
  static const double _largeurCadre = 310;
  static const double _hauteurCadre = 150;

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
          // Pas de scanWindow : il n'accélère rien (toute l'image est analysée)
          // et rejette en silence un code dont un coin dépasse du cadre, ce qui
          // obligeait à reculer. Le code est lu dès qu'il est net à l'image.
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
              width: _largeurCadre,
              height: _hauteurCadre,
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
              'Visez le code-barres',
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
