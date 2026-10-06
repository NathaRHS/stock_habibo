import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application/screens/ecran_liste_journaux.dart';
import 'package:flutter_application/theme/habibo.dart';
import 'package:http/http.dart' as http;

class EcranLogin extends StatefulWidget {
  const EcranLogin({super.key, required this.baseUrl});

  final String baseUrl;

  @override
  State<EcranLogin> createState() => _EcranLoginState();
}

class _EcranLoginState extends State<EcranLogin> {
  static const _bleu = Habibo.bleu;
  static const _fond = Habibo.fond;
  static const _texte = Habibo.texte;
  static const _texteSecondaire = Habibo.texteSecondaire;
  static const _bordure = Habibo.bordure;
  static const _rouge = Habibo.rouge;

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
      final userId = (utilisateur?['id'] as num?)?.toInt();
      if (token == null || token.isEmpty) {
        throw const FormatException("Le serveur n'a pas renvoyé de token.");
      }
      if (userId == null) {
        throw const FormatException(
          "Le serveur n'a pas renvoyé l'utilisateur.",
        );
      }

      if (!mounted) return;

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => EcranListeJournaux(
            baseUrl: widget.baseUrl,
            accessToken: token,
            role: role,
            userId: userId,
            nomUtilisateur: utilisateur?['username'] as String?,
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Fond clair : icônes de la barre d'état en sombre.
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _fond,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, contraintes) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: contraintes.maxHeight,
                    maxWidth: 430,
                  ),
                  child: IntrinsicHeight(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 24),
                          _entete(),
                          const Spacer(flex: 3),
                          const SizedBox(height: 32),
                          const Text(
                            'Bonjour.',
                            style: TextStyle(
                              color: _texte,
                              fontSize: 44,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1.5,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Connectez-vous avec votre matricule pour '
                            'accéder à l’entrepôt.',
                            style: TextStyle(
                              color: _texteSecondaire,
                              fontSize: 16,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 32),
                          _libelle('Matricule'),
                          TextFormField(
                            controller: _matriculeController,
                            enabled: !_connexionEnCours,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.username],
                            style: const TextStyle(fontSize: 16, color: _texte),
                            decoration: _decorationChamp(hint: 'Ex. 10482'),
                            validator: (valeur) {
                              if (valeur == null || valeur.trim().isEmpty) {
                                return 'Saisissez votre matricule.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _libelle('Mot de passe'),
                          TextFormField(
                            controller: _passwordController,
                            enabled: !_connexionEnCours,
                            obscureText: _masquerMotDePasse,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => _seConnecter(),
                            style: const TextStyle(fontSize: 16, color: _texte),
                            decoration: _decorationChamp(
                              hint: '••••••••',
                              suffixIcon: IconButton(
                                tooltip: _masquerMotDePasse
                                    ? 'Afficher le mot de passe'
                                    : 'Masquer le mot de passe',
                                onPressed: () {
                                  setState(() {
                                    _masquerMotDePasse = !_masquerMotDePasse;
                                  });
                                },
                                icon: Icon(
                                  _masquerMotDePasse
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: _texteSecondaire,
                                ),
                              ),
                            ),
                            validator: (valeur) {
                              if (valeur == null || valeur.isEmpty) {
                                return 'Saisissez votre mot de passe.';
                              }
                              return null;
                            },
                          ),
                          if (_erreur != null) ...[
                            const SizedBox(height: 16),
                            _messageErreur(_erreur!),
                          ],
                          const SizedBox(height: 28),
                          SizedBox(
                            height: 54,
                            child: FilledButton(
                              onPressed: _connexionEnCours
                                  ? null
                                  : _seConnecter,
                              style: FilledButton.styleFrom(
                                backgroundColor: _bleu,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: _bleu.withValues(
                                  alpha: 0.6,
                                ),
                                disabledForegroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _connexionEnCours
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  // Style sur le texte : il garde la police du thème.
                                  : const Text(
                                      'Se connecter',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          const Spacer(flex: 2),
                          const SizedBox(height: 24),
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

  Widget _entete() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _bleu,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'H',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 14),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Habibo',
              style: TextStyle(
                color: _texte,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Gestion d’entrepôt',
              style: TextStyle(color: _texteSecondaire, fontSize: 15),
            ),
          ],
        ),
      ],
    );
  }

  Widget _libelle(String texte) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        texte,
        style: const TextStyle(
          color: _texte,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  InputDecoration _decorationChamp({required String hint, Widget? suffixIcon}) {
    OutlineInputBorder bordure(Color couleur, {double epaisseur = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: couleur, width: epaisseur),
      );
    }

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF98A2AB)),
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: bordure(_bordure),
      disabledBorder: bordure(_bordure),
      focusedBorder: bordure(_bleu, epaisseur: 1.5),
      errorBorder: bordure(_rouge),
      focusedErrorBorder: bordure(_rouge, epaisseur: 1.5),
      errorStyle: const TextStyle(color: _rouge, fontSize: 13),
    );
  }

  Widget _messageErreur(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBECEC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: _rouge, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: _rouge, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
