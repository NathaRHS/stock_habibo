/// Qui est connecté sur le téléphone. Renseignée à la connexion, vidée à la
/// déconnexion : le bouton de profil s'en sert pour s'ouvrir depuis n'importe
/// quel écran, sans qu'on ait à lui passer l'utilisateur à chaque fois.
class SessionUtilisateur {
  const SessionUtilisateur._();

  static String? baseUrl;
  static String? accessToken;
  static int? userId;
  static String? nom;

  static bool get connecte =>
      baseUrl != null && accessToken != null && userId != null;

  static void ouvrir({
    required String baseUrl,
    required String accessToken,
    required int userId,
    String? nom,
  }) {
    SessionUtilisateur.baseUrl = baseUrl;
    SessionUtilisateur.accessToken = accessToken;
    SessionUtilisateur.userId = userId;
    SessionUtilisateur.nom = nom;
  }

  static void fermer() {
    baseUrl = null;
    accessToken = null;
    userId = null;
    nom = null;
  }

  /// "Jean Martin" donne "JM", "Jean" donne "JE" ; null si on ne connaît pas le nom.
  static String? get initiales {
    final mots = (nom ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((mot) => mot.isNotEmpty)
        .toList();
    if (mots.isEmpty) return null;
    if (mots.length == 1) {
      final mot = mots.first;
      return mot.substring(0, mot.length < 2 ? 1 : 2).toUpperCase();
    }
    return '${mots.first[0]}${mots.last[0]}'.toUpperCase();
  }
}
