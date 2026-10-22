package com.example.demo.service;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.article.CreateFamilleRequest;
import com.example.demo.dto.article.FamilleResponse;
import com.example.demo.entity.Famille;
import com.example.demo.repository.ArticleRepository;
import com.example.demo.repository.FamilleRepository;

@Service
public class FamilleService {
    private final FamilleRepository familleRepository;
    private final ArticleRepository articleRepository;

    public FamilleService(FamilleRepository familleRepository, ArticleRepository articleRepository) {
        this.familleRepository = familleRepository;
        this.articleRepository = articleRepository;
    }

    @Transactional
    public FamilleResponse creerFamille(CreateFamilleRequest request) {
        if (request.nom() == null || request.nom().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Le nom de la famille est obligatoire");
        }
        String nom = request.nom().trim();
        if (familleRepository.findByNom(nom).isPresent()) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Cette famille existe deja : " + nom);
        }
        Famille famille = familleRepository.save(new Famille(nom));
        return new FamilleResponse(famille.getId(), famille.getNom(), 0);
    }

    @Transactional(readOnly = true)
    public List<FamilleResponse> getAllFamilles() {
        return familleRepository.findAll().stream()
                .map(famille -> new FamilleResponse(
                        famille.getId(),
                        famille.getNom(),
                        articleRepository.findAllByFamilleId(famille.getId()).size()))
                .toList();
    }
}
