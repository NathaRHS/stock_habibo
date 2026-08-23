package com.example.demo.dto;

public record ArticleResponse(
        Long id,
        String codeBar,
        String nomArticle,
        Long typeProduitId,
        String typeProduit
) 
{
}
