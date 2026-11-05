package com.example.demo.Controller;

import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.example.demo.dto.importation.ImportResponse;
import com.example.demo.service.ArticleImportService;

@RestController
@RequestMapping("/articles/import")
public class ArticleImportController {
    private final ArticleImportService articleImportService;

    public ArticleImportController(ArticleImportService articleImportService) {
        this.articleImportService = articleImportService;
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ImportResponse importer(@RequestParam("file") MultipartFile fichier) {
        return articleImportService.importer(fichier);
    }

    @GetMapping("/modele")
    public ResponseEntity<byte[]> modele() {
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType("text/csv; charset=UTF-8"))
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        ContentDisposition.attachment().filename("modele_articles.csv").build().toString())
                .body(articleImportService.modele());
    }
}
