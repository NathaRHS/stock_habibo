package com.example.demo.dto;

import java.time.LocalDate;

public record ScanLigneRequest(Long lignePickingId, String codeBarres, Integer quantiteConditionnement, LocalDate dlc,
        LocalDate dlv) {

}
