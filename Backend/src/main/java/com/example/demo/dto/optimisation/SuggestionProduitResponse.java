package com.example.demo.dto.optimisation;

import java.util.List;

public record SuggestionProduitResponse(
        Long detailJournalId,
        Long articleId,
        String nomArticle,
        Long articleConditionnementId,
        Integer quantiteConditionnementsAAffecter,
        Long quantiteConditionnementsProposee,
        Long quantiteConditionnementsNonAffectee,
        List<SuggestionEmplacementResponse> suggestions) {
}
