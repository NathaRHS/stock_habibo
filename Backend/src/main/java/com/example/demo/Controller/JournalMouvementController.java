package com.example.demo.Controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import com.example.demo.dto.DetailJournalResponse;
import com.example.demo.dto.ComptageInventaireResponse;
import com.example.demo.dto.JournalMouvementRequest;
import com.example.demo.dto.JournalMouvementResponse;
import com.example.demo.dto.ScanArticleRequest;
import com.example.demo.dto.ScanInventaireRequest;
import com.example.demo.dto.UpdateStatutJournalRequest;
import com.example.demo.service.JournalMouvementService;
import org.springframework.security.oauth2.jwt.Jwt;

@RestController
@RequestMapping("/journaux-mouvements")
public class JournalMouvementController {
    private final JournalMouvementService service;

    public JournalMouvementController(JournalMouvementService service) {
        this.service = service;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public JournalMouvementResponse create(@RequestBody JournalMouvementRequest request) {
        return service.create(request);
    }

    @GetMapping
    public List<JournalMouvementResponse> findAll() {
        return service.findAll();
    }

    @GetMapping("/{id}")
    public JournalMouvementResponse findById(@PathVariable Long id) {
        return service.findById(id);
    }

    @GetMapping("/detailJournal")
    public List<DetailJournalResponse> findAllDetailJournal() {
        return service.findAllDetailJournal();
    }

    @PutMapping("/{id}")
    public JournalMouvementResponse update(
            @PathVariable Long id, @RequestBody JournalMouvementRequest request) {
        return service.update(id, request);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) {
        service.delete(id);
    }

    @PutMapping("/{id}/statut")
    public JournalMouvementResponse changeStatutJournal(
            @PathVariable Long id,
            @RequestBody UpdateStatutJournalRequest request) {
        return service.updateStatutJournal(id, request.statutId());
    }

    @PostMapping("/{id}/valider")
    public JournalMouvementResponse valider(@PathVariable Long id) {
        return service.valider(id);
    }

    @PostMapping("/{id}/demander-modification")
    public JournalMouvementResponse demanderModification(@PathVariable Long id) {
        return service.demanderModification(id);
    }

    @PostMapping("/{journalId}/scans")
    public DetailJournalResponse scan(
            @PathVariable Long journalId,
            @RequestBody ScanArticleRequest request, @AuthenticationPrincipal Jwt jwt) {
        String matricule = jwt.getSubject();
        return service.scanArticle(journalId, request,matricule);
    }

    @PostMapping("/{journalId}/inventaire/scans")
    public ComptageInventaireResponse scanInventaire(
            @PathVariable Long journalId,
            @RequestBody ScanInventaireRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        String matricule = jwt.getSubject();
        return service.scanArticleInventaire(journalId, request, matricule);
    }

}
