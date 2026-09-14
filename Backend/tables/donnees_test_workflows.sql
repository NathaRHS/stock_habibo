-- ============================================================================
-- DONNEES TRANSACTIONNELLES POUR TESTER LES WORKFLOWS DU WMS
-- ============================================================================
-- Prerequis :
--   1. Executer create.sql si la base n'existe pas encore.
--   2. Executer script-vrai.sql pour charger le referentiel permanent.
--   3. Executer reset_donnees_test.sql pour vider les anciennes operations.
--   4. Executer ce fichier.
--
-- Scenarios fournis :
--   - deux receptions validees constituant le stock initial ;
--   - deux lots de Coca-Cola avec des DLC differentes pour tester le FEFO ;
--   - une reception en cours pour tester le scan mobile ;
--   - un inventaire termine avec un manque et un surplus ;
--   - une sortie en cours avec trois commandes a preparer.
--
-- IMPORTANT : aucun prelevement n'est insere. La table t_prelevement doit
-- rester vide afin de tester manuellement chaque scan de sortie.
-- ============================================================================

USE stock_habibo;

START TRANSACTION;

-- ---------------------------------------------------------------------------
-- 1. RECEPTIONS VALIDEES QUI CONSTITUENT LE STOCK DISPONIBLE
-- ---------------------------------------------------------------------------

INSERT INTO t_journal_mouvement (
    nom_client, reference, url_piece_jointe, fournisseur_id,
    type_mouvement_journal_id, statut_journal_mouvement_id
) VALUES
    (NULL, 'REC-STOCK-001', '/documents/rec-stock-001.pdf',
     (SELECT id FROM t_societe WHERE nom_societe = 'Hb' LIMIT 1),
     (SELECT id FROM t_type_mouvement_journal WHERE nom_type_mouvement = 'ENTREE' LIMIT 1),
     (SELECT id FROM t_statut_journal_mouvement WHERE nom_statut = 'VALIDE' LIMIT 1)),
    (NULL, 'REC-STOCK-002', '/documents/rec-stock-002.pdf',
     (SELECT id FROM t_societe WHERE nom_societe = 'HH' LIMIT 1),
     (SELECT id FROM t_type_mouvement_journal WHERE nom_type_mouvement = 'ENTREE' LIMIT 1),
     (SELECT id FROM t_statut_journal_mouvement WHERE nom_statut = 'VALIDE' LIMIT 1));

-- REC-STOCK-001 : premier lot de Coca-Cola, Candia et Eau Vive.
INSERT INTO t_detail_journal (
    journal_mouvement_id, article_id, quantite,
    quantite_conditionnement, dlc, dlv
) VALUES
    ((SELECT id FROM t_journal_mouvement WHERE reference = 'REC-STOCK-001'),
     (SELECT id FROM t_article WHERE code_bar = '60001548856446'),
     360, 60, '2026-12-15', '2026-12-05'),
    ((SELECT id FROM t_journal_mouvement WHERE reference = 'REC-STOCK-001'),
     (SELECT id FROM t_article WHERE code_bar = '6200000000018'),
     360, 30, '2027-01-31', '2027-01-20'),
    ((SELECT id FROM t_journal_mouvement WHERE reference = 'REC-STOCK-001'),
     (SELECT id FROM t_article WHERE code_bar = '6223000011111'),
     240, 40, '2027-04-30', '2027-04-15');

-- REC-STOCK-002 : second lot du meme Coca-Cola, avec une DLC plus tardive.
INSERT INTO t_detail_journal (
    journal_mouvement_id, article_id, quantite,
    quantite_conditionnement, dlc, dlv
) VALUES (
    (SELECT id FROM t_journal_mouvement WHERE reference = 'REC-STOCK-002'),
    (SELECT id FROM t_article WHERE code_bar = '60001548856446'),
    240, 40, '2027-03-31', '2027-03-20'
);

INSERT INTO t_user_journal_mouvement (
    journal_mouvement_id, user_id, statut_participation, date_debut, date_fin
) VALUES
    ((SELECT id FROM t_journal_mouvement WHERE reference = 'REC-STOCK-001'),
     (SELECT id FROM t_user WHERE matricule = 'OPE001'),
     'TERMINE', '2026-09-01 08:00:00', '2026-09-01 09:00:00'),
    ((SELECT id FROM t_journal_mouvement WHERE reference = 'REC-STOCK-002'),
     (SELECT id FROM t_user WHERE matricule = 'OPE002'),
     'TERMINE', '2026-09-02 08:00:00', '2026-09-02 08:35:00');

