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

import com.example.demo.dto.StatutPrelevementRequest;
import com.example.demo.dto.StatutPrelevementResponse;
import com.example.demo.service.StatutPrelevementService;

@RestController
@RequestMapping("/statuts-prelevements")
public class StatutPrelevementController {

    private final StatutPrelevementService statutPrelevementService;

    public StatutPrelevementController(StatutPrelevementService statutPrelevementService) {
        this.statutPrelevementService = statutPrelevementService;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public StatutPrelevementResponse create(@RequestBody StatutPrelevementRequest request) {
        return statutPrelevementService.create(request);
    }

    @GetMapping
    public List<StatutPrelevementResponse> findAll() {
        return statutPrelevementService.findAll();
    }

    @GetMapping("/{id}")
    public StatutPrelevementResponse findById(@PathVariable Long id) {
        return statutPrelevementService.findById(id);
    }

    @PutMapping("/{id}")
    public StatutPrelevementResponse update(
            @PathVariable Long id,
            @RequestBody StatutPrelevementRequest request) {
        return statutPrelevementService.update(id, request);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) {
        statutPrelevementService.delete(id);
    }
}
