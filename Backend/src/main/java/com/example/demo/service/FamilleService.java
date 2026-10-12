package com.example.demo.service;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.example.demo.dto.article.FamilleResponse;
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
