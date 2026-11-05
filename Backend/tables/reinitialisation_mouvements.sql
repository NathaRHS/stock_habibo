-- ============================================================================
-- REINITIALISATION DES MOUVEMENTS (entrees, sorties, inventaires)
-- ============================================================================
-- Supprime TOUS les journaux de mouvement et tout ce qui en depend. Le stock
-- repart donc de zero (il est calcule a partir des mouvements).
--
-- SUPPRIME :
--   t_prelevement, t_historique_ligne_picking_statut, t_ligne_picking,
--   t_historique_picking_statut, t_picking, t_comptage_inventaire,
--   t_mouvement_stock, t_commande, t_user_journal_mouvement,
--   t_historique_journal_mouvement_statut, t_detail_journal, t_journal_mouvement,
--   + dans t_notification : toutes sauf les demandes de mot de passe oublie,
--   + dans t_journal_user : seulement les evenements lies aux mouvements.
--
-- CONSERVE (jamais touche) :
--   t_user, t_roles, t_article, t_article_conditionnement, t_palette_conditionnement,
--   t_famille, t_unite, t_type_produit, t_type_conditionnement, t_societe, t_rack,
--   t_emplacement, t_type_mouvement, t_type_mouvement_journal, t_statut_*,
--   t_parametre_suggestion, et le reste de t_journal_user (connexions, comptes...).
--
-- NE TOUCHE PAS aux fichiers : les pieces jointes et rapports PDF du dossier
-- Backend/uploads restent sur le disque (a supprimer a la main si besoin).
--
-- IRREVERSIBLE. Faites une sauvegarde avant :
--   mysqldump -h 127.0.0.1 -P 3307 -u root -p stock_habibo > sauvegarde.sql
--
-- A lancer dans le client mysql (il utilise DELIMITER). Les suppressions sont
-- dans une procedure avec ROLLBACK automatique : si UNE suppression echoue, RIEN
-- n'est supprime. Le script peut etre relance sans danger.
-- ============================================================================

USE stock_habibo;

-- ----------------------------------------------------------------------------
-- 0. CONTROLE PREALABLE : cles etrangeres parasites.
-- Liste toute cle d'une table CONSERVEE qui pointe vers une table qu'on va
-- vider. Le resultat doit etre VIDE. S'il affiche une ligne (par exemple
-- t_article.famille_id -> t_commande), supprimez d'abord cette cle :
--   ALTER TABLE <table> DROP FOREIGN KEY <constraint_name>;
-- ----------------------------------------------------------------------------
SELECT TABLE_NAME AS table_conservee,
       COLUMN_NAME AS colonne,
       CONSTRAINT_NAME AS constraint_name,
       REFERENCED_TABLE_NAME AS pointe_vers
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'stock_habibo'
  AND REFERENCED_TABLE_NAME IN (
      't_prelevement', 't_historique_ligne_picking_statut', 't_ligne_picking',
      't_historique_picking_statut', 't_picking', 't_comptage_inventaire',
      't_mouvement_stock', 't_commande', 't_user_journal_mouvement',
      't_historique_journal_mouvement_statut', 't_detail_journal',
      't_journal_mouvement')
  AND TABLE_NAME NOT IN (
      't_prelevement', 't_historique_ligne_picking_statut', 't_ligne_picking',
      't_historique_picking_statut', 't_picking', 't_comptage_inventaire',
      't_mouvement_stock', 't_commande', 't_user_journal_mouvement',
      't_historique_journal_mouvement_statut', 't_detail_journal',
      't_journal_mouvement', 't_notification');

-- Ce qui va etre supprime (pour verifier avant de continuer).
SELECT 't_journal_mouvement' AS table_cible, COUNT(*) AS lignes FROM t_journal_mouvement
UNION ALL SELECT 't_detail_journal', COUNT(*) FROM t_detail_journal
UNION ALL SELECT 't_mouvement_stock', COUNT(*) FROM t_mouvement_stock
UNION ALL SELECT 't_comptage_inventaire', COUNT(*) FROM t_comptage_inventaire
UNION ALL SELECT 't_commande', COUNT(*) FROM t_commande
UNION ALL SELECT 't_picking', COUNT(*) FROM t_picking
UNION ALL SELECT 't_ligne_picking', COUNT(*) FROM t_ligne_picking
UNION ALL SELECT 't_prelevement', COUNT(*) FROM t_prelevement
UNION ALL SELECT 't_user_journal_mouvement', COUNT(*) FROM t_user_journal_mouvement;

-- ----------------------------------------------------------------------------
-- 1. SUPPRESSION ATOMIQUE
-- ----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS reinitialiser_mouvements;

