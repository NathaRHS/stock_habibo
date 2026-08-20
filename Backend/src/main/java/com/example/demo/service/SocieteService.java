package com.example.demo.service;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.FournisseurRequest;
import com.example.demo.dto.FournisseurResponse;
import com.example.demo.entity.Societe;
import com.example.demo.repository.SocieteRepository;
import com.example.demo.repository.JournalMouvementRepository;

@Service
public class SocieteService {
    private final SocieteRepository fournisseurRepository;
    private final JournalMouvementRepository journalMouvementRepository;

    public SocieteService(
            SocieteRepository SocieteRepository,
            JournalMouvementRepository journalMouvementRepository) {
        this.fournisseurRepository = SocieteRepository;
        this.journalMouvementRepository = journalMouvementRepository;
    }

    public FournisseurResponse create(FournisseurRequest request) {
        String nomSociete = validerEtNettoyerNom(request.nomSociete());
        verifierNomDisponible(nomSociete, null);
        return versResponse(fournisseurRepository.save(new Societe(nomSociete)));
    }

    public List<FournisseurResponse> findAll() {
        return fournisseurRepository.findAll().stream()
                .map(this::versResponse)
                .toList();
    }

    public FournisseurResponse findById(Long id) {
        return versResponse(trouverFournisseur(id));
    }

    public FournisseurResponse update(Long id, FournisseurRequest request) {
        Societe fournisseur = trouverFournisseur(id);
        String nomSociete = validerEtNettoyerNom(request.nomSociete());
        verifierNomDisponible(nomSociete, id);
        fournisseur.setNomSociete(nomSociete);
        return versResponse(fournisseurRepository.save(fournisseur));
    }

    public void delete(Long id) {
        Societe fournisseur = trouverFournisseur(id);
        if (journalMouvementRepository.existsByFournisseurId(id)) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Ce fournisseur est utilise par des journaux de mouvement");
        }
        fournisseurRepository.delete(fournisseur);
    }

    private Societe trouverFournisseur(Long id) {
        return fournisseurRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Fournisseur introuvable : " + id));
    }

    private String validerEtNettoyerNom(String nomSociete) {
        if (nomSociete == null || nomSociete.isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Le nom de la societe est obligatoire");
        }
        return nomSociete.trim();
    }

    private void verifierNomDisponible(String nomSociete, Long idExclu) {
        fournisseurRepository.findByNomSocieteIgnoreCase(nomSociete)
                .filter(fournisseur -> idExclu == null || !fournisseur.getId().equals(idExclu))
                .ifPresent(fournisseur -> {
                    throw new ResponseStatusException(
                            HttpStatus.CONFLICT,
                            "Ce fournisseur existe deja : " + nomSociete);
                });
    }

    private FournisseurResponse versResponse(Societe fournisseur) {
        return new FournisseurResponse(
                fournisseur.getId(),
                fournisseur.getNomSociete());
    }
}
