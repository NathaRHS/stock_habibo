-- ============================================================================
-- SIMULATION D'UN MOIS D'OPERATIONS WMS
-- ============================================================================
-- Ce script conserve le referentiel : utilisateurs, roles, articles,
-- conditionnements, palettes, racks et emplacements.
-- Il reinitialise uniquement les donnees operationnelles, puis insere :
--   - entrees de stock et mouvements d'entree ;
--   - sorties, pickings, lignes de picking et prelevements ;
--   - inventaires et comptages ;
--   - notifications administrateur.
--
-- Prerequis : lancer le backend une fois pour creer t_notification avec JPA.
-- Dates : le script simule les 30 derniers jours a partir de CURDATE().

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

START TRANSACTION;

-- --------------------------------------------------------------------------
-- 1. REFERENCES EXISTANTES UTILISEES PAR LA SIMULATION

-- --------------------------------------------------------------------------
INSERT IGNORE INTO t_statut_prelevement (nom_statut)
VALUES ('CONFIRME');

SET @admin_id = (
    SELECT u.id
    FROM t_user u JOIN t_roles r ON r.id = u.role_id
    WHERE r.nom_role = 'ADMIN'
    ORDER BY u.id LIMIT 1
);
SET @operateur_id = (
    SELECT u.id
    FROM t_user u JOIN t_roles r ON r.id = u.role_id
    WHERE r.nom_role = 'OPERATEUR'
    ORDER BY u.id LIMIT 1
);
SET @inventoriste_id = (
    SELECT u.id
    FROM t_user u JOIN t_roles r ON r.id = u.role_id
    WHERE r.nom_role = 'INVENTORISTE'
    ORDER BY u.id LIMIT 1
);

SET @type_entree = (SELECT id FROM t_type_mouvement_journal WHERE nom_type_mouvement = 'ENTREE' LIMIT 1);
SET @type_sortie = (SELECT id FROM t_type_mouvement_journal WHERE nom_type_mouvement = 'SORTIE' LIMIT 1);
SET @type_inventaire = (SELECT id FROM t_type_mouvement_journal WHERE nom_type_mouvement = 'INVENTAIRE' LIMIT 1);
SET @statut_valide = (SELECT id FROM t_statut WHERE nom = 'VALIDE' LIMIT 1);
SET @statut_cours = (SELECT id FROM t_statut WHERE nom = 'EN COURS' LIMIT 1);
SET @statut_attente = (SELECT id FROM t_statut WHERE nom = 'EN ATTENTE' LIMIT 1);
SET @type_mvt_entree = (SELECT id FROM t_type_mouvement WHERE nom_type_mouvement = 'ENTREE' LIMIT 1);
SET @type_mvt_sortie = (SELECT id FROM t_type_mouvement WHERE nom_type_mouvement = 'SORTIE' LIMIT 1);
SET @statut_prelevement_confirme = (SELECT id FROM t_statut_prelevement WHERE nom_statut = 'CONFIRME' LIMIT 1);

SET @article_coca = (SELECT id FROM t_article WHERE nom_article LIKE 'Coca-Cola%' ORDER BY id LIMIT 1);
SET @article_lait = (SELECT id FROM t_article WHERE nom_article LIKE 'Lait Candia%' ORDER BY id LIMIT 1);
SET @article_eau = (SELECT id FROM t_article WHERE nom_article LIKE 'Eau Vive%' ORDER BY id LIMIT 1);
SET @article_savon = (SELECT id FROM t_article WHERE nom_article LIKE 'Savon liquide%' ORDER BY id LIMIT 1);

SET @cond_coca = (SELECT id FROM t_article_conditionnement WHERE article_id = @article_coca ORDER BY id LIMIT 1);
SET @cond_lait = (SELECT id FROM t_article_conditionnement WHERE article_id = @article_lait ORDER BY id LIMIT 1);
SET @cond_eau = (SELECT id FROM t_article_conditionnement WHERE article_id = @article_eau ORDER BY id LIMIT 1);
SET @cond_savon = (SELECT id FROM t_article_conditionnement WHERE article_id = @article_savon ORDER BY id LIMIT 1);

