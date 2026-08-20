package com.example.demo.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.demo.entity.Societe;

@Repository
public interface SocieteRepository extends JpaRepository<Societe, Long> {
    Optional<Societe> findByNomSocieteIgnoreCase(String nomSociete);
}
