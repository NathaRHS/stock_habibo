import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/magasin.dart';
import '../data/modeles.dart';
import '../theme/habibo.dart';

// ---------------------------------------------------------------------------
// Retours sensoriels et formats
// ---------------------------------------------------------------------------

void retourLeger() {
  if (magasin.vibrations) HapticFeedback.selectionClick();
}

void retourSucces() {
  if (magasin.vibrations) HapticFeedback.mediumImpact();
  if (magasin.sons) SystemSound.play(SystemSoundType.click);
}

void retourErreur() {
  if (magasin.vibrations) HapticFeedback.heavyImpact();
  if (magasin.sons) SystemSound.play(SystemSoundType.alert);
}

String formaterDate(DateTime date) {
  final jour = date.day.toString().padLeft(2, '0');
  final mois = date.month.toString().padLeft(2, '0');
  return '$jour/$mois/${date.year}';
}

const _jours = [
  'Lundi',
  'Mardi',
  'Mercredi',
  'Jeudi',
  'Vendredi',
  'Samedi',
  'Dimanche',
];
const _mois = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

String dateDuJour() {
  final maintenant = DateTime.now();
  return '${_jours[maintenant.weekday - 1]} ${maintenant.day} '
      '${_mois[maintenant.month - 1]}';
}

String ilYA(DateTime date) {
  final ecart = DateTime.now().difference(date);
  if (ecart.inMinutes < 1) return "à l'instant";
  if (ecart.inMinutes < 60) return 'il y a ${ecart.inMinutes} min';
  if (ecart.inHours < 24) return 'il y a ${ecart.inHours} h';
  return 'il y a ${ecart.inDays} j';
}

int joursAvant(DateTime date) {
  final maintenant = DateTime.now();
  final aujourdhui = DateTime(
    maintenant.year,
    maintenant.month,
    maintenant.day,
  );
  return date.difference(aujourdhui).inDays;
}

/// [decalageBas] remonte le message quand un bouton est fixe en bas de l'ecran,
/// pour ne jamais le recouvrir.
void afficherMessage(
  BuildContext context,
  String texte, {
  IconData? icone,
  double decalageBas = 16,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        margin: EdgeInsets.fromLTRB(16, 0, 16, decalageBas),
        content: Row(
          children: [
            if (icone != null) ...[
              Icon(icone, color: Colors.white, size: 18),
              const SizedBox(width: 10),
            ],
            Expanded(child: Text(texte)),
          ],
        ),
      ),
    );
}

// ---------------------------------------------------------------------------
// Vignette d'article : la photo, ou une icone neutre
// ---------------------------------------------------------------------------

class VignetteArticle extends StatelessWidget {
  const VignetteArticle({
    super.key,
    required this.article,
    this.taille = 48,
    this.hero = false,
  });

  final Article article;
  final double taille;

  /// Anime la photo entre la liste et la fiche produit.
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final photo = article.photo;
    final contenu = Container(
      width: taille,
      height: taille,
      padding: EdgeInsets.all(taille * 0.09),
      decoration: BoxDecoration(
        color: photo == null ? Habibo.neutreDoux : Habibo.surface,
        borderRadius: BorderRadius.circular(taille * 0.26),
        border: Border.all(color: Habibo.bordure),
      ),
      child: photo == null
          ? Icon(
              LucideIcons.package,
              size: taille * 0.44,
              color: Habibo.texteDiscret,
            )
          : Image.asset(
              photo,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Icon(
                LucideIcons.package,
                size: taille * 0.44,
                color: Habibo.texteDiscret,
              ),
            ),
    );

    if (!hero) return contenu;
    return Hero(tag: 'article-${article.id}', child: contenu);
  }
}

// ---------------------------------------------------------------------------
// Pastille de statut
// ---------------------------------------------------------------------------

class PastilleStatut extends StatelessWidget {
  const PastilleStatut({super.key, required this.statut});

  final String statut;

  @override
  Widget build(BuildContext context) {
    final (libelle, couleur, fond) = _apparence(statut);
    return Etiquette(texte: libelle, couleur: couleur, fond: fond, point: true);
  }

  static (String, Color, Color) _apparence(String statut) {
    switch (statut.trim().toUpperCase().replaceAll('_', ' ')) {
      case 'EN COURS':
        return ('En cours', Habibo.orange, Habibo.orangeDoux);
      case 'MODIFIE':
        return ('À corriger', Habibo.rouge, Habibo.rougeDoux);
      case 'EN ATTENTE':
        return ('En attente', Habibo.texteSecondaire, Habibo.neutreDoux);
      case 'VALIDE':
        return ('Validé', Habibo.vert, Habibo.vertDoux);
      case 'AFFECTEE':
        return ('Affecté', Habibo.vert, Habibo.vertDoux);
      case 'CLOTURE':
        return ('Clôturé', Habibo.vert, Habibo.vertDoux);
      case 'RESERVEE':
        return ('À prélever', Habibo.bleu, Habibo.bleuDoux);
      case 'PRELEVEE':
        return ('Prélevé', Habibo.vert, Habibo.vertDoux);
      default:
        return (statut, Habibo.texteSecondaire, Habibo.neutreDoux);
    }
  }
}

class Etiquette extends StatelessWidget {
  const Etiquette({
    super.key,
    required this.texte,
    this.couleur = Habibo.texteSecondaire,
    this.fond = Habibo.neutreDoux,
    this.point = false,
    this.icone,
  });

