package com.example.demo.repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.example.demo.entity.ComptageInventaire;

public interface ComptageInventaireRepository extends JpaRepository<ComptageInventaire, Long> {

    Optional<ComptageInventaire> findByDetailJournalIdAndEmplacementId(
            Long detailJournalId,
            Long emplacementId);

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query(value = """
            INSERT INTO t_comptage_inventaire (
                detail_journal_id,
                emplacement_id,
                quantite_comptee,
                date_comptage
            )
            VALUES (
                :detailJournalId,
                :emplacementId,
                :quantiteComptee,
                :dateComptage
            )
            ON DUPLICATE KEY UPDATE
                quantite_comptee = quantite_comptee + VALUES(quantite_comptee),
                date_comptage = VALUES(date_comptage)
            """, nativeQuery = true)
    int ajouterOuIncrementer(
            @Param("detailJournalId") Long detailJournalId,
            @Param("emplacementId") Long emplacementId,
            @Param("quantiteComptee") Integer quantiteComptee,
            @Param("dateComptage") LocalDateTime dateComptage);

    List<ComptageInventaire> findAllByDetailJournalJournalMouvementId(
            Long journalId);
}
