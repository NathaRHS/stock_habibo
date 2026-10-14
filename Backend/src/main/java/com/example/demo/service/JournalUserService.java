package com.example.demo.service;

import java.time.LocalDate;
import java.util.Arrays;
import java.util.List;

import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.journaluser.ActivitePageResponse;
import com.example.demo.dto.journaluser.ActiviteResponse;
import com.example.demo.dto.journaluser.TypeEvenementResponse;
import com.example.demo.entity.CibleEvenement;
import com.example.demo.entity.JournalUser;
import com.example.demo.entity.TypeEvenementUser;
import com.example.demo.entity.User;
import com.example.demo.repository.JournalUserRepository;
import com.example.demo.repository.UserRepository;

/**
 * Le "cahier de bord" : enregistre qui a fait quoi, et quand.
 *
 * L'utilisateur est lu dans le jeton JWT de la requete en cours, jamais envoye
 * par le client. La date est celle du serveur.
 */
@Service
public class JournalUserService {

    private static final int LONGUEUR_MAX_DETAILS = 500;
    private static final int LONGUEUR_MAX_MATRICULE = 100;
    private static final String ACTEUR_SYSTEME = "SYSTEME";

    private final JournalUserRepository journalUserRepository;
    private final UserRepository userRepository;

    public JournalUserService(
            JournalUserRepository journalUserRepository,
            UserRepository userRepository) {
        this.journalUserRepository = journalUserRepository;
        this.userRepository = userRepository;
    }

    // ------------------------------------------------------------------
    // Ecriture
    // ------------------------------------------------------------------

    /**
     * Enregistre une action de l'utilisateur authentifie. S'execute dans la
     * transaction de l'appelant : si l'action est annulee, la ligne l'est aussi.
     */
    @Transactional
    public void enregistrer(
            TypeEvenementUser type,
            CibleEvenement cible,
            Long cibleId,
            String details) {
        enregistrerPour(null, type, cible, cibleId, details);
    }

    /**
     * Meme chose avec un acteur connu (connexion : le jeton n'existe pas encore).
     * Si l'acteur est null, on prend celui du jeton ; sans jeton, c'est le systeme.
     */
    @Transactional
    public void enregistrerPour(
            User acteur,
            TypeEvenementUser type,
            CibleEvenement cible,
            Long cibleId,
            String details) {
        User utilisateur = acteur != null ? acteur : utilisateurCourant();
        String matricule = utilisateur == null ? ACTEUR_SYSTEME : null;

        journalUserRepository.save(new JournalUser(
                utilisateur, matricule, type, cible, cibleId, tronquer(details, LONGUEUR_MAX_DETAILS)));
    }

    /**
     * Connexion echouee. Dans sa propre transaction : l'action a echoue, mais la
     * trace doit rester.
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void enregistrerEchecConnexion(String matriculeSaisi, String details) {
        String matricule = matriculeSaisi == null || matriculeSaisi.isBlank()
                ? "(vide)"
                : tronquer(matriculeSaisi.trim(), LONGUEUR_MAX_MATRICULE);

        journalUserRepository.save(new JournalUser(
                null,
                matricule,
                TypeEvenementUser.CONNEXION_ECHOUEE,
                null,
                null,
                tronquer(details, LONGUEUR_MAX_DETAILS)));
    }

    // ------------------------------------------------------------------
    // Lecture
    // ------------------------------------------------------------------

    @Transactional(readOnly = true)
    public List<ActiviteResponse> recentes(int limite) {
        int taille = Math.max(1, Math.min(limite, 50));
        return journalUserRepository
                .rechercher(null, null, null, null, PageRequest.of(0, taille))
                .stream()
                .map(this::versResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public ActivitePageResponse rechercher(
            Long userId,
            String type,
            LocalDate depuis,
            LocalDate jusqua,
            int page,
            int taille) {
        TypeEvenementUser typeFiltre = convertirType(type);
        int numero = Math.max(0, page);
        int nombre = Math.max(1, Math.min(taille, 100));

        var debut = depuis == null ? null : depuis.atStartOfDay();
        // Le jour de fin est inclus : on s'arrete au debut du lendemain.
        var fin = jusqua == null ? null : jusqua.plusDays(1).atStartOfDay();

        List<ActiviteResponse> elements = journalUserRepository
                .rechercher(userId, typeFiltre, debut, fin, PageRequest.of(numero, nombre))
                .stream()
                .map(this::versResponse)
                .toList();

        long total = journalUserRepository.compter(userId, typeFiltre, debut, fin);
        return new ActivitePageResponse(elements, total, numero, nombre);
    }

    public List<TypeEvenementResponse> types() {
        return Arrays.stream(TypeEvenementUser.values())
                .map(type -> new TypeEvenementResponse(type.name(), type.getLibelle()))
                .toList();
    }

    // ------------------------------------------------------------------
    // Outils
    // ------------------------------------------------------------------

    private ActiviteResponse versResponse(JournalUser ligne) {
        User user = ligne.getUser();

        String matricule = user != null ? user.getMatricule() : ligne.getMatriculeSaisi();
        String nom = user != null && user.getUsername() != null && !user.getUsername().isBlank()
                ? user.getUsername()
                : (matricule != null ? matricule : "Système");

        String acteur = matricule != null ? matricule : nom;
        String suite = ligne.getDetails() == null || ligne.getDetails().isBlank()
                ? ""
                : " · " + ligne.getDetails();
        String texte = acteur + " " + ligne.getType().getLibelle() + suite;

        return new ActiviteResponse(
                ligne.getId(),
                user != null ? user.getId() : null,
                nom,
                matricule,
                ligne.getType().name(),
                ligne.getType().getLibelle(),
                ligne.getCibleType() != null ? ligne.getCibleType().name() : null,
                ligne.getCibleId(),
                ligne.getDetails(),
                texte,
                ligne.getDateEvenement());
    }

    private TypeEvenementUser convertirType(String type) {
        if (type == null || type.isBlank()) {
            return null;
        }
        try {
            return TypeEvenementUser.valueOf(type.trim());
        } catch (IllegalArgumentException exception) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Type d'evenement inconnu : " + type);
        }
    }

    // Renvoie null si aucun utilisateur n'est authentifie (action automatique).
    private User utilisateurCourant() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();

        if (authentication != null && authentication.getPrincipal() instanceof Jwt jwt) {
            return userRepository.findByMatricule(jwt.getSubject()).orElse(null);
        }

        return null;
    }

    private String tronquer(String texte, int longueurMax) {
        if (texte == null) {
            return null;
        }
        String nettoye = texte.trim();
        if (nettoye.isEmpty()) {
            return null;
        }
        return nettoye.length() <= longueurMax ? nettoye : nettoye.substring(0, longueurMax);
    }
}
