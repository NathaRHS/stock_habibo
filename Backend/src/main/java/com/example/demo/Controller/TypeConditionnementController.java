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

import com.example.demo.dto.CreateTypeConditionnementRequest;
import com.example.demo.dto.TypeConditionnementResponse;
import com.example.demo.service.TypeConditionnementService;

@RestController
@RequestMapping("/types-conditionnements")
public class TypeConditionnementController {
    private final TypeConditionnementService typeConditionnementService;

    public TypeConditionnementController(TypeConditionnementService typeConditionnementService) {
        this.typeConditionnementService = typeConditionnementService;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public TypeConditionnementResponse createTypeConditionnement(
            @RequestBody CreateTypeConditionnementRequest request) {
        return typeConditionnementService.creerTypeConditionnement(request);
    }

    @GetMapping
    public List<TypeConditionnementResponse> showTypesConditionnement() {
        return typeConditionnementService.getAllTypesConditionnement();
    }

    @GetMapping("/{id}")
    public TypeConditionnementResponse showTypeConditionnement(@PathVariable Long id) {
        return typeConditionnementService.getTypeConditionnementById(id);
    }

    @PutMapping("/{id}")
    public TypeConditionnementResponse updateTypeConditionnement(
            @PathVariable Long id, @RequestBody CreateTypeConditionnementRequest request) {
        return typeConditionnementService.modifierTypeConditionnement(id, request);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteTypeConditionnement(@PathVariable Long id) {
        typeConditionnementService.supprimerTypeConditionnement(id);
    }
}