SET @rack_a = (SELECT id FROM t_rack WHERE nom_rack = 'RACK-A' LIMIT 1);
SET @rack_b = (SELECT id FROM t_rack WHERE nom_rack = 'RACK-B' LIMIT 1);
SET @rack_c = (SELECT id FROM t_rack WHERE nom_rack = 'RACK-C' LIMIT 1);
SET @emp_a001 = (SELECT id FROM t_emplacement WHERE nom_emplacement = 'A-001' LIMIT 1);
SET @emp_a002 = (SELECT id FROM t_emplacement WHERE nom_emplacement = 'A-002' LIMIT 1);
SET @emp_a003 = (SELECT id FROM t_emplacement WHERE nom_emplacement = 'A-003' LIMIT 1);
SET @emp_b001 = (SELECT id FROM t_emplacement WHERE nom_emplacement = 'B-001' LIMIT 1);
SET @emp_b002 = (SELECT id FROM t_emplacement WHERE nom_emplacement = 'B-002' LIMIT 1);
SET @emp_c001 = (SELECT id FROM t_emplacement WHERE nom_emplacement = 'C-001' LIMIT 1);

-- Affiche les references essentielles avant insertion. Elles ne doivent pas etre NULL.
SELECT @admin_id AS admin_id, @operateur_id AS operateur_id,
       @inventoriste_id AS inventoriste_id, @type_entree AS type_entree,
       @type_sortie AS type_sortie, @type_inventaire AS type_inventaire,
       @article_coca AS article_coca, @article_lait AS article_lait,
       @article_eau AS article_eau, @article_savon AS article_savon;

-- --------------------------------------------------------------------------
-- 2. ENTREES SUR LE MOIS : STOCK HISTORIQUE ET ENTREE EN ATTENTE
-- --------------------------------------------------------------------------
INSERT INTO t_journal_mouvement
    (nom_client, reference, url_piece_jointe, fournisseur_id, type_mouvement_journal_id, statut_id)
VALUES
    (NULL, 'REC-202609-001', '/documents/rec-202609-001.pdf', NULL, @type_entree, @statut_valide),
    (NULL, 'REC-202609-002', '/documents/rec-202609-002.pdf', NULL, @type_entree, @statut_valide),
    (NULL, 'REC-202609-003', '/documents/rec-202609-003.pdf', NULL, @type_entree, @statut_cours),
    (NULL, 'REC-202609-004', '/documents/rec-202609-004.pdf', NULL, @type_entree, @statut_valide);

SET @rec_1 = (SELECT id FROM t_journal_mouvement WHERE reference = 'REC-202609-001');
SET @rec_2 = (SELECT id FROM t_journal_mouvement WHERE reference = 'REC-202609-002');
SET @rec_3 = (SELECT id FROM t_journal_mouvement WHERE reference = 'REC-202609-003');
SET @rec_4 = (SELECT id FROM t_journal_mouvement WHERE reference = 'REC-202609-004');

INSERT INTO t_detail_journal
    (journal_mouvement_id, article_id, quantite, quantite_conditionnement, dlc, dlv)
VALUES
    (@rec_1, @article_coca, 600, 100, DATE_ADD(CURDATE(), INTERVAL 150 DAY), DATE_ADD(CURDATE(), INTERVAL 140 DAY)),
    (@rec_1, @article_lait, 480, 40, DATE_ADD(CURDATE(), INTERVAL 70 DAY), DATE_ADD(CURDATE(), INTERVAL 60 DAY)),
    (@rec_1, @article_eau, 360, 60, DATE_ADD(CURDATE(), INTERVAL 210 DAY), DATE_ADD(CURDATE(), INTERVAL 200 DAY)),
    (@rec_2, @article_coca, 300, 50, DATE_ADD(CURDATE(), INTERVAL 120 DAY), DATE_ADD(CURDATE(), INTERVAL 110 DAY)),
    (@rec_2, @article_savon, 240, 20, DATE_ADD(CURDATE(), INTERVAL 180 DAY), DATE_ADD(CURDATE(), INTERVAL 170 DAY)),
    (@rec_3, @article_lait, 240, 20, DATE_ADD(CURDATE(), INTERVAL 45 DAY), DATE_ADD(CURDATE(), INTERVAL 35 DAY)),
    (@rec_4, @article_coca, 240, 40, DATE_ADD(CURDATE(), INTERVAL 100 DAY), DATE_ADD(CURDATE(), INTERVAL 90 DAY)),
    (@rec_4, @article_eau, 180, 30, DATE_ADD(CURDATE(), INTERVAL 190 DAY), DATE_ADD(CURDATE(), INTERVAL 180 DAY));

