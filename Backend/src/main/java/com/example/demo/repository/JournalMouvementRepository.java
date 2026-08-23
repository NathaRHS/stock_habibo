package com.example.demo.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.demo.entity.JournalMouvement;

@Repository
public interface JournalMouvementRepository extends JpaRepository<JournalMouvement, Long> {
    Optional<JournalMouvement> findByReference(String reference);

    boolean existsByTypeMouvementJournalId(Long typeMouvementJournalId);

    boolean existsByStatutJournalMouvementId(Long statutJournalMouvementId);

    boolean existsByFournisseurId(Long fournisseurId);

}
