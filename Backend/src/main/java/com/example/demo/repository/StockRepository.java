package com.example.demo.repository;

import java.util.List;

import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.Repository;
import org.springframework.data.repository.query.Param;

import com.example.demo.entity.Article;
import com.example.demo.projection.StockParEmplacementProjection;
import com.example.demo.projection.StockProjection;

public interface StockRepository extends Repository<Article, Long> {

        @Query(value = """
                        SELECT
                            article_id AS articleId,
                            emplacement_id AS emplacementId,
                            quantite_stock AS quantiteStock
                        FROM v_stock_par_emplacement
                        ORDER BY article_id, emplacement_id
                        """, nativeQuery = true)
        List<StockParEmplacementProjection> findAllStocksParEmplacement();

        @Query(value = """
                        SELECT
                            article_id AS articleId,
                            emplacement_id AS emplacementId,
                            quantite_stock AS quantiteStock
                        FROM v_stock_par_emplacement
                        WHERE article_id = :articleId
                        ORDER BY emplacement_id
                        """, nativeQuery = true)
        List<StockParEmplacementProjection> findStocksParEmplacementByArticleId(@Param("articleId") Long articleId);

        @Query(value = """
                                   SELECT
                            vs.article_id AS articleId,
                            vs.emplacement_id AS emplacementId,
                            vs.quantite_stock AS quantiteStock,
                            detail.dlc,
                            mouvement.date_mouvement
                        FROM v_stock_par_emplacement vs
                        JOIN t_mouvement_stock mouvement
                            ON mouvement.emplacement_id = vs.emplacement_id
                        JOIN t_detail_journal detail
                            ON detail.id = mouvement.detail_journal_id
                            AND detail.article_id = vs.article_id
                        WHERE vs.article_id = :articleId
                          AND detail.dlc IS NOT NULL
                        ORDER BY
                            detail.dlc ASC,
                            mouvement.date_mouvement ASC,
                            vs.emplacement_id ASC
                                    """, nativeQuery = true)
        List<StockProjection> findBestArticle(@Param("articleId") Long articleId);

        /*
         * SELECT
         * article_id AS articleId,
         * emplacement_id AS emplacementId,
         * quantite_stock AS quantiteStock,
         * detail.dlc
         * FROM v_stock_par_emplacement
         * JOIN t_detail_journal detail ON detail.article_id = articleId
         * WHERE article_id = :articleId
         * ORDER BY emplacement_id , detail.dlc ASC
         * 
         * 
         * 
         * //test
         * 
         * 
         * SELECT
         * vs.article_id AS articleId,
         * vs.emplacement_id AS emplacementId,
         * vs.quantite_stock AS quantiteStock,
         * detail.dlc,
         * mouvement.date_mouvement
         * FROM v_stock_par_emplacement vs
         * JOIN t_mouvement_stock mouvement
         * ON mouvement.emplacement_id = vs.emplacement_id
         * JOIN t_detail_journal detail
         * ON detail.id = mouvement.detail_journal_id
         * AND detail.article_id = vs.article_id
         * WHERE vs.article_id = :articleId
         * AND detail.dlc IS NOT NULL
         * ORDER BY
         * detail.dlc ASC,
         * mouvement.date_mouvement ASC,
         * vs.emplacement_id ASC
         * 
         * 
         * SELECT
         * vs.article_id AS articleId,
         * vs.emplacement_id AS emplacementId,
         * vs.quantite_stock AS quantiteStock,
         * detail.dlc,
         * mouvement.date_mouvement
         * FROM v_stock_par_emplacement vs
         * JOIN t_mouvement_stock mouvement
         * ON mouvement.emplacement_id = vs.emplacement_id
         * JOIN t_detail_journal detail
         * ON detail.id = mouvement.detail_journal_id
         * AND detail.article_id = vs.article_id
         * WHERE vs.article_id = 1
         * AND detail.dlc IS NOT NULL
         * ORDER BY
         * mouvement.date_mouvement ASC,
         * detail.dlc ASC,
         * vs.emplacement_id ASC
         */

        @Query(value = """
                        SELECT COALESCE(MAX(quantite_stock), 0)
                        FROM v_stock_par_emplacement
                        WHERE article_id = :articleId
                          AND emplacement_id = :emplacementId
                        """, nativeQuery = true)
        Integer trouverQuantiteTheorique(
                        @Param("articleId") Long articleId,
                        @Param("emplacementId") Long emplacementId);

}
