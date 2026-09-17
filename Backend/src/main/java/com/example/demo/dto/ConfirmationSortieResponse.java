package com.example.demo.dto;

import java.util.List;

public record ConfirmationSortieResponse(
    JournalSortieResponse journal,
    OperateurSortieResponse operateur,
    List<LigneConfirmationResponse> lignes
) {}