-- Stock en pieces :
--   A-001 : 60 packs Coca-Cola = 360 pieces, DLC 15/12/2026
--   A-002 : 40 packs Coca-Cola = 240 pieces, DLC 31/03/2027
--   A-011 : 30 cartons Candia  = 360 pieces
--   B-001 : 40 packs Eau Vive  = 240 pieces
INSERT INTO t_mouvement_stock (
    conditionnement_id, commentaire, date_mouvement,
    nombre_conditionnements, quantite_pieces_reelle,
    type_mouvement_id, user_id, emplacement_id, en_reserve,
    detail_journal_id
) VALUES
    ((SELECT id FROM t_article_conditionnement WHERE code_barres = '60001548856453'),
     'Stock test Coca-Cola - lot DLC 15/12/2026', '2026-09-01 09:05:00',
     60, 360,
     (SELECT id FROM t_type_mouvement WHERE nom_type_mouvement = 'ENTREE' LIMIT 1),
     (SELECT id FROM t_user WHERE matricule = 'OPE001'),
     (SELECT id FROM t_emplacement WHERE nom_emplacement = 'A-001'), FALSE,
     (SELECT d.id FROM t_detail_journal d
      JOIN t_journal_mouvement j ON j.id = d.journal_mouvement_id
      JOIN t_article a ON a.id = d.article_id
      WHERE j.reference = 'REC-STOCK-001' AND a.code_bar = '60001548856446')),

    ((SELECT id FROM t_article_conditionnement WHERE code_barres = '60001548856453'),
     'Stock test Coca-Cola - lot DLC 31/03/2027', '2026-09-02 08:40:00',
     40, 240,
     (SELECT id FROM t_type_mouvement WHERE nom_type_mouvement = 'ENTREE' LIMIT 1),
     (SELECT id FROM t_user WHERE matricule = 'OPE002'),
     (SELECT id FROM t_emplacement WHERE nom_emplacement = 'A-002'), FALSE,
     (SELECT d.id FROM t_detail_journal d
      JOIN t_journal_mouvement j ON j.id = d.journal_mouvement_id
      JOIN t_article a ON a.id = d.article_id
      WHERE j.reference = 'REC-STOCK-002' AND a.code_bar = '60001548856446')),

    ((SELECT id FROM t_article_conditionnement WHERE code_barres = '6200000000025'),
     'Stock test Lait Candia', '2026-09-01 09:10:00',
     30, 360,
     (SELECT id FROM t_type_mouvement WHERE nom_type_mouvement = 'ENTREE' LIMIT 1),
     (SELECT id FROM t_user WHERE matricule = 'OPE001'),
     (SELECT id FROM t_emplacement WHERE nom_emplacement = 'A-011'), FALSE,
     (SELECT d.id FROM t_detail_journal d
      JOIN t_journal_mouvement j ON j.id = d.journal_mouvement_id
      JOIN t_article a ON a.id = d.article_id
      WHERE j.reference = 'REC-STOCK-001' AND a.code_bar = '6200000000018')),

    ((SELECT id FROM t_article_conditionnement WHERE code_barres = '6223000011128'),
     'Stock test Eau Vive', '2026-09-01 09:15:00',
     40, 240,
     (SELECT id FROM t_type_mouvement WHERE nom_type_mouvement = 'ENTREE' LIMIT 1),
     (SELECT id FROM t_user WHERE matricule = 'OPE001'),
     (SELECT id FROM t_emplacement WHERE nom_emplacement = 'B-001'), FALSE,
     (SELECT d.id FROM t_detail_journal d
      JOIN t_journal_mouvement j ON j.id = d.journal_mouvement_id
      JOIN t_article a ON a.id = d.article_id
      WHERE j.reference = 'REC-STOCK-001' AND a.code_bar = '6223000011111'));

-- ---------------------------------------------------------------------------
-- 2. RECEPTION EN COURS POUR TESTER LE SCAN
-- ---------------------------------------------------------------------------

