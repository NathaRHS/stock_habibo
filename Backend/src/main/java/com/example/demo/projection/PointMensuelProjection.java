package com.example.demo.projection;

// Pieces entrees et sorties d'un mois (1 = janvier ... 12 = decembre).
public interface PointMensuelProjection {
    Integer getMois();

    Long getEntrees();

    Long getSorties();
}
