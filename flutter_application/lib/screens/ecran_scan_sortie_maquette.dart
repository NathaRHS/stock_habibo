import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EcranScanSortieMaquette extends StatefulWidget {
  const EcranScanSortieMaquette({super.key});

  @override
  State<EcranScanSortieMaquette> createState() =>
      _EcranScanSortieMaquetteState();
}

class _EcranScanSortieMaquetteState extends State<EcranScanSortieMaquette> {
  final _codeBarresController = TextEditingController();
  int _quantite = 12;

  @override
  void dispose() {
    _codeBarresController.dispose();
    super.dispose();
  }

  void _modifierQuantite(int difference) {
    setState(() {
      _quantite = (_quantite + difference).clamp(1, 60).toInt();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF073A66),
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 4,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Préparation de sortie',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              'SOR-PREP-TEST-001',
              style: TextStyle(
                color: Color(0xFFBDD5E8),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _progression(),
                        const SizedBox(height: 18),
                        _mission(),
                        const SizedBox(height: 18),
                        _instruction(),
                        const SizedBox(height: 18),
                        _zoneScan(),
                        const SizedBox(height: 18),
                        _zoneQuantite(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _actionPrincipale(),
          ],
        ),
      ),
    );
  }

  Widget _progression() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Commande 1 sur 3',
            style: TextStyle(
              color: Color(0xFF516171),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Text(
          'Étape 2 sur 3',
          style: TextStyle(
            color: Color(0xFF073A66),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 54,
          child: LinearProgressIndicator(
            value: 0.66,
            minHeight: 5,
            borderRadius: BorderRadius.circular(10),
            backgroundColor: const Color(0xFFDCE5EB),
            color: const Color(0xFF1886A7),
          ),
        ),
      ],
    );
  }

  Widget _mission() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF073A66),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ARTICLE À PRÉLEVER',
                  style: TextStyle(
                    color: Color(0xFF9FC5DE),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Coca-Cola 30 cl',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Commande n°1  ·  70 packs demandés',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF0D486F),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: _InformationMission(
                    libelle: 'EMPLACEMENT',
                    valeur: 'A-001',
                  ),
                ),
                SizedBox(
                  height: 38,
                  child: VerticalDivider(color: Color(0xFF467392)),
                ),
                Expanded(
                  child: _InformationMission(
                    libelle: 'RACK / NIVEAU',
                    valeur: 'RACK-A · 1',
                  ),
                ),
                SizedBox(
                  height: 38,
                  child: VerticalDivider(color: Color(0xFF467392)),
                ),
                Expanded(
                  child: _InformationMission(
                    libelle: 'DLC',
                    valeur: '15/12/2026',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _instruction() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4F7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFC9E0E7)),
      ),
      child: const Text(
        'Rendez-vous à A-001, vérifiez la DLC puis scannez le conditionnement.',
        style: TextStyle(
          color: Color(0xFF254D5E),
          fontSize: 13,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _zoneScan() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD5DFE6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Scanner le conditionnement',
            style: TextStyle(
              color: Color(0xFF172B3A),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Le code scanné doit correspondre à Coca-Cola 30 cl.',
            style: TextStyle(color: Color(0xFF697987), fontSize: 12),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _codeBarresController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: '60001548856453',
              filled: true,
              fillColor: const Color(0xFFF7F9FA),
              prefixIcon: const Icon(
                Icons.qr_code_scanner,
                color: Color(0xFF073A66),
              ),
              suffixIcon: Container(
                margin: const EdgeInsets.all(5),
                child: FilledButton(
                  onPressed: () {
                    _codeBarresController.text = '60001548856453';
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1886A7),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  child: const Text('Scanner'),
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: Color(0xFFD5DFE6)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: Color(0xFFD5DFE6)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _zoneQuantite() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD5DFE6)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quantité prélevée',
                  style: TextStyle(
                    color: Color(0xFF172B3A),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  '60 packs maximum sur cet emplacement',
                  style: TextStyle(color: Color(0xFF697987), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          _boutonQuantite(
            symbole: '−',
            onPressed: () => _modifierQuantite(-1),
          ),
          Container(
            width: 54,
            alignment: Alignment.center,
            child: Text(
              '$_quantite',
              style: const TextStyle(
                color: Color(0xFF073A66),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _boutonQuantite(
            symbole: '+',
            onPressed: () => _modifierQuantite(1),
          ),
        ],
      ),
    );
  }

  Widget _boutonQuantite({
    required String symbole,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 38,
      height: 38,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: const Color(0xFF073A66),
          side: const BorderSide(color: Color(0xFFB8C7D1)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          symbole,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _actionPrincipale() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFD5DFE6))),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF073A66),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                child: const Text(
                  'Confirmer le prélèvement',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InformationMission extends StatelessWidget {
  const _InformationMission({required this.libelle, required this.valeur});

  final String libelle;
  final String valeur;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          libelle,
          style: const TextStyle(
            color: Color(0xFF9FC5DE),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          valeur,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
