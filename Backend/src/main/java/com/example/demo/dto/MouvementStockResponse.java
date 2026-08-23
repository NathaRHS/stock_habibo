package com.example.demo.dto;

import java.time.LocalDateTime;
import java.util.Date;

import com.example.demo.entity.TypeMouvementStock;

public record MouvementStockResponse(
        Long id_type_mouvement,
        String nom_type_mouvement,
        Short sens,
        Integer quantite_piece_reelle,
        LocalDateTime date_mouvement
    ) { 
}
