package com.example.demo.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.demo.entity.StatutJournalMouvement;

@Repository
public interface StatutJournalMouvementRepository extends JpaRepository<StatutJournalMouvement, Long> {
    Optional<StatutJournalMouvement> findByNom(String nom);
}
