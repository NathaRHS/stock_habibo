package com.example.demo.service;

import java.time.LocalDateTime;

import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.entity.HistoriqueLignePickingStatut;
import com.example.demo.entity.LignePicking;
import com.example.demo.entity.StatutLignePicking;
import com.example.demo.entity.StatutLignePickingCode;
import com.example.demo.entity.User;
import com.example.demo.repository.HistoriqueLignePickingStatutRepository;
import com.example.demo.repository.LignePickingRepository;
import com.example.demo.repository.StatutLignePickingRepository;
import com.example.demo.repository.UserRepository;

/**
 * Point d'entree unique pour changer le statut d'une ligne de picking.
 * Chaque changement met a jour le statut courant ET insere une ligne dans
 * l'historique, dans la meme transaction.
 */
@Service
public class LignePickingStatutService {

    private final StatutLignePickingRepository statutRepository;
    private final HistoriqueLignePickingStatutRepository historiqueRepository;
    private final LignePickingRepository lignePickingRepository;
    private final UserRepository userRepository;

    public LignePickingStatutService(
            StatutLignePickingRepository statutRepository,
            HistoriqueLignePickingStatutRepository historiqueRepository,
            LignePickingRepository lignePickingRepository,
            UserRepository userRepository) {
        this.statutRepository = statutRepository;
        this.historiqueRepository = historiqueRepository;
        this.lignePickingRepository = lignePickingRepository;
        this.userRepository = userRepository;
    }

    // Premiere ligne d'historique, a appeler juste apres la creation de la ligne.
    @Transactional(propagation = Propagation.MANDATORY)
    public void enregistrerStatutInitial(LignePicking lignePicking) {
        historiqueRepository.save(new HistoriqueLignePickingStatut(
                lignePicking, lignePicking.getStatut(), LocalDateTime.now(), utilisateurCourant()));
    }

    // Change le statut en utilisant l'utilisateur authentifie (JWT) comme auteur.
    @Transactional(propagation = Propagation.MANDATORY)
    public void changerStatut(LignePicking lignePicking, StatutLignePickingCode code) {
        changerStatut(lignePicking, code, utilisateurCourant());
    }

    @Transactional(propagation = Propagation.MANDATORY)
    public void changerStatut(LignePicking lignePicking, StatutLignePickingCode code, User user) {
        StatutLignePicking statut = trouverStatut(code);

        if (lignePicking.getStatut() != null
                && lignePicking.getStatut().getId().equals(statut.getId())) {
            return;
        }

        lignePicking.setStatut(statut);
        lignePickingRepository.save(lignePicking);
        historiqueRepository.save(new HistoriqueLignePickingStatut(
                lignePicking, statut, LocalDateTime.now(), user));
    }

    @Transactional(readOnly = true)
    public StatutLignePicking trouverStatut(StatutLignePickingCode code) {
        return statutRepository.findByNom(code.getNom())
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.INTERNAL_SERVER_ERROR,
                        "Le statut " + code.getNom() + " n'est pas configure"));
    }

    // Renvoie null si aucun utilisateur n'est authentifie (action automatique).
    private User utilisateurCourant() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();

        if (authentication != null && authentication.getPrincipal() instanceof Jwt jwt) {
            return userRepository.findByMatricule(jwt.getSubject()).orElse(null);
        }

        return null;
    }
}
