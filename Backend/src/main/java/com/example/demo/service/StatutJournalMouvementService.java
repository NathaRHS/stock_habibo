package com.example.demo.service;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.journal.StatutJournalMouvementRequest;
import com.example.demo.dto.journal.StatutJournalMouvementResponse;
import com.example.demo.entity.StatutJournalMouvement;
import com.example.demo.entity.StatutJournalMouvementCode;
import com.example.demo.repository.JournalMouvementRepository;
import com.example.demo.repository.StatutJournalMouvementRepository;

@Service
public class StatutJournalMouvementService {
    private final StatutJournalMouvementRepository statutRepository;
    private final JournalMouvementRepository journalRepository;

    public StatutJournalMouvementService(
            StatutJournalMouvementRepository statutRepository,
            JournalMouvementRepository journalRepository) {
        this.statutRepository = statutRepository;
        this.journalRepository = journalRepository;
    }

    public StatutJournalMouvementResponse create(StatutJournalMouvementRequest request) {
        String nom = normaliserNom(request.nomStatut());
        verifierNomDisponible(nom, null);
        return versResponse(statutRepository.save(new StatutJournalMouvement(nom)));
    }

    public List<StatutJournalMouvementResponse> findAll() {
        return statutRepository.findAll().stream()
                .filter(statut -> StatutJournalMouvementCode.accepte(statut.getNom()))
                .map(this::versResponse)
                .toList();
    }

    public StatutJournalMouvementResponse findById(Long id) {
        return versResponse(trouver(id));
    }

    public StatutJournalMouvementResponse update(
            Long id,
            StatutJournalMouvementRequest request) {
        StatutJournalMouvement statut = trouver(id);
        String nom = normaliserNom(request.nomStatut());
        verifierNomDisponible(nom, id);
        statut.setNom(nom);
        return versResponse(statutRepository.save(statut));
    }

    public void delete(Long id) {
        StatutJournalMouvement statut = trouver(id);
        if (journalRepository.existsByStatutId(id)) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Ce statut est utilise par des journaux de mouvement");
        }
        statutRepository.delete(statut);
    }

    private StatutJournalMouvement trouver(Long id) {
        StatutJournalMouvement statut = statutRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Statut de journal de mouvement introuvable : " + id));
        verifierStatutJournal(statut.getNom());
        return statut;
    }

    private String normaliserNom(String nom) {
        if (nom == null || nom.isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Le nom du statut est obligatoire");
        }
        String nomNormalise = nom.trim().toUpperCase();
        verifierStatutJournal(nomNormalise);
        return nomNormalise;
    }

    private void verifierNomDisponible(String nom, Long idExclu) {
        statutRepository.findByNom(nom)
                .filter(statut -> idExclu == null || !statut.getId().equals(idExclu))
                .ifPresent(statut -> {
                    throw new ResponseStatusException(
                            HttpStatus.CONFLICT,
                            "Ce statut existe deja : " + nom);
                });
    }

    private StatutJournalMouvementResponse versResponse(
            StatutJournalMouvement statut) {
        return new StatutJournalMouvementResponse(
                statut.getId(),
                statut.getNom());
    }

    private void verifierStatutJournal(String nom) {
        try {
            StatutJournalMouvementCode.depuisNom(nom);
        } catch (IllegalArgumentException exception) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, exception.getMessage());
        }
    }
}
