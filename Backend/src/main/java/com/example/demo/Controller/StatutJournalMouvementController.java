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

import com.example.demo.dto.StatutJournalMouvementRequest;
import com.example.demo.dto.StatutJournalMouvementResponse;
import com.example.demo.service.StatutJournalMouvementService;

@RestController
@RequestMapping("/statuts-journaux-mouvements")
public class StatutJournalMouvementController {
    private final StatutJournalMouvementService service;

    public StatutJournalMouvementController(
            StatutJournalMouvementService service) {
        this.service = service;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public StatutJournalMouvementResponse create(
            @RequestBody StatutJournalMouvementRequest request) {
        return service.create(request);
    }

    @GetMapping
    public List<StatutJournalMouvementResponse> findAll() {
        return service.findAll();
    }

    @GetMapping("/{id}")
    public StatutJournalMouvementResponse findById(@PathVariable Long id) {
        return service.findById(id);
    }

    @PutMapping("/{id}")
    public StatutJournalMouvementResponse update(
            @PathVariable Long id,
            @RequestBody StatutJournalMouvementRequest request) {
        return service.update(id, request);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) {
        service.delete(id);
    }
}

