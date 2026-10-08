package com.example.demo.service;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.article.CreateUniteRequest;
import com.example.demo.dto.article.UniteResponse;
import com.example.demo.entity.Unite;
import com.example.demo.repository.ArticleRepository;
import com.example.demo.repository.UniteRepository;

@Service
public class UniteService {
    private final UniteRepository uniteRepository;
    private final ArticleRepository articleRepository;

    public UniteService(UniteRepository uniteRepository, ArticleRepository articleRepository) {
        this.uniteRepository = uniteRepository;
        this.articleRepository = articleRepository;
    }

    public UniteResponse creerUnite(CreateUniteRequest request) {
        String nom = normaliser(request.nomUnite());
        if (uniteRepository.existsByNomUnite(nom)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Cette unite existe deja : " + nom);
        }
        return versResponse(uniteRepository.save(new Unite(nom)));
    }

    public List<UniteResponse> getAllUnites() {
        return uniteRepository.findAll().stream().map(this::versResponse).toList();
    }

    public UniteResponse getUniteById(Long id) {
        return versResponse(trouverUnite(id));
    }

    public UniteResponse modifierUnite(Long id, CreateUniteRequest request) {
        Unite unite = trouverUnite(id);
        String nom = normaliser(request.nomUnite());
        if (!nom.equals(unite.getNomUnite()) && uniteRepository.existsByNomUnite(nom)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Cette unite existe deja : " + nom);
        }
        unite.setNomUnite(nom);
        return versResponse(uniteRepository.save(unite));
    }

    public void supprimerUnite(Long id) {
        Unite unite = trouverUnite(id);
        if (articleRepository.existsByUniteId(id)) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT, "Cette unite est encore utilisee par des articles");
        }
        uniteRepository.delete(unite);
    }

    private String normaliser(String nomUnite) {
        if (nomUnite == null || nomUnite.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "nomUnite est obligatoire");
        }
        return nomUnite.trim();
    }

    private Unite trouverUnite(Long id) {
        return uniteRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Unite introuvable : " + id));
    }

    private UniteResponse versResponse(Unite unite) {
        return new UniteResponse(unite.getId(), unite.getNomUnite());
    }
}
