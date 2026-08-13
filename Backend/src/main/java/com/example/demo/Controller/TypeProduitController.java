package com.example.demo.Controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import com.example.demo.dto.CreateTypeProduitRequest;
import com.example.demo.dto.TypeProduitResponse;
import com.example.demo.service.TypeProduitService;

@RestController
@RequestMapping("/types-produits")
public class TypeProduitController {
    private final TypeProduitService typeProduitService;

    public TypeProduitController(TypeProduitService typeProduitService) {
        this.typeProduitService = typeProduitService;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public TypeProduitResponse createTypeProduit(@RequestBody CreateTypeProduitRequest request) {
        return typeProduitService.creerTypeProduit(request);
    }

    @GetMapping
    public List<TypeProduitResponse> showTypesProduit() {
        return typeProduitService.getAllTypesProduit();
    }

    @GetMapping("/{id}")
    public TypeProduitResponse showTypeProduit(@PathVariable Long id) {
        return typeProduitService.getTypeProduitById(id);
    }

    @PutMapping("/{id}")
    public TypeProduitResponse updateTypeProduit(
            @PathVariable Long id, @RequestBody CreateTypeProduitRequest request) {
        return typeProduitService.modifierTypeProduit(id, request);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteTypeProduit(@PathVariable Long id) {
        typeProduitService.supprimerTypeProduit(id);
    }
}
