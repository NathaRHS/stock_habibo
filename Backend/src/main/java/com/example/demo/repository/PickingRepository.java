package com.example.demo.repository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.example.demo.entity.Picking;
import com.example.demo.entity.StatutPicking;

@Repository
public interface PickingRepository extends JpaRepository<Picking, Long> {

        List<Picking> findAllByOrderByDateGenerationPickingDesc();

        List<Picking> findAllByJournalMouvementIdOrderByDateGenerationPickingDesc(Long journalId);

        boolean existsByJournalMouvementIdAndStatutIn(
                        Long journalId,
                        Collection<StatutPicking> statuts);

        Optional<Picking> findFirstByJournalMouvementIdAndStatutInOrderByIdDesc(
                        Long journalId,
                        Collection<StatutPicking> statuts);

        @Query(value = """
                        SELECT *
                        from t_picking
                        WHERE journal_mouvement_id = :journalId
                        order by date_fin  desc
                        LIMIT 1;
                        """, nativeQuery = true)
        Optional<Picking> findPicking(@Param("journalId") Long journalId);
}
