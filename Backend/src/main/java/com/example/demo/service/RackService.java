package com.example.demo.service;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.RackRequest;
import com.example.demo.dto.RackResponse;
import com.example.demo.entity.Rack;
import com.example.demo.repository.RackRepository;

@Service
public class RackService {
    private final RackRepository rackRepository;

    public RackService(RackRepository rackRepository) {
        this.rackRepository = rackRepository;
    }

    public RackResponse create(RackRequest request) {
        Rack rack = new Rack(request.name());
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
        rack.setNomRack(request.name());
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
        return new RackResponse(rack.getId(), rack.getNomRack());
    }
}
