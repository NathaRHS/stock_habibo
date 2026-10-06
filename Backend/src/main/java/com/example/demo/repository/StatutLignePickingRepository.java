package com.example.demo.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.demo.entity.StatutLignePicking;

@Repository
public interface StatutLignePickingRepository extends JpaRepository<StatutLignePicking, Long> {

    Optional<StatutLignePicking> findByNom(String nom);
}
