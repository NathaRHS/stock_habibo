package com.example.demo.dto.automatisation;

import com.example.demo.dto.article.ArticleCompletResponse;
import com.example.demo.dto.article.ArticleResponse;

public record EmplacementDeplace(Long emplacementSourceId, Long emplacementDestinationId, ArticleResponse article,
        Long quantite, String raison) {

}
