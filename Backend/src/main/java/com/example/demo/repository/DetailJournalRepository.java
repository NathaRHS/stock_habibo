package com.example.demo.repository;

import java.util.List;
import java.util.Optional;
import java.time.LocalDate;

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

    Optional<DetailJournal> findByArticleIdAndDlcAndDlv(
            Long articleId,
            LocalDate dlc,
            LocalDate dlv);

    @Modifying(flushAutomatically = true,clearAutomatically = true)
    @Query(value = """
                        INSERT INTO t_detail_journal (
                journal_mouvement_id,
                article_id,
                quantite,
                quantite_conditionnement,
                dlc,
                dlv
            )
            VALUES (
                :journalId,
                :articleId,
                :quantite,
                CEIL(:quantite / :quantitePieceStandard),
                :dlc,
                :dlv
            )
            ON DUPLICATE KEY UPDATE
                quantite_conditionnement = CEIL(
                    (quantite + VALUES(quantite)) / :quantitePieceStandard
                ),
                quantite = quantite + VALUES(quantite)
                        """, nativeQuery = true)
    int ajouterOuIncrementer(@Param("journalId") Long journalId,
            @Param("articleId") Long articleId,
            @Param("quantite") Integer quantite,
            @Param("quantitePieceStandard") Integer quantitePieceStandard,
            @Param("dlc") LocalDate dlc,
            @Param("dlv") LocalDate dlv);


                // Ajoute une reception en gardant le nombre de conditionnements tel quel :
    // deux boites incompletes restent deux boites (pas de CEIL sur la somme).
    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query(value = """
            INSERT INTO t_detail_journal (
                journal_mouvement_id,
                article_id,
                quantite,
                quantite_conditionnement,
                dlc,
                dlv
            )
            VALUES (
                :journalId,
                :articleId,
                :quantite,
                :quantiteConditionnement,
                :dlc,
                :dlv
            )
            ON DUPLICATE KEY UPDATE
                quantite = quantite + VALUES(quantite),
                quantite_conditionnement =
                    quantite_conditionnement + VALUES(quantite_conditionnement)
            """, nativeQuery = true)
    int ajouterOuIncrementerPrecis(
            @Param("journalId") Long journalId,
            @Param("articleId") Long articleId,
            @Param("quantite") Integer quantite,
            @Param("quantiteConditionnement") Integer quantiteConditionnement,
            @Param("dlc") LocalDate dlc,
            @Param("dlv") LocalDate dlv);

}
