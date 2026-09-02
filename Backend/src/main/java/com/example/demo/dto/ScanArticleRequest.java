package com.example.demo.dto;

import java.time.LocalDate;

public record ScanArticleRequest(
        String codeBarres,
        Integer quantite,
        Integer quantiteConditionnement,
        LocalDate dlc,
        LocalDate dlv) {
    
}
