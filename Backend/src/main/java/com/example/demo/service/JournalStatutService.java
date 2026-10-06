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

import com.example.demo.entity.HistoriqueJournalMouvementStatut;
import com.example.demo.entity.JournalMouvement;
import com.example.demo.entity.StatutJournalMouvement;
import com.example.demo.entity.StatutJournalMouvementCode;
import com.example.demo.entity.User;
import com.example.demo.repository.HistoriqueJournalMouvementStatutRepository;
import com.example.demo.repository.JournalMouvementRepository;
import com.example.demo.repository.StatutJournalMouvementRepository;
import com.example.demo.repository.UserRepository;

/**
 * Point d'entree unique pour changer le statut d'un journal de mouvement.
 * Chaque changement met a jour le statut courant ET insere une ligne dans
 * l'historique, dans la meme transaction.
 */
@Service
public class JournalStatutService {

    private final StatutJournalMouvementRepository statutRepository;
    private final HistoriqueJournalMouvementStatutRepository historiqueRepository;
    private final JournalMouvementRepository journalRepository;
    private final UserRepository userRepository;

    public JournalStatutService(
            StatutJournalMouvementRepository statutRepository,
            HistoriqueJournalMouvementStatutRepository historiqueRepository,
            JournalMouvementRepository journalRepository,
            UserRepository userRepository) {
        this.statutRepository = statutRepository;
        this.historiqueRepository = historiqueRepository;
        this.journalRepository = journalRepository;
        this.userRepository = userRepository;
    }

    // Change le statut en utilisant l'utilisateur authentifie (JWT) comme auteur.
    @Transactional(propagation = Propagation.MANDATORY)
    public void changerStatut(JournalMouvement journal, StatutJournalMouvementCode code) {
        changerStatut(journal, code, utilisateurCourant());
    }

    @Transactional(propagation = Propagation.MANDATORY)
    public void changerStatut(JournalMouvement journal, StatutJournalMouvementCode code, User user) {
        StatutJournalMouvement statut = trouverStatut(code);

        if (journal.getStatut() != null
                && journal.getStatut().getId().equals(statut.getId())) {
            return;
        }

        journal.setStatut(statut);
        journalRepository.save(journal);
        historiqueRepository.save(new HistoriqueJournalMouvementStatut(
                journal, statut, LocalDateTime.now(), user));
    }

    // Premiere ligne d'historique, a appeler juste apres la creation du journal.
    @Transactional(propagation = Propagation.MANDATORY)
    public void enregistrerStatutInitial(JournalMouvement journal) {
        historiqueRepository.save(new HistoriqueJournalMouvementStatut(
                journal, journal.getStatut(), LocalDateTime.now(), utilisateurCourant()));
    }

    @Transactional(readOnly = true)
    public StatutJournalMouvement trouverStatut(StatutJournalMouvementCode code) {
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
