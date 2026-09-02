-- ============================================================================
-- SEEDERS COMPLETS - WMS HABIBO
-- Base cible : stock_habibo
--
-- ATTENTION : ce script supprime les donnees presentes dans les tables metier,
-- y compris les utilisateurs, puis insere un jeu de test deterministe.
-- Il suppose que le schema et les vues ont deja ete crees par l'application.
--
-- Comptes de test (mot de passe commun : password)
--   ADM001  / admin
--   SUP001  / superviseur
--   OPE001  / operateur
-- ============================================================================

USE stock_habibo;

SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE t_mouvement_stock;
TRUNCATE TABLE t_user_journal_mouvement;
TRUNCATE TABLE t_detail_journal;
TRUNCATE TABLE t_journal_mouvement;
TRUNCATE TABLE t_palette_conditionnement;
TRUNCATE TABLE t_article_conditionnement;
TRUNCATE TABLE t_article;
TRUNCATE TABLE t_emplacement;
TRUNCATE TABLE t_rack;
TRUNCATE TABLE t_societe;
TRUNCATE TABLE t_user;
TRUNCATE TABLE t_roles;
TRUNCATE TABLE t_statut_journal_mouvement;
TRUNCATE TABLE t_type_mouvement;
TRUNCATE TABLE t_type_mouvement_journal;
TRUNCATE TABLE t_type_conditionnement;
TRUNCATE TABLE t_type_produit;

SET FOREIGN_KEY_CHECKS = 1;

START TRANSACTION;

-- ============================================================================
-- 1. REFERENTIELS
-- ============================================================================

INSERT INTO t_roles (id, nom_role) VALUES
    (1, 'ADMIN'),
    (2, 'SUPERVISEUR'),
    (3, 'RESPONSABLE_INVENTAIRE');

INSERT INTO t_statut_journal_mouvement (id, nom_statut) VALUES
    (1, 'EN COURS'),
    (2, 'VALIDE'),
    (3, 'MODIFIE'),
    (4, 'EN ATTENTE');

INSERT INTO t_type_mouvement (id, nom_type_mouvement, sens) VALUES
    (1, 'ENTREE', 1),
    (2, 'SORTIE', -1),
    (3, 'AJUSTEMENT_POSITIF', 1),
    (4, 'AJUSTEMENT_NEGATIF', -1);

INSERT INTO t_type_mouvement_journal (id, nom_type_mouvement, sens) VALUES
    (1, 'ENTREE', 1),
    (2, 'SORTIE', -1);

-- Dans le modele metier actuel, la piece n'est pas un conditionnement.
INSERT INTO t_type_conditionnement (id, nom_conditionnement) VALUES
    (1, 'PACK'),
    (2, 'CARTON');

INSERT INTO t_type_produit (id, nom_type) VALUES
    (1, 'BOISSON'),
    (2, 'ALIMENTAIRE'),
    (3, 'HYGIENE'),
    (4, 'ENTRETIEN');

-- ============================================================================
-- 2. UTILISATEURS
-- Hash BCrypt correspondant au mot de passe : password
-- ============================================================================

INSERT INTO t_user (
    id, username, matricule, email, password_hash, role_id
) VALUES
    (1, 'admin', 'ADM001', 'admin@habibo.test',
     '$2a$10$ji4.ARxiXTyclInFJFEJCu5s/EG8tu8undoP7PnZh/TXaKFhy9aOK', 1),
    (2, 'superviseur', 'SUP001', 'superviseur@habibo.test',
     '$2a$10$ji4.ARxiXTyclInFJFEJCu5s/EG8tu8undoP7PnZh/TXaKFhy9aOK', 2),
    (3, 'operateur', 'OPE001', 'operateur@habibo.test',
     '$2a$10$ji4.ARxiXTyclInFJFEJCu5s/EG8tu8undoP7PnZh/TXaKFhy9aOK', 3);

-- ============================================================================
-- 3. FOURNISSEURS / SOCIETES
-- ============================================================================

INSERT INTO t_societe (id, nom_societe) VALUES
    (1, 'STAR DISTRIBUTION'),
    (2, 'SODIMILK'),
    (3, 'DISTRIBUTION OCEAN INDIEN');

-- ============================================================================
-- 4. STRUCTURE DE L'ENTREPOT
-- Un emplacement represente directement une palette.
-- ============================================================================

INSERT INTO t_rack (id, nom_rack, nombre_etages) VALUES
    (1, 'RACK-A', 3),
    (2, 'RACK-B', 3),
    (3, 'RACK-C', 2);

