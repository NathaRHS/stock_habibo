package com.example.demo.Controller;

import java.time.LocalDate;
import java.util.List;

import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.ResponseStatus;

import com.example.demo.dto.stock.ActiviteEmplacementResponse;
import com.example.demo.dto.stock.CreerMouvementsStockRequest;
import com.example.demo.dto.stock.MouvementStockResponse;
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

    // Stock a la fin de la periode, variation et nombre de mouvements par emplacement.
    // Format des dates : AAAA-MM-JJ. Sans parametre, le jour courant est utilise.
    @GetMapping("/activite")
    public List<ActiviteEmplacementResponse> activite(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate debut,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fin) {
        return mouvementStockService.calculerActivite(debut, fin);
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

    @PostMapping ("/validerSortie/{journalId}")
    public List<MouvementStockResponse> validerSortie(@PathVariable  Long journalId){
        return mouvementStockService.validerSortie(journalId);
    }

}
