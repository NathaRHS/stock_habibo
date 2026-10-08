import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/magasin.dart';
import '../data/modeles.dart';
import '../theme/habibo.dart';
import '../widgets/cadre_telephone.dart';
import '../widgets/commun.dart';

/// Scanner de code-barres SIMULE : pas de camera, on touche un produit pour
/// faire comme si on le scannait. Renvoie le code-barres lu.
class EcranScanner extends StatefulWidget {
  const EcranScanner({super.key, this.consigne, this.attendu});

  /// Texte affiche sous le viseur.
  final String? consigne;

  /// Produit attendu : il est propose en premier.
  final Article? attendu;

  @override
  State<EcranScanner> createState() => _EcranScannerState();
}

class _EcranScannerState extends State<EcranScanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _balayage = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  bool _lu = false;
  bool _lampe = false;

  @override
  void dispose() {
    _balayage.dispose();
    super.dispose();
  }

  Future<void> _lire(Article article) async {
    if (_lu) return;
    retourSucces();
    setState(() => _lu = true);
    _balayage.stop();
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (mounted) Navigator.of(context).pop(article.codeBarres);
  }

  Future<void> _saisirCode() async {
    final controleur = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saisir le code-barres'),
        content: TextField(
          controller: controleur,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Ex. 5449000000996'),
          onSubmitted: (valeur) => Navigator.pop(context, valeur),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controleur.text),
            style: FilledButton.styleFrom(backgroundColor: Habibo.bleu),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    if (!mounted || code == null || code.trim().isEmpty) return;
    Navigator.of(context).pop(code.trim());
  }

  @override
  Widget build(BuildContext context) {
    final attendu = widget.attendu;
    final produits = [
      ?attendu,
      ...magasin.articles.where((article) => article.id != attendu?.id),
    ];

    return FondFonce(
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1118),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    BoutonRond(
                      icone: LucideIcons.x,
                      libelle: 'Fermer',
                      clair: true,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Scanner',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    BoutonRond(
                      icone: _lampe
                          ? LucideIcons.flashlightOff
                          : LucideIcons.flashlight,
                      libelle: 'Lampe',
                      clair: true,
                      onTap: () {
                        retourLeger();
                        setState(() => _lampe = !_lampe);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(child: Center(child: _viseur())),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _lu
                      ? 'Code lu'
                      : widget.consigne ??
                            'Placez le code-barres dans le cadre.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _lu ? const Color(0xFF5FE0A2) : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _plateau(produits),
            ],
          ),
        ),
      ),
    );
  }

  Widget _viseur() {
    final couleur = _lu ? const Color(0xFF5FE0A2) : Colors.white;

    return SizedBox(
      width: 236,
      height: 236,
      child: Stack(
        children: [
          // Halo de la lampe.
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: _lampe ? 0.12 : 0.04),
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          for (final coin in const [
            Alignment.topLeft,
            Alignment.topRight,
            Alignment.bottomLeft,
            Alignment.bottomRight,
          ])
            Align(
              alignment: coin,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  border: Border(
                    top: coin.y < 0
                        ? BorderSide(color: couleur, width: 4)
                        : BorderSide.none,
                    bottom: coin.y > 0
                        ? BorderSide(color: couleur, width: 4)
                        : BorderSide.none,
                    left: coin.x < 0
                        ? BorderSide(color: couleur, width: 4)
                        : BorderSide.none,
                    right: coin.x > 0
                        ? BorderSide(color: couleur, width: 4)
                        : BorderSide.none,
                  ),
                ),
              ),
            ),
          if (_lu)
            const Center(
              child: Icon(
                LucideIcons.circleCheck,
                size: 64,
                color: Color(0xFF5FE0A2),
              ),
            )
          else
            AnimatedBuilder(
              animation: _balayage,
              builder: (context, _) => Align(
                alignment: Alignment(0, -0.82 + 1.64 * _balayage.value),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 18),
                  height: 2.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6FB0FF),
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: const [
                      BoxShadow(color: Color(0xAA3B8CFF), blurRadius: 14),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Plateau de simulation : les produits « devant la camera ».
  Widget _plateau(List<Article> produits) {
    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF151D27),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.mousePointerClick,
                  size: 15,
                  color: Color(0xFF8FA3B8),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Simulation : touchez un produit pour le scanner',
                    style: TextStyle(color: Color(0xFF8FA3B8), fontSize: 13),
                  ),
                ),
                GestureDetector(
                  onTap: _saisirCode,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Icon(
                      LucideIcons.keyboard,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: produits.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final article = produits[index];
                final estAttendu = article.id == widget.attendu?.id;

                return GestureDetector(
                  key: estAttendu
                      ? const ValueKey('scan-attendu')
                      : ValueKey('scan-${article.id}'),
                  onTap: () => _lire(article),
                  child: Container(
                    width: 92,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2935),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: estAttendu
                            ? const Color(0xFF6FB0FF)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        VignetteArticle(article: article, taille: 54),
                        const SizedBox(height: 6),
                        Text(
                          article.nom,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          article.contenance,
                          maxLines: 1,
                          style: const TextStyle(
                            color: Color(0xFF8FA3B8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
