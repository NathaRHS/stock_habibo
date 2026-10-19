-- ============================================================================
-- 99 - NETTOYAGE DE LA SIMULATION
-- ============================================================================
-- Supprime UNIQUEMENT les journaux dont la reference commence par "SIM-" et
-- tout ce qui en depend. Referentiels, structure, comptes et journaux crees
-- depuis l'application ne sont jamais touches.
--
-- Si un journal cree depuis l'application a consomme du stock simule (sortie,
-- picking, inventaire), une cle etrangere bloque la suppression : le script
-- s'arrete et la transaction est annulee, rien n'est supprime a moitie.
-- ============================================================================

USE stock_habibo;

START TRANSACTION;

DELETE n FROM t_notification n
JOIN t_journal_mouvement j ON j.id = n.journal_id
WHERE j.reference LIKE 'SIM-%';

DELETE ju FROM t_journal_user ju
JOIN t_journal_mouvement j ON j.id = ju.cible_id
WHERE ju.cible_type = 'JOURNAL' AND j.reference LIKE 'SIM-%';

DELETE m FROM t_mouvement_stock m
JOIN t_detail_journal d    ON d.id = m.detail_journal_id
JOIN t_journal_mouvement j ON j.id = d.journal_mouvement_id
WHERE j.reference LIKE 'SIM-%';

DELETE h FROM t_historique_journal_mouvement_statut h
JOIN t_journal_mouvement j ON j.id = h.journal_mouvement_id
WHERE j.reference LIKE 'SIM-%';

DELETE p FROM t_user_journal_mouvement p
JOIN t_journal_mouvement j ON j.id = p.journal_mouvement_id
WHERE j.reference LIKE 'SIM-%';

DELETE d FROM t_detail_journal d
JOIN t_journal_mouvement j ON j.id = d.journal_mouvement_id
WHERE j.reference LIKE 'SIM-%';

DELETE FROM t_journal_mouvement WHERE reference LIKE 'SIM-%';

COMMIT;

SELECT COUNT(*) AS journaux_sim_restants
FROM t_journal_mouvement WHERE reference LIKE 'SIM-%';
