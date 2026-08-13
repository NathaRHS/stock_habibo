package com.example.demo.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.demo.entity.TypeProduit;

@Repository
public interface TypeProduitRepository extends JpaRepository<TypeProduit, Long> {
    Optional<TypeProduit> findByNomType(String nomType);
}
