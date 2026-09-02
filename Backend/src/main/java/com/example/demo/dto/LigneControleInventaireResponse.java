package com.example.demo.dto;

public record LigneControleInventaireResponse(Long EmplacementId, String nomEmplacement, String nomRack,
        Integer numeroEtage, Long ArticleId, String nomArticle, Integer quantiteTheorique, Integer quanantiteComptee,
        Long ecart) {

}
