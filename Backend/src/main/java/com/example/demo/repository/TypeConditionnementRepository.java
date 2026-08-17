package com.example.demo.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.demo.entity.TypeConditionnement;

@Repository
public interface TypeConditionnementRepository extends JpaRepository<TypeConditionnement, Long> {
    Optional<TypeConditionnement> findByNomConditionnement(String nomConditionnement);
}
