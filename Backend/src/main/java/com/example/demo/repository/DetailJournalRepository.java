package com.example.demo.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.demo.entity.DetailJournal;

@Repository
public interface DetailJournalRepository extends JpaRepository<DetailJournal, Long> {
    List<DetailJournal> findAllByJournalMouvementId(Long idJournal);

    DetailJournal findByJournalMouvementIdAndArticleId(Long journalId, Long articleId);
}
