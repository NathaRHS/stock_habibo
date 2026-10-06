package com.example.demo.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.demo.entity.Notification;

public interface NotificationRepository extends JpaRepository<Notification, Long> {

    List<Notification> findAllByDestinataireIdOrderByDateCreationDesc(Long destinataireId);

    List<Notification> findAllByDestinataireIdAndLuFalseOrderByDateCreationDesc(Long destinataireId);
}
