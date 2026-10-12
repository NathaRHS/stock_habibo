import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/magasin.dart';
import '../data/modeles.dart';
import '../theme/habibo.dart';
import '../widgets/commun.dart';

/// Fin du parcours : resume de ce qui a ete preleve et de ce qui reste.
/// La sortie est ensuite validee par l'administrateur sur le site web.
class EcranParcoursTermine extends StatefulWidget {
  const EcranParcoursTermine({super.key, required this.journal});

  final Journal journal;

  @override
  State<EcranParcoursTermine> createState() => _EcranParcoursTermineState();
}

class _EcranParcoursTermineState extends State<EcranParcoursTermine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  @override
  void initState() {
    super.initState();
    retourSucces();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final journal = widget.journal;
    final etapes = journal.parcours ?? const <EtapePicking>[];
    final restes = [
      for (final commande in journal.commandes)
        if (magasin.resteCommande(journal, commande) > 0)
          (commande, magasin.resteCommande(journal, commande)),
    ];

    return Scaffold(
      backgroundColor: Habibo.fond,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  Habibo.marge,
                  48,
                  Habibo.marge,
                  24,
                ),
                children: [
                  Center(
                    child: ScaleTransition(
                      scale: CurvedAnimation(
                        parent: _animation,
                        curve: Curves.elasticOut,
                      ),
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: const BoxDecoration(
                          color: Habibo.vertDoux,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.check,
                          size: 40,
                          color: Habibo.vert,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Parcours terminé',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Habibo.texte,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${journal.reference} · ${journal.tiers ?? ''}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Habibo.texteSecondaire,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Les deux cartes gardent la meme hauteur.
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _Chiffre(
                            valeur: '${etapes.length}',
                            libelle: 'emplacements',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Chiffre(
                            valeur:
                                '${etapes.fold(0, (total, e) => total + e.quantitePrelevee)}',
                            libelle: 'unités prélevées',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (restes.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Habibo.orangeDoux,
                        borderRadius: BorderRadius.circular(Habibo.rayonCarte),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                LucideIcons.triangleAlert,
                                size: 18,
                                color: Habibo.orange,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Reste à servir',
                                style: TextStyle(
                                  color: Habibo.orange,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          for (final (commande, reste) in restes)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  VignetteArticle(
                                    article: commande.article,
                                    taille: 36,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      commande.article.titre,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Habibo.texte,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    commande.article.unites(reste),
                                    style: const TextStyle(
                                      color: Habibo.orange,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 4),
                          const Text(
                            'L’administrateur sera prévenu. Il pourra créer un '
                            'nouveau bon quand le stock sera revenu.',
                            style: TextStyle(
                              color: Habibo.texteSecondaire,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        LucideIcons.clock,
                        size: 17,
                        color: Habibo.texteSecondaire,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'En attente de validation de la sortie par '
                          'l’administrateur. Le stock baissera à ce moment-là.',
                          style: TextStyle(
                            color: Habibo.texteSecondaire,
                            fontSize: 13.5,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Habibo.marge,
                8,
                Habibo.marge,
                16,
              ),
              child: BoutonPrincipal(
                libelle: 'Retour aux opérations',
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chiffre extends StatelessWidget {
  const _Chiffre({required this.valeur, required this.libelle});

  final String valeur;
  final String libelle;

  @override
  Widget build(BuildContext context) {
    return Carte(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            valeur,
            style: const TextStyle(
              color: Habibo.texte,
              fontSize: 30,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            libelle,
            style: const TextStyle(color: Habibo.texteSecondaire, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
