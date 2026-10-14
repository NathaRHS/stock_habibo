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

    // Liste de base de l'entrepot : c'est l'application qui en tire le stock, les
    // variations et le detail de chaque emplacement.
    //
    // - une ligne SOLDE_INITIAL par (emplacement, article) : le stock juste avant
    //   la periode (tous les mouvements anterieurs a :debut, sans les lister) ;
    // - une ligne par mouvement de la periode [debut, finExclue[, avec sa
    //   quantite signee (entree +, sortie -).
    //
    // Stock a la fin de la periode = somme des quantites de toutes les lignes.
    // Les mouvements en reserve n'ont pas d'emplacement : ils sont exclus.
    // Le solde initial passe avant les mouvements (son id est NULL).
    @Query(value = """
            SELECT m.emplacement_id AS emplacementId,
                   a.id AS articleId,
                   a.nom_article AS nomArticle,
                   CAST(:debut AS DATETIME(6)) AS dateMouvement,
                   'SOLDE_INITIAL' AS typeMouvement,
                   CAST(SUM(m.quantite_pieces_reelle * t.sens) AS SIGNED) AS quantite,
                   CAST(NULL AS CHAR) AS journalReference,
                   CAST(NULL AS CHAR) AS matricule,
                   CAST(NULL AS SIGNED) AS id
            FROM t_mouvement_stock m
            JOIN t_type_mouvement t ON t.id = m.type_mouvement_id
            JOIN t_article_conditionnement c ON c.id = m.conditionnement_id
            JOIN t_article a ON a.id = c.article_id
            WHERE m.emplacement_id IS NOT NULL
              AND m.date_mouvement < :debut
            GROUP BY m.emplacement_id, a.id, a.nom_article
            HAVING SUM(m.quantite_pieces_reelle * t.sens) <> 0

            UNION ALL

            SELECT m.emplacement_id,
                   a.id,
                   a.nom_article,
                   m.date_mouvement,
                   t.nom_type_mouvement,
                   CAST(m.quantite_pieces_reelle * t.sens AS SIGNED),
                   j.reference,
                   u.matricule,
                   m.id
            FROM t_mouvement_stock m
            JOIN t_type_mouvement t ON t.id = m.type_mouvement_id
            JOIN t_article_conditionnement c ON c.id = m.conditionnement_id
            JOIN t_article a ON a.id = c.article_id
            JOIN t_detail_journal d ON d.id = m.detail_journal_id
            JOIN t_journal_mouvement j ON j.id = d.journal_mouvement_id
            LEFT JOIN t_user u ON u.id = m.user_id
            WHERE m.emplacement_id IS NOT NULL
              AND m.date_mouvement >= :debut
              AND m.date_mouvement < :finExclue

            ORDER BY emplacementId, dateMouvement, id
            """, nativeQuery = true)
    List<ActiviteEmplacementProjection> listerActivite(
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
