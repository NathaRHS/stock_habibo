package com.example.demo.service;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.RackRequest;
import com.example.demo.dto.RackResponse;
import com.example.demo.entity.Rack;
import com.example.demo.repository.RackRepository;
import com.example.demo.repository.EmplacementRepository;

@Service
public class RackService {
    private final RackRepository rackRepository;
    private final EmplacementRepository emplacementRepository;

    public RackService(RackRepository rackRepository, EmplacementRepository emplacementRepository) {
        this.rackRepository = rackRepository;
        this.emplacementRepository = emplacementRepository;
    }

    public RackResponse create(RackRequest request) {
        validerNombreEtages(request.nombreEtages());
        Rack rack = new Rack(request.name(), request.nombreEtages());
        return versResponse(rackRepository.save(rack));
    }

    public List<RackResponse> findAll() {
        return rackRepository.findAll().stream()
                .map(this::versResponse)
                .toList();
    }

    public RackResponse findById(Long id) {
        return versResponse(trouverRack(id));
    }

    public RackResponse update(Long id, RackRequest request) {
        Rack rack = trouverRack(id);
        validerNombreEtages(request.nombreEtages());
        Integer numeroEtageMaximum = emplacementRepository.findNumeroEtageMaximumByRackId(id);
        if (numeroEtageMaximum != null && request.nombreEtages() < numeroEtageMaximum) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Le rack contient deja un emplacement a l'etage " + numeroEtageMaximum);
        }
        rack.setNomRack(request.name());
        rack.setNombreEtages(request.nombreEtages());
        return versResponse(rackRepository.save(rack));
    }

    public void delete(Long id) {
        rackRepository.delete(trouverRack(id));
    }

    private Rack trouverRack(Long id) {
        return rackRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Rack introuvable : " + id));
    }

    private RackResponse versResponse(Rack rack) {
        return new RackResponse(rack.getId(), rack.getNomRack(), rack.getNombreEtages());
    }

    private void validerNombreEtages(Integer nombreEtages) {
        if (nombreEtages == null || nombreEtages <= 0) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Le nombre d'etages doit etre strictement positif");
        }
    }
}
