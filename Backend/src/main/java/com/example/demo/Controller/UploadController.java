package com.example.demo.Controller;

import java.nio.charset.StandardCharsets;

import org.springframework.core.io.Resource;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.example.demo.service.FileStorageService;

@RestController
public class UploadController {

    private final FileStorageService fileStorageService;

    public UploadController(FileStorageService fileStorageService) {
        this.fileStorageService = fileStorageService;
    }

    @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @ResponseStatus(HttpStatus.CREATED)
    public String upload(@RequestParam("file") MultipartFile file) {
        String nomFichier = fileStorageService.enregistrerFichier(file);
        return "uploads/" + nomFichier;
    }

    // Lecture publique des PHOTOS d'articles (une balise <img> ne peut pas envoyer de jeton).
    // Seuls les fichiers de photo sont servis ici ; les PDF restent proteges.
    @GetMapping("/photos/{nomPhoto:.+}")
    public ResponseEntity<Resource> consulterPhoto(@PathVariable String nomPhoto) {
        Resource photo = fileStorageService.chargerPhoto(nomPhoto);
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(fileStorageService.typeContenuPhoto(nomPhoto)))
                .header(HttpHeaders.CACHE_CONTROL, "public, max-age=31536000, immutable")
                .header("X-Content-Type-Options", "nosniff")
                .body(photo);
    }

    @GetMapping("/uploads/{nomFichier:.+}")
    public ResponseEntity<Resource> consulter(@PathVariable String nomFichier) {
        Resource fichier = fileStorageService.chargerFichier(nomFichier);
        MediaType typeContenu = MediaType.parseMediaType(
                fileStorageService.detecterTypeContenu(fichier));
        ContentDisposition disposition = ContentDisposition.inline()
                .filename(nomFichier, StandardCharsets.UTF_8)
                .build();

        return ResponseEntity.ok()
                .contentType(typeContenu)
                .header(HttpHeaders.CONTENT_DISPOSITION, disposition.toString())
                .body(fichier);
    }
}