INSERT INTO t_emplacement (id, nom_emplacement, rack_id, numero_etage) VALUES
    -- RACK-A : six palettes par niveau
    (1,  'A-01', 1, 1),
    (2,  'A-02', 1, 1),
    (3,  'A-03', 1, 1),
    (4,  'A-04', 1, 1),
    (5,  'A-05', 1, 1),
    (6,  'A-06', 1, 1),
    (7,  'A-07', 1, 2),
    (8,  'A-08', 1, 2),
    (9,  'A-09', 1, 2),
    (10, 'A-10', 1, 2),
    (11, 'A-11', 1, 2),
    (12, 'A-12', 1, 2),
    (13, 'A-13', 1, 3),
    (14, 'A-14', 1, 3),
    (15, 'A-15', 1, 3),
    (16, 'A-16', 1, 3),
    (17, 'A-17', 1, 3),
    (18, 'A-18', 1, 3),

    -- RACK-B
    (19, 'B-01', 2, 1),
    (20, 'B-02', 2, 1),
    (21, 'B-03', 2, 1),
    (22, 'B-04', 2, 2),
    (23, 'B-05', 2, 2),
    (24, 'B-06', 2, 2),
    (25, 'B-07', 2, 3),
    (26, 'B-08', 2, 3),
    (27, 'B-09', 2, 3),

    -- RACK-C
    (28, 'C-01', 3, 1),
    (29, 'C-02', 3, 1),
    (30, 'C-03', 3, 2),
    (31, 'C-04', 3, 2);

-- ============================================================================
-- 5. ARTICLES, CONDITIONNEMENTS ET CAPACITES PALETTES
-- Regle actuelle : un seul ArticleConditionnement par Article.
-- ============================================================================

INSERT INTO t_article (
    id, code_bar, nom_article, type_conditionnement_id, type_produit_id
) VALUES
    (1, '60001548856446', 'Coca-Cola 30cl',       1, 1),
    (2, '6200000000018',  'Lait Candia 1L',       2, 2),
    (3, '6223000011111',  'Eau Vive 1.5L',        2, 1),
    (4, '6111000022222',  'Biscuits Oreo 120g',   2, 2),
    (5, '6333000033333',  'Savon liquide 500ml',  2, 3);

INSERT INTO t_article_conditionnement (
    id, article_id, type_conditionnement_id, code_barres,
    quantite_piece_standard
) VALUES
    (1, 1, 1, '60001548856453', 6),
    (2, 2, 2, '6200000000025',  12),
    (3, 3, 2, '6223000011128',  24),
    (4, 4, 2, '6111000022239',  20),
    (5, 5, 2, '6333000033340',  12);

-- quantite = nombre maximal de conditionnements sur une palette/emplacement.
INSERT INTO t_palette_conditionnement (
    id, article_conditionnement_id, quantite
) VALUES
    (1, 1, 100), -- Coca-Cola : 100 packs
    (2, 2, 60),  -- Candia    : 60 cartons
    (3, 3, 50),  -- Eau Vive  : 50 cartons
    (4, 4, 80),  -- Oreo      : 80 cartons
    (5, 5, 70);  -- Savon     : 70 cartons

-- ============================================================================
-- 6. JOURNAUX
-- ============================================================================

INSERT INTO t_journal_mouvement (
    id, nom_client, reference, url_piece_jointe, fournisseur_id,
    type_mouvement_journal_id, statut_journal_mouvement_id
) VALUES
    -- Historique entierement range : alimente les vues de stock.
    (1, NULL, 'REC-HIST-001', '/documents/bon-reception-historique.pdf',
     1, 1, 2),

    -- Journal principal a utiliser pour tester la page d'affectation.
    (2, NULL, 'REC-AFFECT-001', '/documents/bon-reception-affectation.pdf',
     2, 1, 2),

    -- Session Flutter encore ouverte.
    (3, NULL, 'REC-SCAN-001', '/documents/bon-reception-scan.pdf',
     3, 1, 1),

    -- Scans termines, document en attente du controle web.
    (4, NULL, 'REC-ATTENTE-001', '/documents/bon-reception-attente.pdf',
     1, 1, 4),

    -- Journal refuse temporairement et a corriger.
    (5, NULL, 'REC-MODIFIE-001', '/documents/bon-reception-modifie.pdf',
     2, 1, 3),

    -- Exemple du futur flux de sortie (sans detail pour le moment).
    (6, 'SUPERETTE CENTRE', 'SOR-TEST-001', NULL,
     NULL, 2, 1);

-- ============================================================================
-- 7. DETAILS DES JOURNAUX
-- ============================================================================

INSERT INTO t_detail_journal (
    id, quantite, article_id, journal_mouvement_id,
    quantite_conditionnement, dlc, dlv
) VALUES
    -- REC-HIST-001 : deja range en emplacement et en reserve
    (1, 450,  1, 1, 75, '2026-12-20', '2026-12-10'),
    (2, 480,  2, 1, 40, '2026-09-30', '2026-09-25'),
    (3, 1200, 3, 1, 50, '2027-02-15', '2027-02-01'),

    -- REC-AFFECT-001 : plan complet a construire dans React
    (4, 360, 1, 2, 60, '2026-12-20', '2026-12-10'),
    (5, 800, 4, 2, 40, '2027-01-10', '2026-12-28'),
    (6, 600, 5, 2, 50, '2027-02-28', '2027-02-15'),

    -- REC-SCAN-001 : un article a deja ete scanne
    (7, 72, 2, 3, 6, '2026-09-30', '2026-09-25'),

    -- REC-ATTENTE-001
    (8, 240, 3, 4, 10, '2027-02-15', '2027-02-01'),
    (9, 200, 4, 4, 10, '2027-01-10', '2026-12-28'),

    -- REC-MODIFIE-001
    (10, 120, 5, 5, 10, '2027-02-28', '2027-02-15');

