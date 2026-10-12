package com.example.demo.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.demo.entity.Unite;

@Repository
public interface UniteRepository extends JpaRepository<Unite, Long> {
    Optional<Unite> findByNomUnite(String nomUnite);

    boolean existsByNomUnite(String nomUnite);
}
