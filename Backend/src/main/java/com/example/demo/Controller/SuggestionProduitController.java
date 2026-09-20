package com.example.demo.Controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.demo.dto.optimisation.SuggestionProduitResponse;
import com.example.demo.service.OptimisationService;

@RestController
@RequestMapping("/optimisation")

public class SuggestionProduitController {
    private final OptimisationService optimisationService;

    public SuggestionProduitController(OptimisationService optimisationService) {
        this.optimisationService = optimisationService;
    }

    @GetMapping("/suggerer/{id}")
    public SuggestionProduitResponse suggererEmplacement(@PathVariable Long id) {
        return optimisationService.proposerEmplacements(id);
    }
}
