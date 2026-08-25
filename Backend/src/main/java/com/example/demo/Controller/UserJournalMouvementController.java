package com.example.demo.Controller;

import java.util.List;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.demo.dto.ParticipantJournalResponse;
import com.example.demo.service.UserJournalMouvementService;

@RestController
@RequestMapping("/journaux-mouvements/{journalId}/participants")
public class UserJournalMouvementController {
    private final UserJournalMouvementService service;

    public UserJournalMouvementController(UserJournalMouvementService service) {
        this.service = service;
    }

    @PostMapping
    public ParticipantJournalResponse ajouterParticipant(
            @PathVariable Long journalId,
            @AuthenticationPrincipal Jwt jwt) {
        return service.ajouterParticipant(journalId, jwt.getSubject());
    }

    @PostMapping("/terminer")
    public ParticipantJournalResponse terminerParticipation(
            @PathVariable Long journalId,
            @AuthenticationPrincipal Jwt jwt) {
        return service.terminerParticipation(journalId, jwt.getSubject());
    }

    @GetMapping
    public List<ParticipantJournalResponse> trouverParticipants(@PathVariable Long journalId) {
        return service.trouverParticipants(journalId);
    }
}
