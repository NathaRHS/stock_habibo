import 'dart:convert';

import 'package:flutter_application/models/ligne_picking.dart';
import 'package:flutter_application/models/scan_ligne_response.dart';
import 'package:http/http.dart' as http;

class PickingService {
  const PickingService({required this.baseUrl, required this.accessToken});

  final String baseUrl;
  final String accessToken;

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $accessToken',
  };

  Future<List<LignePicking>?> chargerParcoursActif({
    required int journalId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/lignes-picking/getLignes/$journalId'),
      headers: _headers,
    );

    // 404 signifie simplement qu'aucun parcours n'a encore été généré.
    if (response.statusCode == 404) return null;

    final donnees = _decoderReponse(response);
    return _convertirLignes(donnees);
  }

  Future<List<LignePicking>> genererMeilleurParcours({
    required int journalId,
    required int userId,
    required int rackDepartId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/lignes-picking/generer-meilleur-parcours'),
      headers: _headers,
      body: jsonEncode({
        'journalId': journalId,
        'userId': userId,
        'rackDepartId': rackDepartId,
      }),
    );

    final donnees = _decoderReponse(response);
    return _convertirLignes(donnees);
  }

  Future<ScanLigneResponse> scannerLigne({
    required int lignePickingId,
    required String codeBarres,
    required int quantiteConditionnement,
    required DateTime dlc,
    required DateTime dlv,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/lignes-picking/scan'),
      headers: _headers,
      body: jsonEncode({
        'lignePickingId': lignePickingId,
        'codeBarres': codeBarres,
        'quantiteConditionnement': quantiteConditionnement,
        'dlc': _dateApi(dlc),
        'dlv': _dateApi(dlv),
      }),
    );

    final donnees = _decoderReponse(response);
    if (donnees is! Map<String, dynamic>) {
      throw const FormatException('Réponse de scan inattendue.');
    }
    return ScanLigneResponse.fromJson(donnees);
  }

  dynamic _decoderReponse(http.Response response) {
    dynamic donnees;
    if (response.bodyBytes.isNotEmpty) {
      try {
        donnees = jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        donnees = null;
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Erreur serveur (${response.statusCode})';
      if (donnees is Map<String, dynamic>) {
        message = (donnees['message'] ?? donnees['error'] ?? message)
            .toString();
      }
      throw Exception(message);
    }
    return donnees;
  }

  List<LignePicking> _convertirLignes(dynamic donnees) {
    if (donnees is! List) {
      throw const FormatException('Liste des étapes de picking absente.');
    }

    final lignes = donnees
        .map((item) => LignePicking.fromJson(item as Map<String, dynamic>))
        .toList();
    lignes.sort((a, b) => a.ordrePassage.compareTo(b.ordrePassage));
    return lignes;
  }

  String _dateApi(DateTime date) {
    final mois = date.month.toString().padLeft(2, '0');
    final jour = date.day.toString().padLeft(2, '0');
    return '${date.year}-$mois-$jour';
  }
}
