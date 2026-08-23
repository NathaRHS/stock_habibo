package com.example.demo.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.example.demo.entity.Article;
import com.example.demo.entity.DetailJournal;

@Repository
public interface DetailJournalRepository extends JpaRepository<DetailJournal, Long> {
    @Query(value = """
        SELECT * from t_detail_journal where jounal_mouvement_id = :journal_mouvement_id""",nativeQuery = true)
    List<DetailJournal> findAllByJournalMouvementId(@Param("journal_mouvement_id") Long idJournal);


}
