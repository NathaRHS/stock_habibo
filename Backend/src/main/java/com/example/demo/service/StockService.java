package com.example.demo.service;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.StockParEtageResponse;
import com.example.demo.projection.StockParEtageProjection;
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

    public List<StockParEtageResponse> getAllStocksParEtage() {
        return stockRepository.findAllStocksParEtage().stream()
                .map(this::versResponse)
                .toList();
    }

    public List<StockParEtageResponse> getStocksParEtageByArticleId(Long articleId) {
        if (!articleRepository.existsById(articleId)) {
            throw new ResponseStatusException(
                    HttpStatus.NOT_FOUND, "Article introuvable : " + articleId);
        }

        return stockRepository.findStocksParEtageByArticleId(articleId).stream()
                .map(this::versResponse)
                .toList();
    }

    private StockParEtageResponse versResponse(StockParEtageProjection stock) {
        return new StockParEtageResponse(
                stock.getArticleId(), stock.getEtageId(), stock.getQuantiteStock());
    }
}
