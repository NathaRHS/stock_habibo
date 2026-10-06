package com.example.demo.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import jakarta.persistence.LockModeType;

import com.example.demo.entity.JournalMouvement;

@Repository
public interface JournalMouvementRepository extends JpaRepository<JournalMouvement, Long> {
    Optional<JournalMouvement> findByReference(String reference);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select journal from JournalMouvement journal where journal.id = :id")
    Optional<JournalMouvement> findByIdForUpdate(@Param("id") Long id);

    boolean existsByTypeMouvementJournalId(Long typeMouvementJournalId);

    boolean existsByStatutId(Long statutId);

    boolean existsByFournisseurId(Long fournisseurId);

    @Query(value = """
        SELECT journal.id,
       journal.reference,
       mienne.statut_participation AS ma_participation,
       COUNT(toutes.id)                                    AS nb_participants,
       SUM(toutes.statut_participation = 'EN_COURS')       AS nb_en_cours,
       SUM(toutes.statut_participation = 'TERMINE')        AS nb_termines
FROM t_user_journal_mouvement mienne
JOIN t_journal_mouvement journal
     ON journal.id = mienne.journal_mouvement_id
JOIN t_type_mouvement_journal type
     ON type.id = journal.type_mouvement_journal_id
JOIN t_user_journal_mouvement toutes
     ON toutes.journal_mouvement_id = journal.id
WHERE mienne.user_id = 4
  AND mienne.statut_participation <> 'TERMINE'
  AND type.nom_type_mouvement = 'ENTREE'
GROUP BY journal.id, journal.reference, mienne.statut_participation;

                        """, nativeQuery = true)
    JournalMouvement findByParticipantsId(@Param ("userId")Long userId);

}
