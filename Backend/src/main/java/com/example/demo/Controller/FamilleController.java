package com.example.demo.Controller;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.demo.dto.article.FamilleResponse;
import com.example.demo.service.FamilleService;

@RestController
@RequestMapping("/familles")
public class FamilleController {
    private final FamilleService familleService;

    public FamilleController(FamilleService familleService) {
        this.familleService = familleService;
    }

    @GetMapping
    public List<FamilleResponse> showFamilles() {
        return familleService.getAllFamilles();
    }
}
