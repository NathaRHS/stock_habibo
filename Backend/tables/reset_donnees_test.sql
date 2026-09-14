-- ============================================================================
-- REINITIALISATION DES DONNEES OPERATIONNELLES DE TEST
-- ============================================================================
--
-- Ce script supprime uniquement les donnees produites par les workflows :
-- receptions, sorties, inventaires, commandes et prelevements.
--
-- Les donnees permanentes suivantes sont volontairement conservees :
--   - utilisateurs et roles ;
--   - statuts et types de mouvement ;
--   - societes ;
--   - racks et emplacements ;
--   - articles, conditionnements et capacites de palette.
--
-- Les vues de stock ne sont pas videes directement : elles seront
-- automatiquement vides apres la suppression des mouvements de stock.
-- ============================================================================

USE stock_habibo;

SET FOREIGN_KEY_CHECKS = 0;

-- Donnees dependantes des commandes de sortie.
TRUNCATE TABLE t_prelevement;

-- Comptages effectues pendant les sessions d'inventaire.
TRUNCATE TABLE t_comptage_inventaire;

-- Historique transactionnel du stock.
TRUNCATE TABLE t_mouvement_stock;

-- Participants aux sessions de mouvement.
TRUNCATE TABLE t_user_journal_mouvement;

-- Commandes associees aux journaux de sortie.
TRUNCATE TABLE t_commande;

-- Lignes scannees ou comptees des journaux.
TRUNCATE TABLE t_detail_journal;

-- Sessions de reception, de sortie et d'inventaire.
TRUNCATE TABLE t_journal_mouvement;

SET FOREIGN_KEY_CHECKS = 1;

-- Verification rapide apres reinitialisation.
SELECT 't_prelevement' AS table_verifiee, COUNT(*) AS nombre_lignes
FROM t_prelevement
UNION ALL
SELECT 't_comptage_inventaire', COUNT(*) FROM t_comptage_inventaire
UNION ALL
SELECT 't_mouvement_stock', COUNT(*) FROM t_mouvement_stock
UNION ALL
SELECT 't_user_journal_mouvement', COUNT(*) FROM t_user_journal_mouvement
UNION ALL
SELECT 't_commande', COUNT(*) FROM t_commande
UNION ALL
SELECT 't_detail_journal', COUNT(*) FROM t_detail_journal
UNION ALL
SELECT 't_journal_mouvement', COUNT(*) FROM t_journal_mouvement;
