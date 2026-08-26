package com.example.demo.service;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.StockParEmplacementResponse;
import com.example.demo.projection.StockParEmplacementProjection;
import com.example.demo.repository.ArticleRepository;
import com.example.demo.repository.StockRepository;

@Service
public class StockService {
    private final StockRepository stockRepository;
    private final ArticleRepository articleRepository;

    public StockService(StockRepository stockRepository, ArticleRepository articleRepository) {
        this.stockRepository = stockRepository;
        this.articleRepository = articleRepository;
    }

    public List<StockParEmplacementResponse> getAllStocksParEmplacement() {
        return stockRepository.findAllStocksParEmplacement().stream()
                .map(this::versResponse)
                .toList();
    }

    public List<StockParEmplacementResponse> getStocksParEmplacementByArticleId(Long articleId) {
        if (!articleRepository.existsById(articleId)) {
            throw new ResponseStatusException(
                    HttpStatus.NOT_FOUND, "Article introuvable : " + articleId);
        }

        return stockRepository.findStocksParEmplacementByArticleId(articleId).stream()
                .map(this::versResponse)
                .toList();
    }

    private StockParEmplacementResponse versResponse(StockParEmplacementProjection stock) {
        return new StockParEmplacementResponse(
                stock.getArticleId(), stock.getEmplacementId(), stock.getQuantiteStock());
    }
}
