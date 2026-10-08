import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/habibo.dart';

/// Couleur de la barre d'etat simulee : sombre par defaut, claire sur les
/// ecrans a fond fonce (demarrage, scanner, parcours).
final barreEtatClaire = ValueNotifier<bool>(false);

/// A placer autour d'un ecran a fond fonce pour passer la barre d'etat en blanc.
class FondFonce extends StatefulWidget {
  const FondFonce({super.key, required this.child});

  final Widget child;

  @override
  State<FondFonce> createState() => _FondFonceState();
}

class _FondFonceState extends State<FondFonce> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => barreEtatClaire.value = true,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => barreEtatClaire.value = false,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Sur un grand ecran (navigateur, bureau), l'application est presentee dans un
/// telephone. Sur un vrai telephone, elle occupe tout l'ecran.
class CadreTelephone extends StatelessWidget {
  const CadreTelephone({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, contraintes) {
        if (contraintes.maxWidth < 600) return child;

        final hauteur = (contraintes.maxHeight - 48).clamp(480.0, 860.0);
        final largeur = (hauteur * 0.468).clamp(300.0, 402.0);
        final donnees = MediaQuery.of(context);

        final telephone = Container(
          width: largeur,
          height: hauteur,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF0E141B),
            borderRadius: BorderRadius.circular(54),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33064B9C),
                blurRadius: 60,
                offset: Offset(0, 30),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(44),
            child: Stack(
              children: [
                MediaQuery(
                  data: donnees.copyWith(
                    size: Size(largeur - 20, hauteur - 20),
                    padding: const EdgeInsets.only(top: 44, bottom: 20),
                    viewPadding: const EdgeInsets.only(top: 44, bottom: 20),
                  ),
                  child: child,
                ),
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(child: _BarreEtat()),
                ),
                Positioned(
                  bottom: 7,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Center(
                      child: ValueListenableBuilder<bool>(
                        valueListenable: barreEtatClaire,
                        builder: (context, clair, _) => Container(
                          width: 118,
                          height: 4.5,
                          decoration: BoxDecoration(
                            color: clair
                                ? Colors.white.withValues(alpha: 0.85)
                                : Habibo.encre.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        return ColoredBox(
          color: const Color(0xFFE9EEF4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (contraintes.maxWidth >= 1040) ...[
                const _Guide(),
                const SizedBox(width: 56),
              ],
              telephone,
            ],
          ),
        );
      },
    );
  }
}

class _BarreEtat extends StatelessWidget {
  const _BarreEtat();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: barreEtatClaire,
      builder: (context, clair, _) {
        final couleur = clair ? Colors.white : Habibo.encre;
        final maintenant = TimeOfDay.now();
        final heure =
            '${maintenant.hour.toString().padLeft(2, '0')}:'
            '${maintenant.minute.toString().padLeft(2, '0')}';

        return SizedBox(
          height: 44,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Row(
              children: [
                Text(
                  heure,
                  style: TextStyle(
                    color: couleur,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                    fontFamily: 'Inter',
                  ),
                ),
                const Spacer(),
                // Encoche centrale.
                Container(
                  width: 92,
                  height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E141B),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const Spacer(),
                Icon(LucideIcons.signal, size: 15, color: couleur),
                const SizedBox(width: 5),
                Icon(LucideIcons.wifi, size: 15, color: couleur),
                const SizedBox(width: 5),
                Icon(LucideIcons.batteryFull, size: 19, color: couleur),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Panneau d'aide affiche a cote du telephone sur les ecrans larges.
class _Guide extends StatelessWidget {
  const _Guide();

  @override
  Widget build(BuildContext context) {
    Widget etape(String numero, String titre, String texte) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Habibo.bleu,
                shape: BoxShape.circle,
              ),
              child: Text(
                numero,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.none,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titre,
                    style: const TextStyle(
                      color: Habibo.texte,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.none,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    texte,
                    style: const TextStyle(
                      color: Habibo.texteSecondaire,
                      fontSize: 13.5,
                      height: 1.45,
                      fontWeight: FontWeight.w400,
                      decoration: TextDecoration.none,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: 340,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset('assets/images/logo_habibo.png', width: 132),
          const SizedBox(height: 26),
          const Text(
            'Simulation de\nl’application mobile',
            style: TextStyle(
              color: Habibo.texte,
              fontSize: 32,
              height: 1.12,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
              decoration: TextDecoration.none,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Données fictives, aucun serveur. Tout est cliquable : essayez ce '
            'parcours.',
            style: TextStyle(
              color: Habibo.texteSecondaire,
              fontSize: 15,
              height: 1.5,
              fontWeight: FontWeight.w400,
              decoration: TextDecoration.none,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 30),
          etape(
            '1',
            'Connexion',
            'Touchez « Opérateur », puis « Se connecter ».',
          ),
          etape(
            '2',
            'Sortie',
            'Accueil → Commencer → Générer le parcours → Scanner chaque '
                'emplacement.',
          ),
          etape(
            '3',
            'Réception',
            'Opérations → ENT-2610-014 → scanner un produit, saisir les dates '
                'et la quantité.',
          ),
          etape(
            '4',
            'Produits',
            'Onglet Produits → scanner ou chercher → fiche avec stock et '
                'mouvements.',
          ),
          etape(
            '5',
            'Inventaire',
            'Profil → Passer en inventoriste → Opérations → INV-2610-004.',
          ),
        ],
      ),
    );
  }
}
