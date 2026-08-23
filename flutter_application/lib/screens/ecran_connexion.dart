import 'package:flutter/material.dart';

class EcranConnexion extends StatefulWidget {
  const EcranConnexion({super.key});

  @override
  State<EcranConnexion> createState() => _EcranConnexionState();
}

class _EcranConnexionState extends State<EcranConnexion> {
  String _session = 'Session-2026';

  final _codeController = TextEditingController(text: '60001548856446');
  final _produitController = TextEditingController(text: 'Coca 30cl');
  final _quantiteController = TextEditingController(text: '200');
  final _cartonsController = TextEditingController(text: '160');

  @override
  void dispose() {
    _codeController.dispose();
    _produitController.dispose();
    _quantiteController.dispose();
    _cartonsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001A38),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0752A7), Color(0xFF001A38)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: [
                      _LogoHeader(height: constraints.maxHeight * 0.31),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 38, 28, 40),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 430),
                          child: Column(
                            children: [
                              const Text(
                                'Page de connexion',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,  
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Entrez les valeurs requises',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 22),
                              _sessionField(),
                              const SizedBox(height: 24),
                              _inputField(
                                controller: _codeController,
                                icon: Icons.qr_code_2,
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 24),
                              _inputField(
                                controller: _produitController,
                                icon: Icons.local_drink_outlined,
                              ),
                              const SizedBox(height: 24),
                              _inputField(
                                controller: _quantiteController,
                                icon: Icons.inventory_2_outlined,
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 34),
                              _inputField(
                                controller: _cartonsController,
                                icon: Icons.hub_outlined,
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 58,
                                child: ElevatedButton(
                                  key: const Key('ajouterProduit'),
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    elevation: 2,
                                    backgroundColor: const Color(0xFF78A9D5),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Ajouter produit',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Icon(Icons.add, size: 22),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _sessionField() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(13),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _session,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 34),
          borderRadius: BorderRadius.circular(13),
          items: const [
            DropdownMenuItem(value: 'Session-2026', child: Text('Session-2026')),
            DropdownMenuItem(value: 'Session-2025', child: Text('Session-2025')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _session = value);
            }
          },
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF9F9F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        suffixIcon: Icon(icon, color: const Color(0xFFB9B9B9), size: 28),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _LogoHeader extends StatelessWidget {
  const _LogoHeader({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _CurvedHeaderClipper(),
      child: Container(
        width: double.infinity,
        height: height.clamp(230, 310),
        color: Colors.white,
        alignment: Alignment.center,
        child: Container(
          width: 205,
          height: 90,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFB9C4D0), width: 2),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_outlined, color: Color(0xFF607D9A)),
              SizedBox(height: 4),
              Text(
                'EMPLACEMENT DU LOGO',
                style: TextStyle(
                  color: Color(0xFF607D9A),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurvedHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, size.height * 0.83)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.45,
        size.width,
        size.height * 0.84,
      )
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
