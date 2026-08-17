package com.example.demo.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.demo.entity.TypeMouvementJournal;

@Repository
public interface TypeMouvementJournalRepository extends JpaRepository<TypeMouvementJournal, Long> {
    Optional<TypeMouvementJournal> findByNomTypeMouvement(String nomTypeMouvement);
}
