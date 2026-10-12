import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/magasin.dart';
import '../data/modeles.dart';
import '../theme/habibo.dart';
import '../widgets/commun.dart';
import 'coquille.dart';

class EcranLogin extends StatefulWidget {
  const EcranLogin({super.key});

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

  void _remplir(String matricule) {
    retourLeger();
    setState(() {
      _matriculeController.text = matricule;
      _passwordController.text = 'habibo2026';
      _erreur = null;
    });
  }

  Future<void> _seConnecter() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _connexionEnCours = true;
      _erreur = null;
    });

    // Simule l'appel au serveur.
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    final matricule = _matriculeController.text.trim();
    if (matricule != '10482' && matricule != '10517') {
      retourErreur();
      setState(() {
        _connexionEnCours = false;
        _erreur = 'Matricule ou mot de passe incorrect.';
      });
      return;
    }

    magasin.connecter(
      matricule == '10517' ? Role.inventoriste : Role.operateur,
    );
    retourSucces();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, _, _) => const Coquille(),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Habibo.fond,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, contraintes) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: contraintes.maxHeight),
              child: IntrinsicHeight(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Image.asset(
                          'assets/images/logo_habibo.png',
                          width: 104,
                        ),
                      ),
                      const Spacer(flex: 3),
                      const SizedBox(height: 28),
                      const Text(
                        'Bonjour.',
                        style: TextStyle(
                          color: Habibo.texte,
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
                          color: Habibo.texteSecondaire,
                          fontSize: 16,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _libelle('Matricule'),
                      TextFormField(
                        controller: _matriculeController,
                        enabled: !_connexionEnCours,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Habibo.texte,
                        ),
                        decoration: _decorationChamp(hint: 'Ex. 10482'),
                        validator: (valeur) =>
                            valeur == null || valeur.trim().isEmpty
                            ? 'Saisissez votre matricule.'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      _libelle('Mot de passe'),
                      TextFormField(
                        controller: _passwordController,
                        enabled: !_connexionEnCours,
                        obscureText: _masquerMotDePasse,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _seConnecter(),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Habibo.texte,
                        ),
                        decoration: _decorationChamp(
                          hint: '••••••••',
                          suffixIcon: IconButton(
                            tooltip: _masquerMotDePasse
                                ? 'Afficher le mot de passe'
                                : 'Masquer le mot de passe',
                            onPressed: () => setState(
                              () => _masquerMotDePasse = !_masquerMotDePasse,
                            ),
                            icon: Icon(
                              _masquerMotDePasse
                                  ? LucideIcons.eye
                                  : LucideIcons.eyeOff,
                              size: 20,
                              color: Habibo.texteSecondaire,
                            ),
                          ),
                        ),
                        validator: (valeur) => valeur == null || valeur.isEmpty
                            ? 'Saisissez votre mot de passe.'
                            : null,
                      ),
                      if (_erreur != null) ...[
                        const SizedBox(height: 16),
                        _messageErreur(_erreur!),
                      ],
                      const SizedBox(height: 28),
                      BoutonPrincipal(
                        libelle: 'Se connecter',
                        chargement: _connexionEnCours,
                        onPressed: _seConnecter,
                      ),
                      const SizedBox(height: 24),
                      _comptesDemo(),
                      const Spacer(flex: 2),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _comptesDemo() {
    Widget compte(String libelle, String matricule, IconData icone) {
      return Expanded(
        child: Material(
          color: Habibo.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Habibo.bordure),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _connexionEnCours ? null : () => _remplir(matricule),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Icon(icone, size: 18, color: Habibo.bleu),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          libelle,
                          style: const TextStyle(
                            color: Habibo.texte,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          matricule,
                          style: const TextStyle(
                            color: Habibo.texteDiscret,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comptes de démonstration',
          style: TextStyle(color: Habibo.texteDiscret, fontSize: 13),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            compte('Opérateur', '10482', LucideIcons.scanLine),
            const SizedBox(width: 10),
            compte('Inventoriste', '10517', LucideIcons.clipboardList),
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
          color: Habibo.texte,
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
      hintStyle: const TextStyle(color: Habibo.texteDiscret),
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: bordure(Habibo.bordure),
      disabledBorder: bordure(Habibo.bordure),
      focusedBorder: bordure(Habibo.bleu, epaisseur: 1.5),
      errorBorder: bordure(Habibo.rouge),
      focusedErrorBorder: bordure(Habibo.rouge, epaisseur: 1.5),
      errorStyle: const TextStyle(color: Habibo.rouge, fontSize: 13),
    );
  }

  Widget _messageErreur(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Habibo.rougeDoux,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.circleAlert, color: Habibo.rouge, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Habibo.rouge, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
