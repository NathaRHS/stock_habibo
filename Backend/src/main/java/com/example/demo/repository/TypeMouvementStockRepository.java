package com.example.demo.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.demo.entity.TypeMouvementStock;

@Repository
public interface TypeMouvementStockRepository extends JpaRepository<TypeMouvementStock, Long> {
    Optional<TypeMouvementStock> findByNomTypeMouvement(String nomTypeMouvement);
}
