package com.example.demo.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.demo.entity.LignePicking;

@Repository
public interface LignePickingRepository extends JpaRepository<LignePicking, Long> {

    List<LignePicking> findAllByCommandeId(Long commandeId);

    List<LignePicking>  findAllByEmplacementIdAndCommandeArticleId(
            Long emplacementId,
            Long articleId);

    boolean existsByPickingIdAndOrdrePassage(Long pickingId, Integer ordrePassage);

    boolean existsByPickingId(Long picking);
}
