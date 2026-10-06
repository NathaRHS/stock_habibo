package com.example.demo.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.example.demo.entity.LignePicking;
import com.example.demo.entity.StatutLignePickingCode;

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
              AND ligne.statut.nom IN :nomsStatuts
            """)
    List<Long> findEmplacementIdsAvecPickingActifParNom(
            @Param("emplacementIds") List<Long> emplacementIds,
            @Param("nomsStatuts") List<String> nomsStatuts);

    // Les appelants raisonnent avec l'enum, jamais avec du texte.
    default List<Long> findEmplacementIdsAvecPickingActif(
            List<Long> emplacementIds,
            List<StatutLignePickingCode> statuts) {
        return findEmplacementIdsAvecPickingActifParNom(emplacementIds, StatutLignePickingCode.versNoms(statuts));
    }
}
