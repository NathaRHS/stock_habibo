package com.example.demo.Controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.ResponseStatus;

import com.example.demo.dto.CreerMouvementsStockRequest;
import com.example.demo.dto.MouvementStockResponse;
import com.example.demo.service.MouvementStockService;

@RestController
@RequestMapping("/mouvementStock")
public class MouvementStockController {
    private final MouvementStockService mouvementStockService;

    public MouvementStockController(MouvementStockService mouvementStockService) {
        this.mouvementStockService = mouvementStockService;
    }

    @GetMapping
    public List<MouvementStockResponse> getMouvementStock() {
        return mouvementStockService.findAll();

    }

    @GetMapping("/entrees")
    public List<MouvementStockResponse> getAllEntry() {
        return mouvementStockService.getAllEntry();
    }

    @PostMapping("/{journalId}/entree-stock")
    @ResponseStatus(HttpStatus.CREATED)
    public List<MouvementStockResponse> entreeStock(
            @PathVariable Long journalId,
            @RequestBody CreerMouvementsStockRequest request,
            @AuthenticationPrincipal Jwt jwt) {

        String matricule = jwt.getSubject();
        return mouvementStockService.creerEntreeStock(journalId, request, matricule);
    }

}
