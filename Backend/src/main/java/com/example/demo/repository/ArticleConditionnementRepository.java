package com.example.demo.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.demo.entity.ArticleConditionnement;

@Repository
public interface ArticleConditionnementRepository extends JpaRepository<ArticleConditionnement, Long> {

    Optional<ArticleConditionnement> findByCodeBarres(String codeBarres);

    Optional<ArticleConditionnement> findFirstByArticleIdOrderByIdAsc(Long articleId);
}