INSERT INTO t_journal_mouvement (
    nom_client, reference, url_piece_jointe, fournisseur_id,
    type_mouvement_journal_id, statut_journal_mouvement_id
) VALUES (
    NULL, 'REC-SCAN-TEST-001', '/documents/rec-scan-test-001.pdf',
    (SELECT id FROM t_societe WHERE nom_societe = 'Hm' LIMIT 1),
    (SELECT id FROM t_type_mouvement_journal WHERE nom_type_mouvement = 'ENTREE' LIMIT 1),
    (SELECT id FROM t_statut_journal_mouvement WHERE nom_statut = 'EN COURS' LIMIT 1)
);

INSERT INTO t_user_journal_mouvement (
    journal_mouvement_id, user_id, statut_participation, date_debut, date_fin
) VALUES (
    (SELECT id FROM t_journal_mouvement WHERE reference = 'REC-SCAN-TEST-001'),
    (SELECT id FROM t_user WHERE matricule = 'OPE002'),
    'EN_COURS', '2026-09-09 08:00:00', NULL
);

-- Aucun detail n'est ajoute : les lignes seront creees par les scans.

-- ---------------------------------------------------------------------------
-- 3. INVENTAIRE TERMINE, EN ATTENTE DE CONTROLE
-- ---------------------------------------------------------------------------

INSERT INTO t_journal_mouvement (
    nom_client, reference, url_piece_jointe, fournisseur_id,
    type_mouvement_journal_id, statut_journal_mouvement_id
) VALUES (
    NULL, 'INV-CONTROLE-TEST-001', NULL, NULL,
    (SELECT id FROM t_type_mouvement_journal WHERE nom_type_mouvement = 'INVENTAIRE' LIMIT 1),
    (SELECT id FROM t_statut_journal_mouvement WHERE nom_statut = 'EN ATTENTE' LIMIT 1)
);

INSERT INTO t_detail_journal (
    journal_mouvement_id, article_id, quantite,
    quantite_conditionnement, dlc, dlv
) VALUES
    ((SELECT id FROM t_journal_mouvement WHERE reference = 'INV-CONTROLE-TEST-001'),
     (SELECT id FROM t_article WHERE code_bar = '60001548856446'),
     355, NULL, NULL, NULL),
    ((SELECT id FROM t_journal_mouvement WHERE reference = 'INV-CONTROLE-TEST-001'),
     (SELECT id FROM t_article WHERE code_bar = '6200000000018'),
     365, NULL, NULL, NULL),
    ((SELECT id FROM t_journal_mouvement WHERE reference = 'INV-CONTROLE-TEST-001'),
     (SELECT id FROM t_article WHERE code_bar = '6223000011111'),
     240, NULL, NULL, NULL);

INSERT INTO t_comptage_inventaire (
    detail_journal_id, emplacement_id, quantite_comptee, date_comptage
) VALUES
    ((SELECT d.id FROM t_detail_journal d
      JOIN t_journal_mouvement j ON j.id = d.journal_mouvement_id
      JOIN t_article a ON a.id = d.article_id
      WHERE j.reference = 'INV-CONTROLE-TEST-001' AND a.code_bar = '60001548856446'),
     (SELECT id FROM t_emplacement WHERE nom_emplacement = 'A-001'),
     355, '2026-09-08 10:15:00'),
    ((SELECT d.id FROM t_detail_journal d
      JOIN t_journal_mouvement j ON j.id = d.journal_mouvement_id
      JOIN t_article a ON a.id = d.article_id
      WHERE j.reference = 'INV-CONTROLE-TEST-001' AND a.code_bar = '6200000000018'),
     (SELECT id FROM t_emplacement WHERE nom_emplacement = 'A-011'),
     365, '2026-09-08 10:30:00'),
    ((SELECT d.id FROM t_detail_journal d
      JOIN t_journal_mouvement j ON j.id = d.journal_mouvement_id
      JOIN t_article a ON a.id = d.article_id
      WHERE j.reference = 'INV-CONTROLE-TEST-001' AND a.code_bar = '6223000011111'),
     (SELECT id FROM t_emplacement WHERE nom_emplacement = 'B-001'),
     240, '2026-09-08 10:45:00');

