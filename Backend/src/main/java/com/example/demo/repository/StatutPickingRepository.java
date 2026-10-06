package com.example.demo.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.demo.entity.StatutPicking;

@Repository
public interface StatutPickingRepository extends JpaRepository<StatutPicking, Long> {

    Optional<StatutPicking> findByNom(String nom);
}
