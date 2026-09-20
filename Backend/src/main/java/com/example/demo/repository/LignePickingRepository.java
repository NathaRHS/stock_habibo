package com.example.demo.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.example.demo.entity.LignePicking;
import com.example.demo.entity.StatutLignePicking;

@Repository
public interface LignePickingRepository extends JpaRepository<LignePicking, Long> {

    List<LignePicking> findAllByCommandeId(Long commandeId);

    List<LignePicking>  findAllByEmplacementIdAndCommandeArticleId(
            Long emplacementId,
            Long articleId);

    boolean existsByPickingIdAndOrdrePassage(Long pickingId, Integer ordrePassage);

    boolean existsByPickingId(Long picking);

    @Query("""
            SELECT DISTINCT ligne.emplacement.id
            FROM LignePicking ligne
            WHERE ligne.emplacement.id IN :emplacementIds
              AND ligne.statut IN :statuts
            """)
    List<Long> findEmplacementIdsAvecPickingActif(
            @Param("emplacementIds") List<Long> emplacementIds,
            @Param("statuts") List<StatutLignePicking> statuts);
}
