package com.example.demo.Controller;

import java.time.LocalDate;
import java.util.List;

import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.example.demo.dto.journaluser.ActivitePageResponse;
import com.example.demo.dto.journaluser.ActiviteResponse;
import com.example.demo.dto.journaluser.TypeEvenementResponse;
import com.example.demo.service.JournalUserService;

/**
 * Journal d'activite des utilisateurs.
 * Aucune route d'ecriture : les lignes sont creees par le serveur, jamais par
 * le client.
 */
@RestController
@RequestMapping("/journal-user")
public class JournalUserController {

    private final JournalUserService journalUserService;

    public JournalUserController(JournalUserService journalUserService) {
        this.journalUserService = journalUserService;
    }

    // Derniers evenements, pour le panneau "Activites" (tout utilisateur connecte).
    @GetMapping("/recentes")
    public List<ActiviteResponse> recentes(@RequestParam(defaultValue = "6") int limite) {
        return journalUserService.recentes(limite);
    }

    // Liste des types, pour le filtre de la page (ADMIN, voir SecurityConfig).
    @GetMapping("/types")
    public List<TypeEvenementResponse> types() {
        return journalUserService.types();
    }

    // Recherche avec filtres et pagination (ADMIN, voir SecurityConfig).
    @GetMapping
    public ActivitePageResponse rechercher(
            @RequestParam(required = false) Long userId,
            @RequestParam(required = false) String type,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate depuis,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate jusqua,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int taille) {
        return journalUserService.rechercher(userId, type, depuis, jusqua, page, taille);
    }
}
