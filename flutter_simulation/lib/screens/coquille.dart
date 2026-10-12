import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/magasin.dart';
import '../theme/habibo.dart';
import '../widgets/commun.dart';
import 'accueil.dart';
import 'operations.dart';
import 'produits.dart';
import 'profil.dart';

/// Structure principale : quatre onglets et une barre de navigation en bas.
/// Le scan n'est pas un onglet : il se fait a l'interieur d'une operation.
class Coquille extends StatefulWidget {
  const Coquille({super.key});

  @override
  State<Coquille> createState() => _CoquilleState();
}

class _CoquilleState extends State<Coquille> {
  /// Index de l'onglet affiche (0 Accueil, 1 Operations, 2 Produits, 3 Profil).
  int _onglet = 0;

  /// Change d'onglet, sauf si c'est deja celui affiche.
  void _aller(int index) {
    if (index == _onglet) return;
    retourLeger();
    setState(() => _onglet = index);
  }

  @override
  Widget build(BuildContext context) {
    // Se reconstruit des que le magasin change (stock, journaux...).
    return ListenableBuilder(
      listenable: magasin,
      builder: (context, _) => Scaffold(
        backgroundColor: Habibo.fond,
        // IndexedStack garde les 4 pages en memoire : on retrouve chaque
        // onglet tel qu'on l'a laisse (defilement, saisie).
        body: IndexedStack(
          index: _onglet,
          children: [
            Accueil(onVoirOperations: () => _aller(1)),
            const Operations(),
            const Produits(),
            const Profil(),
          ],
        ),
        bottomNavigationBar: _BarreNavigation(
          selection: _onglet,
          onChange: _aller,
        ),
      ),
    );
  }
}

/// Barre du bas : une entree par onglet.
class _BarreNavigation extends StatelessWidget {
  const _BarreNavigation({required this.selection, required this.onChange});

  /// Index de l'onglet actif.
  final int selection;

  /// Appelee avec l'index touche.
  final ValueChanged<int> onChange;

  /// Icone et libelle de chaque onglet, dans l'ordre de l'IndexedStack.
  static const _onglets = [
    (LucideIcons.house, 'Accueil'),
    (LucideIcons.clipboardList, 'Opérations'),
    (LucideIcons.package, 'Produits'),
    (LucideIcons.user, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Habibo.surface,
        border: Border(top: BorderSide(color: Habibo.bordure)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < _onglets.length; i++)
                Expanded(
                  child: _Onglet(
                    icone: _onglets[i].$1,
                    libelle: _onglets[i].$2,
                    actif: i == selection,
                    onTap: () => onChange(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Un onglet : icone dans une pastille bleue (qui s'elargit quand il est
/// actif) et son libelle dessous.
class _Onglet extends StatelessWidget {
  const _Onglet({
    required this.icone,
    required this.libelle,
    required this.actif,
    required this.onTap,
  });

  final IconData icone;
  final String libelle;
  final bool actif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: actif ? 58 : 40,
            height: 30,
            decoration: BoxDecoration(
              color: actif ? Habibo.bleuDoux : Colors.transparent,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Icon(
              icone,
              size: 20,
              color: actif ? Habibo.bleu : Habibo.texteDiscret,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            libelle,
            style: TextStyle(
              color: actif ? Habibo.bleu : Habibo.texteDiscret,
              fontSize: 11.5,
              fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
