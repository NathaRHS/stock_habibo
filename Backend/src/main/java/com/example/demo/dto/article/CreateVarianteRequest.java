package com.example.demo.dto.article;

/**
 * Creation d'une variante d'un article existant. La famille est creee a la
 * premiere variante : nomFamille est facultatif (par defaut, le nom de
 * l'article de depart) et ignore si l'article a deja une famille.
 */
public record CreateVarianteRequest(
        String nomFamille,
        CreateArticleCompletRequest.ArticleInfo article,
        CreateArticleCompletRequest.ConditionnementInfo conditionnement,
        CreateArticleCompletRequest.PaletteInfo palette) {
}
