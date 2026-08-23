package com.example.demo.service;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.TypeMouvementJournalRequest;
import com.example.demo.dto.TypeMouvementJournalResponse;
import com.example.demo.entity.TypeMouvementJournal;
import com.example.demo.repository.JournalMouvementRepository;
import com.example.demo.repository.TypeMouvementJournalRepository;

@Service
public class TypeMouvementJournalService {
    private final TypeMouvementJournalRepository typeRepository;
    private final JournalMouvementRepository journalRepository;

    public TypeMouvementJournalService(
            TypeMouvementJournalRepository typeRepository,
            JournalMouvementRepository journalRepository) {
        this.typeRepository = typeRepository;
        this.journalRepository = journalRepository;
    }

    public TypeMouvementJournalResponse create(TypeMouvementJournalRequest request) {
        String nom = normaliserNom(request.nomTypeMouvement());
        verifierSens(request.sens());
        verifierNomDisponible(nom, null);
        return versResponse(typeRepository.save(new TypeMouvementJournal(nom, request.sens())));
    }

    public List<TypeMouvementJournalResponse> findAll() {
        return typeRepository.findAll().stream().map(this::versResponse).toList();
    }

    public TypeMouvementJournalResponse findById(Long id) {
        return versResponse(trouver(id));
    }

    public TypeMouvementJournalResponse update(Long id, TypeMouvementJournalRequest request) {
        TypeMouvementJournal type = trouver(id);
        String nom = normaliserNom(request.nomTypeMouvement());
        verifierSens(request.sens());
        verifierNomDisponible(nom, id);
        type.setNomTypeMouvement(nom);
        type.setSens(request.sens());
        return versResponse(typeRepository.save(type));
    }

    public void delete(Long id) {
        TypeMouvementJournal type = trouver(id);
        if (journalRepository.existsByTypeMouvementJournalId(id)) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT, "Ce type est utilise par des journaux de mouvement");
        }
        typeRepository.delete(type);
    }

    private TypeMouvementJournal trouver(Long id) {
        return typeRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Type de mouvement journal introuvable : " + id));
    }

    private String normaliserNom(String nom) {
        if (nom == null || nom.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Le nom est obligatoire");
        }
        return nom.trim().toUpperCase();
    }

    private void verifierSens(Short sens) {
        if (sens == null || (sens != -1 && sens != 1)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Le sens doit valoir -1 ou 1");
        }
    }

    private void verifierNomDisponible(String nom, Long idExclu) {
        typeRepository.findByNomTypeMouvement(nom)
                .filter(type -> idExclu == null || !type.getId().equals(idExclu))
                .ifPresent(type -> {
                    throw new ResponseStatusException(
                            HttpStatus.CONFLICT, "Ce type de mouvement journal existe deja : " + nom);
                });
    }

    private TypeMouvementJournalResponse versResponse(TypeMouvementJournal type) {
        return new TypeMouvementJournalResponse(
                type.getId(), type.getNomTypeMouvement(), type.getSens());
    }
}