-- ============================================================================
-- 8. PARTICIPANTS AUX SESSIONS DE SCAN
-- ============================================================================

INSERT INTO t_user_journal_mouvement (
    id, journal_mouvement_id, user_id, statut_participation,
    date_debut, date_fin
) VALUES
    (1, 1, 3, 'TERMINE',  '2026-08-25 08:00:00', '2026-08-25 08:40:00'),
    (2, 2, 3, 'TERMINE',  '2026-08-29 07:30:00', '2026-08-29 08:10:00'),
    (3, 3, 3, 'EN_COURS', '2026-08-30 09:00:00', NULL),
    (4, 4, 2, 'TERMINE',  '2026-08-30 07:45:00', '2026-08-30 08:20:00'),
    (5, 4, 3, 'TERMINE',  '2026-08-30 07:50:00', '2026-08-30 08:25:00'),
    (6, 5, 3, 'TERMINE',  '2026-08-28 10:00:00', '2026-08-28 10:30:00');

-- ============================================================================
-- 9. MOUVEMENTS DE STOCK HISTORIQUES
-- Le journal REC-HIST-001 est totalement traite :
--   Coca-Cola : 75 packs  = 25 sur A-01 + 35 sur A-13 + 15 en reserve
--   Candia    : 40 cartons = 40 sur A-04
--   Eau Vive  : 50 cartons = 30 sur A-17 + 20 en reserve
-- ============================================================================

INSERT INTO t_mouvement_stock (
    id, conditionnement_id, commentaire, date_mouvement,
    nombre_conditionnements, quantite_pieces_reelle,
    type_mouvement_id, user_id, emplacement_id, en_reserve,
    detail_journal_id
) VALUES
    (1, 1, 'Entree Coca-Cola - REC-HIST-001', '2026-08-25 09:00:00.000000',
     25, 150, 1, 1, 1, 0, 1),

    (2, 1, 'Entree Coca-Cola - REC-HIST-001', '2026-08-25 09:00:00.000000',
     35, 210, 1, 1, 13, 0, 1),

    (3, 1, 'Surplus Coca-Cola place en reserve - REC-HIST-001',
     '2026-08-25 09:00:00.000000',
     15, 90, 1, 1, NULL, 1, 1),

    (4, 2, 'Entree Candia - REC-HIST-001', '2026-08-25 09:02:00.000000',
     40, 480, 1, 1, 4, 0, 2),

    (5, 3, 'Entree Eau Vive - REC-HIST-001', '2026-08-25 09:04:00.000000',
     30, 720, 1, 1, 17, 0, 3),

    (6, 3, 'Surplus Eau Vive place en reserve - REC-HIST-001',
     '2026-08-25 09:04:00.000000',
     20, 480, 1, 1, NULL, 1, 3);

COMMIT;

-- ============================================================================
-- 10. VERIFICATIONS LISIBLES APRES EXECUTION
-- ============================================================================

SELECT
    journal.id AS journal_id,
    journal.reference,
    statut.nom_statut,
    detail.id AS detail_journal_id,
    article.nom_article,
    detail.quantite,
    detail.quantite_conditionnement
FROM t_journal_mouvement journal
JOIN t_statut_journal_mouvement statut
    ON statut.id = journal.statut_journal_mouvement_id
LEFT JOIN t_detail_journal detail
    ON detail.journal_mouvement_id = journal.id
LEFT JOIN t_article article
    ON article.id = detail.article_id
ORDER BY journal.id, detail.id;

SELECT
    rack.nom_rack,
    emplacement.numero_etage,
    emplacement.nom_emplacement,
    article.nom_article,
    stock.quantite_stock
FROM v_stock_par_emplacement stock
JOIN t_article article
    ON article.id = stock.article_id
LEFT JOIN t_emplacement emplacement
    ON emplacement.id = stock.emplacement_id
LEFT JOIN t_rack rack
    ON rack.id = emplacement.rack_id
ORDER BY rack.id, emplacement.numero_etage, emplacement.id, article.id;

SELECT
    mouvement.id,
    article.nom_article,
    mouvement.nombre_conditionnements,
    mouvement.quantite_pieces_reelle,
    mouvement.emplacement_id,
    mouvement.en_reserve
FROM t_mouvement_stock mouvement
JOIN t_article_conditionnement conditionnement
    ON conditionnement.id = mouvement.conditionnement_id
JOIN t_article article
    ON article.id = conditionnement.article_id
ORDER BY mouvement.id;
