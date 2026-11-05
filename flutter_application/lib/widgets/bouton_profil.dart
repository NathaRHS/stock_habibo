import 'package:flutter/material.dart';
import 'package:flutter_application/screens/ecran_profil.dart';
import 'package:flutter_application/services/session_utilisateur.dart';
import 'package:flutter_application/theme/habibo.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Rond avec les initiales de la personne connectée. Au toucher, il ouvre son
/// profil : on peut donc le poser en haut à droite de n'importe quel écran.
/// Rien ne s'affiche tant que personne n'est connecté.
class BoutonProfil extends StatelessWidget {
  const BoutonProfil({super.key, this.taille = 44, this.surFondSombre = false});

  final double taille;

  /// À utiliser sur une barre foncée : le rond devient clair et transparent.
  final bool surFondSombre;

  void _ouvrir(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EcranProfil(
          baseUrl: SessionUtilisateur.baseUrl!,
          accessToken: SessionUtilisateur.accessToken!,
          userId: SessionUtilisateur.userId!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!SessionUtilisateur.connecte) return const SizedBox.shrink();

    final initiales = SessionUtilisateur.initiales;
    final couleurTexte = surFondSombre ? Colors.white : Habibo.texte;

    return GestureDetector(
      onTap: () => _ouvrir(context),
      child: Semantics(
        button: true,
        label: 'Mon profil',
        child: Container(
          width: taille,
          height: taille,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: surFondSombre
                ? Colors.white.withValues(alpha: 0.12)
                : Habibo.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: surFondSombre
                  ? Colors.white.withValues(alpha: 0.6)
                  : Habibo.bleu,
              width: 1.5,
            ),
          ),
          child: initiales == null
              ? Icon(
                  LucideIcons.user,
                  size: taille * 0.45,
                  color: surFondSombre ? Colors.white : Habibo.texteSecondaire,
                )
              : Text(
                  initiales,
                  style: TextStyle(
                    color: couleurTexte,
                    fontSize: taille * 0.32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}
