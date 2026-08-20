package com.example.demo.service;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.ArticleConditionnementResponse;
import com.example.demo.dto.CreateArticleConditionnementRequest;
import com.example.demo.entity.Article;
import com.example.demo.entity.ArticleConditionnement;
import com.example.demo.entity.TypeConditionnement;
import com.example.demo.repository.ArticleConditionnementRepository;
import com.example.demo.repository.ArticleRepository;
import com.example.demo.repository.TypeConditionnementRepository;

@Service
public class ArticleConditionnementService {

    private final ArticleConditionnementRepository articleConditionnementRepository;
    private final ArticleRepository articleRepository;
    private final TypeConditionnementRepository typeConditionnementRepository;

    public ArticleConditionnementService(
            ArticleConditionnementRepository articleConditionnementRepository,
            ArticleRepository articleRepository,
            TypeConditionnementRepository typeConditionnementRepository) {
        this.articleConditionnementRepository = articleConditionnementRepository;
        this.articleRepository = articleRepository;
        this.typeConditionnementRepository = typeConditionnementRepository;
    }

    public ArticleConditionnementResponse creerArticleConditionnement(
            CreateArticleConditionnementRequest request) {
        Article article = trouverArticle(request.articleId());
        TypeConditionnement typeConditionnement = trouverTypeConditionnement(request.typeConditionnementId());
        Integer quantite = validerQuantite(request.quantitePieceStandard());

        ArticleConditionnement articleConditionnement = new ArticleConditionnement(
                article,
                typeConditionnement,
                normaliserCodeBarres(request.codeBarres()),
                quantite);

        return versResponse(articleConditionnementRepository.save(articleConditionnement));
    }

    public List<ArticleConditionnementResponse> getAllArticlesConditionnements() {
        return articleConditionnementRepository.findAll().stream()
                .map(this::versResponse)
                .toList();
    }

    public ArticleConditionnementResponse getArticleConditionnementById(Long id) {
        return versResponse(trouverArticleConditionnement(id));
    }

    public ArticleConditionnementResponse modifierArticleConditionnement(
            Long id, CreateArticleConditionnementRequest request) {
        ArticleConditionnement articleConditionnement = trouverArticleConditionnement(id);

        articleConditionnement.setArticle(trouverArticle(request.articleId()));
        articleConditionnement.setTypeConditionnement(
                trouverTypeConditionnement(request.typeConditionnementId()));
        articleConditionnement.setCodeBarres(normaliserCodeBarres(request.codeBarres()));
        articleConditionnement.setQuantitePieceStandard(
                validerQuantite(request.quantitePieceStandard()));

        return versResponse(articleConditionnementRepository.save(articleConditionnement));
    }

    public void supprimerArticleConditionnement(Long id) {
        articleConditionnementRepository.delete(trouverArticleConditionnement(id));
    }

    private ArticleConditionnement trouverArticleConditionnement(Long id) {
        return articleConditionnementRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Conditionnement d'article introuvable : " + id));
    }

    private Article trouverArticle(Long id) {
        if (id == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "articleId est obligatoire");
        }

        return articleRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Article introuvable : " + id));
    }

    private TypeConditionnement trouverTypeConditionnement(Long id) {
        if (id == null) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "typeConditionnementId est obligatoire");
        }

        return typeConditionnementRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Type de conditionnement introuvable : " + id));
    }

    private Integer validerQuantite(Integer quantite) {
        if (quantite == null || quantite <= 0) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "quantitePieceStandard doit etre strictement positive");
        }
        return quantite;
    }

    private String normaliserCodeBarres(String codeBarres) {
        if (codeBarres == null || codeBarres.isBlank()) {
            return null;
        }
        return codeBarres.trim();
    }

    private ArticleConditionnementResponse versResponse(
            ArticleConditionnement articleConditionnement) {
        return new ArticleConditionnementResponse(
                articleConditionnement.getId(),
                articleConditionnement.getArticle().getId(),
                articleConditionnement.getArticle().getNomArticle(),
                articleConditionnement.getTypeConditionnement().getId(),
                articleConditionnement.getTypeConditionnement().getNomConditionnement(),
                articleConditionnement.getCodeBarres(),
                articleConditionnement.getQuantitePieceStandard());
    }
}
