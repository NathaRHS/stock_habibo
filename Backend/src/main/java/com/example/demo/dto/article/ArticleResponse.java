package com.example.demo.dto.article;

public record ArticleResponse(
        Long id,
        String codeBar,
        String nomArticle,
        Long typeProduitId,
        String typeProduit
) 
{
}
