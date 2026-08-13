package com.example.demo.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.demo.entity.Emplacement;

@Repository
public interface EmplacementRepository extends JpaRepository<Emplacement, Long> {
    boolean existsByRackIdAndNomEmplacement(Long rackId, String nomEmplacement);
}
