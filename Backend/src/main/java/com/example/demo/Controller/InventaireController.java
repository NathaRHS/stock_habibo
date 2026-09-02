package com.example.demo.Controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.demo.dto.ControleInventaireResponse;
import com.example.demo.service.InventaireService;

@RestController
@RequestMapping("/inventaire")
public class InventaireController {
    private final InventaireService inventaireService;

    public InventaireController(InventaireService inventaireService) {
        this.inventaireService = inventaireService;
    }

    @GetMapping("/{id}")
    public ControleInventaireResponse inventaire(@PathVariable Long id) {
        System.out.println("id: " + id);
        return inventaireService.constructInventaire(id);
    }
}
