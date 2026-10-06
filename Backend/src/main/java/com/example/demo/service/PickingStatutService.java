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

import com.example.demo.entity.HistoriquePickingStatut;
import com.example.demo.entity.JournalMouvement;
import com.example.demo.entity.Picking;
import com.example.demo.entity.Rack;
import com.example.demo.entity.StatutPicking;
import com.example.demo.entity.StatutPickingCode;
import com.example.demo.entity.User;
import com.example.demo.repository.HistoriquePickingStatutRepository;
import com.example.demo.repository.PickingRepository;
import com.example.demo.repository.StatutPickingRepository;
import com.example.demo.repository.UserRepository;

/**
 * Point d'entree unique pour creer un picking et changer son statut.
 * Chaque changement met a jour le statut courant ET insere une ligne dans
 * l'historique, dans la meme transaction.
 */
@Service
public class PickingStatutService {

    private final StatutPickingRepository statutRepository;
    private final HistoriquePickingStatutRepository historiqueRepository;
    private final PickingRepository pickingRepository;
    private final UserRepository userRepository;

    public PickingStatutService(
            StatutPickingRepository statutRepository,
            HistoriquePickingStatutRepository historiqueRepository,
            PickingRepository pickingRepository,
            UserRepository userRepository) {
        this.statutRepository = statutRepository;
        this.historiqueRepository = historiqueRepository;
        this.pickingRepository = pickingRepository;
        this.userRepository = userRepository;
    }

    // Cree un picking au statut GENERE et ecrit sa premiere ligne d'historique.
    @Transactional(propagation = Propagation.MANDATORY)
    public Picking creerPicking(JournalMouvement journal, User user, Rack rackDepart) {
        StatutPicking statutGenere = trouverStatut(StatutPickingCode.GENERE);
        Picking picking = pickingRepository.save(new Picking(journal, user, rackDepart, statutGenere));

        historiqueRepository.save(new HistoriquePickingStatut(
                picking, statutGenere, LocalDateTime.now(), utilisateurCourant()));

        return picking;
    }

    // Change le statut en utilisant l'utilisateur authentifie (JWT) comme auteur.
    @Transactional(propagation = Propagation.MANDATORY)
    public void changerStatut(Picking picking, StatutPickingCode code) {
        changerStatut(picking, code, utilisateurCourant());
    }

    @Transactional(propagation = Propagation.MANDATORY)
    public void changerStatut(Picking picking, StatutPickingCode code, User user) {
        StatutPicking statut = trouverStatut(code);

        if (picking.getStatut() != null
                && picking.getStatut().getId().equals(statut.getId())) {
            return;
        }

        picking.setStatut(statut);
        pickingRepository.save(picking);
        historiqueRepository.save(new HistoriquePickingStatut(
                picking, statut, LocalDateTime.now(), user));
    }

    @Transactional(readOnly = true)
    public StatutPicking trouverStatut(StatutPickingCode code) {
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
