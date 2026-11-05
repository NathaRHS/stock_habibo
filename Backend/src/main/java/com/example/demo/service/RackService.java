package com.example.demo.service;

import java.util.Collection;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.emplacement.RackRequest;
import com.example.demo.dto.emplacement.RackResponse;
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
        // Sans ordre, la suggestion d'emplacements refuse de calculer : le nouveau rack passe en dernier.
        rack.setOrdre(rackRepository.findAll().stream()
                .map(Rack::getOrdre)
                .filter(Objects::nonNull)
                .max(Integer::compare)
                .orElse(0) + 1);
        return versResponse(rackRepository.save(rack));
    }

    /** Numerote les racks 1, 2, 3... dans l'ordre de la liste : du plus proche de la sortie au plus loin. */
    @Transactional
    public List<RackResponse> reordonner(List<Long> idsDansLOrdre) {
        List<Rack> racks = rackRepository.findAll();
        Set<Long> idsExistants = racks.stream().map(Rack::getId).collect(Collectors.toSet());

        if (idsDansLOrdre == null
                || idsDansLOrdre.size() != idsExistants.size()
                || !idsExistants.equals(new HashSet<>(idsDansLOrdre))) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "La liste doit contenir chaque rack une seule fois");
        }

        for (Rack rack : racks) {
            rack.setOrdre(idsDansLOrdre.indexOf(rack.getId()) + 1);
        }
        rackRepository.saveAll(racks);

        return racks.stream()
                .sorted(Comparator.comparing(Rack::getOrdre))
                .map(this::versResponse)
                .toList();
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
        return new RackResponse(rack.getId(), rack.getNomRack(), rack.getNombreEtages(), rack.getOrdre());
    }

    private void validerNombreEtages(Integer nombreEtages) {
        if (nombreEtages == null || nombreEtages <= 0) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Le nombre d'etages doit etre strictement positif");
        }
    }


    
}
