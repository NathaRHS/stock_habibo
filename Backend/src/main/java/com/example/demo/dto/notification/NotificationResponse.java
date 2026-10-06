package com.example.demo.dto.notification;

import java.time.LocalDateTime;

import com.example.demo.entity.NotificationCategorie;
import com.example.demo.entity.NotificationPriorite;
import com.example.demo.entity.NotificationType;

public record NotificationResponse(
        Long id,
        NotificationCategorie categorie,
        NotificationType type,
        NotificationPriorite priorite,
        String titre,
        String message,
        LocalDateTime dateCreation,
        LocalDateTime dateLecture,
        LocalDateTime dateTraitement,
        String urlCible,
        boolean lu,
        boolean traitee,
        Long journalId,
        Long detailJournalId,
        Long emplacementId) {
}
