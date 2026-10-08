import 'package:flutter/material.dart';

import '../data/magasin.dart';
import '../theme/habibo.dart';
import 'coquille.dart';
import 'ecran_login.dart';

/// Ecran de demarrage : le logo apparait, puis l'application ouvre l'accueil
/// si une session est memorisee, sinon l'ecran de connexion.
class EcranDemarrage extends StatefulWidget {
  const EcranDemarrage({super.key});

  @override
  State<EcranDemarrage> createState() => _EcranDemarrageState();
}

class _EcranDemarrageState extends State<EcranDemarrage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  late final Animation<double> _apparition = CurvedAnimation(
    parent: _animation,
    curve: const Interval(0, 0.55, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _texte = CurvedAnimation(
    parent: _animation,
    curve: const Interval(0.45, 1, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _animation.forward();
    Future<void>.delayed(const Duration(milliseconds: 2300), _continuer);
  }

  void _continuer() {
    if (!mounted) return;
    final connecte = magasin.sessionMemorisee && magasin.utilisateur != null;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, _, _) =>
            connecte ? const Coquille() : const EcranLogin(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reprise = magasin.sessionMemorisee && magasin.utilisateur != null;

    return Scaffold(
      backgroundColor: Habibo.surface,
      body: SafeArea(
        // Center donne toute la largeur a la colonne : le logo reste au milieu.
        child: Center(
          child: Column(
            children: [
              const Spacer(flex: 5),
              FadeTransition(
                opacity: _apparition,
                child: ScaleTransition(
                  scale: Tween<double>(
                    begin: 0.86,
                    end: 1,
                  ).animate(_apparition),
                  child: Image.asset(
                    'assets/images/logo_habibo.png',
                    width: 210,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              FadeTransition(
                opacity: _texte,
                child: const Text(
                  'Gestion d’entrepôt',
                  style: TextStyle(
                    color: Habibo.texteSecondaire,
                    fontSize: 16,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const Spacer(flex: 4),
              FadeTransition(
                opacity: _texte,
                child: Column(
                  children: [
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Habibo.bleu,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      reprise
                          ? 'Reprise de votre session…'
                          : 'Préparation de l’entrepôt…',
                      style: const TextStyle(
                        color: Habibo.texteDiscret,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 44),
            ],
          ),
        ),
      ),
    );
  }
}
