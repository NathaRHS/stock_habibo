import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application/screens/ecran_liste_journaux.dart';
import 'package:http/http.dart' as http;

class EcranLogin extends StatefulWidget {
  const EcranLogin({super.key, required this.baseUrl});

  final String baseUrl;

  @override
  State<EcranLogin> createState() => _EcranLoginState();
}

class _EcranLoginState extends State<EcranLogin> {
  final _formKey = GlobalKey<FormState>();
  final _matriculeController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _erreur;
  bool _connexionEnCours = false;
  bool _masquerMotDePasse = true;

  @override
  void dispose() {
    _matriculeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _seConnecter() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _connexionEnCours = true;
      _erreur = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/user/login'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'matricule': _matriculeController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Matricule ou mot de passe incorrect.');
      }

      final donnees = jsonDecode(utf8.decode(response.bodyBytes));

      if (donnees is! Map<String, dynamic>) {
        throw const FormatException('Réponse inattendue du serveur.');
      }

      final token = donnees['token'] as String?;
      final utilisateur = donnees['user'] as Map<String, dynamic>?;
      final role = utilisateur?['role'] as String;
      if (token == null || token.isEmpty) {
        throw const FormatException("Le serveur n'a pas renvoyé de token.");
      }

      if (!mounted) return;

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => EcranListeJournaux(
            baseUrl: widget.baseUrl,
            accessToken: token,
            role: role,
          ),
        ),
      );
    } catch (erreur) {
      if (!mounted) return;

      setState(() {
        _erreur = erreur.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _connexionEnCours = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001A38),
      appBar: AppBar(
        title: const Text('Connexion'),
        backgroundColor: const Color(0xFF064B9C),
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0752A7), Color(0xFF001A38)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(
                            Icons.lock_person_outlined,
                            size: 58,
                            color: Color(0xFF064B9C),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Connexion utilisateur',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _matriculeController,
                            enabled: !_connexionEnCours,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Matricule',
                              prefixIcon: Icon(Icons.badge_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: (valeur) {
                              if (valeur == null || valeur.trim().isEmpty) {
                                return 'Le matricule est obligatoire.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _passwordController,
                            enabled: !_connexionEnCours,
                            obscureText: _masquerMotDePasse,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _seConnecter(),
                            decoration: InputDecoration(
                              labelText: 'Mot de passe',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _masquerMotDePasse = !_masquerMotDePasse;
                                  });
                                },
                                icon: Icon(
                                  _masquerMotDePasse
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            validator: (valeur) {
                              if (valeur == null || valeur.isEmpty) {
                                return 'Le mot de passe est obligatoire.';
                              }
                              return null;
                            },
                          ),
                          if (_erreur != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _erreur!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _connexionEnCours
                                  ? null
                                  : _seConnecter,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF064B9C),
                                foregroundColor: Colors.white,
                              ),
                              child: _connexionEnCours
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Se connecter'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
