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

import com.example.demo.dto.article.CreateUniteRequest;
import com.example.demo.dto.article.UniteResponse;
import com.example.demo.service.UniteService;

@RestController
@RequestMapping("/unites")
public class UniteController {
    private final UniteService uniteService;

    public UniteController(UniteService uniteService) {
        this.uniteService = uniteService;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public UniteResponse createUnite(@RequestBody CreateUniteRequest request) {
        return uniteService.creerUnite(request);
    }

    @GetMapping
    public List<UniteResponse> showUnites() {
        return uniteService.getAllUnites();
    }

    @GetMapping("/{id}")
    public UniteResponse showUnite(@PathVariable Long id) {
        return uniteService.getUniteById(id);
    }

    @PutMapping("/{id}")
    public UniteResponse updateUnite(@PathVariable Long id, @RequestBody CreateUniteRequest request) {
        return uniteService.modifierUnite(id, request);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteUnite(@PathVariable Long id) {
        uniteService.supprimerUnite(id);
    }
}