  final String texte;
  final Color couleur;
  final Color fond;
  final bool point;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (point) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          if (icone != null) ...[
            Icon(icone, size: 13, color: couleur),
            const SizedBox(width: 5),
          ],
          Text(
            texte,
            style: TextStyle(
              color: couleur,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// En-tete des ecrans secondaires
// ---------------------------------------------------------------------------

class EnTetePage extends StatelessWidget {
  const EnTetePage({
    super.key,
    required this.titre,
    this.sousTitre,
    this.action,
    this.clair = false,
  });

  final String titre;
  final String? sousTitre;
  final Widget? action;

  /// Version pour fond bleu : texte blanc, bouton translucide.
  final bool clair;

  @override
  Widget build(BuildContext context) {
    final couleurTexte = clair ? Colors.white : Habibo.texte;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Habibo.marge, 12, Habibo.marge, 12),
      child: SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: BoutonRond(
                icone: LucideIcons.chevronLeft,
                libelle: 'Retour',
                clair: clair,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 76),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    titre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: couleurTexte,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (sousTitre != null)
                    Text(
                      sousTitre!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: clair
                            ? Colors.white.withValues(alpha: 0.72)
                            : Habibo.texteSecondaire,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
            if (action != null)
              Align(alignment: Alignment.centerRight, child: action),
          ],
        ),
      ),
    );
  }
}

class BoutonRond extends StatelessWidget {
  const BoutonRond({
    super.key,
    required this.icone,
    required this.libelle,
    required this.onTap,
    this.clair = false,
  });

  final IconData icone;
  final String libelle;
  final VoidCallback onTap;
  final bool clair;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: clair ? Colors.white.withValues(alpha: 0.14) : Habibo.surface,
      shape: CircleBorder(
        side: BorderSide(
          color: clair ? Colors.white.withValues(alpha: 0.2) : Habibo.bordure,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icone,
            size: 21,
            color: clair ? Colors.white : Habibo.texte,
            semanticLabel: libelle,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bouton principal
// ---------------------------------------------------------------------------

class BoutonPrincipal extends StatelessWidget {
  const BoutonPrincipal({
    super.key,
    required this.libelle,
    required this.onPressed,
    this.icone,
    this.chargement = false,
    this.couleur = Habibo.bleu,
  });

  final String libelle;
  final VoidCallback? onPressed;
  final IconData? icone;
  final bool chargement;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: chargement ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: couleur,
          foregroundColor: Colors.white,
          disabledBackgroundColor: couleur.withValues(alpha: 0.45),
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Habibo.rayon),
          ),
        ),
        child: chargement
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icone != null) ...[
                    Icon(icone, size: 19),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Text(
                      libelle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Carte, filtres, etats
// ---------------------------------------------------------------------------

class Carte extends StatelessWidget {
  const Carte({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.couleur = Habibo.surface,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: couleur,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Habibo.rayonCarte),
        side: const BorderSide(color: Habibo.bordure),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class FiltrePastille {
  const FiltrePastille({required this.libelle, this.compteur});

  final String libelle;
  final int? compteur;
}

class FiltresPastilles extends StatelessWidget {
  const FiltresPastilles({
    super.key,
    required this.filtres,
    required this.selection,
    required this.onChange,
    this.marge = Habibo.marge,
  });

  final List<FiltrePastille> filtres;
  final int selection;
  final ValueChanged<int> onChange;
  final double marge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: marge),
        itemCount: filtres.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filtre = filtres[index];
          final actif = index == selection;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: ShapeDecoration(
              color: actif ? Habibo.encre : Habibo.surface,
              shape: StadiumBorder(
                side: BorderSide(color: actif ? Habibo.encre : Habibo.bordure),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  retourLeger();
                  onChange(index);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        filtre.libelle,
                        style: TextStyle(
                          color: actif ? Colors.white : Habibo.texte,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (filtre.compteur != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '${filtre.compteur}',
                          style: TextStyle(
                            color: actif
                                ? Colors.white.withValues(alpha: 0.75)
                                : Habibo.texteDiscret,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class EtatVide extends StatelessWidget {
  const EtatVide({
    super.key,
    required this.icone,
    required this.titre,
    required this.texte,
  });

  final IconData icone;
  final String titre;
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 48, 40, 24),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Habibo.neutreDoux,
              shape: BoxShape.circle,
            ),
            child: Icon(icone, size: 26, color: Habibo.texteSecondaire),
          ),
          const SizedBox(height: 16),
          Text(
            titre,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Habibo.texte,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            texte,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Habibo.texteSecondaire,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bloc gris qui pulse pendant un chargement (a la place d'un cercle).
class Squelette extends StatefulWidget {
  const Squelette({
    super.key,
    this.largeur = double.infinity,
    required this.hauteur,
    this.rayon = 10,
  });

  final double largeur;
  final double hauteur;
  final double rayon;

  @override
  State<Squelette> createState() => _SqueletteState();
}

class _SqueletteState extends State<Squelette>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(_animation),
      child: Container(
        width: widget.largeur,
        height: widget.hauteur,
        decoration: BoxDecoration(
          color: Habibo.neutreDoux,
          borderRadius: BorderRadius.circular(widget.rayon),
        ),
      ),
    );
  }
}

class TitreSection extends StatelessWidget {
  const TitreSection(this.texte, {super.key, this.action, this.onAction});

  final String texte;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Habibo.marge, 0, Habibo.marge, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              texte,
              style: const TextStyle(
                color: Habibo.texte,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Text(
                action!,
                style: const TextStyle(
                  color: Habibo.bleu,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
