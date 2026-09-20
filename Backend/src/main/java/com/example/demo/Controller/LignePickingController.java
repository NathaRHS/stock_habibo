package com.example.demo.Controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import com.example.demo.dto.picking.LignePickingCreateRequest;
import com.example.demo.dto.picking.LignePickingResponse;
import com.example.demo.dto.picking.PickingCreateRequest;
import com.example.demo.dto.picking.ScanLigneRequest;
import com.example.demo.dto.picking.ScanLigneResponse;
import com.example.demo.service.CommandeService;
import com.example.demo.service.LignePickingService;

@RestController
@RequestMapping("/lignes-picking")
public class LignePickingController {

    private final LignePickingService lignePickingService;
    private final CommandeService commandeService;

    public LignePickingController(LignePickingService lignePickingService, CommandeService commandeService) {
        this.lignePickingService = lignePickingService;
        this.commandeService = commandeService;

    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public LignePickingResponse creerLigne(
            @RequestBody LignePickingCreateRequest request) {
        return lignePickingService.creerLigne(request);
    }

    @PostMapping("/generer-meilleur-parcours")
    public List<LignePickingResponse> genererMeilleurParcours(
            @RequestBody PickingCreateRequest request) {

        return commandeService.genererMeilleurParcours(
                request.journalId(),
                request.userId(),
                request.rackDepartId());
    }

    @PostMapping("/scan")
    public ScanLigneResponse scan(@RequestBody ScanLigneRequest request) {
        return lignePickingService.scan(request);
    }

    @GetMapping("/getLignes/{journalId}")
    public List<LignePickingResponse> getLignes(@PathVariable Long journalId) {
        return lignePickingService.getPickingResponses(journalId);
    }

}
