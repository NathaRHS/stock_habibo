import 'package:flutter/material.dart';

import '../data/magasin.dart';
import '../data/modeles.dart';
import 'commandes.dart';
import 'inventaire.dart';
import 'parcours.dart';
import 'reception.dart';

/// Ouvre le bon parcours selon le type du journal.
/// Le scan se fait toujours a l'interieur de l'operation choisie.
Future<void> ouvrirJournal(BuildContext context, Journal journal) {
  magasin.noterOuverture(journal);

  final Widget page = switch (journal.type) {
    TypeJournal.entree => EcranReception(journal: journal),
    TypeJournal.inventaire => EcranInventaire(journal: journal),
    // Une sortie deja commencee reprend directement sur son parcours.
    TypeJournal.sortie =>
      journal.parcours != null && !journal.parcoursTermine
          ? EcranParcours(journal: journal)
          : EcranCommandes(journal: journal),
  };

  return Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
}
