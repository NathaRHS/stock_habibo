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

import com.example.demo.dto.EmplacementRequest;
import com.example.demo.dto.EmplacementResponse;
import com.example.demo.service.EmplacementService;

@RestController
@RequestMapping("/emplacements")
public class EmplacementController {
    private final EmplacementService emplacementService;

    public EmplacementController(EmplacementService emplacementService) {
        this.emplacementService = emplacementService;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public EmplacementResponse create(@RequestBody EmplacementRequest request) {
        return emplacementService.create(request);
    }

    @GetMapping
    public List<EmplacementResponse> findAll() {
        return emplacementService.findAll();
    }

    @GetMapping("/{id}")
    public EmplacementResponse findById(@PathVariable Long id) {
        return emplacementService.findById(id);
    }

    @PutMapping("/{id}")
    public EmplacementResponse update(
            @PathVariable Long id,
            @RequestBody EmplacementRequest request) {
        return emplacementService.update(id, request);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) {
        emplacementService.delete(id);
    }
}
