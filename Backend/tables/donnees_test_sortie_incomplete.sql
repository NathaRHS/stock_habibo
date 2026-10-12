-- ============================================================================
-- DONNEES DE TEST : SORTIES INCOMPLETES ET BON DE RESTE
-- ============================================================================
-- Deux scenarios, relies a toutes les tables du workflow de sortie :
--
--   A. SOR-DEMO-RESTE-001  (EN COURS, a valider)
--      Picking termine par l'operateur, sortie PAS ENCORE validee. Il suffit de
--      cliquer sur "Valider la sortie" dans l'application pour voir le bon de
--      reste se creer (SOR-DEMO-RESTE-001-R1) et obtenir son PDF.
--
--        Article            Demande  Prelevee  Cas illustre
--        Coca-Cola 30cl        14        7     ligne PARTIELLE (EN_COURS)
--        Lait Candia 1L         8        8     ligne complete (PRELEVEE)
--        Eau Vive 1.5L          6        0     "aucun produit ici" (IMPOSSIBLE)
--        Savon liquide 500ml    4        0     aucun stock : aucune ligne
--
--      Bon attendu apres validation : Coca-Cola 7, Eau Vive 6, Savon 4.
--
--   B. SOR-DEMO-RESTE-002  (CLOTURE) + son bon SOR-DEMO-RESTE-002-R1 (EN COURS)
--      Sortie deja validee : mouvements de stock ecrits, bon de reste cree.
--
--        Coca-Cola 30cl : 10 demandes, 6 prelevees -> reste 4 (bon -R1)
--        Lait Candia 1L :  5 demandes, 5 prelevees -> complet
--
-- Prerequis (voir donnees dans script-vrai.sql) :
--   - badgaga.sql deja execute (tables d'historique et statuts) ;
--   - referentiel : utilisateurs ADM001 / OPE001, societe Hb, RACK-E avec les
--     emplacements E-001 a E-005, les 4 articles de demonstration et leurs
--     conditionnements.
--
-- Le script est REJOUABLE : il supprime d'abord ses propres donnees (references
-- SOR-DEMO-RESTE-* et ENT-DEMO-RESTE-*), sans toucher au reste de la base.
-- Les emplacements E-001 a E-005 ne doivent contenir aucun autre stock.
-- ============================================================================

USE stock_habibo;

