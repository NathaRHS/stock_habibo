package com.example.demo.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.demo.entity.StatutParticipation;
import com.example.demo.entity.UserJournalMouvement;

@Repository
public interface UserJournalMouvementRepository extends JpaRepository<UserJournalMouvement, Long> {
    Optional<UserJournalMouvement> findByJournalMouvementIdAndUserId(Long journalId, Long userId);

    List<UserJournalMouvement> findAllByJournalMouvementIdOrderByDateDebutAsc(Long journalId);

    boolean existsByJournalMouvementIdAndStatutParticipation(
            Long journalId,
            StatutParticipation statutParticipation);
}
