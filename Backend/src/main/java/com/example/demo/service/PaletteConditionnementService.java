package com.example.demo.service;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.CreatePaletteConditionnementRequest;
import com.example.demo.dto.PaletteConditionnementResponse;
import com.example.demo.entity.ArticleConditionnement;
import com.example.demo.entity.PaletteConditionnement;
import com.example.demo.repository.ArticleConditionnementRepository;
import com.example.demo.repository.PaletteConditionnementRepository;

@Service
public class PaletteConditionnementService {
    private final PaletteConditionnementRepository paletteConditionnementRepository;
    private final ArticleConditionnementRepository articleConditionnementRepository;

    public PaletteConditionnementService(
            PaletteConditionnementRepository paletteConditionnementRepository,
            ArticleConditionnementRepository articleConditionnementRepository) {
        this.paletteConditionnementRepository = paletteConditionnementRepository;
        this.articleConditionnementRepository = articleConditionnementRepository;
    }

    public PaletteConditionnementResponse create(CreatePaletteConditionnementRequest request) {
        if (request.articleConditionnementId() == null) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "articleConditionnementId est obligatoire");
        }
        if (request.quantiteMaximale() == null || request.quantiteMaximale() <= 0) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "La quantite maximale doit etre strictement positive");
        }

        ArticleConditionnement articleConditionnement = articleConditionnementRepository
                .findById(request.articleConditionnementId())
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "ArticleConditionnement introuvable"));

        if (paletteConditionnementRepository
                .existsByArticleConditionnementId(request.articleConditionnementId())) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Une regle palette existe deja pour cet ArticleConditionnement");
        }

        PaletteConditionnement paletteConditionnement = new PaletteConditionnement(
                articleConditionnement,
                request.quantiteMaximale());
        return versResponse(paletteConditionnementRepository.save(paletteConditionnement));
    }

    public List<PaletteConditionnementResponse> findAll() {
        return paletteConditionnementRepository.findAll().stream()
                .map(this::versResponse)
                .toList();
    }

    public PaletteConditionnementResponse findById(Long id) {
        return versResponse(trouverPaletteConditionnement(id));
    }

    private PaletteConditionnement trouverPaletteConditionnement(Long id) {
        return paletteConditionnementRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "PaletteConditionnement introuvable : " + id));
    }

    private PaletteConditionnementResponse versResponse(
            PaletteConditionnement paletteConditionnement) {
        return new PaletteConditionnementResponse(
                paletteConditionnement.getId(),
                paletteConditionnement.getArticleConditionnement().getId(),
                paletteConditionnement.getQuantite());
    }
}
