package com.example.demo.service;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.article.ArticleCompletResponse;
import com.example.demo.dto.article.ArticleConditionnementResponse;
import com.example.demo.dto.article.ArticleResponse;
import com.example.demo.dto.article.CreateArticleCompletRequest;
import com.example.demo.dto.article.CreateArticleConditionnementRequest;
import com.example.demo.dto.article.CreateArticleRequest;
import com.example.demo.dto.article.CreatePaletteConditionnementRequest;
import com.example.demo.dto.article.PaletteConditionnementResponse;
import com.example.demo.dto.article.UpdateArticleCompletRequest;
import com.example.demo.entity.Article;
import com.example.demo.entity.CibleEvenement;
import com.example.demo.entity.TypeEvenementUser;
import com.example.demo.repository.ArticleRepository;

/**
 * Cree un article, son conditionnement et sa capacite palette dans une seule
 * transaction : si l'une des trois etapes echoue, rien n'est enregistre.
 */
@Service
public class ArticleCompletService {

    private final ArticleService articleService;
    private final ArticleConditionnementService articleConditionnementService;
    private final PaletteConditionnementService paletteConditionnementService;
    private final ArticleRepository articleRepository;
    private final JournalUserService journalUserService;

    public ArticleCompletService(
            ArticleService articleService,
            ArticleConditionnementService articleConditionnementService,
            PaletteConditionnementService paletteConditionnementService, ArticleRepository articleRepository,
            JournalUserService journalUserService) {
        this.articleService = articleService;
        this.articleRepository = articleRepository;
        this.articleConditionnementService = articleConditionnementService;
        this.paletteConditionnementService = paletteConditionnementService;
        this.journalUserService = journalUserService;
    }

    // Creation d'un article : le travail, puis la trace "article cree".
    @Transactional
    public ArticleCompletResponse creerArticleComplet(CreateArticleCompletRequest request) {
        ArticleCompletResponse cree = construireArticleComplet(request);

        journalUserService.enregistrer(
                TypeEvenementUser.ARTICLE_CREE,
                CibleEvenement.ARTICLE,
                cree.article().id(),
                cree.article().nomArticle() + " (" + cree.article().codeBar() + ")");

        return cree;
    }

    // Le travail de creation, sans trace : une variante l'utilise aussi et
    // enregistre sa propre action ("variante creee"), pas deux.
    @Transactional
    public ArticleCompletResponse construireArticleComplet(CreateArticleCompletRequest request) {
        verifierSections(request);

        // 1. L'article.
        ArticleResponse article = articleService.creerArticle(new CreateArticleRequest(
                request.article().nomArticle(),
                request.article().codeBar(),
                request.article().typeProduitId(),
                request.article().typeConditionnementId(),
                request.article().contenanceValeur(),
                request.article().uniteId()));

        // 2. Son conditionnement, rattache a l'article qui vient d'etre cree.
        ArticleConditionnementResponse conditionnement = articleConditionnementService
                .creerArticleConditionnement(new CreateArticleConditionnementRequest(
                        article.id(),
                        request.conditionnement().typeConditionnementId(),
                        request.conditionnement().codeBarres(),
                        request.conditionnement().quantitePieceStandard()));

        // 3. Sa capacite palette, rattachee a ce conditionnement.
        PaletteConditionnementResponse palette = paletteConditionnementService
                .create(new CreatePaletteConditionnementRequest(
                        conditionnement.id(),
                        request.palette().quantiteMaximale()));

        return new ArticleCompletResponse(article, conditionnement, palette);
    }

    // Meme creation, avec une photo facultative envoyee dans la meme demande.
    @Transactional
    public ArticleCompletResponse creerArticleComplet(CreateArticleCompletRequest request, MultipartFile photo) {
        boolean aPhoto = photo != null && !photo.isEmpty();
        if (aPhoto) {
            articleService.verifierPhoto(photo); // avant toute ecriture
        }

        ArticleCompletResponse cree = creerArticleComplet(request);
        if (!aPhoto) {
            return cree;
        }

        ArticleResponse avecPhoto = articleService.enregistrerPhoto(cree.article().id(), photo);
        return new ArticleCompletResponse(avecPhoto, cree.conditionnement(), cree.palette());
    }

    private void verifierSections(CreateArticleCompletRequest request) {
        if (request == null || request.article() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "La section article est obligatoire");
        }
        if (request.conditionnement() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "La section conditionnement est obligatoire");
        }
        if (request.palette() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "La section palette est obligatoire");
        }
    }

    public ArticleCompletResponse updateCompletArticle(UpdateArticleCompletRequest request) {
        Article article = articleRepository.findById(request.article().articleId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "article introuvable"));
        ArticleResponse articleResponse = articleService.modifierArticle(article.getId(), new CreateArticleRequest(
                request.article().nomArticle(), request.article().codeBar(), request.article().typeProduitId(),
                request.article().typeProduitId(), request.article().contenanceValeur(), request.article().uniteId()));
        ArticleConditionnementResponse conditionnement = articleConditionnementService
                .modifierArticleConditionnement(article.getArticleConditionnements().get(0).getId(),
                        new CreateArticleConditionnementRequest(
                                articleResponse.id(),
                                request.conditionnement().typeConditionnementId(),
                                request.conditionnement().codeBarres(),
                                request.conditionnement().quantitePieceStandard()));

        PaletteConditionnementResponse palette = paletteConditionnementService
                .modifier(article.getArticleConditionnements().get(0).getId(), request.palette().quantiteMaximale());
        return new ArticleCompletResponse(articleResponse, conditionnement, palette);
    }
}
