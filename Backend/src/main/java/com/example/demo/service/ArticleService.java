package com.example.demo.service;

import java.math.BigDecimal;
import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.article.ArticleResponse;
import com.example.demo.dto.article.CreateArticleRequest;
import com.example.demo.repository.TypeProduitRepository;
import com.example.demo.entity.Article;
import com.example.demo.entity.TypeConditionnement;
import com.example.demo.entity.TypeProduit;
import com.example.demo.entity.Unite;
import com.example.demo.repository.ArticleRepository;
import com.example.demo.repository.TypeConditionnementRepository;
import com.example.demo.repository.UniteRepository;

@Service
public class ArticleService {
    private final ArticleRepository articleRepository;
    private final TypeProduitRepository typeProduitRepository;
    private final TypeConditionnementRepository typeConditionnementRepository;
    private final UniteRepository uniteRepository;
    private final FileStorageService fileStorageService;

    private static final String DOSSIER_PHOTOS = "photos/";

    //Injection de dépendances
    public ArticleService(ArticleRepository articleRepository, TypeProduitRepository typeProduitRepository,
            TypeConditionnementRepository typeConditionnementRepository, UniteRepository uniteRepository,
            FileStorageService fileStorageService) {
        this.articleRepository = articleRepository;
        this.typeProduitRepository = typeProduitRepository;
        this.typeConditionnementRepository = typeConditionnementRepository;
        this.uniteRepository = uniteRepository;
        this.fileStorageService = fileStorageService;
    }

    // Verifie une photo AVANT toute ecriture (utilise par les creations avec photo).
    public void verifierPhoto(MultipartFile photo) {
        fileStorageService.verifierPhoto(photo);
    }

    // Ajoute ou remplace la photo d'un article. L'ancien fichier est supprime.
    public ArticleResponse enregistrerPhoto(Long id, MultipartFile photo) {
        Article article = trouverArticle(id);
        String anciennePhoto = article.getPhotoUrl();
        String nomFichier = fileStorageService.enregistrerPhoto(photo);

        try {
            article.setPhotoUrl(DOSSIER_PHOTOS + nomFichier);
            ArticleResponse reponse = versResponse(articleRepository.save(article));

            if (anciennePhoto != null && anciennePhoto.startsWith(DOSSIER_PHOTOS)) {
                fileStorageService.supprimerPhoto(anciennePhoto.substring(DOSSIER_PHOTOS.length()));
            }
            return reponse;
        } catch (RuntimeException exception) {
            // L'enregistrement a echoue : on ne laisse pas de fichier orphelin.
            fileStorageService.supprimerPhoto(nomFichier);
            throw exception;
        }
    }

    public ArticleResponse creerArticle(CreateArticleRequest request) {
        TypeProduit typeProduit = trouverTypeProduit(request.typeProduitId());
        TypeConditionnement typeConditionnement = trouverTypeConditionnement(request.typeConditionnementId());
        Article article = new Article(typeProduit, request.codeBar(), request.nomArticle(), typeConditionnement);
        appliquerContenance(article, request.contenanceValeur(), request.uniteId());
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
        appliquerContenance(article, request.contenanceValeur(), request.uniteId());
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

    // La contenance est facultative, mais valeur et unite vont ensemble.
    private void appliquerContenance(Article article, BigDecimal valeur, Long uniteId) {
        if (valeur == null && uniteId == null) {
            article.setContenanceValeur(null);
            article.setUnite(null);
            return;
        }
        if (valeur == null || uniteId == null) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "La contenance demande une valeur et une unite");
        }
        if (valeur.signum() <= 0) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "La contenance doit etre strictement positive");
        }
        Unite unite = uniteRepository.findById(uniteId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Unite introuvable : " + uniteId));
        article.setContenanceValeur(valeur);
        article.setUnite(unite);
    }

    private ArticleResponse versResponse(Article article) {
        return new ArticleResponse(
                article.getId(),
                article.getCodeBar(),
                article.getNomArticle(),
                article.getTypeProduit().getId(),
                article.getTypeProduit().getNomType(),
                article.getPhotoUrl(),
                article.getFamille() == null ? null : article.getFamille().getId(),
                article.getFamille() == null ? null : article.getFamille().getNom(),
                article.getContenanceValeur(),
                article.getUnite() == null ? null : article.getUnite().getId(),
                article.getUnite() == null ? null : article.getUnite().getNomUnite());
    }

}
