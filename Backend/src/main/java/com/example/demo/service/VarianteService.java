package com.example.demo.service;

import java.math.BigDecimal;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.article.ArticleCompletResponse;
import com.example.demo.dto.article.ArticleResponse;
import com.example.demo.dto.article.CreateArticleCompletRequest;
import com.example.demo.dto.article.CreateVarianteRequest;
import com.example.demo.entity.Article;
import com.example.demo.entity.Famille;
import com.example.demo.repository.ArticleRepository;
import com.example.demo.repository.FamilleRepository;

/**
 * Ajoute une variante a un article. La famille est creee a la premiere variante
 * et l'article de depart y est rattache. Tout se fait dans une seule transaction.
 */
@Service
public class VarianteService {

    private final ArticleRepository articleRepository;
    private final FamilleRepository familleRepository;
    private final ArticleService articleService;
    private final ArticleCompletService articleCompletService;

    public VarianteService(
            ArticleRepository articleRepository,
            FamilleRepository familleRepository,
            ArticleService articleService,
            ArticleCompletService articleCompletService) {
        this.articleRepository = articleRepository;
        this.familleRepository = familleRepository;
        this.articleService = articleService;
        this.articleCompletService = articleCompletService;
    }

    @Transactional
    public ArticleCompletResponse creerVariante(Long articleBaseId, CreateVarianteRequest request) {
        if (request == null || request.article() == null
                || request.conditionnement() == null || request.palette() == null) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Les sections article, conditionnement et palette sont obligatoires");
        }

        Article base = articleRepository.findById(articleBaseId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Article introuvable : " + articleBaseId));

        CreateArticleCompletRequest.ArticleInfo info = request.article();

        // Meme type de produit que l'article de depart : repris s'il n'est pas donne.
        Long typeProduitId = info.typeProduitId() != null ? info.typeProduitId() : base.getTypeProduit().getId();
        if (!typeProduitId.equals(base.getTypeProduit().getId())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Les articles d'une meme famille doivent avoir le meme type de produit");
        }
        Long typeConditionnementId = info.typeConditionnementId() != null
                ? info.typeConditionnementId()
                : base.getTypeConditionnement().getId();

        Famille famille = obtenirFamille(base, request.nomFamille());
        verifierContenanceUnique(famille, info.contenanceValeur(), info.uniteId());

        // Creation de la variante : article + conditionnement + palette.
        ArticleCompletResponse cree = articleCompletService.creerArticleComplet(
                new CreateArticleCompletRequest(
                        new CreateArticleCompletRequest.ArticleInfo(
                                info.nomArticle(),
                                info.codeBar(),
                                typeProduitId,
                                typeConditionnementId,
                                info.contenanceValeur(),
                                info.uniteId()),
                        request.conditionnement(),
                        request.palette()));

        Article variante = articleRepository.findById(cree.article().id())
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.INTERNAL_SERVER_ERROR, "Variante introuvable apres creation"));
        variante.setFamille(famille);
        articleRepository.save(variante);

        return new ArticleCompletResponse(
                articleService.getArticleById(variante.getId()),
                cree.conditionnement(),
                cree.palette());
    }

    // Meme creation, avec une photo facultative envoyee dans la meme demande.
    @Transactional
    public ArticleCompletResponse creerVariante(
            Long articleBaseId, CreateVarianteRequest request, MultipartFile photo) {
        boolean aPhoto = photo != null && !photo.isEmpty();
        if (aPhoto) {
            articleService.verifierPhoto(photo); // avant toute ecriture
        }

        ArticleCompletResponse cree = creerVariante(articleBaseId, request);
        if (!aPhoto) {
            return cree;
        }

        ArticleResponse avecPhoto = articleService.enregistrerPhoto(cree.article().id(), photo);
        return new ArticleCompletResponse(avecPhoto, cree.conditionnement(), cree.palette());
    }

    // Reprend la famille de l'article, ou la cree (une seule ligne) et y rattache l'article.
    private Famille obtenirFamille(Article base, String nomFamilleDemande) {
        if (base.getFamille() != null) {
            return base.getFamille();
        }

        String nom = nomFamilleDemande == null || nomFamilleDemande.isBlank()
                ? base.getNomArticle()
                : nomFamilleDemande.trim();

        Famille famille = familleRepository.findByNom(nom)
                .orElseGet(() -> familleRepository.save(new Famille(nom)));

        // Une famille qui existait deja ne doit pas melanger les types de produit.
        for (Article membre : articleRepository.findAllByFamilleId(famille.getId())) {
            if (!membre.getTypeProduit().getId().equals(base.getTypeProduit().getId())) {
                throw new ResponseStatusException(HttpStatus.CONFLICT,
                        "La famille " + nom + " contient deja des articles d'un autre type de produit");
            }
        }

        base.setFamille(famille);
        articleRepository.save(base);
        return famille;
    }

    // Pas deux variantes avec la meme contenance dans une famille.
    private void verifierContenanceUnique(Famille famille, BigDecimal valeur, Long uniteId) {
        if (valeur == null || uniteId == null) {
            return;
        }
        for (Article membre : articleRepository.findAllByFamilleId(famille.getId())) {
            if (membre.getContenanceValeur() != null
                    && membre.getUnite() != null
                    && membre.getContenanceValeur().compareTo(valeur) == 0
                    && membre.getUnite().getId().equals(uniteId)) {
                throw new ResponseStatusException(HttpStatus.CONFLICT,
                        "Cette famille a deja une variante avec cette contenance");
            }
        }
    }
}
