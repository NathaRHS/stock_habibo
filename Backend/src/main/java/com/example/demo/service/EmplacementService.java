package com.example.demo.service;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.EmplacementRequest;
import com.example.demo.dto.EmplacementResponse;
import com.example.demo.entity.Emplacement;
import com.example.demo.entity.Rack;
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

    public EmplacementResponse create(EmplacementRequest request) {
        Rack rack = trouverRack(request.rackId());
        verifierNomDisponible(request.rackId(), request.nomEmplacement());
        Emplacement emplacement = new Emplacement(request.nomEmplacement(), rack);
        return versResponse(emplacementRepository.save(emplacement));
    }

    public List<EmplacementResponse> findAll() {
        return emplacementRepository.findAll().stream()
                .map(this::versResponse)
                .toList();
    }

    public EmplacementResponse findById(Long id) {
        return versResponse(trouverEmplacement(id));
    }

    public EmplacementResponse update(Long id, EmplacementRequest request) {
        Emplacement emplacement = trouverEmplacement(id);
        Rack rack = trouverRack(request.rackId());

        boolean nomOuRackModifie = !emplacement.getNomEmplacement().equals(request.nomEmplacement())
                || !emplacement.getRack().getId().equals(request.rackId());
        if (nomOuRackModifie) {
            verifierNomDisponible(request.rackId(), request.nomEmplacement());
        }

        emplacement.setNomEmplacement(request.nomEmplacement());
        emplacement.setRack(rack);
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

    private void verifierNomDisponible(Long rackId, String nomEmplacement) {
        if (emplacementRepository.existsByRackIdAndNomEmplacement(rackId, nomEmplacement)) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Un emplacement portant ce nom existe deja dans ce rack");
        }
    }

    private EmplacementResponse versResponse(Emplacement emplacement) {
        return new EmplacementResponse(
                emplacement.getId(),
                emplacement.getNomEmplacement(),
                emplacement.getRack().getId(),
                emplacement.getRack().getNomRack());
    }
}
