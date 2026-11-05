package com.example.demo.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.demo.entity.Notification;
import com.example.demo.entity.NotificationType;

public interface NotificationRepository extends JpaRepository<Notification, Long> {

    List<Notification> findAllByDestinataireIdOrderByDateCreationDesc(Long destinataireId);

    List<Notification> findAllByDestinataireIdAndLuFalseOrderByDateCreationDesc(Long destinataireId);

    // Demandes de mot de passe : retrouvees par leur lien (/users/reinitialisation/{id}).
    boolean existsByTypeAndUrlCibleAndTraiteeFalse(NotificationType type, String urlCible);

    List<Notification> findAllByTypeAndUrlCibleAndTraiteeFalse(NotificationType type, String urlCible);
}