DELIMITER $$

CREATE PROCEDURE reinitialiser_mouvements()
BEGIN
    -- Au moindre probleme : tout est annule, puis l'erreur est affichee.
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Picking : du plus dependant au moins dependant.
    DELETE FROM t_prelevement;
    DELETE FROM t_historique_ligne_picking_statut;
    DELETE FROM t_ligne_picking;
    DELETE FROM t_historique_picking_statut;
    DELETE FROM t_picking;

    -- Inventaire et stock.
    DELETE FROM t_comptage_inventaire;
    DELETE FROM t_mouvement_stock;

    -- Notifications liees aux mouvements (les demandes de mot de passe oublie restent).
    DELETE FROM t_notification WHERE type <> 'MOT_DE_PASSE_OUBLIE';

    -- Commandes des sorties.
    DELETE FROM t_commande;

    -- Journal d'activite : seulement les evenements lies aux mouvements.
    DELETE FROM t_journal_user
    WHERE type IN (
        'JOURNAL_CREE', 'JOURNAL_MODIFIE', 'JOURNAL_SUPPRIME', 'JOURNAL_VALIDE',
        'MODIFICATION_DEMANDEE', 'ENTREE_STOCK_VALIDEE', 'SORTIE_CONFIRMEE',
        'PARTICIPATION_DEBUTEE', 'PARTICIPATION_TERMINEE', 'COMMANDES_AJOUTEES',
        'PARCOURS_GENERE', 'AUCUN_PRODUIT_DECLARE'
    );

    -- Les journaux eux-memes.
    DELETE FROM t_user_journal_mouvement;
    DELETE FROM t_historique_journal_mouvement_statut;
    DELETE FROM t_detail_journal;
    -- Un bon de reste pointe vers son journal d'origine : on coupe ce lien d'abord.
    UPDATE t_journal_mouvement SET journal_origine_id = NULL;
    DELETE FROM t_journal_mouvement;

    COMMIT;
END$$

DELIMITER ;

CALL reinitialiser_mouvements();
DROP PROCEDURE reinitialiser_mouvements;

-- ----------------------------------------------------------------------------
-- 2. NUMEROTATION : les identifiants repartent de 1.
-- ----------------------------------------------------------------------------
ALTER TABLE t_prelevement                         AUTO_INCREMENT = 1;
ALTER TABLE t_historique_ligne_picking_statut     AUTO_INCREMENT = 1;
ALTER TABLE t_ligne_picking                       AUTO_INCREMENT = 1;
ALTER TABLE t_historique_picking_statut           AUTO_INCREMENT = 1;
ALTER TABLE t_picking                             AUTO_INCREMENT = 1;
ALTER TABLE t_comptage_inventaire                 AUTO_INCREMENT = 1;
ALTER TABLE t_mouvement_stock                     AUTO_INCREMENT = 1;
ALTER TABLE t_notification                        AUTO_INCREMENT = 1;
ALTER TABLE t_commande                            AUTO_INCREMENT = 1;
ALTER TABLE t_user_journal_mouvement              AUTO_INCREMENT = 1;
ALTER TABLE t_historique_journal_mouvement_statut AUTO_INCREMENT = 1;
ALTER TABLE t_detail_journal                      AUTO_INCREMENT = 1;
ALTER TABLE t_journal_mouvement                   AUTO_INCREMENT = 1;

-- ----------------------------------------------------------------------------
-- 3. VERIFICATION : tout doit etre a 0, et la vue de stock vide.
-- ----------------------------------------------------------------------------
SELECT 't_journal_mouvement' AS table_cible, COUNT(*) AS lignes FROM t_journal_mouvement
UNION ALL SELECT 't_detail_journal', COUNT(*) FROM t_detail_journal
UNION ALL SELECT 't_mouvement_stock', COUNT(*) FROM t_mouvement_stock
UNION ALL SELECT 't_comptage_inventaire', COUNT(*) FROM t_comptage_inventaire
UNION ALL SELECT 't_commande', COUNT(*) FROM t_commande
UNION ALL SELECT 't_picking', COUNT(*) FROM t_picking
UNION ALL SELECT 't_ligne_picking', COUNT(*) FROM t_ligne_picking
UNION ALL SELECT 't_prelevement', COUNT(*) FROM t_prelevement
UNION ALL SELECT 't_user_journal_mouvement', COUNT(*) FROM t_user_journal_mouvement
UNION ALL SELECT 'v_stock_par_emplacement', COUNT(*) FROM v_stock_par_emplacement;
