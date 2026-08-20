package com.example.demo.service;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.StatutJournalMouvementRequest;
import com.example.demo.dto.StatutJournalMouvementResponse;
import com.example.demo.entity.StatutjournalMouvement;
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
        return versResponse(statutRepository.save(new StatutjournalMouvement(nom)));
    }

    public List<StatutJournalMouvementResponse> findAll() {
        return statutRepository.findAll().stream()
                .map(this::versResponse)
                .toList();
    }

    public StatutJournalMouvementResponse findById(Long id) {
        return versResponse(trouver(id));
    }

    public StatutJournalMouvementResponse update(
            Long id,
            StatutJournalMouvementRequest request) {
        StatutjournalMouvement statut = trouver(id);
        String nom = normaliserNom(request.nomStatut());
        verifierNomDisponible(nom, id);
        statut.setNomStatut(nom);
        return versResponse(statutRepository.save(statut));
    }

    public void delete(Long id) {
        StatutjournalMouvement statut = trouver(id);
        if (journalRepository.existsByStatutJournalMouvementId(id)) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Ce statut est utilise par des journaux de mouvement");
        }
        statutRepository.delete(statut);
    }

    private StatutjournalMouvement trouver(Long id) {
        return statutRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Statut de journal de mouvement introuvable : " + id));
    }

    private String normaliserNom(String nom) {
        if (nom == null || nom.isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Le nom du statut est obligatoire");
        }
        return nom.trim().toUpperCase();
    }

    private void verifierNomDisponible(String nom, Long idExclu) {
        statutRepository.findByNomStatut(nom)
                .filter(statut -> idExclu == null || !statut.getId().equals(idExclu))
                .ifPresent(statut -> {
                    throw new ResponseStatusException(
                            HttpStatus.CONFLICT,
                            "Ce statut existe deja : " + nom);
                });
    }

    private StatutJournalMouvementResponse versResponse(
            StatutjournalMouvement statut) {
        return new StatutJournalMouvementResponse(
                statut.getId(),
                statut.getNomStatut());
    }
}

