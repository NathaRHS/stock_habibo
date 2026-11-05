package com.example.demo.projection;

// Totaux des mouvements d'une periode : un seul enregistrement, meme sans mouvement.
public interface SynthesePeriodeProjection {
    Long getEntrees();

    Long getSorties();

    Long getNombreMouvements();
}
