package com.example.demo.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.demo.entity.HistoriqueJournalMouvementStatut;

@Repository
public interface HistoriqueJournalMouvementStatutRepository
        extends JpaRepository<HistoriqueJournalMouvementStatut, Long> {

    List<HistoriqueJournalMouvementStatut> findByJournalMouvementIdOrderByDateChangementAsc(Long journalId);
}
