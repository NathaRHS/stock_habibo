package com.example.demo.service;

import java.util.List;
import java.util.Optional;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.CreateTypeConditionnementRequest;
import com.example.demo.dto.TypeConditionnementResponse;
import com.example.demo.entity.TypeConditionnement;
import com.example.demo.repository.TypeConditionnementRepository;

@Service
public class TypeConditionnementService {
    private final TypeConditionnementRepository typeConditionnementRepository;

    public TypeConditionnementService(TypeConditionnementRepository typeConditionnementRepository) {
        this.typeConditionnementRepository = typeConditionnementRepository;
    }

    public TypeConditionnementResponse creerTypeConditionnement(CreateTypeConditionnementRequest request) {
        String nom = normaliserNom(request.nomConditionnement());
        verifierNomDisponible(nom, null);
        return versResponse(typeConditionnementRepository.save(new TypeConditionnement(nom)));
    }

    public List<TypeConditionnementResponse> getAllTypesConditionnement() {
        return typeConditionnementRepository.findAll().stream()
                .map(this::versResponse)
                .toList();
    }

    public TypeConditionnementResponse getTypeConditionnementById(Long id) {
        return versResponse(trouverTypeConditionnement(id));
    }

    public TypeConditionnementResponse modifierTypeConditionnement(
            Long id, CreateTypeConditionnementRequest request) {
        TypeConditionnement typeConditionnement = trouverTypeConditionnement(id);
        String nom = normaliserNom(request.nomConditionnement());
        verifierNomDisponible(nom, id);
        typeConditionnement.setNomConditionnement(nom);
        return versResponse(typeConditionnementRepository.save(typeConditionnement));
    }

    public void supprimerTypeConditionnement(Long id) {
        typeConditionnementRepository.delete(trouverTypeConditionnement(id));
    }

    private TypeConditionnement trouverTypeConditionnement(Long id) {
        return typeConditionnementRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Type de conditionnement introuvable : " + id));
    }

    private String normaliserNom(String nom) {
        if (nom == null || nom.isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Le nom du type de conditionnement est obligatoire");
        }
        return nom.trim();
    }

    private void verifierNomDisponible(String nom, Long idExclu) {
        Optional<TypeConditionnement> typeExistant = typeConditionnementRepository.findByNomConditionnement(nom);

        if (typeExistant.isPresent()) {
            TypeConditionnement type = typeExistant.get();

            if (idExclu == null || !type.getId().equals(idExclu)) {
                throw new ResponseStatusException(
                        HttpStatus.CONFLICT,
                        "Ce type de conditionnement existe déjà : " + nom);
            }
        }
    }

    private TypeConditionnementResponse versResponse(TypeConditionnement typeConditionnement) {
        return new TypeConditionnementResponse(
                typeConditionnement.getId(), typeConditionnement.getNomConditionnement());
    }
}