SET @d_rec1_coca = (SELECT id FROM t_detail_journal WHERE journal_mouvement_id = @rec_1 AND article_id = @article_coca);
SET @d_rec1_lait = (SELECT id FROM t_detail_journal WHERE journal_mouvement_id = @rec_1 AND article_id = @article_lait);
SET @d_rec1_eau = (SELECT id FROM t_detail_journal WHERE journal_mouvement_id = @rec_1 AND article_id = @article_eau);
SET @d_rec2_coca = (SELECT id FROM t_detail_journal WHERE journal_mouvement_id = @rec_2 AND article_id = @article_coca);
SET @d_rec2_savon = (SELECT id FROM t_detail_journal WHERE journal_mouvement_id = @rec_2 AND article_id = @article_savon);
SET @d_rec4_coca = (SELECT id FROM t_detail_journal WHERE journal_mouvement_id = @rec_4 AND article_id = @article_coca);
SET @d_rec4_eau = (SELECT id FROM t_detail_journal WHERE journal_mouvement_id = @rec_4 AND article_id = @article_eau);

-- Mouvements d'entree deja ranges : ils alimentent v_stock_par_emplacement.
INSERT INTO t_mouvement_stock
    (conditionnement_id, commentaire, date_mouvement, nombre_conditionnements,
     quantite_pieces_reelle, type_mouvement_id, user_id, emplacement_id, en_reserve, detail_journal_id)
VALUES
    (@cond_coca, 'Reception septembre - Coca-Cola A-001', TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 27 DAY), '08:20:00'), 60, 360, @type_mvt_entree, @admin_id, @emp_a001, FALSE, @d_rec1_coca),
    (@cond_coca, 'Reception septembre - Coca-Cola A-002', TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 27 DAY), '08:22:00'), 40, 240, @type_mvt_entree, @admin_id, @emp_a002, FALSE, @d_rec1_coca),
    (@cond_lait, 'Reception septembre - Lait B-001', TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 27 DAY), '08:30:00'), 40, 480, @type_mvt_entree, @admin_id, @emp_b001, FALSE, @d_rec1_lait),
    (@cond_eau, 'Reception septembre - Eau C-001', TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 27 DAY), '08:40:00'), 60, 360, @type_mvt_entree, @admin_id, @emp_c001, FALSE, @d_rec1_eau),
    (@cond_coca, 'Reception septembre - Coca-Cola A-003', TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 19 DAY), '09:10:00'), 50, 300, @type_mvt_entree, @admin_id, @emp_a003, FALSE, @d_rec2_coca),
    (@cond_savon, 'Reception septembre - Savon B-002', TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 19 DAY), '09:18:00'), 20, 240, @type_mvt_entree, @admin_id, @emp_b002, FALSE, @d_rec2_savon);

-- --------------------------------------------------------------------------
-- 3. SORTIES : UNE TERMINEE, UNE EN COURS, UNE PRETE A CONFIRMER
-- --------------------------------------------------------------------------
INSERT INTO t_journal_mouvement
    (nom_client, reference, url_piece_jointe, fournisseur_id, type_mouvement_journal_id, statut_id)
VALUES
    ('SUPERETTE CENTRE', 'SOR-202609-001', '/documents/bl-sor-001.pdf', NULL, @type_sortie, @statut_valide),
    ('MAGASIN BETA', 'SOR-202609-002', '/documents/bl-sor-002.pdf', NULL, @type_sortie, @statut_cours),
    ('HOTEL OCEAN', 'SOR-202609-003', '/documents/bl-sor-003.pdf', NULL, @type_sortie, @statut_attente);

SET @sor_1 = (SELECT id FROM t_journal_mouvement WHERE reference = 'SOR-202609-001');
SET @sor_2 = (SELECT id FROM t_journal_mouvement WHERE reference = 'SOR-202609-002');
SET @sor_3 = (SELECT id FROM t_journal_mouvement WHERE reference = 'SOR-202609-003');

