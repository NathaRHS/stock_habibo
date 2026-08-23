package com.example.demo.repository;

import java.util.List;

import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.Repository;
import org.springframework.data.repository.query.Param;

import com.example.demo.entity.Article;
import com.example.demo.projection.StockParEtageProjection;

public interface StockRepository extends Repository<Article, Long> {

    @Query(value = """
            SELECT
                article_id AS articleId,
                etage_id AS etageId,
                quantite_stock AS quantiteStock
            FROM v_stock_par_etage
            ORDER BY article_id, etage_id
            """, nativeQuery = true)
    List<StockParEtageProjection> findAllStocksParEtage();

    @Query(value = """
            SELECT
                article_id AS articleId,
                etage_id AS etageId,
                quantite_stock AS quantiteStock
            FROM v_stock_par_etage
            WHERE article_id = :articleId
            ORDER BY etage_id
            """, nativeQuery = true)
    List<StockParEtageProjection> findStocksParEtageByArticleId(@Param("articleId") Long articleId);
}
