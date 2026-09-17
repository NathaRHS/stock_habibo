import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application/models/commande.dart';
import 'package:flutter_application/models/meilleur_emplacement.dart';
import 'package:flutter_application/screens/ecran_insertion_sortie.dart';
import 'package:flutter_application/screens/ecran_parcours_picking_maquette.dart';
import 'package:http/http.dart' as http;

class EcranListeCommande extends StatefulWidget {
  const EcranListeCommande({
    super.key,
    required this.journalId,
    required this.baseUrl,
    required this.accessToken,
    required this.userId,
  });
  final int journalId;
  final String baseUrl;
  final String accessToken;
  final int userId;

  @override
  State<EcranListeCommande> createState() => EcranListeCommandeState();
}

class EcranListeCommandeState extends State<EcranListeCommande> {
  List<Commande> _commandes = [];
  List<MeilleurEmplacement> _meilleurEmplacements = [];
  String? _erreur;
  @override
  void initState() {
    super.initState();
    _chargerCommandes();
  }

  Future<void> _chargerCommandes() async {
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

  Future<void> _chargerMeilleurEmplacement(int commandeId) async {
    try {
      final uri = Uri.parse(
        '${widget.baseUrl}/commande/proposerEmplacement/$commandeId',
      );

      final response = await http.get(
        uri,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer ${widget.accessToken}',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Impossible de charger les emplacements (${response.statusCode})',
        );
      }

      final donnees = jsonDecode(utf8.decode(response.bodyBytes));

      if (donnees is! List) {
        throw const FormatException('Liste des emplacements attendue');
      }

      final emplacements = donnees
          .map(
            (element) =>
                MeilleurEmplacement.fromJson(element as Map<String, dynamic>),
          )
          .toList();

      if (!mounted) return;

      setState(() {
        _meilleurEmplacements = emplacements;
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
      body: _erreur != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_erreur!, textAlign: TextAlign.center),
              ),
            )
          : Container(
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
                              style: const TextStyle(
                                color: Color((0xFF064B9C)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => EcranParcoursPickingMaquette(
                                  baseUrl: widget.baseUrl,
                                  accessToken: widget.accessToken,
                                  journalId: widget.journalId,
                                  userId: widget.userId,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.route_outlined),
                          label: const Text('Générer le meilleur parcours'),
                        ),
                        Column(
                          children: [
                            ..._commandes.map((commande) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(commande.nomArticle),
                                        Text("${commande.quantiteDemande}"),
                                      ],
                                    ),
                                    Spacer(),
                                    ElevatedButton(
                                      onPressed: () async {
                                        await _chargerMeilleurEmplacement(
                                          commande.idCommande,
                                        );
                                        if (!context.mounted) return;
                                        showModalBottomSheet(
                                          context: context,
                                          builder: (context) {
                                            return SizedBox(
                                              height:
                                                  MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.5,
                                              child: Center(
                                                child: Column(
                                                  children: [
                                                    Text(
                                                      "Meilleurs emplacements",
                                                    ),
                                                    Text(
                                                      "Quantité totale à prelever :${commande.quantiteDemande}",
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                      ),
                                                    ),

                                                    ..._meilleurEmplacements.map((
                                                      emplacement,
                                                    ) {
                                                      return InkWell(
                                                        onTap: () async {
                                                          await Navigator.of(
                                                            context,
                                                          ).push(
                                                            MaterialPageRoute(
                                                              builder: (_) => EcranInsertionSortie(
                                                                baseUrl: widget
                                                                    .baseUrl,
                                                                idEmplacement:
                                                                    emplacement
                                                                        .emplacementId,
                                                                idCommande: commande
                                                                    .idCommande,
                                                                journalId: widget
                                                                    .journalId,
                                                                articleId: commande
                                                                    .idArticle,
                                                                nomArticle: commande
                                                                    .nomArticle,
                                                                nomRack:
                                                                    emplacement
                                                                        .nomRack,
                                                                nomEmplacement:
                                                                    emplacement
                                                                        .nomEmplacement,
                                                                quantiteMaximale:
                                                                    emplacement
                                                                        .quantiteAPrelever,
                                                                dlc: emplacement
                                                                    .dlc,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        child: Container(
                                                          margin:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 16,
                                                                vertical: 6,
                                                              ),
                                                          padding:
                                                              const EdgeInsets.all(
                                                                14,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: Colors.white,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  10,
                                                                ),
                                                            border: Border.all(
                                                              color:
                                                                  const Color(
                                                                    0xFFD7E2EE,
                                                                  ),
                                                            ),
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              Expanded(
                                                                child: Text(
                                                                  emplacement
                                                                      .nomRack,
                                                                  style: const TextStyle(
                                                                    color: Color(
                                                                      0xFF064B9C,
                                                                    ),
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                              ),

                                                              Expanded(
                                                                flex: 2,
                                                                child: Text(
                                                                  emplacement
                                                                      .nomEmplacement,
                                                                  style: const TextStyle(
                                                                    color: Color(
                                                                      0xFF1E293B,
                                                                    ),
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                  ),
                                                                ),
                                                              ),

                                                              Container(
                                                                padding:
                                                                    const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          10,
                                                                      vertical:
                                                                          6,
                                                                    ),
                                                                decoration: BoxDecoration(
                                                                  color: const Color(
                                                                    0xFFE8F7F1,
                                                                  ),
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        6,
                                                                      ),
                                                                ),
                                                                child: Text(
                                                                  '${emplacement.quantiteAPrelever} packs',
                                                                  style: const TextStyle(
                                                                    color: Color(
                                                                      0xFF087E5B,
                                                                    ),
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    }),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
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
