package com.example.demo.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.example.demo.entity.DetailJournal;

@Repository
public interface DetailJournalRepository extends JpaRepository<DetailJournal, Long> {
    List<DetailJournal> findAllByJournalMouvementId(Long idJournal);

    DetailJournal findByJournalMouvementIdAndArticleId(Long journalId, Long articleId);

    @Modifying(flushAutomatically = true,clearAutomatically = true)
    @Query(value = """
                        INSERT INTO t_detail_journal (
                journal_mouvement_id,
                article_id,
                quantite
            )
            VALUES (:journalId,:articleId,:quantite)
            ON DUPLICATE KEY UPDATE
                quantite = quantite + VALUES(quantite);
                        """, nativeQuery = true)
    int ajouterOuIncrementer(@Param("journalId") Long journalId,
            @Param("articleId") Long articleId,
            @Param("quantite") Integer quantite

    );
}
