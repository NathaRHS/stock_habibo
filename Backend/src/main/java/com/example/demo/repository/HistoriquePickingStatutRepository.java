package com.example.demo.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.demo.entity.HistoriquePickingStatut;

@Repository
public interface HistoriquePickingStatutRepository extends JpaRepository<HistoriquePickingStatut, Long> {

    List<HistoriquePickingStatut> findByPickingIdOrderByDateChangementAsc(Long pickingId);
}
