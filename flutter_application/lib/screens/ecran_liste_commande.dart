import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application/models/commande.dart';
import 'package:http/http.dart' as http;

class EcranListeCommande extends StatefulWidget {
  const EcranListeCommande({
    super.key,
    required this.journalId,
    required this.baseUrl,
    required this.accessToken,
  });
  final int journalId;
  final String baseUrl;
  final String accessToken;

  @override
  State<EcranListeCommande> createState() => EcranListeCommandeState();
}

class EcranListeCommandeState extends State<EcranListeCommande> {
  List<Commande> _commandes = [];
  String? _erreur;
  @override
  void initState() {
    super.initState();
    _chargerCommandes();
  }

  Future<void> _chargerCommandes() async {
    print("JOURNAL ID -> ${widget.journalId}");
    try {
      final uri = Uri.parse('${widget.baseUrl}/commande/${widget.journalId}');
      final response = await http.get(
        uri,
        headers: {
          'accept': "application/json",
          'Authorization': 'Bearer ${widget.accessToken}',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Impossible de charger les commandes (${response.statusCode})',
        );
      }
      final donnees = jsonDecode(utf8.decode(response.bodyBytes));

      if (donnees is! Map<String, dynamic>) {
        throw const FormatException('Réponse inattendue du serveur');
      }

      final listeCommandes = donnees['commandes'];

      if (listeCommandes is! List) {
        throw const FormatException('Liste des commandes absente');
      }

      final commandes = listeCommandes
          .map(
            (commande) => Commande.fromJson(commande as Map<String, dynamic>),
          )
          .toList();

      if (!mounted) return;

      setState(() {
        _commandes = commandes;
      });
    } catch (erreur) {
      if (!mounted) return;
      setState(() {
        _erreur = erreur.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Test")),
      body: Container(
        child: Column(
          children: [
            Container(
              child: Column(
                children: [
                  Row(
                    children: [
                      Text("Liste des commandes"),
                      SizedBox(width: 24),
                      Text(
                        "${_commandes.length} commandes",
                        style: const TextStyle(color: Color((0xFF064B9C))),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      ..._commandes.map((commande) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [Text(commande.nomArticle)],
                              ),
                              Spacer(),
                              ElevatedButton(
                                onPressed: () {
                                  debugPrint("cliqué");
                                },
                                child: const Text("consulter"),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
