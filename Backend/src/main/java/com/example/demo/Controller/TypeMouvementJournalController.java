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

import com.example.demo.dto.TypeMouvementJournalRequest;
import com.example.demo.dto.TypeMouvementJournalResponse;
import com.example.demo.service.TypeMouvementJournalService;

@RestController
@RequestMapping("/types-mouvements-journal")
public class TypeMouvementJournalController {
    private final TypeMouvementJournalService service;

    public TypeMouvementJournalController(TypeMouvementJournalService service) {
        this.service = service;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public TypeMouvementJournalResponse create(@RequestBody TypeMouvementJournalRequest request) {
        return service.create(request);
    }

    @GetMapping
    public List<TypeMouvementJournalResponse> findAll() {
        return service.findAll();
    }

    @GetMapping("/{id}")
    public TypeMouvementJournalResponse findById(@PathVariable Long id) {
        return service.findById(id);
    }

    @PutMapping("/{id}")
    public TypeMouvementJournalResponse update(
            @PathVariable Long id, @RequestBody TypeMouvementJournalRequest request) {
        return service.update(id, request);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) {
        service.delete(id);
    }
}
