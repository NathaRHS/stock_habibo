package com.example.demo.service;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.ParticipantJournalResponse;
import com.example.demo.entity.JournalMouvement;
import com.example.demo.entity.StatutParticipation;
import com.example.demo.entity.StatutjournalMouvement;
import com.example.demo.entity.User;
import com.example.demo.entity.UserJournalMouvement;
import com.example.demo.repository.JournalMouvementRepository;
import com.example.demo.repository.StatutJournalMouvementRepository;
import com.example.demo.repository.UserJournalMouvementRepository;
import com.example.demo.repository.UserRepository;

@Service
@Transactional
public class UserJournalMouvementService {
    private static final String STATUT_EN_COURS = "EN COURS";
    private static final String STATUT_MODIFIE = "MODIFIE";
    private static final String STATUT_EN_ATTENTE = "EN ATTENTE";

    private final UserJournalMouvementRepository participationRepository;
    private final JournalMouvementRepository journalRepository;
    private final UserRepository userRepository;
    private final StatutJournalMouvementRepository statutRepository;

    public UserJournalMouvementService(
            UserJournalMouvementRepository participationRepository,
            JournalMouvementRepository journalRepository,
            UserRepository userRepository,
            StatutJournalMouvementRepository statutRepository) {
        this.participationRepository = participationRepository;
        this.journalRepository = journalRepository;
        this.userRepository = userRepository;
        this.statutRepository = statutRepository;
    }

    public ParticipantJournalResponse ajouterParticipant(Long journalId, String matricule) {
        JournalMouvement journal = trouverJournal(journalId);
        User user = trouverUtilisateur(matricule);
        verifierSessionOuverte(journal);

        UserJournalMouvement participation = participationRepository
                .findByJournalMouvementIdAndUserId(journalId, user.getId())
                .orElseGet(() -> participationRepository.save(
                        new UserJournalMouvement(journal, user)));

        if (participation.getStatutParticipation() == StatutParticipation.TERMINE) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Vous avez deja termine votre participation a cette session");
        }

        return versResponse(participation);
    }

    public ParticipantJournalResponse terminerParticipation(Long journalId, String matricule) {
        JournalMouvement journal = journalRepository.findByIdForUpdate(journalId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Journal de mouvement introuvable : " + journalId));
        User user = trouverUtilisateur(matricule);
        UserJournalMouvement participation = participationRepository
                .findByJournalMouvementIdAndUserId(journalId, user.getId())
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.CONFLICT,
                        "Aucune participation trouvee pour cet utilisateur"));

        if (participation.getStatutParticipation() == StatutParticipation.TERMINE) {
            return versResponse(participation);
        }

        verifierSessionOuverte(journal);

        participation.setStatutParticipation(StatutParticipation.TERMINE);
        participation.setDateFin(LocalDateTime.now());
        participationRepository.saveAndFlush(participation);

        boolean participantActifRestant = participationRepository
                .existsByJournalMouvementIdAndStatutParticipation(
                        journalId,
                        StatutParticipation.EN_COURS);

        if (!participantActifRestant) {
            journal.setStatutJournalMouvement(trouverStatutMetier(STATUT_EN_ATTENTE));
            journalRepository.save(journal);
        }

        return versResponse(participation);
    }

    @Transactional(readOnly = true)
    public List<ParticipantJournalResponse> trouverParticipants(Long journalId) {
        trouverJournal(journalId);
        return participationRepository
                .findAllByJournalMouvementIdOrderByDateDebutAsc(journalId)
                .stream()
                .map(this::versResponse)
                .toList();
    }

    private JournalMouvement trouverJournal(Long journalId) {
        return journalRepository.findById(journalId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Journal de mouvement introuvable : " + journalId));
    }

    private User trouverUtilisateur(String matricule) {
        if (matricule == null || matricule.isBlank()) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Utilisateur non authentifie");
        }
        return userRepository.findByMatricule(matricule)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED,
                        "Utilisateur authentifie introuvable"));
    }

    private void verifierSessionOuverte(JournalMouvement journal) {
        String statut = journal.getStatutJournalMouvement().getNomStatut();
        if (!STATUT_EN_COURS.equals(statut) && !STATUT_MODIFIE.equals(statut)) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "La session n'accepte plus de participants. Statut actuel : " + statut);
        }
    }

    private StatutjournalMouvement trouverStatutMetier(String nomStatut) {
        return statutRepository.findByNomStatut(nomStatut)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.INTERNAL_SERVER_ERROR,
                        "Le statut " + nomStatut + " n'est pas configure"));
    }

    private ParticipantJournalResponse versResponse(UserJournalMouvement participation) {
        User user = participation.getUser();
        return new ParticipantJournalResponse(
                participation.getId(),
                user.getId(),
                user.getUsername(),
                user.getMatricule(),
                participation.getStatutParticipation(),
                participation.getDateDebut(),
                participation.getDateFin());
    }
}
