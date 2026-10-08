// Parcourt toute la simulation comme un utilisateur et enregistre une capture
// de chaque ecran dans test/captures/. Une erreur de mise en page (texte qui
// deborde, par exemple) fait echouer le test.
//
// Lancer :  flutter test --update-goldens
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habibo_simulation/main.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Future<void> _chargerPolices() async {
  Future<void> charger(String famille, List<String> fichiers) async {
    final chargeur = FontLoader(famille);
    for (final fichier in fichiers) {
      chargeur.addFont(rootBundle.load(fichier));
    }
    await chargeur.load();
  }

  await charger('Inter', [
    'assets/fonts/Inter-Regular.ttf',
    'assets/fonts/Inter-Medium.ttf',
    'assets/fonts/Inter-SemiBold.ttf',
    'assets/fonts/Inter-Bold.ttf',
  ]);
  await charger('packages/lucide_icons_flutter/Lucide', [
    'packages/lucide_icons_flutter/assets/lucide.ttf',
  ]);
}

/// Les images d'assets se decodent hors du faux temps des tests.
Future<void> _chargerImages(WidgetTester tester) async {
  final images = tester.widgetList<Image>(find.byType(Image)).toList();
  await tester.runAsync(() async {
    for (final image in images) {
      final element = tester.element(find.byWidget(image).first);
      await precacheImage(image.image, element);
    }
  });
  await tester.pump();
}

// Une transition ne demarre qu'a la premiere image qui suit : il faut donc
// plusieurs images pour la voir terminee.
Future<void> _attendre(WidgetTester tester, int millisecondes) async {
  await tester.pump(Duration(milliseconds: millisecondes));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> _capturer(WidgetTester tester, String nom) async {
  await _chargerImages(tester);
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('captures/$nom.png'),
  );
}

