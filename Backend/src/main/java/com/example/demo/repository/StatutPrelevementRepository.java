package com.example.demo.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.demo.entity.StatutPrelevement;

@Repository
public interface StatutPrelevementRepository extends JpaRepository<StatutPrelevement, Long> {

    Optional<StatutPrelevement> findByNomStatut(String nomStatut);
}
