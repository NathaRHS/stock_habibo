-- Donne une premiere ligne d'historique a chaque journal existant qui n'en a pas.
-- A executer apres le premier demarrage du backend (la table d'historique est
-- creee par Hibernate). Peut etre rejoue sans risque : un journal qui a deja
-- une ligne d'historique est ignore.

USE stock_habibo;

INSERT INTO t_historique_journal_mouvement_statut
    (journal_mouvement_id, statut_id, date_changement, user_id)
SELECT journal.id, journal.statut_id, NOW(), NULL
FROM t_journal_mouvement journal
WHERE NOT EXISTS (
    SELECT 1
    FROM t_historique_journal_mouvement_statut historique
    WHERE historique.journal_mouvement_id = journal.id
);

-- Verification : chaque journal doit avoir au moins une ligne.
SELECT journal.id, journal.reference, statut.nom AS statut_actuel,
       COUNT(historique.id) AS nb_lignes_historique
FROM t_journal_mouvement journal
JOIN t_statut_journal_mouvement statut ON statut.id = journal.statut_id
LEFT JOIN t_historique_journal_mouvement_statut historique
       ON historique.journal_mouvement_id = journal.id
GROUP BY journal.id, journal.reference, statut.nom
ORDER BY journal.id;
