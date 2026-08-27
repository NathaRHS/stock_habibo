package com.example.demo.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.demo.entity.PaletteConditionnement;

@Repository
public interface PaletteConditionnementRepository extends JpaRepository<PaletteConditionnement, Long> {
    boolean existsByArticleConditionnementId(Long articleConditionnementId);

    Optional<PaletteConditionnement> findByArticleConditionnementId(Long articleConditionnementId);
}