void main() {
  setUpAll(_chargerPolices);

  testWidgets('parcours complet sur telephone', (tester) async {
    // Les vraies ombres, pour des captures fideles a l'ecran.
    debugDisableShadows = false;
    tester.view.physicalSize = const Size(784, 1700);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const SimulationHabibo());
    await tester.pump(const Duration(milliseconds: 1600));
    await _capturer(tester, '01_demarrage');

    await _attendre(tester, 1200);
    await _capturer(tester, '02_connexion');

    await tester.tap(find.text('Opérateur'));
    await tester.pump();
    await tester.tap(find.text('Se connecter'));
    await tester.pump(const Duration(milliseconds: 1050));
    await tester.pump(const Duration(milliseconds: 500));
    await _capturer(tester, '03_accueil_chargement');

    await _attendre(tester, 1000);
    await _capturer(tester, '04_accueil');

    // Sortie : commandes -> emplacements -> parcours -> scan -> fin.
    await tester.tap(find.text('Commencer'));
    await _attendre(tester, 500);
    await _capturer(tester, '05_commandes');

    await tester.tap(find.text('Reste 3'));
    await _attendre(tester, 500);
    await _capturer(tester, '06_emplacements_proposes');
    await tester.tapAt(const Offset(196, 60));
    await _attendre(tester, 500);

    await tester.tap(find.text('Générer le meilleur parcours'));
    await tester.pump(const Duration(milliseconds: 600));
    await _capturer(tester, '07_generation');
    await _attendre(tester, 900);
    await _attendre(tester, 500);
    await _capturer(tester, '08_parcours');

    await tester.tap(find.text('Scanner'));
    await _attendre(tester, 500);
    await _capturer(tester, '09_prelevement');

    await tester.tap(find.text('Scanner le conditionnement'));
    await _attendre(tester, 500);
    await _capturer(tester, '10_scanner');

    // Le premier produit du plateau est celui attendu.
    await tester.tap(find.byKey(const ValueKey('scan-attendu')));
    await tester.pump(const Duration(milliseconds: 250));
    await _capturer(tester, '11_scanner_code_lu');
    await _attendre(tester, 600);

    await tester.tap(find.text('Tout'));
    await tester.pump();
    await _capturer(tester, '12_prelevement_pret');

    await tester.tap(find.text('Confirmer le prélèvement'));
    await tester.pump(const Duration(milliseconds: 600));
    await _attendre(tester, 500);
    await _capturer(tester, '13_parcours_avance');

    // Les etapes suivantes, sans capture.
    for (var etape = 0; etape < 12; etape++) {
      if (find.text('Parcours terminé').evaluate().isNotEmpty) break;
      if (find.text('Scanner').evaluate().isEmpty) {
        await tester.tap(find.text('Emplacement suivant'));
        await _attendre(tester, 300);
        continue;
      }
      await tester.tap(find.text('Scanner'));
      await _attendre(tester, 500);
      await tester.tap(find.text('Scanner le conditionnement'));
      await _attendre(tester, 500);
      // La premiere tuile du plateau est le produit attendu.
      await tester.tap(find.byKey(const ValueKey('scan-attendu')));
      await _attendre(tester, 600);
      await tester.tap(find.text('Tout'));
      await tester.pump();
      await tester.tap(find.text('Confirmer le prélèvement'));
      await tester.pump(const Duration(milliseconds: 600));
      await _attendre(tester, 500);
    }
    await _attendre(tester, 900);
    await _capturer(tester, '14_parcours_termine');

    await tester.tap(find.text('Retour aux opérations'));
    await _attendre(tester, 600);
    await tester.pump(const Duration(seconds: 4)); // le message disparait

    await tester.tap(find.text('Opérations'));
    await _attendre(tester, 300);
    await _capturer(tester, '15_operations');

    // Reception.
    await tester.tap(find.text('ENT-2610-014'));
    await _attendre(tester, 500);
    await _capturer(tester, '16_reception');
    await tester.tap(find.text('Scanner le code-barres'));
    await _attendre(tester, 500);
    await tester.tap(find.byKey(const ValueKey('scan-2')));
    await _attendre(tester, 600);
    await _capturer(tester, '17_reception_produit_reconnu');
    await tester.tap(find.byIcon(LucideIcons.chevronLeft).last);
    await _attendre(tester, 500);

    // Produits et fiche.
    await tester.tap(find.text('Produits'));
    await _attendre(tester, 300);
    await _capturer(tester, '18_produits');
    await tester.tap(find.text('Lait Candia Viva'));
    await _attendre(tester, 600);
    await _capturer(tester, '19_fiche_produit');
    await tester.drag(find.byType(ListView).last, const Offset(0, -520));
    await _attendre(tester, 300);
    await _capturer(tester, '20_fiche_produit_mouvements');
    await tester.tap(find.byIcon(LucideIcons.chevronLeft).last);
    await _attendre(tester, 500);

    // Profil, puis inventaire avec l'autre role.
    await tester.tap(find.text('Profil'));
    await _attendre(tester, 300);
    await _capturer(tester, '21_profil');

    await tester.tap(find.text('Passer en inventoriste'));
    await _attendre(tester, 300);
    await tester.pump(const Duration(seconds: 4));
    await tester.tap(find.text('Opérations'));
    await _attendre(tester, 300);
    await tester.tap(find.text('INV-2610-004'));
    await _attendre(tester, 500);
    await _capturer(tester, '22_inventaire');

    await tester.tap(find.text('Compter A11'));
    await _attendre(tester, 500);
    await tester.tap(find.text('Scanner le produit'));
    await _attendre(tester, 500);
    await tester.tap(find.byKey(const ValueKey('scan-attendu')));
    await _attendre(tester, 700);
    await _capturer(tester, '23_comptage');
    await tester.tap(find.text('Enregistrer le comptage'));
    await tester.pump(const Duration(milliseconds: 600));
    await _attendre(tester, 500);
    await _capturer(tester, '24_inventaire_compte');
    await tester.pump(const Duration(seconds: 4));
    debugDisableShadows = true;
  });

  testWidgets('presentation dans un telephone sur grand ecran', (tester) async {
    debugDisableShadows = false;
    tester.view.physicalSize = const Size(2560, 1720);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const SimulationHabibo());
    await _attendre(tester, 2400);
    await _attendre(tester, 600);
    await _capturer(tester, '00_grand_ecran');
    debugDisableShadows = true;
  });
}
