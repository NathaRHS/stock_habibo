package com.example.demo.dto.optimisation;

import java.util.List;

public record SuggestionEmplacementResponse(
        Long emplacementId,
        String nomEmplacement,
        Long rackId,
        String nomRack,
        Integer ordreRack,
        Integer numeroEtage,
        Integer ordreDansEtage,
        Long capaciteLibre,
        Long quantiteConditionnementsProposee,
        double scoreProximite,
        double scoreCapacite,
        double scoreFiabilite,
        double scoreRegroupement,
        double scoreFinal,
        List<String> raisons) {
}
