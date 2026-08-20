package com.example.demo.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.demo.entity.StatutjournalMouvement;

@Repository
public interface StatutJournalMouvementRepository extends JpaRepository<StatutjournalMouvement, Long> {
    Optional<StatutjournalMouvement> findByNomStatut(String nomStatut);
}
