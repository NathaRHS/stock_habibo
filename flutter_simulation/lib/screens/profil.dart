import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/magasin.dart';
import '../data/modeles.dart';
import '../theme/habibo.dart';
import '../widgets/commun.dart';
import 'ecran_demarrage.dart';
import 'ecran_login.dart';

/// Profil (proposition) : compte, reglages, deconnexion.
class Profil extends StatelessWidget {
  const Profil({super.key});

  void _redemarrer(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, _, _) => const EcranDemarrage(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
      (route) => false,
    );
  }

  Future<void> _deconnecter(BuildContext context) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text(
          'Vos opérations en cours sont conservées. Vous devrez saisir à '
          'nouveau votre matricule.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Habibo.rouge),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
    if (confirmation != true || !context.mounted) return;

    magasin.deconnecter();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const EcranLogin()),
      (route) => false,
    );
  }

  void _aPropos(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _FeuilleAPropos(),
    );
  }

  // L'onglet se redessine quand un reglage ou le role change.
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: magasin,
    builder: (context, _) => _construire(context),
  );

  Widget _construire(BuildContext context) {
    final utilisateur = magasin.utilisateur;
    if (utilisateur == null) return const SizedBox.shrink();

    final autreRole = utilisateur.role == Role.operateur
        ? Role.inventoriste
        : Role.operateur;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Habibo.marge, 24, Habibo.marge, 32),
        children: [
          Center(
            child: Container(
              width: 84,
              height: 84,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Habibo.bleu,
                shape: BoxShape.circle,
              ),
              child: Text(
                utilisateur.initiales,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            utilisateur.nom,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Habibo.texte,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${utilisateur.libelleRole} · matricule ${utilisateur.matricule}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Habibo.texteSecondaire, fontSize: 15),
          ),
          const SizedBox(height: 28),
          _Groupe(
            titre: 'Réglages',
            lignes: [
              _LigneReglage(
                icone: LucideIcons.vibrate,
                libelle: 'Vibrations',
                aide: 'À chaque scan réussi ou refusé',
                trailing: Switch(
                  value: magasin.vibrations,
                  activeTrackColor: Habibo.bleu,
                  onChanged: magasin.reglerVibrations,
                ),
              ),
              _LigneReglage(
                icone: LucideIcons.volume2,
                libelle: 'Sons',
                aide: 'Bip de confirmation',
                trailing: Switch(
                  value: magasin.sons,
                  activeTrackColor: Habibo.bleu,
                  onChanged: magasin.reglerSons,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Groupe(
            titre: 'Simulation',
            lignes: [
              _LigneReglage(
                icone: LucideIcons.repeat,
                libelle:
                    'Passer en ${autreRole == Role.operateur ? 'opérateur' : 'inventoriste'}',
                aide: 'Chaque rôle voit ses propres journaux',
                onTap: () {
                  retourLeger();
                  magasin.connecter(autreRole);
                  afficherMessage(
                    context,
                    'Vous êtes maintenant '
                    '${magasin.utilisateur!.libelleRole.toLowerCase()}.',
                    icone: LucideIcons.circleCheck,
                  );
                },
              ),
              _LigneReglage(
                icone: LucideIcons.rotateCcw,
                libelle: 'Redémarrer l’application',
                aide: 'Pour voir la session mémorisée au lancement',
                onTap: () => _redemarrer(context),
              ),
              _LigneReglage(
                icone: LucideIcons.info,
                libelle: 'À propos de cette simulation',
                aide: 'Ce qui existe déjà, ce qui est proposé',
                onTap: () => _aPropos(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Groupe(
            lignes: [
              _LigneReglage(
                icone: LucideIcons.logOut,
                libelle: 'Se déconnecter',
                couleur: Habibo.rouge,
                onTap: () => _deconnecter(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Habibo WMS · version 1.0 (simulation)',
            textAlign: TextAlign.center,
            style: TextStyle(color: Habibo.texteDiscret, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _Groupe extends StatelessWidget {
  const _Groupe({this.titre, required this.lignes});

  final String? titre;
  final List<Widget> lignes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (titre != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              titre!,
              style: const TextStyle(
                color: Habibo.texteSecondaire,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: Habibo.surface,
            borderRadius: BorderRadius.circular(Habibo.rayonCarte),
            border: Border.all(color: Habibo.bordure),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < lignes.length; i++) ...[
                if (i > 0)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 62,
                    color: Habibo.bordure,
                  ),
                lignes[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LigneReglage extends StatelessWidget {
  const _LigneReglage({
    required this.icone,
    required this.libelle,
    this.aide,
    this.trailing,
    this.onTap,
    this.couleur = Habibo.texte,
  });

  final IconData icone;
  final String libelle;
  final String? aide;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: couleur == Habibo.rouge
                      ? Habibo.rougeDoux
                      : Habibo.neutreDoux,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icone,
                  size: 18,
                  color: couleur == Habibo.rouge
                      ? Habibo.rouge
                      : Habibo.texteSecondaire,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      libelle,
                      style: TextStyle(
                        color: couleur,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (aide != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        aide!,
                        style: const TextStyle(
                          color: Habibo.texteSecondaire,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing ??
                  (onTap == null || couleur == Habibo.rouge
                      ? const SizedBox.shrink()
                      : const Icon(
                          LucideIcons.chevronRight,
                          size: 18,
                          color: Habibo.texteDiscret,
                        )),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeuilleAPropos extends StatelessWidget {
  const _FeuilleAPropos();

  @override
  Widget build(BuildContext context) {
    Widget bloc(String titre, Color couleur, List<String> points) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Etiquette(
              texte: titre,
              couleur: couleur,
              fond: couleur.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 10),
            for (final point in points)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 7, right: 10),
                      child: CircleAvatar(
                        radius: 2.5,
                        backgroundColor: Habibo.texteDiscret,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        point,
                        style: const TextStyle(
                          color: Habibo.texte,
                          fontSize: 14.5,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Habibo.marge, 12, Habibo.marge, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Habibo.bordure,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Cette simulation',
              style: TextStyle(
                color: Habibo.texte,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 18),
            bloc('Parcours existant', Habibo.bleu, const [
              'Connexion par matricule, journaux filtrés par rôle',
              'Réception : scan, DLV et DLC, quantité',
              'Sortie : commandes, meilleur parcours, scan et pavé numérique',
              'Inventaire : choix de l’emplacement, comptage',
            ]),
            bloc('Propositions', Habibo.vert, const [
              'Écran de démarrage et session mémorisée',
              'Barre de navigation, accueil avec « Reprendre »',
              'Onglet Produits, fiche produit, photos partout',
              'Reste à servir quand le stock ne suffit pas',
              'Vibrations, chargements, états vides',
            ]),
            const Text(
              'Données fictives. Photos : Open Food Facts (CC BY-SA).',
              style: TextStyle(color: Habibo.texteDiscret, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}
