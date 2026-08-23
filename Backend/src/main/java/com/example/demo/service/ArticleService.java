package com.example.demo.service;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.ArticleResponse;
import com.example.demo.dto.CreateArticleRequest;
import com.example.demo.repository.TypeProduitRepository;
import com.example.demo.entity.Article;
import com.example.demo.entity.TypeConditionnement;
import com.example.demo.entity.TypeProduit;
import com.example.demo.repository.ArticleRepository;
import com.example.demo.repository.TypeConditionnementRepository;

@Service
public class ArticleService {
    private final ArticleRepository articleRepository;
    private final TypeProduitRepository typeProduitRepository;
    private final TypeConditionnementRepository typeConditionnementRepository;

    //Injection de dépendances
    public ArticleService(ArticleRepository articleRepository, TypeProduitRepository typeProduitRepository,
            TypeConditionnementRepository typeConditionnementRepository) {
        this.articleRepository = articleRepository;
        this.typeProduitRepository = typeProduitRepository;
        this.typeConditionnementRepository = typeConditionnementRepository;
    }

    public ArticleResponse creerArticle(CreateArticleRequest request) {
        TypeProduit typeProduit = trouverTypeProduit(request.typeProduitId());
        TypeConditionnement typeConditionnement = trouverTypeConditionnement(request.typeConditionnementId());
        Article article = new Article(typeProduit, request.codeBar(), request.nomArticle(), typeConditionnement);
        return versResponse(articleRepository.save(article));
    }

    // Lister les articles
    public List<ArticleResponse> getAllArticles() {
        return articleRepository.findAll().stream().map(this::versResponse).toList();
    }

    // Récupérer un article par son ID
    public ArticleResponse getArticleById(Long id) {
        return versResponse(trouverArticle(id));
    }

    // Modifier un article existant
    public ArticleResponse modifierArticle(Long id, CreateArticleRequest request) {
        Article article = trouverArticle(id);
        article.setNomArticle(request.nomArticle());
        article.setCodeBar(request.codeBar());
        article.setTypeProduit(trouverTypeProduit(request.typeProduitId()));
        article.setTypeConditionnement(trouverTypeConditionnement(request.typeConditionnementId()));
        return versResponse(articleRepository.save(article));
    }

    // Supprimer un article
    public void supprimerArticle(Long id) {
        articleRepository.delete(trouverArticle(id));
    }

    // HTTPStatus not found -> 400
    private Article trouverArticle(Long id) {
        return articleRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Article introuvable : " + id));
    }

    private TypeProduit trouverTypeProduit(Long id) {
        if (id == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "typeProduitId est obligatoire");
        }
        return typeProduitRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Type de produit introuvable : " + id));
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

    private ArticleResponse versResponse(Article article) {
        return new ArticleResponse(
                article.getId(),
                article.getCodeBar(),
                article.getNomArticle(),
                article.getTypeProduit().getId(),
                article.getTypeProduit().getNomType());
    }

}
