package com.example.demo.Controller;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.demo.dto.optimisation.ParametreSuggestionRequest;
import com.example.demo.dto.optimisation.ParametreSuggestionResponse;
import com.example.demo.service.ParametreSuggestionService;

@RestController
@RequestMapping("/optimisation/parametres")
public class ParametreSuggestionController {
    private final ParametreSuggestionService parametreSuggestionService;

    public ParametreSuggestionController(ParametreSuggestionService parametreSuggestionService) {
        this.parametreSuggestionService = parametreSuggestionService;
    }

    @GetMapping
    public List<ParametreSuggestionResponse> lister() {
        return parametreSuggestionService.lister();
    }

    // Reserve a l'administrateur (regle PUT de SecurityConfig).
    @PutMapping
    public List<ParametreSuggestionResponse> modifier(@RequestBody List<ParametreSuggestionRequest> demandes) {
        return parametreSuggestionService.modifier(demandes);
    }
}
