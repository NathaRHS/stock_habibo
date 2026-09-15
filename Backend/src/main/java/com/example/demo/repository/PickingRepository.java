package com.example.demo.repository;

import java.util.Collection;
import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
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
}