INSERT INTO t_commande
    (etat, isChecked, quantite_demande, quantite_reel, remarque, article_id, journal_mouvement_id, user_id)
VALUES
    (1, 1, 25, 25, 'Sortie deja confirmee', @article_coca, @sor_1, @operateur_id),
    (1, 1, 10, 10, 'Sortie deja confirmee', @article_lait, @sor_1, @operateur_id),
    (0, 1, 30, NULL, 'Picking en cours', @article_coca, @sor_2, @operateur_id),
    (0, 1, 8, NULL, 'Picking en cours', @article_lait, @sor_2, @operateur_id),
    (0, 1, 20, 20, 'Prelevement termine, confirmation admin attendue', @article_eau, @sor_3, @operateur_id);

SET @cmd_sor1_coca = (SELECT id FROM t_commande WHERE journal_mouvement_id = @sor_1 AND article_id = @article_coca);
SET @cmd_sor1_lait = (SELECT id FROM t_commande WHERE journal_mouvement_id = @sor_1 AND article_id = @article_lait);
SET @cmd_sor2_coca = (SELECT id FROM t_commande WHERE journal_mouvement_id = @sor_2 AND article_id = @article_coca);
SET @cmd_sor2_lait = (SELECT id FROM t_commande WHERE journal_mouvement_id = @sor_2 AND article_id = @article_lait);
SET @cmd_sor3_eau = (SELECT id FROM t_commande WHERE journal_mouvement_id = @sor_3 AND article_id = @article_eau);

INSERT INTO t_picking
    (date_generation_picking, date_debut, date_fin, journal_mouvement_id, user_id, rack_depart_id, statut)
VALUES
    (TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 16 DAY), '07:50:00'), TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 16 DAY), '08:00:00'), TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 16 DAY), '08:45:00'), @sor_1, @operateur_id, @rack_a, 'TERMINE'),
    (TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 3 DAY), '09:00:00'), TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 3 DAY), '09:10:00'), NULL, @sor_2, @operateur_id, @rack_a, 'EN_COURS'),
    (TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '13:10:00'), TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '13:20:00'), TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '14:15:00'), @sor_3, @operateur_id, @rack_c, 'TERMINE');

SET @pick_sor1 = (SELECT id FROM t_picking WHERE journal_mouvement_id = @sor_1);
SET @pick_sor2 = (SELECT id FROM t_picking WHERE journal_mouvement_id = @sor_2);
SET @pick_sor3 = (SELECT id FROM t_picking WHERE journal_mouvement_id = @sor_3);

INSERT INTO t_ligne_picking
    (date_reservation, ordre_passage, quantite_conditionnements_a_prelever, quantite_pieces_a_prelever,
     statut, commande_id, detail_journal_source_id, emplacement_id, picking_id, article_conditionnement_id)
VALUES
    (TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 16 DAY), '08:00:00'), 1, 25, 150, 'PRELEVEE', @cmd_sor1_coca, @d_rec1_coca, @emp_a001, @pick_sor1, @cond_coca),
    (TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 16 DAY), '08:10:00'), 2, 10, 120, 'PRELEVEE', @cmd_sor1_lait, @d_rec1_lait, @emp_b001, @pick_sor1, @cond_lait),
    (TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 3 DAY), '09:10:00'), 1, 20, 120, 'PRELEVEE', @cmd_sor2_coca, @d_rec1_coca, @emp_a001, @pick_sor2, @cond_coca),
    (TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 3 DAY), '09:10:00'), 2, 10, 60, 'RESERVEE', @cmd_sor2_coca, @d_rec2_coca, @emp_a003, @pick_sor2, @cond_coca),
    (TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 3 DAY), '09:10:00'), 3, 8, 96, 'RESERVEE', @cmd_sor2_lait, @d_rec1_lait, @emp_b001, @pick_sor2, @cond_lait),
    (TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '13:20:00'), 1, 20, 120, 'PRELEVEE', @cmd_sor3_eau, @d_rec1_eau, @emp_c001, @pick_sor3, @cond_eau);

