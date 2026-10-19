package com.example.demo.dto.article;

import java.util.List;

import com.example.demo.dto.stock.StockParEmplacementResponse;
import com.example.demo.dto.stock.TotalMouvementResponse;

public record FicheProduitResponseDto(ArticleResponse articleResponse,List<StockParEmplacementResponse> stockArticleParEmplacement,TotalMouvementResponse nombreMouvement) {
 

}
