package com.example.demo.Controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import com.example.demo.dto.article.CreateFamilleRequest;
import com.example.demo.dto.article.FamilleResponse;
import com.example.demo.service.FamilleService;

@RestController
@RequestMapping("/familles")
public class FamilleController {
    private final FamilleService familleService;

    public FamilleController(FamilleService familleService) {
        this.familleService = familleService;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public FamilleResponse createFamille(@RequestBody CreateFamilleRequest request) {
        return familleService.creerFamille(request);
    }

    @GetMapping
    public List<FamilleResponse> showFamilles() {
        return familleService.getAllFamilles();
    }
}
