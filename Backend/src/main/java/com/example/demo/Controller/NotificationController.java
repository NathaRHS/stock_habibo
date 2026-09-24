package com.example.demo.Controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.notification.NotificationResponse;
import com.example.demo.entity.User;
import com.example.demo.repository.UserRepository;
import com.example.demo.service.NotificationService;

@RestController
@RequestMapping("/notifications")
public class NotificationController {

    private final NotificationService notificationService;
    private final UserRepository userRepository;

    public NotificationController(NotificationService notificationService, UserRepository userRepository) {
        this.notificationService = notificationService;
        this.userRepository = userRepository;
    }

    @GetMapping
    public List<NotificationResponse> trouverToutes(@AuthenticationPrincipal Jwt jwt) {
        return notificationService.trouverToutes(utilisateurConnecte(jwt));
    }

    @GetMapping("/non-lues")
    public List<NotificationResponse> trouverNonLues(@AuthenticationPrincipal Jwt jwt) {
        return notificationService.trouverNonLues(utilisateurConnecte(jwt));
    }

    @PatchMapping("/{id}/lue")
    public NotificationResponse marquerLue(@PathVariable Long id, @AuthenticationPrincipal Jwt jwt) {
        return notificationService.marquerCommeLue(id, utilisateurConnecte(jwt));
    }

    @PatchMapping("/{id}/traitee")
    public NotificationResponse marquerTraitee(@PathVariable Long id, @AuthenticationPrincipal Jwt jwt) {
        return notificationService.marquerCommeTraitee(id, utilisateurConnecte(jwt));
    }

    @PatchMapping("/toutes-lues")
    public ResponseEntity<Void> marquerToutesLues(@AuthenticationPrincipal Jwt jwt) {
        notificationService.marquerToutesCommeLues(utilisateurConnecte(jwt));
        return ResponseEntity.noContent().build();
    }

    private User utilisateurConnecte(Jwt jwt) {
        return userRepository.findByMatricule(jwt.getSubject()).orElseThrow(() ->
                new ResponseStatusException(HttpStatus.UNAUTHORIZED,
                        "Utilisateur authentifie introuvable"));
    }
}
