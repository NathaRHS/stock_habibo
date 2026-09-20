package com.example.demo.Controller;

import java.util.List;

import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.demo.dto.optimisation.SuggestionProduitResponse;
import com.example.demo.dto.stock.AffectationStockRequest;
import com.example.demo.service.OptimisationService;

@RestController
@RequestMapping("/optimisation")

public class SuggestionProduitController {
    private final OptimisationService optimisationService;

    public SuggestionProduitController(OptimisationService optimisationService) {
        this.optimisationService = optimisationService;
    }

    @PostMapping ("/suggerer/{id}")
    public SuggestionProduitResponse suggererEmplacement(@PathVariable Long id,@RequestBody List<AffectationStockRequest>affectations) {
        return optimisationService.proposerEmplacements(id,affectations);
    }
}
