package com.example.demo.repository;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.example.demo.entity.Article;
import com.example.demo.entity.MouvementStock;
import com.example.demo.projection.ActiviteEmplacementProjection;

public interface MouvementStockRepository extends JpaRepository<MouvementStock, Long> {

    // Stock cumule jusqu'a finExclue, plus variation et nombre de mouvements
    // sur [debut, finExclue[. Une ligne par emplacement, meme vide.
    @Query(value = """
            SELECT e.id AS emplacementId,
                   CAST(COALESCE(SUM(CASE WHEN m.date_mouvement < :finExclue
                                          THEN m.quantite_pieces_reelle * t.sens END), 0)
                        AS SIGNED) AS stockFin,
                   CAST(COALESCE(SUM(CASE WHEN m.date_mouvement >= :debut
                                           AND m.date_mouvement < :finExclue
                                          THEN m.quantite_pieces_reelle * t.sens END), 0)
                        AS SIGNED) AS variation,
                   COUNT(CASE WHEN m.date_mouvement >= :debut
                               AND m.date_mouvement < :finExclue
                              THEN m.id END) AS nbMouvements
            FROM t_emplacement e
            LEFT JOIN t_mouvement_stock m ON m.emplacement_id = e.id
            LEFT JOIN t_type_mouvement t ON t.id = m.type_mouvement_id
            GROUP BY e.id
            """, nativeQuery = true)
    List<ActiviteEmplacementProjection> calculerActiviteParEmplacement(
            @Param("debut") LocalDateTime debut,
            @Param("finExclue") LocalDateTime finExclue);

    List<MouvementStock> findAllByTypeMouvementNomTypeMouvement(String nomTypeMouvement);

    boolean existsByDetailJournalId(Long detailJournalId);

    boolean existsByDetailJournalIdAndEmplacementId(
            Long detailJournalId,
            Long emplacementId);

    @Query(value = """
            SELECT COUNT(*)
            FROM (
                SELECT mouvement.emplacement_id
                FROM t_mouvement_stock mouvement
                JOIN t_type_mouvement type_mouvement
                    ON type_mouvement.id = mouvement.type_mouvement_id
                WHERE mouvement.emplacement_id = :emplacementId
                GROUP BY mouvement.emplacement_id
                HAVING SUM(mouvement.quantite_pieces_reelle * type_mouvement.sens) > 0
            ) stock_actif
            """, nativeQuery = true)
    long countStockActifByEmplacementId(@Param("emplacementId") Long emplacementId);

    @Query(value = """
            SELECT COALESCE(
                SUM(mouvement.nombre_conditionnements * type_mouvement.sens),
                0
            )
            FROM t_mouvement_stock mouvement
            JOIN t_type_mouvement type_mouvement
                ON type_mouvement.id = mouvement.type_mouvement_id
            WHERE mouvement.emplacement_id = :emplacementId
            """, nativeQuery = true)
    long calculerNombreConditionnementsPresents(
            @Param("emplacementId") Long emplacementId);

    @Query(value = """
            SELECT article.*
            FROM t_article article
            WHERE article.id IN (
                SELECT detail.article_id
                FROM t_mouvement_stock mouvement
                JOIN t_detail_journal detail
                    ON detail.id = mouvement.detail_journal_id
                JOIN t_type_mouvement type_mouvement
                    ON type_mouvement.id = mouvement.type_mouvement_id
                WHERE mouvement.emplacement_id = :emplacementId
                GROUP BY detail.article_id
                HAVING SUM(
                    mouvement.quantite_pieces_reelle * type_mouvement.sens
                ) > 0
            )
            """, nativeQuery = true)
    List<Article> findArticlesPresentsByEmplacementId(
            @Param("emplacementId") Long emplacementId);

}
