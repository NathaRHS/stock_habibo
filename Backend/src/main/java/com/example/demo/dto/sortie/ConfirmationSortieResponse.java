package com.example.demo.dto.sortie;

import java.util.List;

public record ConfirmationSortieResponse(
    JournalSortieResponse journal,
    OperateurSortieResponse operateur,
    List<LigneConfirmationResponse> lignes
) {}
