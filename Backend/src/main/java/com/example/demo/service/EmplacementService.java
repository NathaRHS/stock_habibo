package com.example.demo.service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.emplacement.EmplacementNouveau;
import com.example.demo.dto.emplacement.EmplacementRequest;
import com.example.demo.dto.emplacement.EmplacementRequestAll;
import com.example.demo.dto.emplacement.EmplacementResponse;
import com.example.demo.dto.emplacement.EmplacementResponseAll;
import com.example.demo.entity.Emplacement;
import com.example.demo.entity.Rack;
import com.example.demo.projection.EmplacementCandidatProjection;
import com.example.demo.repository.EmplacementRepository;
import com.example.demo.repository.RackRepository;

@Service 
public class EmplacementService {
    private final EmplacementRepository emplacementRepository;
    private final RackRepository rackRepository;

    public EmplacementService(
            EmplacementRepository emplacementRepository,
            RackRepository rackRepository) {
        this.emplacementRepository = emplacementRepository;
        this.rackRepository = rackRepository;
    }

    @Transactional
    public EmplacementResponse create(EmplacementRequest request) {
        Rack rack = trouverRack(request.rackId());
        verifierNumeroEtage(rack, request.numeroEtage());
        verifierNomDisponible(request.rackId(), request.numeroEtage(), request.nomEmplacement());

        Integer ordreMaximum = emplacementRepository.findOrdreMaximumDansEtage(
                request.rackId(), request.numeroEtage());
        Integer nouvelOrdre = ordreMaximum == null ? 1 : ordreMaximum + 1;

        Emplacement emplacement = new Emplacement(
                request.nomEmplacement(), rack, request.numeroEtage(), nouvelOrdre);
        return versResponse(emplacementRepository.save(emplacement));
    }
  

    // Cree un rack et tous ses emplacements dans une seule transaction :
    // si un emplacement est refuse, rien n'est enregistre.
    @Transactional
    public EmplacementResponseAll createAll(EmplacementRequestAll request) {
        if (request.name() == null || request.name().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Le nom du rack est obligatoire");
        }
        Integer nombreEtages = request.nombreEtages();
        if (nombreEtages == null || nombreEtages <= 0) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Le nombre d'etages doit etre strictement positif");
        }
        String nomRack = request.name().trim();
        if (rackRepository.existsByNomRack(nomRack)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Un rack porte deja ce nom : " + nomRack);
        }

        List<EmplacementNouveau> demandes = request.emplacements() == null
                ? List.of()
                : request.emplacements();

