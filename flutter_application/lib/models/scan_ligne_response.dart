class ScanLigneResponse {
  const ScanLigneResponse({
    required this.prelevementId,
    required this.lignePickingId,
    required this.quantiteScannee,
    required this.quantitePreleveeAuTotal,
    required this.quantiteRestante,
    required this.ligneTerminee,
  });

  final int prelevementId;
  final int lignePickingId;
  final int quantiteScannee;
  final int quantitePreleveeAuTotal;
  final int quantiteRestante;
  final bool ligneTerminee;

  factory ScanLigneResponse.fromJson(Map<String, dynamic> json) {
    return ScanLigneResponse(
      prelevementId: (json['prelevementId'] as num).toInt(),
      lignePickingId: (json['lignePickingId'] as num).toInt(),
      quantiteScannee: (json['quantiteScannee'] as num).toInt(),
      quantitePreleveeAuTotal: (json['quantitePreleveeAuTotal'] as num).toInt(),
      quantiteRestante: (json['quantiteRestante'] as num).toInt(),
      ligneTerminee: json['ligneTerminee'] as bool,
    );
  }
}
