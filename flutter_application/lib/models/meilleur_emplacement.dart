class MeilleurEmplacement {
  const MeilleurEmplacement({
    required this.emplacementId,
    required this.nomEmplacement,
    required this.rackId,
    required this.nomRack,
    required this.numeroEtage,
    required this.commandeId,
    required this.quantiteDisponible,
    required this.quantiteAPrelever,
    required this.dlc,
  });

  final int emplacementId;
  final String nomEmplacement;
  final int rackId;
  final String nomRack;
  final int numeroEtage;
  final int commandeId;
  final int quantiteDisponible;
  final int quantiteAPrelever;
  final DateTime dlc;

  factory MeilleurEmplacement.fromJson(Map<String, dynamic> json) {
    return MeilleurEmplacement(
      emplacementId: (json['emplacementId'] as num).toInt(),
      nomEmplacement: (json['nomEmplacement'] as String),
      rackId: (json['rackId'] as num).toInt(),
      nomRack: (json['nomRack'] as String),
      numeroEtage: (json['numeroEtage'] as num).toInt(),
      commandeId: (json['commandeId'] as num).toInt(),
      quantiteDisponible: (json['quantiteDisponible'] as num).toInt(),
      quantiteAPrelever: (json['quantiteAPrelever'] as num).toInt(),
      dlc: DateTime.parse(json['dlc'] as String),
    );
  }
}
