package com.example.demo.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.example.demo.entity.Emplacement;
import com.example.demo.projection.EmplacementCandidatProjection;

@Repository
public interface EmplacementRepository extends JpaRepository<Emplacement, Long> {
        boolean existsByRackIdAndNumeroEtageAndNomEmplacement(
                        Long rackId, Integer numeroEtage, String nomEmplacement);

        @Query("SELECT MAX(e.numeroEtage) FROM Emplacement e WHERE e.rack.id = :rackId")
        Integer findNumeroEtageMaximumByRackId(@Param("rackId") Long rackId);

        @Query("""
                        SELECT MAX(e.ordreDansEtage)
                        FROM Emplacement e
                        WHERE e.rack.id = :rackId
                          AND e.numeroEtage = :numeroEtage
                        """)
        Integer findOrdreMaximumDansEtage(
                        @Param("rackId") Long rackId,
                        @Param("numeroEtage") Integer numeroEtage);

        @Query(value = """
                        SELECT
                            e.id AS emplacementId,
                            e.nom_emplacement AS nomEmplacement,
                            r.id AS rackId,
                            r.nom_rack AS nomRack,
                            r.ordre AS ordreRack,
                            e.numero_etage AS numeroEtage,
                            e.ordre_dans_etage AS ordreDansEtage,
                            stock.article_id AS articlePresentId,
                            COALESCE(stock.quantite_stock, 0) AS quantitePiecesPresentes,
                            ac.quantite_piece_standard AS quantitePieceStandard,
                            pc.quantite AS capaciteMaxConditionnements
                        FROM t_emplacement e
                        JOIN t_rack r
                            ON r.id = e.rack_id
                        JOIN t_article_conditionnement ac
                            ON ac.id = :articleConditionnementId
                        JOIN t_palette_conditionnement pc
                            ON pc.article_conditionnement_id = ac.id
                        LEFT JOIN v_stock_par_emplacement stock
                            ON stock.emplacement_id = e.id
                        WHERE NOT EXISTS (
                            SELECT 1
                            FROM v_stock_par_emplacement autre_stock
                            WHERE autre_stock.emplacement_id = e.id
                              AND autre_stock.article_id <> ac.article_id
                              AND autre_stock.quantite_stock > 0
                        )
                        ORDER BY
                            r.ordre,
                            e.numero_etage,
                            e.ordre_dans_etage
                        """, nativeQuery = true)
        List<EmplacementCandidatProjection> rechercherEmplacementsCandidats(
                        @Param("articleConditionnementId") Long articleConditionnementId);

        // Emplacement calculStock(Long emplacementId);

        /*
         * SELECT
         * FROM
         * 
         */
}
