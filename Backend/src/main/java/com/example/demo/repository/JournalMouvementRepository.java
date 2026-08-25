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

    boolean existsByStatutJournalMouvementId(Long statutJournalMouvementId);

    boolean existsByFournisseurId(Long fournisseurId);

   


}