SET @lp_sor1_coca = (SELECT id FROM t_ligne_picking WHERE picking_id = @pick_sor1 AND ordre_passage = 1);
SET @lp_sor1_lait = (SELECT id FROM t_ligne_picking WHERE picking_id = @pick_sor1 AND ordre_passage = 2);
SET @lp_sor2_coca = (SELECT id FROM t_ligne_picking WHERE picking_id = @pick_sor2 AND ordre_passage = 1);
SET @lp_sor3_eau = (SELECT id FROM t_ligne_picking WHERE picking_id = @pick_sor3 AND ordre_passage = 1);

INSERT INTO t_prelevement
    (commande_id, ligne_picking_id, emplacement_id, statut_prelevement_id,
     quantite_pieces_prelevee, user_id, date_prelevement, dlc, dlv)
VALUES
    (@cmd_sor1_coca, @lp_sor1_coca, @emp_a001, @statut_prelevement_confirme, 150, @operateur_id, TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 16 DAY), '08:12:00'), DATE_ADD(CURDATE(), INTERVAL 150 DAY), DATE_ADD(CURDATE(), INTERVAL 140 DAY)),
    (@cmd_sor1_lait, @lp_sor1_lait, @emp_b001, @statut_prelevement_confirme, 120, @operateur_id, TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 16 DAY), '08:30:00'), DATE_ADD(CURDATE(), INTERVAL 70 DAY), DATE_ADD(CURDATE(), INTERVAL 60 DAY)),
    (@cmd_sor2_coca, @lp_sor2_coca, @emp_a001, @statut_prelevement_confirme, 120, @operateur_id, TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 3 DAY), '09:25:00'), DATE_ADD(CURDATE(), INTERVAL 150 DAY), DATE_ADD(CURDATE(), INTERVAL 140 DAY)),
    (@cmd_sor3_eau, @lp_sor3_eau, @emp_c001, @statut_prelevement_confirme, 120, @operateur_id, TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '13:55:00'), DATE_ADD(CURDATE(), INTERVAL 210 DAY), DATE_ADD(CURDATE(), INTERVAL 200 DAY));

-- Seule la sortie confirmee cree les mouvements SORTIE definitifs.
INSERT INTO t_mouvement_stock
    (conditionnement_id, commentaire, date_mouvement, nombre_conditionnements,
     quantite_pieces_reelle, type_mouvement_id, user_id, emplacement_id, en_reserve, detail_journal_id)
VALUES
    (@cond_coca, 'Sortie confirmee SOR-202609-001', TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 16 DAY), '10:00:00'), 25, 150, @type_mvt_sortie, @admin_id, @emp_a001, FALSE, @d_rec1_coca),
    (@cond_lait, 'Sortie confirmee SOR-202609-001', TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 16 DAY), '10:00:00'), 10, 120, @type_mvt_sortie, @admin_id, @emp_b001, FALSE, @d_rec1_lait);

-- --------------------------------------------------------------------------
-- 4. INVENTAIRES : UN TERMINE AVEC ECART, UN EN COURS
-- --------------------------------------------------------------------------
INSERT INTO t_journal_mouvement
    (nom_client, reference, url_piece_jointe, fournisseur_id, type_mouvement_journal_id, statut_id)
VALUES
    (NULL, 'INV-202609-001', NULL, NULL, @type_inventaire, @statut_valide),
    (NULL, 'INV-202609-002', NULL, NULL, @type_inventaire, @statut_cours);

SET @inv_1 = (SELECT id FROM t_journal_mouvement WHERE reference = 'INV-202609-001');
SET @inv_2 = (SELECT id FROM t_journal_mouvement WHERE reference = 'INV-202609-002');

INSERT INTO t_detail_journal
    (journal_mouvement_id, article_id, quantite, quantite_conditionnement, dlc, dlv)
VALUES
    (@inv_1, @article_coca, 330, NULL, NULL, NULL),
    (@inv_1, @article_lait, 360, NULL, NULL, NULL),
    (@inv_2, @article_eau, 240, NULL, NULL, NULL),
    (@inv_2, @article_savon, 180, NULL, NULL, NULL);

SET @d_inv1_coca = (SELECT id FROM t_detail_journal WHERE journal_mouvement_id = @inv_1 AND article_id = @article_coca);
SET @d_inv1_lait = (SELECT id FROM t_detail_journal WHERE journal_mouvement_id = @inv_1 AND article_id = @article_lait);
SET @d_inv2_eau = (SELECT id FROM t_detail_journal WHERE journal_mouvement_id = @inv_2 AND article_id = @article_eau);

