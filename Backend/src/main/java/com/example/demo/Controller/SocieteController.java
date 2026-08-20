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

import com.example.demo.dto.FournisseurRequest;
import com.example.demo.dto.FournisseurResponse;
import com.example.demo.service.SocieteService;

@RestController
@RequestMapping("/societes")
public class SocieteController {
    private final SocieteService fournisseurService;

    public SocieteController(SocieteService fournisseurService) {
        this.fournisseurService = fournisseurService;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public FournisseurResponse create(@RequestBody FournisseurRequest request) {
        return fournisseurService.create(request);
    }

    @GetMapping
    public List<FournisseurResponse> findAll() {
        return fournisseurService.findAll();
    }

    @GetMapping("/{id}")
    public FournisseurResponse findById(@PathVariable Long id) {
        return fournisseurService.findById(id);
    }

    @PutMapping("/{id}")
    public FournisseurResponse update(
            @PathVariable Long id,
            @RequestBody FournisseurRequest request) {
        return fournisseurService.update(id, request);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) {
        fournisseurService.delete(id);
    }
}
