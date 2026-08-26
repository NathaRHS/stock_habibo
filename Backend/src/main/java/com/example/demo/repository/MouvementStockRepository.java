package com.example.demo.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import com.example.demo.entity.MouvementStock;

public interface MouvementStockRepository extends JpaRepository<MouvementStock, Long> {

    @Query(value = """  
                SELECT * from t_mouvement_stock where type_mouvement_id = 1
            """,nativeQuery = true)
    List<MouvementStock> getAllEntry();

}
