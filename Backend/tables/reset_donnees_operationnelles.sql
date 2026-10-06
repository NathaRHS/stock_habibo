-- Nettoyage des donnees operationnelles uniquement.
-- Les articles, conditionnements, racks, emplacements, roles et utilisateurs
-- sont conserves.

SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE t_notification;
TRUNCATE TABLE t_prelevement;
TRUNCATE TABLE t_ligne_picking;
TRUNCATE TABLE t_picking;
TRUNCATE TABLE t_mouvement_stock;
TRUNCATE TABLE t_comptage_inventaire;
TRUNCATE TABLE t_commande;
TRUNCATE TABLE t_user_journal_mouvement;
TRUNCATE TABLE t_detail_journal;
TRUNCATE TABLE t_journal_mouvement;

SET FOREIGN_KEY_CHECKS = 1;

-- Verification rapide : ces tables doivent etre vides.
SELECT 't_notification' AS table_name, COUNT(*) AS total FROM t_notification
UNION ALL
SELECT 't_prelevement', COUNT(*) FROM t_prelevement
UNION ALL
SELECT 't_ligne_picking', COUNT(*) FROM t_ligne_picking
UNION ALL
SELECT 't_picking', COUNT(*) FROM t_picking
UNION ALL
SELECT 't_mouvement_stock', COUNT(*) FROM t_mouvement_stock
UNION ALL
SELECT 't_comptage_inventaire', COUNT(*) FROM t_comptage_inventaire
UNION ALL
SELECT 't_commande', COUNT(*) FROM t_commande
UNION ALL
SELECT 't_user_journal_mouvement', COUNT(*) FROM t_user_journal_mouvement
UNION ALL
SELECT 't_detail_journal', COUNT(*) FROM t_detail_journal
UNION ALL
SELECT 't_journal_mouvement', COUNT(*) FROM t_journal_mouvement;
