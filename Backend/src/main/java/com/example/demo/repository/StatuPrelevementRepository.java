package com.example.demo.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.demo.entity.StatutPrelevement;

public interface StatuPrelevementRepository extends JpaRepository<StatutPrelevement,Long> {

    Optional<StatutPrelevement> findByNomStatut(String trim);
    
}