INSERT INTO t_comptage_inventaire
    (date_comptage, quantite_comptee, detail_journal_id, emplacement_id)
VALUES
    (TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 8 DAY), '10:15:00'), 325, @d_inv1_coca, @emp_a001),
    (TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 8 DAY), '10:28:00'), 360, @d_inv1_lait, @emp_b001),
    (TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 0 DAY), '09:30:00'), 240, @d_inv2_eau, @emp_c001);

-- --------------------------------------------------------------------------
-- 5. NOTIFICATIONS ADMINISTRATEUR : ACTIONS EN ATTENTE ET HISTORIQUE
-- --------------------------------------------------------------------------
INSERT INTO t_notification
    (categorie, type, priorite, titre, message, date_creation,
     date_lecture, date_traitement, url_cible, lu, traitee,
     destinataire_id, journal_id, detail_journal_id, emplacement_id)
VALUES
    ('ENTREE', 'ENTREE_A_AFFECTER', 'ATTENTION',
     'Affectation d''entree requise',
     'Le journal REC-202609-004 attend une affectation.',
     TIMESTAMP(CURDATE(), '08:00:00'), NULL, NULL,
     CONCAT('/journaux-mouvements/', @rec_4, '/affectation-stock'), FALSE, FALSE,
     @admin_id, @rec_4,
     (SELECT id FROM t_detail_journal WHERE journal_mouvement_id = @rec_4 AND article_id = @article_coca), NULL),
    ('SORTIE', 'SORTIE_A_CONFIRMER', 'URGENTE',
     'Sortie a confirmer',
     'La sortie SOR-202609-003 attend votre confirmation.',
     TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '14:20:00'), NULL, NULL,
     CONCAT('/sortie/', @sor_3), FALSE, FALSE,
     @admin_id, @sor_3, NULL, NULL),
    ('INVENTAIRE', 'INVENTAIRE_ECART', 'ATTENTION',
     'Ecart d''inventaire detecte',
     'Un ecart de comptage a ete detecte sur l''emplacement A-001.',
     TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 8 DAY), '11:00:00'),
     TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 8 DAY), '11:30:00'), NULL,
     CONCAT('/inventaire/', @inv_1), TRUE, FALSE,
     @admin_id, @inv_1, @d_inv1_coca, @emp_a001),
    ('INVENTAIRE', 'INVENTAIRE_A_REALISER', 'INFORMATION',
     'Inventaire en cours',
     'L''inventaire INV-202609-002 contient encore des emplacements a compter.',
     TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 2 DAY), '08:30:00'),
     TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 2 DAY), '09:00:00'), NULL,
     CONCAT('/inventaire/', @inv_2), TRUE, TRUE,
     @admin_id, @inv_2, @d_inv2_eau, @emp_c001);

COMMIT;

-- --------------------------------------------------------------------------
-- 6. CONTROLE FINAL
-- --------------------------------------------------------------------------
SELECT 'Journaux par type et statut' AS controle;
SELECT type.nom_type_mouvement AS type_journal,
       statut.nom AS statut,
       COUNT(*) AS total
FROM t_journal_mouvement journal
JOIN t_type_mouvement_journal type ON type.id = journal.type_mouvement_journal_id
JOIN t_statut statut ON statut.id = journal.statut_id
GROUP BY type.nom_type_mouvement, statut.nom
ORDER BY type_journal, statut;

SELECT 'Stock calcule par emplacement' AS controle;
SELECT * FROM v_stock_par_emplacement ORDER BY emplacement_id, article_id;

SELECT 'Pickings et lignes' AS controle;
SELECT picking.id, journal.reference, picking.statut, COUNT(ligne.id) AS nombre_lignes
FROM t_picking picking
JOIN t_journal_mouvement journal ON journal.id = picking.journal_mouvement_id
LEFT JOIN t_ligne_picking ligne ON ligne.picking_id = picking.id
GROUP BY picking.id, journal.reference, picking.statut
ORDER BY picking.id;

SELECT 'Notifications' AS controle;
SELECT id, categorie, type, priorite, titre, lu, traitee, url_cible
FROM t_notification
ORDER BY date_creation DESC;
