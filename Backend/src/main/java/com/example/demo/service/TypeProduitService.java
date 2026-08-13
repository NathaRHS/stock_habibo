package com.example.demo.service;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.CreateTypeProduitRequest;
import com.example.demo.dto.TypeProduitResponse;
import com.example.demo.entity.TypeProduit;
import com.example.demo.repository.ArticleRepository;
import com.example.demo.repository.TypeProduitRepository;

@Service
public class TypeProduitService {
    private final TypeProduitRepository typeProduitRepository;
    private final ArticleRepository articleRepository;

    public TypeProduitService(TypeProduitRepository typeProduitRepository, ArticleRepository articleRepository) {
        this.typeProduitRepository = typeProduitRepository;
        this.articleRepository = articleRepository;
    }

    public TypeProduitResponse creerTypeProduit(CreateTypeProduitRequest request) {
        return versResponse(typeProduitRepository.save(new TypeProduit(request.nomType())));
    }

    public List<TypeProduitResponse> getAllTypesProduit() {
        return typeProduitRepository.findAll().stream().map(this::versResponse).toList();
    }

    public TypeProduitResponse getTypeProduitById(Long id) {
        return versResponse(trouverTypeProduit(id));
    }

    public TypeProduitResponse modifierTypeProduit(Long id, CreateTypeProduitRequest request) {
        TypeProduit typeProduit = trouverTypeProduit(id);
        typeProduit.setNomType(request.nomType());
        return versResponse(typeProduitRepository.save(typeProduit));
    }

    public void supprimerTypeProduit(Long id) {
        TypeProduit typeProduit = trouverTypeProduit(id);
        if (articleRepository.existsByTypeProduitId(id)) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT, "Ce type de produit est encore utilise par des articles");
        }
        typeProduitRepository.delete(typeProduit);
    }

    private TypeProduit trouverTypeProduit(Long id) {
        return typeProduitRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Type de produit introuvable : " + id));
    }

    private TypeProduitResponse versResponse(TypeProduit typeProduit) {
        return new TypeProduitResponse(typeProduit.getId(), typeProduit.getNomType());
    }
}
