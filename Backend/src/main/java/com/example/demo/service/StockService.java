package com.example.demo.service;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.article.ArticleResponse;
import com.example.demo.dto.article.FicheProduitResponseDto;
import com.example.demo.dto.stock.StockParEmplacementResponse;
import com.example.demo.dto.stock.TotalMouvementResponse;
import com.example.demo.entity.Article;
import com.example.demo.projection.StockParEmplacementProjection;
import com.example.demo.projection.TotalMouvementProjection;
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

    public TotalMouvementResponse getTotalMouvement(Long articleId) {
        TotalMouvementProjection totalMouvementProjection = stockRepository.findTotalEntreeEtSortie(articleId);
        return new TotalMouvementResponse(totalMouvementProjection.getTotalEntrees(),
                totalMouvementProjection.getTotalSorties());
    }

    private StockParEmplacementResponse versResponse(StockParEmplacementProjection stock) {
        return new StockParEmplacementResponse(
                stock.getArticleId(), stock.getEmplacementId(), stock.getQuantiteStock());
    }

    public FicheProduitResponseDto getFicheProduit(Long id) {
        TotalMouvementResponse totalMouvementProjection = getTotalMouvement(id);
        Article article = articleRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
                System.out.println("tato");
        Long idFamille = Long.valueOf(0);
        String nomFamille = "";

        if (article.getFamille() == null) {
            idFamille = Long.valueOf(0);

        } else {
            idFamille = article.getFamille().getId();
            nomFamille = article.getFamille().getNom();
        }
        ArticleResponse articleResponse = new ArticleResponse(article.getId(), article.getCodeBar(),
                article.getNomArticle(), article.getTypeProduit().getId(), article.getTypeProduit().getNomType(),
                article.getPhotoUrl(), idFamille, nomFamille,
                article.getContenanceValeur(), article.getUnite().getId(), article.getUnite().getNomUnite());
        List<StockParEmplacementResponse> stockParEmplacementResponse = getStocksParEmplacementByArticleId(id);

        return new FicheProduitResponseDto(articleResponse, stockParEmplacementResponse, totalMouvementProjection);
    }
}
