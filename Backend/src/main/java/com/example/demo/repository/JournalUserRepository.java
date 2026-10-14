package com.example.demo.repository;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.example.demo.entity.JournalUser;
import com.example.demo.entity.TypeEvenementUser;

@Repository
public interface JournalUserRepository extends JpaRepository<JournalUser, Long> {

    // Les filtres vides (null) sont ignores. Les plus recents d'abord.
    @Query("""
            select j from JournalUser j
            left join fetch j.user u
            where (:userId is null or u.id = :userId)
              and (:type is null or j.type = :type)
              and (:depuis is null or j.dateEvenement >= :depuis)
              and (:jusqua is null or j.dateEvenement < :jusqua)
            order by j.dateEvenement desc, j.id desc
            """)
    List<JournalUser> rechercher(
            @Param("userId") Long userId,
            @Param("type") TypeEvenementUser type,
            @Param("depuis") LocalDateTime depuis,
            @Param("jusqua") LocalDateTime jusqua,
            Pageable pageable);

    @Query("""
            select count(j) from JournalUser j
            left join j.user u
            where (:userId is null or u.id = :userId)
              and (:type is null or j.type = :type)
              and (:depuis is null or j.dateEvenement >= :depuis)
              and (:jusqua is null or j.dateEvenement < :jusqua)
            """)
    long compter(
            @Param("userId") Long userId,
            @Param("type") TypeEvenementUser type,
            @Param("depuis") LocalDateTime depuis,
            @Param("jusqua") LocalDateTime jusqua);
}