INSERT INTO t_user_journal_mouvement (
    journal_mouvement_id, user_id, statut_participation, date_debut, date_fin
) VALUES
    ((SELECT id FROM t_journal_mouvement WHERE reference = 'INV-CONTROLE-TEST-001'),
     (SELECT id FROM t_user WHERE matricule = 'INV001'),
     'TERMINE', '2026-09-08 09:00:00', '2026-09-08 11:00:00'),
    ((SELECT id FROM t_journal_mouvement WHERE reference = 'INV-CONTROLE-TEST-001'),
     (SELECT id FROM t_user WHERE matricule = 'INV002'),
     'TERMINE', '2026-09-08 09:00:00', '2026-09-08 11:00:00');

-- Resultats attendus du rapport :
--   Coca-Cola A-001 : theorique 360, compte 355, ecart -5.
--   Candia A-011    : theorique 360, compte 365, ecart +5.
--   Eau Vive B-001  : theorique 240, compte 240, ecart  0.

-- ---------------------------------------------------------------------------
-- 4. SORTIE EN COURS AVEC COMMANDES, MAIS SANS PRELEVEMENT
-- ---------------------------------------------------------------------------

INSERT INTO t_journal_mouvement (
    nom_client, reference, url_piece_jointe, fournisseur_id,
    type_mouvement_journal_id, statut_journal_mouvement_id
) VALUES (
    'Client Supermarche Analakely', 'SOR-PREP-TEST-001',
    '/documents/sor-prep-test-001.pdf', NULL,
    (SELECT id FROM t_type_mouvement_journal WHERE nom_type_mouvement = 'SORTIE' LIMIT 1),
    (SELECT id FROM t_statut_journal_mouvement WHERE nom_statut = 'EN COURS' LIMIT 1)
);

-- Les quantites demandees sont exprimees en conditionnements.
INSERT INTO t_commande (
    etat, remarque, quantite_demande, quantite_reel, isChecked,
    article_id, journal_mouvement_id, user_id
) VALUES
    (FALSE, 'Tester la proposition FEFO sur deux emplacements', 70, NULL, TRUE,
     (SELECT id FROM t_article WHERE code_bar = '60001548856446'),
     (SELECT id FROM t_journal_mouvement WHERE reference = 'SOR-PREP-TEST-001'),
     NULL),
    (FALSE, 'Commande standard Candia', 10, NULL, TRUE,
     (SELECT id FROM t_article WHERE code_bar = '6200000000018'),
     (SELECT id FROM t_journal_mouvement WHERE reference = 'SOR-PREP-TEST-001'),
     NULL),
    (FALSE, 'Commande standard Eau Vive', 15, NULL, TRUE,
     (SELECT id FROM t_article WHERE code_bar = '6223000011111'),
     (SELECT id FROM t_journal_mouvement WHERE reference = 'SOR-PREP-TEST-001'),
     NULL);

COMMIT;

-- ============================================================================
-- 5. VERIFICATIONS ET IDENTIFIANTS UTILES POUR LES TESTS API
-- ============================================================================

SELECT
    j.id AS journal_id,
    j.reference,
    tmj.nom_type_mouvement AS type_journal,
    sjm.nom_statut AS statut
FROM t_journal_mouvement j
JOIN t_type_mouvement_journal tmj
    ON tmj.id = j.type_mouvement_journal_id
JOIN t_statut_journal_mouvement sjm
    ON sjm.id = j.statut_journal_mouvement_id
ORDER BY j.id;

SELECT
    c.id AS commande_id,
    j.reference AS journal,
    a.id AS article_id,
    a.nom_article,
    c.quantite_demande AS quantite_demandee_conditionnements
FROM t_commande c
JOIN t_journal_mouvement j ON j.id = c.journal_mouvement_id
JOIN t_article a ON a.id = c.article_id
ORDER BY c.id;

SELECT
    v.article_id,
    a.nom_article,
    v.emplacement_id,
    e.nom_emplacement,
    v.quantite_stock AS quantite_stock_pieces
FROM v_stock_par_emplacement v
JOIN t_article a ON a.id = v.article_id
JOIN t_emplacement e ON e.id = v.emplacement_id
ORDER BY a.nom_article, e.nom_emplacement;

-- Le resultat attendu est obligatoirement 0 avant les tests de scan.
SELECT COUNT(*) AS nombre_prelevements_avant_test
FROM t_prelevement;
