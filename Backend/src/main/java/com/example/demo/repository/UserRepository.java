package com.example.demo.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.example.demo.entity.User;
import com.example.demo.projection.UserParticipationProjection;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByMatricule(String matricule);

    @Query(value = """
            SELECT
                journal.type_mouvement_journal_id AS typeMouvementId,
                typeMouvement.nom_type_mouvement AS nomTypeMouvement,
                t_user.id AS userId,
                t_user.matricule AS matricule,
                COUNT(*) AS operations
            FROM t_user_journal_mouvement AS user
            JOIN t_journal_mouvement AS journal
                ON journal.id = user.journal_mouvement_id
            JOIN t_user
                ON t_user.id = user.user_id
            JOIN t_type_mouvement_journal AS typeMouvement
                ON typeMouvement.id = journal.type_mouvement_journal_id
            WHERE user.user_id = :id
            GROUP BY
                journal.type_mouvement_journal_id,
                typeMouvement.nom_type_mouvement,
                t_user.id,
                t_user.matricule;   """, nativeQuery = true)
    List<UserParticipationProjection> getNombreParticipations(@Param("id") Long id);
}
