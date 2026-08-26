package com.example.demo.repository;

import java.util.List;

import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.Repository;
import org.springframework.data.repository.query.Param;

import com.example.demo.entity.Article;
import com.example.demo.projection.StockParEmplacementProjection;

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
}
