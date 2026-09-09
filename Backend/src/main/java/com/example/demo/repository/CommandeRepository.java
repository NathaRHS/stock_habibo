package com.example.demo.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import com.example.demo.entity.Commande;

@Repository
public interface CommandeRepository extends JpaRepository<Commande, Long> {

    List<Commande> findAllByJournalMouvementId(Long journalId);

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query(value = """
            UPDATE commande set etat=:etat set isChecked = true set quantite_reel = :quantiteReel set remarque =:remarque set user_id =:userId where id = :id
            """, nativeQuery = true)
    Commande updatCommandePrelevement(@Param("etat") boolean etat, @Param("quantiteReel") Integer quantiteReel,
            @Param("remarque") String remarque, @Param("userId") Long userId, @Param("id") Long id);

}
