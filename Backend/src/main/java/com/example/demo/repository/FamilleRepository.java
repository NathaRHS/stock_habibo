package com.example.demo.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.demo.entity.Famille;

@Repository
public interface FamilleRepository extends JpaRepository<Famille, Long> {
    Optional<Famille> findByNom(String nom);
}
