package com.example.demo.dto.importation;

import java.util.List;

/**
 * Resultat d'un import CSV : soit des elements crees, soit des erreurs par
 * ligne (dans ce cas rien n'est enregistre).
 */
public record ImportResponse(
        int nombreCrees,
        List<LigneErreur> erreurs
) {
}
