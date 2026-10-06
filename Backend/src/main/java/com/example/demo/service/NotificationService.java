package com.example.demo.service;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.notification.NotificationResponse;
import com.example.demo.entity.DetailJournal;
import com.example.demo.entity.Emplacement;
import com.example.demo.entity.JournalMouvement;
import com.example.demo.entity.Notification;
import com.example.demo.entity.NotificationCategorie;
import com.example.demo.entity.NotificationPriorite;
import com.example.demo.entity.NotificationType;
import com.example.demo.entity.User;
import com.example.demo.repository.NotificationRepository;

@Service
public class NotificationService {

    private final NotificationRepository notificationRepository;

    public NotificationService(NotificationRepository notificationRepository) {
        this.notificationRepository = notificationRepository;
    }

    @Transactional
    public NotificationResponse creer(NotificationCategorie categorie,
            NotificationType type,
            NotificationPriorite priorite,
            User destinataire,
            JournalMouvement journal,
            DetailJournal detailJournal,
            Emplacement emplacement) {

        if (categorie == null || type == null || priorite == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "La categorie, le type et la priorite sont obligatoires");
        }
        if (destinataire == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Le destinataire de la notification est obligatoire");
        }

        String referenceJournal = journal == null ? null : journal.getReference();
        String nomArticle = detailJournal == null || detailJournal.getArticle() == null
                ? null
                : detailJournal.getArticle().getNomArticle();

        String titre;
        String message;
        String urlCible = null;

        switch (type) {
            case ENTREE_A_AFFECTER -> {
                titre = "Affectation d'entree requise";
                message = referenceJournal == null
                        ? "Une entree attend une affectation."
                        : "Le journal " + referenceJournal + " attend une affectation.";
                if (journal != null) {
                    urlCible = "/journaux-mouvements/" + journal.getId() + "/affectation-stock";
                }
            }
            case ENTREE_ANOMALIE -> {
                titre = "Anomalie sur une entree";
                message = nomArticle == null
                        ? "Une anomalie a ete detectee sur une entree."
                        : "Une anomalie concerne l'article " + nomArticle + ".";
                if (journal != null) {
                    urlCible = "/journaux-mouvements/" + journal.getId() + "/affectation-stock";
                }
            }
            case SORTIE_A_CONFIRMER -> {
                titre = "Sortie a confirmer";
                message = referenceJournal == null
                        ? "Une sortie attend votre confirmation."
                        : "La sortie " + referenceJournal + " attend votre confirmation.";
                if (journal != null) {
                    urlCible = "/sortie/" + journal.getId();
                }
            }
            case SORTIE_ECART -> {
                titre = "Ecart sur une sortie";
                message = nomArticle == null
                        ? "Un ecart a ete detecte sur une sortie."
                        : "Un ecart concerne l'article " + nomArticle + ".";
                if (journal != null) {
                    urlCible = "/sortie/" + journal.getId();
                }
            }
            case INVENTAIRE_A_REALISER -> {
                titre = "Inventaire a realiser";
                message = "Un inventaire attend votre intervention.";
                if (journal != null) {
                    urlCible = "/inventaires/" + journal.getId();
                }
            }
            case INVENTAIRE_ECART -> {
                titre = "Ecart d'inventaire";
                message = emplacement == null
                        ? "Un ecart a ete detecte pendant un inventaire."
                        : "Un ecart a ete detecte sur l'emplacement "
                                + emplacement.getNomEmplacement() + ".";
                if (journal != null) {
                    urlCible = "/inventaires/" + journal.getId();
                }
            }
            default -> throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Type de notification non gere");
        }

        Notification notification = new Notification(
                categorie, type, priorite, titre, message, urlCible, destinataire);
        notification.setJournal(journal);
        notification.setDetailJournal(detailJournal);
        notification.setEmplacement(emplacement);

        return versResponse(notificationRepository.save(notification));
    }

    @Transactional(readOnly = true)
    public List<NotificationResponse> trouverToutes(User destinataire) {
        verifierDestinataire(destinataire);
        return notificationRepository
                .findAllByDestinataireIdOrderByDateCreationDesc(destinataire.getId())
                .stream()
                .map(this::versResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<NotificationResponse> trouverNonLues(User destinataire) {
        verifierDestinataire(destinataire);
        return notificationRepository
                .findAllByDestinataireIdAndLuFalseOrderByDateCreationDesc(destinataire.getId())
                .stream()
                .map(this::versResponse)
                .toList();
    }

    @Transactional
    public NotificationResponse marquerCommeLue(Long notificationId, User destinataire) {
        Notification notification = trouverPourDestinataire(notificationId, destinataire);
        if (!notification.isLu()) {
            notification.setLu(true);
            notification.setDateLecture(LocalDateTime.now());
        }
        return versResponse(notificationRepository.save(notification));
    }

    @Transactional
    public NotificationResponse marquerCommeTraitee(Long notificationId, User destinataire) {
        Notification notification = trouverPourDestinataire(notificationId, destinataire);
        notification.setTraitee(true);
        notification.setLu(true);
        if (notification.getDateLecture() == null) {
            notification.setDateLecture(LocalDateTime.now());
        }
        notification.setDateTraitement(LocalDateTime.now());
        return versResponse(notificationRepository.save(notification));
    }

    @Transactional
    public void marquerToutesCommeLues(User destinataire) {
        verifierDestinataire(destinataire);
        List<Notification> notifications = notificationRepository
                .findAllByDestinataireIdAndLuFalseOrderByDateCreationDesc(destinataire.getId());
        LocalDateTime maintenant = LocalDateTime.now();
        notifications.forEach(notification -> {
            notification.setLu(true);
            notification.setDateLecture(maintenant);
        });
        notificationRepository.saveAll(notifications);
    }

    private Notification trouverPourDestinataire(Long notificationId, User destinataire) {
        if (notificationId == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "L'identifiant de la notification est obligatoire");
        }
        verifierDestinataire(destinataire);
        Notification notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                        "Notification introuvable"));
        if (!notification.getDestinataire().getId().equals(destinataire.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "Cette notification ne vous est pas destinee");
        }
        return notification;
    }

    private void verifierDestinataire(User destinataire) {
        if (destinataire == null || destinataire.getId() == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED,
                    "Utilisateur authentifie introuvable");
        }
    }

    private NotificationResponse versResponse(Notification notification) {
        return new NotificationResponse(
                notification.getId(),
                notification.getCategorie(),
                notification.getType(),
                notification.getPriorite(),
                notification.getTitre(),
                notification.getMessage(),
                notification.getDateCreation(),
                notification.getDateLecture(),
                notification.getDateTraitement(),
                notification.getUrlCible(),
                notification.isLu(),
                notification.isTraitee(),
                notification.getJournal() == null ? null : notification.getJournal().getId(),
                notification.getDetailJournal() == null ? null : notification.getDetailJournal().getId(),
                notification.getEmplacement() == null ? null : notification.getEmplacement().getId());
    }
}
