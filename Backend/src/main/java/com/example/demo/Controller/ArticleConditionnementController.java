package com.example.demo.Controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import com.example.demo.dto.ArticleConditionnementResponse;
import com.example.demo.dto.CreateArticleConditionnementRequest;
import com.example.demo.service.ArticleConditionnementService;

@RestController
@RequestMapping("/articles-conditionnements")
public class ArticleConditionnementController {

    private final ArticleConditionnementService articleConditionnementService;

    public ArticleConditionnementController(
            ArticleConditionnementService articleConditionnementService) {
        this.articleConditionnementService = articleConditionnementService;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ArticleConditionnementResponse createArticleConditionnement(
            @RequestBody CreateArticleConditionnementRequest request) {
        return articleConditionnementService.creerArticleConditionnement(request);
    }

    @GetMapping
    public List<ArticleConditionnementResponse> showArticlesConditionnements() {
        return articleConditionnementService.getAllArticlesConditionnements();
    }

    @GetMapping("/{id}")
    public ArticleConditionnementResponse showArticleConditionnement(@PathVariable Long id) {
        return articleConditionnementService.getArticleConditionnementById(id);
    }

    @PutMapping("/{id}")
    public ArticleConditionnementResponse updateArticleConditionnement(
            @PathVariable Long id,
            @RequestBody CreateArticleConditionnementRequest request) {
        return articleConditionnementService.modifierArticleConditionnement(id, request);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteArticleConditionnement(@PathVariable Long id) {
        articleConditionnementService.supprimerArticleConditionnement(id);
    }
}
