package com.example.demo.service;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.StatutPrelevementRequest;
import com.example.demo.dto.StatutPrelevementResponse;
import com.example.demo.entity.StatutPrelevement;
import com.example.demo.repository.PrelevementRepository;
import com.example.demo.repository.StatutPrelevementRepository;

@Service
public class StatutPrelevementService {

    private final StatutPrelevementRepository statutPrelevementRepository;
    private final PrelevementRepository prelevementRepository;

    public StatutPrelevementService(
            StatutPrelevementRepository statutPrelevementRepository,
            PrelevementRepository prelevementRepository) {
        this.statutPrelevementRepository = statutPrelevementRepository;
        this.prelevementRepository = prelevementRepository;
    }

    public StatutPrelevementResponse create(StatutPrelevementRequest request) {
        String nomStatut = normaliserNom(request.nomStatut());
        verifierNomDisponible(nomStatut, null);

        StatutPrelevement statut = new StatutPrelevement(nomStatut);
        return versResponse(statutPrelevementRepository.save(statut));
    }

    public List<StatutPrelevementResponse> findAll() {
        return statutPrelevementRepository.findAll().stream()
                .map(this::versResponse)
                .toList();
    }

    public StatutPrelevementResponse findById(Long id) {
        return versResponse(trouver(id));
    }

    public StatutPrelevementResponse update(Long id, StatutPrelevementRequest request) {
        StatutPrelevement statut = trouver(id);
        String nomStatut = normaliserNom(request.nomStatut());
        verifierNomDisponible(nomStatut, id);

        statut.setNomStatut(nomStatut);
        return versResponse(statutPrelevementRepository.save(statut));
    }

    public void delete(Long id) {
        StatutPrelevement statut = trouver(id);

        if (prelevementRepository.existsByStatutPrelevementId(id)) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Ce statut est utilise par des prelevements");
        }

        statutPrelevementRepository.delete(statut);
    }

    private StatutPrelevement trouver(Long id) {
        return statutPrelevementRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Statut de prelevement introuvable : " + id));
    }

    private String normaliserNom(String nomStatut) {
        if (nomStatut == null || nomStatut.isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Le nom du statut est obligatoire");
        }

        return nomStatut.trim().toUpperCase();
    }

    private void verifierNomDisponible(String nomStatut, Long idExclu) {
        statutPrelevementRepository.findByNomStatut(nomStatut)
                .filter(statut -> idExclu == null || !statut.getId().equals(idExclu))
                .ifPresent(statut -> {
                    throw new ResponseStatusException(
                            HttpStatus.CONFLICT,
                            "Ce statut existe deja : " + nomStatut);
                });
    }

    private StatutPrelevementResponse versResponse(StatutPrelevement statut) {
        return new StatutPrelevementResponse(
                statut.getId(),
                statut.getNomStatut());
    }
}