        // Verifie toute la liste avant d'ecrire quoi que ce soit.
        Set<String> dejaVus = new HashSet<>();
        for (EmplacementNouveau demande : demandes) {
            if (demande.nomEmplacement() == null || demande.nomEmplacement().isBlank()) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST, "Le nom d'un emplacement est obligatoire");
            }
            if (demande.numeroEtage() == null
                    || demande.numeroEtage() < 1
                    || demande.numeroEtage() > nombreEtages) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        "Le numero d'etage doit etre compris entre 1 et " + nombreEtages);
            }
            if (!dejaVus.add(demande.numeroEtage() + "/" + demande.nomEmplacement().trim())) {
                throw new ResponseStatusException(
                        HttpStatus.CONFLICT,
                        "Emplacement en double a l'etage " + demande.numeroEtage()
                                + " : " + demande.nomEmplacement());
            }
        }

        Rack rack = new Rack(nomRack, nombreEtages);
        rack.setOrdre(rackRepository.findAll().stream()
                .map(Rack::getOrdre)
                .filter(Objects::nonNull)
                .max(Integer::compare)
                .orElse(0) + 1);
        Rack rackEnregistre = rackRepository.save(rack);

        // Ordre dans l'etage : 1, 2, 3... dans l'ordre de la liste recue.
        Map<Integer, Integer> ordreParEtage = new HashMap<>();
        List<Emplacement> aEnregistrer = new ArrayList<>();
        for (EmplacementNouveau demande : demandes) {
            int ordre = ordreParEtage.merge(demande.numeroEtage(), 1, Integer::sum);
            aEnregistrer.add(new Emplacement(
                    demande.nomEmplacement().trim(), rackEnregistre, demande.numeroEtage(), ordre));
        }

        List<EmplacementResponse> emplacements = emplacementRepository.saveAll(aEnregistrer).stream()
                .map(this::versResponse)
                .toList();

        return new EmplacementResponseAll(
                rackEnregistre.getId(),
                rackEnregistre.getNomRack(),
                rackEnregistre.getNombreEtages(),
                emplacements);
    }

    public List<EmplacementResponse> findAll() {
        return emplacementRepository.findAll().stream()
                .map(this::versResponse)
                .toList();
    }

    public EmplacementResponse findById(Long id) {
        return versResponse(trouverEmplacement(id));
    }

    @Transactional
    public EmplacementResponse update(Long id, EmplacementRequest request) {
        Emplacement emplacement = trouverEmplacement(id);
        Rack rack = trouverRack(request.rackId());
        verifierNumeroEtage(rack, request.numeroEtage());

        boolean rackOuEtageModifie = !emplacement.getRack().getId().equals(request.rackId())
                || !emplacement.getNumeroEtage().equals(request.numeroEtage());
        boolean nomOuRackModifie = !emplacement.getNomEmplacement().equals(request.nomEmplacement())
                || rackOuEtageModifie;
        if (nomOuRackModifie) {
            verifierNomDisponible(request.rackId(), request.numeroEtage(), request.nomEmplacement());
        }

        if (rackOuEtageModifie || emplacement.getOrdreDansEtage() == null) {
            Integer ordreMaximum = emplacementRepository.findOrdreMaximumDansEtage(
                    request.rackId(), request.numeroEtage());
            Integer nouvelOrdre = ordreMaximum == null ? 1 : ordreMaximum + 1;
            emplacement.setOrdreDansEtage(nouvelOrdre);
        }

        emplacement.setNomEmplacement(request.nomEmplacement());
        emplacement.setRack(rack);
        emplacement.setNumeroEtage(request.numeroEtage());
        return versResponse(emplacementRepository.save(emplacement));
    }

    public void delete(Long id) {
        emplacementRepository.delete(trouverEmplacement(id));
    }

    private Emplacement trouverEmplacement(Long id) {
        return emplacementRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Emplacement introuvable : " + id));
    }

    private Rack trouverRack(Long id) {
        if (id == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "rackId est obligatoire");
        }
        return rackRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Rack introuvable : " + id));
    }

    private void verifierNomDisponible(Long rackId, Integer numeroEtage, String nomEmplacement) {
        if (emplacementRepository.existsByRackIdAndNumeroEtageAndNomEmplacement(
                rackId, numeroEtage, nomEmplacement)) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Un emplacement portant ce nom existe deja dans ce rack");
        }
    }

    private void verifierNumeroEtage(Rack rack, Integer numeroEtage) {
        if (numeroEtage == null || numeroEtage < 1 || numeroEtage > rack.getNombreEtages()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Le numero d'etage doit etre compris entre 1 et " + rack.getNombreEtages());
        }
    }

    private EmplacementResponse versResponse(Emplacement emplacement) {
        return new EmplacementResponse(
                emplacement.getId(),
                emplacement.getNomEmplacement(),
                emplacement.getRack().getId(),
                emplacement.getRack().getNomRack(),
                emplacement.getNumeroEtage(),
                emplacement.getOrdreDansEtage());
    }

    
    public List<EmplacementCandidatProjection> trouverEmplacementLibre(Long articleConditionnementId){
        List<EmplacementCandidatProjection> emplacementCandidats = emplacementRepository.rechercherEmplacementsCandidats(articleConditionnementId);
        return emplacementCandidats;

    }
}
