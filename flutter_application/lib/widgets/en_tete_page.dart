import 'package:flutter/material.dart';
import 'package:flutter_application/theme/habibo.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// En-tête des écrans secondaires : retour rond à gauche, titre centré et
/// action facultative à droite.
class EnTetePage extends StatelessWidget {
  const EnTetePage({
    super.key,
    required this.titre,
    this.sousTitre,
    this.action,
  });

  final String titre;
  final String? sousTitre;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Habibo.marge, 12, Habibo.marge, 12),
      child: SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Material(
                color: Habibo.surface,
                shape: const CircleBorder(
                  side: BorderSide(color: Habibo.bordure),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      LucideIcons.chevronLeft,
                      size: 22,
                      color: Habibo.texte,
                      semanticLabel: 'Retour',
                    ),
                  ),
                ),
              ),
            ),
            // Le titre reste centré : on lui réserve la place des deux côtés.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 96),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    titre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Habibo.texte,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (sousTitre != null)
                    Text(
                      sousTitre!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Habibo.texteSecondaire,
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