-- ----------------------------------------------------------------------------
-- 0. COLONNE journal_origine_id (lien d'un bon de reste vers sa sortie d'origine)
--    Normalement creee par Hibernate au demarrage ; ajoutee ici si absente.
-- ----------------------------------------------------------------------------
SET @sql = IF(
    (SELECT COUNT(*) FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 't_journal_mouvement'
        AND COLUMN_NAME = 'journal_origine_id') = 0,
    'ALTER TABLE t_journal_mouvement
        ADD COLUMN journal_origine_id BIGINT NULL,
        ADD CONSTRAINT fk_journal_origine
            FOREIGN KEY (journal_origine_id) REFERENCES t_journal_mouvement (id)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Statut de prelevement attendu par le scan (nom CONFIRME).
INSERT IGNORE INTO t_statut_prelevement (nom_statut) VALUES ('CONFIRME');

START TRANSACTION;

-- ----------------------------------------------------------------------------
-- 1. NETTOYAGE DES ANCIENNES DONNEES DE CE SCRIPT (ordre des cles etrangeres)
-- ----------------------------------------------------------------------------

-- Prelevements des commandes de ces journaux.
DELETE FROM t_prelevement
WHERE commande_id IN (
    SELECT c.id FROM t_commande c
    JOIN t_journal_mouvement j ON j.id = c.journal_mouvement_id
    WHERE j.reference LIKE 'SOR-DEMO-RESTE-%'
);

-- Historique et lignes de picking.
DELETE FROM t_historique_ligne_picking_statut
WHERE ligne_picking_id IN (
    SELECT l.id FROM t_ligne_picking l
    JOIN t_picking p ON p.id = l.picking_id
    JOIN t_journal_mouvement j ON j.id = p.journal_mouvement_id
    WHERE j.reference LIKE 'SOR-DEMO-RESTE-%'
);

DELETE FROM t_ligne_picking
WHERE picking_id IN (
    SELECT p.id FROM t_picking p
    JOIN t_journal_mouvement j ON j.id = p.journal_mouvement_id
    WHERE j.reference LIKE 'SOR-DEMO-RESTE-%'
);

DELETE FROM t_historique_picking_statut
WHERE picking_id IN (
    SELECT p.id FROM t_picking p
    JOIN t_journal_mouvement j ON j.id = p.journal_mouvement_id
    WHERE j.reference LIKE 'SOR-DEMO-RESTE-%'
);

DELETE FROM t_picking
WHERE journal_mouvement_id IN (
    SELECT id FROM t_journal_mouvement WHERE reference LIKE 'SOR-DEMO-RESTE-%'
);

-- Mouvements de stock (entrees ET sorties : ils pointent vers le detail de la
-- reception), puis commandes et details.
DELETE FROM t_mouvement_stock
WHERE detail_journal_id IN (
    SELECT d.id FROM t_detail_journal d
    JOIN t_journal_mouvement j ON j.id = d.journal_mouvement_id
    WHERE j.reference LIKE 'ENT-DEMO-RESTE-%' OR j.reference LIKE 'SOR-DEMO-RESTE-%'
);

DELETE FROM t_commande
WHERE journal_mouvement_id IN (
    SELECT id FROM t_journal_mouvement WHERE reference LIKE 'SOR-DEMO-RESTE-%'
);

DELETE FROM t_detail_journal
WHERE journal_mouvement_id IN (
    SELECT id FROM t_journal_mouvement
    WHERE reference LIKE 'ENT-DEMO-RESTE-%' OR reference LIKE 'SOR-DEMO-RESTE-%'
);

-- Participations, historique des statuts, notifications, puis journaux.
DELETE FROM t_user_journal_mouvement
WHERE journal_mouvement_id IN (
    SELECT id FROM t_journal_mouvement
    WHERE reference LIKE 'ENT-DEMO-RESTE-%' OR reference LIKE 'SOR-DEMO-RESTE-%'
);

DELETE FROM t_historique_journal_mouvement_statut
WHERE journal_mouvement_id IN (
    SELECT id FROM t_journal_mouvement
    WHERE reference LIKE 'ENT-DEMO-RESTE-%' OR reference LIKE 'SOR-DEMO-RESTE-%'
);

DELETE FROM t_notification
WHERE journal_id IN (
    SELECT id FROM t_journal_mouvement
    WHERE reference LIKE 'ENT-DEMO-RESTE-%' OR reference LIKE 'SOR-DEMO-RESTE-%'
);

UPDATE t_journal_mouvement
SET journal_origine_id = NULL
WHERE reference LIKE 'SOR-DEMO-RESTE-%';

DELETE FROM t_journal_mouvement
WHERE reference LIKE 'ENT-DEMO-RESTE-%' OR reference LIKE 'SOR-DEMO-RESTE-%';

-- ----------------------------------------------------------------------------
-- 2. IDENTIFIANTS DU REFERENTIEL (utilises partout ensuite)
-- ----------------------------------------------------------------------------

SET @u_adm  = (SELECT id FROM t_user WHERE matricule = 'ADM001');
SET @u_ope  = (SELECT id FROM t_user WHERE matricule = 'OPE001');
SET @societe = (SELECT id FROM t_societe WHERE nom_societe = 'Hb' LIMIT 1);
SET @rack_e = (SELECT id FROM t_rack WHERE nom_rack = 'RACK-E');

SET @tj_entree = (SELECT id FROM t_type_mouvement_journal WHERE nom_type_mouvement = 'ENTREE');
SET @tj_sortie = (SELECT id FROM t_type_mouvement_journal WHERE nom_type_mouvement = 'SORTIE');
SET @tm_entree = (SELECT id FROM t_type_mouvement WHERE nom_type_mouvement = 'ENTREE');
SET @tm_sortie = (SELECT id FROM t_type_mouvement WHERE nom_type_mouvement = 'SORTIE');

SET @sj_en_cours = (SELECT id FROM t_statut_journal_mouvement WHERE nom = 'EN COURS');
SET @sj_valide   = (SELECT id FROM t_statut_journal_mouvement WHERE nom = 'VALIDE');
SET @sj_affectee = (SELECT id FROM t_statut_journal_mouvement WHERE nom = 'AFFECTEE');
SET @sj_cloture  = (SELECT id FROM t_statut_journal_mouvement WHERE nom = 'CLOTURE');

SET @sp_genere   = (SELECT id FROM t_statut_picking WHERE nom = 'GENERE');
SET @sp_en_cours = (SELECT id FROM t_statut_picking WHERE nom = 'EN_COURS');
SET @sp_termine  = (SELECT id FROM t_statut_picking WHERE nom = 'TERMINE');

SET @sl_reservee   = (SELECT id FROM t_statut_ligne_picking WHERE nom = 'RESERVEE');
SET @sl_en_cours   = (SELECT id FROM t_statut_ligne_picking WHERE nom = 'EN_COURS');
SET @sl_prelevee   = (SELECT id FROM t_statut_ligne_picking WHERE nom = 'PRELEVEE');
SET @sl_impossible = (SELECT id FROM t_statut_ligne_picking WHERE nom = 'IMPOSSIBLE');

SET @spr_confirme = (SELECT id FROM t_statut_prelevement WHERE nom_statut = 'CONFIRME');

-- Articles et leurs conditionnements (pieces par conditionnement : 6, 12, 6, 12).
SET @a_coca   = (SELECT id FROM t_article WHERE code_bar = '60001548856446');
SET @a_candia = (SELECT id FROM t_article WHERE code_bar = '6200000000018');
SET @a_eau    = (SELECT id FROM t_article WHERE code_bar = '6223000011111');
SET @a_savon  = (SELECT id FROM t_article WHERE code_bar = '6333000033333');

SET @c_coca   = (SELECT id FROM t_article_conditionnement WHERE code_barres = '60001548856453');
SET @c_candia = (SELECT id FROM t_article_conditionnement WHERE code_barres = '6200000000025');
SET @c_eau    = (SELECT id FROM t_article_conditionnement WHERE code_barres = '6223000011128');

-- Emplacements : un seul article par emplacement.
SET @e1 = (SELECT id FROM t_emplacement WHERE nom_emplacement = 'E-001');
SET @e2 = (SELECT id FROM t_emplacement WHERE nom_emplacement = 'E-002');
SET @e3 = (SELECT id FROM t_emplacement WHERE nom_emplacement = 'E-003');
SET @e4 = (SELECT id FROM t_emplacement WHERE nom_emplacement = 'E-004');
SET @e5 = (SELECT id FROM t_emplacement WHERE nom_emplacement = 'E-005');

-- Controle : toutes les valeurs ci-dessous doivent etre non nulles.
SELECT @u_adm AS adm, @u_ope AS ope, @societe AS societe, @rack_e AS rack_e,
       @tj_entree AS tj_entree, @tj_sortie AS tj_sortie,
       @tm_entree AS tm_entree, @tm_sortie AS tm_sortie,
       @sj_en_cours AS sj_en_cours, @sj_valide AS sj_valide,
       @sj_affectee AS sj_affectee, @sj_cloture AS sj_cloture,
       @sp_genere AS sp_genere, @sp_en_cours AS sp_en_cours, @sp_termine AS sp_termine,
       @sl_reservee AS sl_reservee, @sl_en_cours AS sl_en_cours,
       @sl_prelevee AS sl_prelevee, @sl_impossible AS sl_impossible,
       @spr_confirme AS spr_confirme,
       @a_coca AS a_coca, @a_candia AS a_candia, @a_eau AS a_eau, @a_savon AS a_savon,
       @c_coca AS c_coca, @c_candia AS c_candia, @c_eau AS c_eau,
       @e1 AS e1, @e2 AS e2, @e3 AS e3, @e4 AS e4, @e5 AS e5;

-- ============================================================================
-- SCENARIO A : SOR-DEMO-RESTE-001  (sortie a valider)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- A1. Reception qui constitue le stock : ENT-DEMO-RESTE-001 (AFFECTEE)
-- ----------------------------------------------------------------------------

INSERT INTO t_journal_mouvement
    (nom_client, reference, url_piece_jointe, fournisseur_id,
     type_mouvement_journal_id, statut_id)
VALUES (NULL, 'ENT-DEMO-RESTE-001', NULL, @societe, @tj_entree, @sj_affectee);
SET @j_ent1 = LAST_INSERT_ID();

-- Historique du statut : EN COURS -> VALIDE -> AFFECTEE.
INSERT INTO t_historique_journal_mouvement_statut
    (journal_mouvement_id, statut_id, date_changement, user_id)
VALUES
    (@j_ent1, @sj_en_cours, NOW() - INTERVAL 10 DAY, @u_ope),
    (@j_ent1, @sj_valide,   NOW() - INTERVAL 10 DAY + INTERVAL 1 HOUR, @u_adm),
    (@j_ent1, @sj_affectee, NOW() - INTERVAL 10 DAY + INTERVAL 2 HOUR, @u_adm);

INSERT INTO t_user_journal_mouvement
    (journal_mouvement_id, user_id, statut_participation, date_debut, date_fin)
VALUES (@j_ent1, @u_ope, 'TERMINE',
        NOW() - INTERVAL 10 DAY, NOW() - INTERVAL 10 DAY + INTERVAL 1 HOUR);

-- Details de reception (quantite en pieces, quantite_conditionnement en boites).
--   Coca-Cola : 10 packs de 6   = 60 pieces   (DLC 31/03/2027)
--   Candia    :  8 cartons de 12 = 96 pieces  (DLC 30/06/2027)
--   Eau Vive  :  5 packs de 6   = 30 pieces   (DLC 31/05/2027)
INSERT INTO t_detail_journal
    (journal_mouvement_id, article_id, quantite, quantite_conditionnement, dlc, dlv)
VALUES (@j_ent1, @a_coca, 60, 10, '2027-03-31', '2027-03-15');
SET @d_coca1 = LAST_INSERT_ID();

INSERT INTO t_detail_journal
    (journal_mouvement_id, article_id, quantite, quantite_conditionnement, dlc, dlv)
VALUES (@j_ent1, @a_candia, 96, 8, '2027-06-30', '2027-06-15');
SET @d_candia1 = LAST_INSERT_ID();

INSERT INTO t_detail_journal
    (journal_mouvement_id, article_id, quantite, quantite_conditionnement, dlc, dlv)
VALUES (@j_ent1, @a_eau, 30, 5, '2027-05-31', '2027-05-15');
SET @d_eau1 = LAST_INSERT_ID();

-- Rangement : une entree en stock par detail, dans un emplacement.
INSERT INTO t_mouvement_stock
    (type_mouvement_id, emplacement_id, en_reserve, user_id,
     nombre_conditionnements, conditionnement_id, quantite_pieces_reelle,
     date_mouvement, commentaire, detail_journal_id)
VALUES
    (@tm_entree, @e1, FALSE, @u_ope, 10, @c_coca, 60,
     NOW() - INTERVAL 10 DAY + INTERVAL 2 HOUR,
     'Entree en stock du journal ENT-DEMO-RESTE-001', @d_coca1),
    (@tm_entree, @e2, FALSE, @u_ope, 8, @c_candia, 96,
     NOW() - INTERVAL 10 DAY + INTERVAL 2 HOUR,
     'Entree en stock du journal ENT-DEMO-RESTE-001', @d_candia1),
    (@tm_entree, @e3, FALSE, @u_ope, 5, @c_eau, 30,
     NOW() - INTERVAL 10 DAY + INTERVAL 2 HOUR,
     'Entree en stock du journal ENT-DEMO-RESTE-001', @d_eau1);

-- ----------------------------------------------------------------------------
-- A2. La sortie : SOR-DEMO-RESTE-001 (EN COURS) et ses 4 commandes
-- ----------------------------------------------------------------------------

INSERT INTO t_journal_mouvement
    (nom_client, reference, url_piece_jointe, fournisseur_id,
     type_mouvement_journal_id, statut_id)
VALUES ('Supermarche Score Ankorondrano', 'SOR-DEMO-RESTE-001', NULL, NULL,
        @tj_sortie, @sj_en_cours);
SET @j_sor1 = LAST_INSERT_ID();

INSERT INTO t_historique_journal_mouvement_statut
    (journal_mouvement_id, statut_id, date_changement, user_id)
VALUES (@j_sor1, @sj_en_cours, NOW() - INTERVAL 2 DAY, @u_adm);

-- Quantites demandees en CONDITIONNEMENTS.
INSERT INTO t_commande
    (etat, remarque, quantite_demande, quantite_reel, isChecked,
     article_id, journal_mouvement_id, user_id)
VALUES (FALSE, 'Ligne partielle : 7 prelevees sur 14', 14, NULL, TRUE,
        @a_coca, @j_sor1, NULL);
SET @cmd_coca1 = LAST_INSERT_ID();

INSERT INTO t_commande
    (etat, remarque, quantite_demande, quantite_reel, isChecked,
     article_id, journal_mouvement_id, user_id)
VALUES (FALSE, 'Commande servie en entier', 8, NULL, TRUE,
        @a_candia, @j_sor1, NULL);
SET @cmd_candia1 = LAST_INSERT_ID();

INSERT INTO t_commande
    (etat, remarque, quantite_demande, quantite_reel, isChecked,
     article_id, journal_mouvement_id, user_id)
VALUES (FALSE, 'Aucun produit a l emplacement', 6, NULL, TRUE,
        @a_eau, @j_sor1, NULL);
SET @cmd_eau1 = LAST_INSERT_ID();

INSERT INTO t_commande
    (etat, remarque, quantite_demande, quantite_reel, isChecked,
     article_id, journal_mouvement_id, user_id)
VALUES (FALSE, 'Aucun stock : pas de ligne de picking', 4, NULL, TRUE,
        @a_savon, @j_sor1, NULL);

-- ----------------------------------------------------------------------------
-- A3. Le picking de l'operateur OPE001
-- ----------------------------------------------------------------------------

INSERT INTO t_picking
    (date_generation_picking, date_debut, date_fin,
     journal_mouvement_id, user_id, rack_depart_id, statut_id)
VALUES (NOW() - INTERVAL 1 DAY, NOW() - INTERVAL 1 DAY + INTERVAL 5 MINUTE, NULL,
        @j_sor1, @u_ope, @rack_e, @sp_en_cours);
SET @pick1 = LAST_INSERT_ID();

INSERT INTO t_historique_picking_statut
    (picking_id, statut_id, date_changement, user_id)
VALUES
    (@pick1, @sp_genere,   NOW() - INTERVAL 1 DAY, @u_ope),
    (@pick1, @sp_en_cours, NOW() - INTERVAL 1 DAY + INTERVAL 5 MINUTE, @u_ope);

-- Lignes de picking : la quantite reservee est celle de la proposition.
--   L1 Coca    : 10 packs reserves (60 pieces), 7 prelevees  -> EN_COURS
--   L2 Candia  :  8 cartons reserves (96 pieces), 8 prelevees -> PRELEVEE
--   L3 Eau Vive:  5 packs reserves (30 pieces), 0 prelevee    -> IMPOSSIBLE
INSERT INTO t_ligne_picking
    (picking_id, commande_id, emplacement_id, detail_journal_source_id,
     article_conditionnement_id, ordre_passage,
     quantite_conditionnements_a_prelever, quantite_pieces_a_prelever,
     date_reservation, statut_id)
VALUES (@pick1, @cmd_coca1, @e1, @d_coca1, @c_coca, 1, 10, 60,
        NOW() - INTERVAL 1 DAY, @sl_en_cours);
SET @lig_coca1 = LAST_INSERT_ID();

INSERT INTO t_ligne_picking
    (picking_id, commande_id, emplacement_id, detail_journal_source_id,
     article_conditionnement_id, ordre_passage,
     quantite_conditionnements_a_prelever, quantite_pieces_a_prelever,
     date_reservation, statut_id)
VALUES (@pick1, @cmd_candia1, @e2, @d_candia1, @c_candia, 2, 8, 96,
        NOW() - INTERVAL 1 DAY, @sl_prelevee);
SET @lig_candia1 = LAST_INSERT_ID();

INSERT INTO t_ligne_picking
    (picking_id, commande_id, emplacement_id, detail_journal_source_id,
     article_conditionnement_id, ordre_passage,
     quantite_conditionnements_a_prelever, quantite_pieces_a_prelever,
     date_reservation, statut_id)
VALUES (@pick1, @cmd_eau1, @e3, @d_eau1, @c_eau, 3, 5, 30,
        NOW() - INTERVAL 1 DAY, @sl_impossible);
SET @lig_eau1 = LAST_INSERT_ID();

-- Historique des statuts de ligne : toujours RESERVEE au depart.
INSERT INTO t_historique_ligne_picking_statut
    (ligne_picking_id, statut_id, date_changement, user_id)
VALUES
    (@lig_coca1,   @sl_reservee,   NOW() - INTERVAL 1 DAY, @u_ope),
    (@lig_coca1,   @sl_en_cours,   NOW() - INTERVAL 1 DAY + INTERVAL 10 MINUTE, @u_ope),
    (@lig_candia1, @sl_reservee,   NOW() - INTERVAL 1 DAY, @u_ope),
    (@lig_candia1, @sl_en_cours,   NOW() - INTERVAL 1 DAY + INTERVAL 20 MINUTE, @u_ope),
    (@lig_candia1, @sl_prelevee,   NOW() - INTERVAL 1 DAY + INTERVAL 21 MINUTE, @u_ope),
    (@lig_eau1,    @sl_reservee,   NOW() - INTERVAL 1 DAY, @u_ope),
    (@lig_eau1,    @sl_impossible, NOW() - INTERVAL 1 DAY + INTERVAL 30 MINUTE, @u_ope);

-- Prelevements reels (en PIECES). Aucun pour la ligne IMPOSSIBLE.
INSERT INTO t_prelevement
    (commande_id, ligne_picking_id, emplacement_id, statut_prelevement_id,
     quantitePiecesPrelevee, user_id, date_prelevement, dlc, dlv)
VALUES
    (@cmd_coca1, @lig_coca1, @e1, @spr_confirme, 42, @u_ope,
     NOW() - INTERVAL 1 DAY + INTERVAL 10 MINUTE, '2027-03-31', '2027-03-15'),
    (@cmd_candia1, @lig_candia1, @e2, @spr_confirme, 96, @u_ope,
     NOW() - INTERVAL 1 DAY + INTERVAL 20 MINUTE, '2027-06-30', '2027-06-15');

-- ============================================================================
-- SCENARIO B : SOR-DEMO-RESTE-002 (CLOTURE) et son bon SOR-DEMO-RESTE-002-R1
-- ============================================================================

-- ----------------------------------------------------------------------------
-- B1. Reception qui constitue le stock : ENT-DEMO-RESTE-002 (AFFECTEE)
--     Coca-Cola : 9 packs (54 pieces) en E-004 ; Candia : 7 cartons (84) en E-005
-- ----------------------------------------------------------------------------

INSERT INTO t_journal_mouvement
    (nom_client, reference, url_piece_jointe, fournisseur_id,
     type_mouvement_journal_id, statut_id)
VALUES (NULL, 'ENT-DEMO-RESTE-002', NULL, @societe, @tj_entree, @sj_affectee);
SET @j_ent2 = LAST_INSERT_ID();

INSERT INTO t_historique_journal_mouvement_statut
    (journal_mouvement_id, statut_id, date_changement, user_id)
VALUES
    (@j_ent2, @sj_en_cours, NOW() - INTERVAL 20 DAY, @u_ope),
    (@j_ent2, @sj_valide,   NOW() - INTERVAL 20 DAY + INTERVAL 1 HOUR, @u_adm),
    (@j_ent2, @sj_affectee, NOW() - INTERVAL 20 DAY + INTERVAL 2 HOUR, @u_adm);

INSERT INTO t_user_journal_mouvement
    (journal_mouvement_id, user_id, statut_participation, date_debut, date_fin)
VALUES (@j_ent2, @u_ope, 'TERMINE',
        NOW() - INTERVAL 20 DAY, NOW() - INTERVAL 20 DAY + INTERVAL 1 HOUR);

INSERT INTO t_detail_journal
    (journal_mouvement_id, article_id, quantite, quantite_conditionnement, dlc, dlv)
VALUES (@j_ent2, @a_coca, 54, 9, '2027-02-28', '2027-02-14');
SET @d_coca2 = LAST_INSERT_ID();

INSERT INTO t_detail_journal
    (journal_mouvement_id, article_id, quantite, quantite_conditionnement, dlc, dlv)
VALUES (@j_ent2, @a_candia, 84, 7, '2027-07-31', '2027-07-15');
SET @d_candia2 = LAST_INSERT_ID();

INSERT INTO t_mouvement_stock
    (type_mouvement_id, emplacement_id, en_reserve, user_id,
     nombre_conditionnements, conditionnement_id, quantite_pieces_reelle,
     date_mouvement, commentaire, detail_journal_id)
VALUES
    (@tm_entree, @e4, FALSE, @u_ope, 9, @c_coca, 54,
     NOW() - INTERVAL 20 DAY + INTERVAL 2 HOUR,
     'Entree en stock du journal ENT-DEMO-RESTE-002', @d_coca2),
    (@tm_entree, @e5, FALSE, @u_ope, 7, @c_candia, 84,
     NOW() - INTERVAL 20 DAY + INTERVAL 2 HOUR,
     'Entree en stock du journal ENT-DEMO-RESTE-002', @d_candia2);

-- ----------------------------------------------------------------------------
-- B2. La sortie d'origine, deja validee (CLOTURE)
-- ----------------------------------------------------------------------------

INSERT INTO t_journal_mouvement
    (nom_client, reference, url_piece_jointe, fournisseur_id,
     type_mouvement_journal_id, statut_id)
VALUES ('Shoprite Analakely', 'SOR-DEMO-RESTE-002', NULL, NULL,
        @tj_sortie, @sj_cloture);
SET @j_sor2 = LAST_INSERT_ID();

INSERT INTO t_historique_journal_mouvement_statut
    (journal_mouvement_id, statut_id, date_changement, user_id)
VALUES
    (@j_sor2, @sj_en_cours, NOW() - INTERVAL 5 DAY, @u_adm),
    (@j_sor2, @sj_cloture,  NOW() - INTERVAL 4 DAY, @u_adm);

INSERT INTO t_commande
    (etat, remarque, quantite_demande, quantite_reel, isChecked,
     article_id, journal_mouvement_id, user_id)
VALUES (FALSE, 'Servie en partie : reste repris dans le bon -R1', 10, NULL, TRUE,
        @a_coca, @j_sor2, NULL);
SET @cmd_coca2 = LAST_INSERT_ID();

INSERT INTO t_commande
    (etat, remarque, quantite_demande, quantite_reel, isChecked,
     article_id, journal_mouvement_id, user_id)
VALUES (FALSE, 'Servie en entier', 5, NULL, TRUE,
        @a_candia, @j_sor2, NULL);
SET @cmd_candia2 = LAST_INSERT_ID();

INSERT INTO t_picking
    (date_generation_picking, date_debut, date_fin,
     journal_mouvement_id, user_id, rack_depart_id, statut_id)
VALUES (NOW() - INTERVAL 5 DAY, NOW() - INTERVAL 5 DAY + INTERVAL 5 MINUTE,
        NOW() - INTERVAL 5 DAY + INTERVAL 40 MINUTE,
        @j_sor2, @u_ope, @rack_e, @sp_termine);
SET @pick2 = LAST_INSERT_ID();

INSERT INTO t_historique_picking_statut
    (picking_id, statut_id, date_changement, user_id)
VALUES
    (@pick2, @sp_genere,   NOW() - INTERVAL 5 DAY, @u_ope),
    (@pick2, @sp_en_cours, NOW() - INTERVAL 5 DAY + INTERVAL 5 MINUTE, @u_ope),
    (@pick2, @sp_termine,  NOW() - INTERVAL 5 DAY + INTERVAL 40 MINUTE, @u_ope);

-- Coca : 9 packs reserves (54 pieces), 6 prelevees (36) ; la ligne a ete fermee
-- en PRELEVEE a la validation. Candia : 5 cartons (60 pieces) prelevees.
INSERT INTO t_ligne_picking
    (picking_id, commande_id, emplacement_id, detail_journal_source_id,
     article_conditionnement_id, ordre_passage,
     quantite_conditionnements_a_prelever, quantite_pieces_a_prelever,
     date_reservation, statut_id)
VALUES (@pick2, @cmd_coca2, @e4, @d_coca2, @c_coca, 1, 9, 54,
        NOW() - INTERVAL 5 DAY, @sl_prelevee);
SET @lig_coca2 = LAST_INSERT_ID();

INSERT INTO t_ligne_picking
    (picking_id, commande_id, emplacement_id, detail_journal_source_id,
     article_conditionnement_id, ordre_passage,
     quantite_conditionnements_a_prelever, quantite_pieces_a_prelever,
     date_reservation, statut_id)
VALUES (@pick2, @cmd_candia2, @e5, @d_candia2, @c_candia, 2, 5, 60,
        NOW() - INTERVAL 5 DAY, @sl_prelevee);
SET @lig_candia2 = LAST_INSERT_ID();

INSERT INTO t_historique_ligne_picking_statut
    (ligne_picking_id, statut_id, date_changement, user_id)
VALUES
    (@lig_coca2,   @sl_reservee, NOW() - INTERVAL 5 DAY, @u_ope),
    (@lig_coca2,   @sl_en_cours, NOW() - INTERVAL 5 DAY + INTERVAL 15 MINUTE, @u_ope),
    (@lig_coca2,   @sl_prelevee, NOW() - INTERVAL 4 DAY, @u_adm),
    (@lig_candia2, @sl_reservee, NOW() - INTERVAL 5 DAY, @u_ope),
    (@lig_candia2, @sl_en_cours, NOW() - INTERVAL 5 DAY + INTERVAL 30 MINUTE, @u_ope),
    (@lig_candia2, @sl_prelevee, NOW() - INTERVAL 5 DAY + INTERVAL 31 MINUTE, @u_ope);

INSERT INTO t_prelevement
    (commande_id, ligne_picking_id, emplacement_id, statut_prelevement_id,
     quantitePiecesPrelevee, user_id, date_prelevement, dlc, dlv)
VALUES
    (@cmd_coca2, @lig_coca2, @e4, @spr_confirme, 36, @u_ope,
     NOW() - INTERVAL 5 DAY + INTERVAL 15 MINUTE, '2027-02-28', '2027-02-14'),
    (@cmd_candia2, @lig_candia2, @e5, @spr_confirme, 60, @u_ope,
     NOW() - INTERVAL 5 DAY + INTERVAL 30 MINUTE, '2027-07-31', '2027-07-15');

-- Mouvements de SORTIE ecrits a la validation (un par prelevement, en pieces).
INSERT INTO t_mouvement_stock
    (type_mouvement_id, emplacement_id, en_reserve, user_id,
     nombre_conditionnements, conditionnement_id, quantite_pieces_reelle,
     date_mouvement, commentaire, detail_journal_id)
VALUES
    (@tm_sortie, @e4, FALSE, @u_ope, 6, @c_coca, 36,
     NOW() - INTERVAL 4 DAY, 'Sortie du journal SOR-DEMO-RESTE-002', @d_coca2),
    (@tm_sortie, @e5, FALSE, @u_ope, 5, @c_candia, 60,
     NOW() - INTERVAL 4 DAY, 'Sortie du journal SOR-DEMO-RESTE-002', @d_candia2);

-- ----------------------------------------------------------------------------
-- B3. Le bon de reste : SOR-DEMO-RESTE-002-R1 (EN COURS), lie a l'origine
--     Il reprend le manque : Coca-Cola 10 - 6 = 4 conditionnements.
-- ----------------------------------------------------------------------------

INSERT INTO t_journal_mouvement
    (nom_client, reference, url_piece_jointe, fournisseur_id,
     type_mouvement_journal_id, statut_id, journal_origine_id)
VALUES ('Shoprite Analakely', 'SOR-DEMO-RESTE-002-R1', NULL, NULL,
        @tj_sortie, @sj_en_cours, @j_sor2);
SET @j_bon2 = LAST_INSERT_ID();

INSERT INTO t_historique_journal_mouvement_statut
    (journal_mouvement_id, statut_id, date_changement, user_id)
VALUES (@j_bon2, @sj_en_cours, NOW() - INTERVAL 4 DAY, @u_adm);

INSERT INTO t_commande
    (etat, remarque, quantite_demande, quantite_reel, isChecked,
     article_id, journal_mouvement_id, user_id)
VALUES (FALSE, 'Reste de SOR-DEMO-RESTE-002', 4, NULL, TRUE,
        @a_coca, @j_bon2, NULL);

COMMIT;

-- ============================================================================
-- 3. VERIFICATIONS
-- ============================================================================

-- 3.1 Journaux crees, avec leur statut et leur journal d'origine.
SELECT j.id, j.reference, tj.nom_type_mouvement AS type, s.nom AS statut,
       j.nom_client, origine.reference AS journal_origine
FROM t_journal_mouvement j
JOIN t_type_mouvement_journal tj ON tj.id = j.type_mouvement_journal_id
JOIN t_statut_journal_mouvement s ON s.id = j.statut_id
LEFT JOIN t_journal_mouvement origine ON origine.id = j.journal_origine_id
WHERE j.reference LIKE 'ENT-DEMO-RESTE-%' OR j.reference LIKE 'SOR-DEMO-RESTE-%'
ORDER BY j.id;

-- 3.2 Reste par commande, calcule comme le fait l'application :
--     demande - (pieces prelevees / pieces par conditionnement).
SELECT j.reference, a.nom_article,
       c.quantite_demande AS demande,
       COALESCE(SUM(p.quantitePiecesPrelevee), 0) AS pieces_prelevees,
       FLOOR(COALESCE(SUM(p.quantitePiecesPrelevee), 0) / ac.quantite_piece_standard) AS servi,
       c.quantite_demande
         - FLOOR(COALESCE(SUM(p.quantitePiecesPrelevee), 0) / ac.quantite_piece_standard) AS reste
FROM t_commande c
JOIN t_journal_mouvement j ON j.id = c.journal_mouvement_id
JOIN t_article a ON a.id = c.article_id
JOIN t_article_conditionnement ac ON ac.article_id = a.id
LEFT JOIN t_prelevement p ON p.commande_id = c.id
WHERE j.reference LIKE 'SOR-DEMO-RESTE-%'
GROUP BY c.id, j.reference, a.nom_article, c.quantite_demande, ac.quantite_piece_standard
ORDER BY j.reference, c.id;

-- 3.3 Lignes de picking et leur statut.
SELECT j.reference, l.ordre_passage, e.nom_emplacement, a.nom_article,
       l.quantite_conditionnements_a_prelever AS reserve_cond,
       l.quantite_pieces_a_prelever AS reserve_pieces,
       s.nom AS statut_ligne,
       COALESCE(SUM(p.quantitePiecesPrelevee), 0) AS pieces_prelevees
FROM t_ligne_picking l
JOIN t_picking pk ON pk.id = l.picking_id
JOIN t_journal_mouvement j ON j.id = pk.journal_mouvement_id
JOIN t_emplacement e ON e.id = l.emplacement_id
JOIN t_commande c ON c.id = l.commande_id
JOIN t_article a ON a.id = c.article_id
JOIN t_statut_ligne_picking s ON s.id = l.statut_id
LEFT JOIN t_prelevement p ON p.ligne_picking_id = l.id
WHERE j.reference LIKE 'SOR-DEMO-RESTE-%'
GROUP BY l.id, j.reference, l.ordre_passage, e.nom_emplacement, a.nom_article,
         l.quantite_conditionnements_a_prelever, l.quantite_pieces_a_prelever, s.nom
ORDER BY j.reference, l.ordre_passage;

-- 3.4 Stock par emplacement (en pieces). Attendu :
--     E-001 Coca 60 | E-002 Candia 96 | E-003 Eau Vive 30
--     E-004 Coca 18 | E-005 Candia 24
--     (le scenario A n'a pas encore retire de stock : la sortie n'est pas validee)
SELECT e.nom_emplacement, a.nom_article, v.quantite_stock AS pieces
FROM v_stock_par_emplacement v
JOIN t_emplacement e ON e.id = v.emplacement_id
JOIN t_article a ON a.id = v.article_id
WHERE e.nom_emplacement IN ('E-001', 'E-002', 'E-003', 'E-004', 'E-005')
ORDER BY e.nom_emplacement;

-- 3.5 Controle : aucun stock negatif (resultat attendu : aucune ligne).
SELECT * FROM v_stock_par_emplacement WHERE quantite_stock < 0;

-- 3.6 Ce qu'il faut observer dans l'application :
--   1. Valider SOR-DEMO-RESTE-001 (page "Confirmation de sortie").
--   2. Le journal passe en CLOTURE ; un journal SOR-DEMO-RESTE-001-R1 apparait
--      avec : Coca-Cola 7, Eau Vive 6, Savon liquide 4.
--   3. Stock apres validation : E-001 Coca 18, E-002 Candia 0, E-003 Eau Vive 30.
--   4. PDF : GET /journaux-mouvements/<id du bon>/bon.pdf
--   5. La ligne Eau Vive (IMPOSSIBLE) ne retire rien : les 30 pieces du stock
--      theorique restent a corriger par un inventaire.
