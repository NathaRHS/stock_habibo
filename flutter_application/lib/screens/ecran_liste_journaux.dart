import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application/screens/ecran_scan_session.dart';
import 'package:flutter_application/screens/ecran_choix_emplacement_inventaire.dart';
import 'package:http/http.dart' as http;

class EcranListeJournaux extends StatefulWidget {
  const EcranListeJournaux({
    super.key,
    required this.baseUrl,
    required this.accessToken,
  });

  final String baseUrl;
  final String accessToken;

  @override
  State<EcranListeJournaux> createState() => _EcranListeJournauxState();
}

class _EcranListeJournauxState extends State<EcranListeJournaux> {
  List<JournalMouvement> _journaux = [];
  String? _erreur;
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _chargerJournaux();
  }

  Future<void> _chargerJournaux() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });

    try {
      final uri = Uri.parse('${widget.baseUrl}/journaux-mouvements');
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.accessToken}',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Impossible de charger les journaux (${response.statusCode})',
        );
      }

      final donnees = jsonDecode(utf8.decode(response.bodyBytes));

      if (donnees is! List) {
        throw const FormatException('Réponse inattendue du serveur');
      }

      final journaux = donnees
          .map(
            (element) =>
                JournalMouvement.fromJson(element as Map<String, dynamic>),
          )
          .toList();

      if (!mounted) return;

      setState(() {
        _journaux = journaux;
      });
    } catch (erreur) {
      if (!mounted) return;

      setState(() {
        _erreur = erreur.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _chargement = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des journaux'),
        backgroundColor: const Color(0xFF064B9C),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _chargement ? null : _chargerJournaux,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _construireContenu(),
    );
  }

  Widget _construireContenu() {
    if (_chargement) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_erreur != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(_erreur!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _chargerJournaux,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_journaux.isEmpty) {
      return const Center(child: Text('Aucun journal trouvé.'));
    }

    return RefreshIndicator(
      onRefresh: _chargerJournaux,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _journaux.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final journal = _journaux[index];
          return _CarteJournal(
            journal: journal,
            onOuvrir:
                journal.statut == 'EN COURS' || journal.statut == 'MODIFIE'
                ? () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            journal.typeMouvementJournal.trim().toUpperCase() ==
                                'INVENTAIRE'
                            ? EcranChoixEmplacementInventaire(
                                journalId: journal.id,
                                referenceJournal: journal.reference,
                                baseUrl: widget.baseUrl,
                                accessToken: widget.accessToken,
                              )
                            : EcranScanSession(
                                journalId: journal.id,
                                referenceJournal: journal.reference,
                                typeJournal: journal.typeMouvementJournal,
                                baseUrl: widget.baseUrl,
                                accessToken: widget.accessToken,
                              ),
                      ),
                    );
                    _chargerJournaux();
                  }
                : null,
          );
        },
      ),
    );
  }
}

class _CarteJournal extends StatelessWidget {
  const _CarteJournal({required this.journal, required this.onOuvrir});

  final JournalMouvement journal;
  final VoidCallback? onOuvrir;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOuvrir,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long, color: Color(0xFF064B9C)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      journal.reference,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Chip(label: Text(journal.statut)),
                ],
              ),
              const Divider(height: 24),
              _information('Type', journal.typeMouvementJournal),
              _information('Sens', journal.sens == 1 ? 'Entrée' : 'Sortie'),
              _information('Client', journal.nomClient ?? '—'),
              _information('Fournisseur', journal.fournisseur ?? '—'),
              _information('Pièce jointe', journal.urlPieceJointe ?? 'Aucune'),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  onOuvrir == null
                      ? 'Consultation uniquement'
                      : 'Ouvrir la session →',
                  style: TextStyle(
                    color: onOuvrir == null
                        ? Colors.grey
                        : const Color(0xFF064B9C),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _information(String titre, String valeur) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              '$titre :',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(valeur)),
        ],
      ),
    );
  }
}

class JournalMouvement {
  const JournalMouvement({
    required this.id,
    required this.reference,
    required this.typeMouvementJournal,
    required this.sens,
    required this.statut,
    this.urlPieceJointe,
    this.nomClient,
    this.fournisseur,
  });

  final int id;
  final String reference;
  final String? urlPieceJointe;
  final String? nomClient;
  final String? fournisseur;
  final String typeMouvementJournal;
  final int sens;
  final String statut;

  factory JournalMouvement.fromJson(Map<String, dynamic> json) {
    return JournalMouvement(
      id: (json['id'] as num).toInt(),
      reference: json['reference'] as String,
      urlPieceJointe: json['urlPieceJointe'] as String?,
      nomClient: json['nomClient'] as String?,
      fournisseur: json['fournisseur'] as String?,
      typeMouvementJournal: json['typeMouvementJournal'] as String,
      sens: (json['sens'] as num).toInt(),
      statut: json['statut'] as String,
    );
  }
}
