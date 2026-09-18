package com.example.demo.dto.sortie;

import java.util.List;

public record LigneConfirmationResponse(
    Long commandeId,
    String nomArticle,
    Integer quantiteDemandee,
    Integer quantitePrelevee,
    Integer ecart,
    String statut,
    List<DetailPrelevementResponse> details
) {}
