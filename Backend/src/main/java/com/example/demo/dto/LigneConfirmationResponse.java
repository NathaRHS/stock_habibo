package com.example.demo.dto;

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