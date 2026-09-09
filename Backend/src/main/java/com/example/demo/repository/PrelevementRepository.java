package com.example.demo.repository;

import java.time.LocalDate;
import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.*;
import org.springframework.stereotype.Repository;

import com.example.demo.entity.Prelevement;

@Repository
public interface PrelevementRepository extends JpaRepository<Prelevement, Long> {

    boolean existsByStatutPrelevementId(Long statutPrelevementId);

    @Modifying
    @Query(value = """
            INSERT INTO t_prelevement (
                date_prelevement,
                quantitePrelevee,
                commande_id,
                emplacement_id,
                statut_prelevement_id,
                user_id,
                dlc,
                dlv
            )
            VALUES (
                NOW(),
                :quantitePrelevee,
                :commandeId,
                :emplacementId,
                :statutId,
                :userId,
                :dlc,
                :dlv
            )
            """, nativeQuery = true)
    int insertPrelevement(
            @Param("quantitePrelevee") Integer quantitePrelevee,
            @Param("commandeId") Long commandeId,
            @Param("emplacementId") Long emplacementId,
            @Param("statutId") Long statutId,
            @Param("userId") Long userId, @Param("dlc") LocalDate dlc, @Param("dlv") LocalDate dlv);

    List<Prelevement> findAllByCommandeId(Long id);

}
