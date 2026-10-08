package com.example.demo.Controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import com.example.demo.dto.article.ArticleCompletResponse;
import com.example.demo.dto.article.ArticleResponse;
import com.example.demo.dto.article.CreateArticleCompletRequest;
import com.example.demo.dto.article.CreateArticleRequest;
import com.example.demo.dto.article.CreateVarianteRequest;
import com.example.demo.service.ArticleCompletService;
import com.example.demo.service.ArticleService;
import com.example.demo.service.VarianteService;

@RestController
@RequestMapping("/articles")
public class ArticleController {
    private final ArticleService articleService;
    private final ArticleCompletService articleCompletService;

    private final VarianteService varianteService;

    public ArticleController(ArticleService articleService, ArticleCompletService articleCompletService,
            VarianteService varianteService) {
        this.articleService = articleService;
        this.articleCompletService = articleCompletService;
        this.varianteService = varianteService;
    }

    // Ajoute une variante a l'article {id} ; la famille est creee a la premiere variante.
    @PostMapping(value = "/{id}/variantes", consumes = MediaType.APPLICATION_JSON_VALUE)
    @ResponseStatus(HttpStatus.CREATED)
    public ArticleCompletResponse createVariante(@PathVariable Long id,
            @RequestBody CreateVarianteRequest request) {
        return varianteService.creerVariante(id, request);
    }

    // Meme chose avec une photo facultative : partie "data" (JSON) + partie "photo" (fichier).
    @PostMapping(value = "/{id}/variantes", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @ResponseStatus(HttpStatus.CREATED)
    public ArticleCompletResponse createVarianteAvecPhoto(@PathVariable Long id,
            @RequestPart("data") CreateVarianteRequest request,
            @RequestPart(value = "photo", required = false) MultipartFile photo) {
        return varianteService.creerVariante(id, request, photo);
    }

    // Ajoute ou remplace la photo d'un article existant.
    @PutMapping(value = "/{id}/photo", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ArticleResponse updatePhoto(@PathVariable Long id, @RequestPart("photo") MultipartFile photo) {
        return articleService.enregistrerPhoto(id, photo);
    }

    @PostMapping({"", "/create"})
    @ResponseStatus(HttpStatus.CREATED)
    public ArticleResponse createArticle(@RequestBody CreateArticleRequest request) {
        return articleService.creerArticle(request);
    }

    @PostMapping(value = "/complet", consumes = MediaType.APPLICATION_JSON_VALUE)
    @ResponseStatus(HttpStatus.CREATED)
    public ArticleCompletResponse createArticleComplet(@RequestBody CreateArticleCompletRequest request) {
        return articleCompletService.creerArticleComplet(request);
    }

    // Meme chose avec une photo facultative : partie "data" (JSON) + partie "photo" (fichier).
    @PostMapping(value = "/complet", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @ResponseStatus(HttpStatus.CREATED)
    public ArticleCompletResponse createArticleCompletAvecPhoto(
            @RequestPart("data") CreateArticleCompletRequest request,
            @RequestPart(value = "photo", required = false) MultipartFile photo) {
        return articleCompletService.creerArticleComplet(request, photo);
    }


    @GetMapping
    public List<ArticleResponse> showArticles() {
        return articleService.getAllArticles();
    }

    @GetMapping("/{id}")
    public ArticleResponse showArticle(@PathVariable Long id) {
        return articleService.getArticleById(id);
    }

    @PutMapping("/{id}")
    public ArticleResponse updateArticle(@PathVariable Long id, @RequestBody CreateArticleRequest request) {
        return articleService.modifierArticle(id, request);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteArticle(@PathVariable Long id) {
        articleService.supprimerArticle(id);
    }
}
