import 'dart:convert';

import 'package:flutter_application/models/detail_journal.dart';
import 'package:http/http.dart' as http;

class ScanService {
  const ScanService({required this.baseUrl, required this.accessToken});

  final String baseUrl;
  final String accessToken;

  Future<void> soumettreSession({required int journalId}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/journaux-mouvements/$journalId/soumettre'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ScanException(
        _messageErreur(response.statusCode, response.bodyBytes),
        response.statusCode,
      );
    }
  }

  Future<DetailJournal> enregistrerScan({
    required int journalId,

    required String codeBarres,
    required int quantite,
  }) async {
    //appel api de scan
    final response = await http.post(
      Uri.parse('$baseUrl/journaux-mouvements/$journalId/scans'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({'codeBarres': codeBarres, 'quantite': quantite}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ScanException(
        _messageErreur(response.statusCode, response.bodyBytes),
        response.statusCode,
      );
    }

    final donnees = jsonDecode(utf8.decode(response.bodyBytes));
    if (donnees is! Map<String, dynamic>) {
      throw const ScanException('Réponse inattendue du serveur.', 500);
    }
    return DetailJournal.fromJson(donnees);
  }

  String _messageErreur(int statut, List<int> contenu) {
    String? messageServeur;
    try {
      final donnees = jsonDecode(utf8.decode(contenu));
      if (donnees is Map<String, dynamic>) {
        messageServeur =
            donnees['detail'] as String? ??
            donnees['message'] as String? ??
            donnees['error'] as String?;
      }
    } catch (_) {
      // Le message adapté au statut HTTP sera utilisé.
    }

    if (messageServeur != null && messageServeur.isNotEmpty) {
      return messageServeur;
    }
    return switch (statut) {
      400 => 'Le code-barres ou la quantité est invalide.',
      401 => 'Votre session a expiré. Reconnectez-vous.',
      403 => "Vous n'avez pas le droit d'enregistrer un scan.",
      404 => 'Journal ou code-barres introuvable.',
      409 => "Cette session n'accepte plus de scans.",
      _ => 'Impossible d’enregistrer le produit ($statut).',
    };
  }
}

class ScanException implements Exception {
  const ScanException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}
