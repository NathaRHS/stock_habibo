package com.example.demo.repository;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.demo.entity.Article;


@Repository
public interface ArticleRepository extends JpaRepository<Article, Long> {
    Optional<Article> findByCodeBar(String codeBar);
    boolean existsByTypeProduitId(Long typeProduitId);
}
