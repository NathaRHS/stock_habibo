package com.example.demo.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.example.demo.entity.Emplacement;

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

    // Emplacement calculStock(Long emplacementId);
}
