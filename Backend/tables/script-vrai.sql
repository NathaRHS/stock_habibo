-- Active: 1786994780822@@127.0.0.1@3307@stock_habibo
-- ============================================================================
-- REFERENTIEL PRINCIPAL - WMS HABIBO
-- Base cible : stock_habibo (MySQL 8+)
--
-- Ce script contient uniquement les donnees stables actuellement confirmees :
--   - les societes du groupe Habibo ;
--   - les roles et les cinq utilisateurs initiaux ;
--   - la structure physique de l'entrepot : 5 racks, 5 etages par rack,
--     50 emplacements par rack, soit 250 emplacements.
--   - un catalogue et des operations fictifs destines a la demonstration.
--
-- Il ne supprime aucune donnee existante et peut etre relance.
-- Mot de passe commun des cinq comptes : password
-- ============================================================================

USE stock_habibo;
START TRANSACTION;


-- ============================================================================
-- 1. ROLES
-- ============================================================================

INSERT INTO t_roles (nom_role) VALUES
    ('ADMIN'),
    ('OPERATEUR'),
    ('INVENTORISTE')
ON DUPLICATE KEY UPDATE nom_role = VALUES(nom_role);

-- Referentiels necessaires aux simulations metier.
INSERT INTO t_statut_journal_mouvement (nom_statut) VALUES
    ('EN COURS'),
    ('EN ATTENTE'),
    ('VALIDE'),
    ('MODIFIE')
ON DUPLICATE KEY UPDATE nom_statut = VALUES(nom_statut);

INSERT INTO t_type_mouvement (nom_type_mouvement, sens) VALUES
    ('ENTREE', 1),
    ('SORTIE', -1),
    ('AJUSTEMENT_POSITIF', 1),
    ('AJUSTEMENT_NEGATIF', -1)
ON DUPLICATE KEY UPDATE sens = VALUES(sens);

INSERT INTO t_type_mouvement_journal (nom_type_mouvement, sens) VALUES
    ('ENTREE', 1),
    ('SORTIE', -1),
    ('INVENTAIRE', 1)
ON DUPLICATE KEY UPDATE sens = VALUES(sens);

INSERT INTO t_type_conditionnement (nom_conditionnement) VALUES
    ('PACK'),
    ('CARTON')
ON DUPLICATE KEY UPDATE nom_conditionnement = VALUES(nom_conditionnement);

INSERT INTO t_type_produit (nom_type) VALUES
    ('BOISSON'),
    ('ALIMENTAIRE'),
    ('HYGIENE')
ON DUPLICATE KEY UPDATE nom_type = VALUES(nom_type);

-- ============================================================================
-- 2. UTILISATEURS
--
-- Le hash BCrypt ci-dessous correspond au mot de passe : password
-- ============================================================================

INSERT INTO t_user (
    username,
    matricule,
    email,
    password_hash,
    role_id
) VALUES
    (
        'admin',
        'ADM001',
        'admin@habibo.local',
        '$2a$10$ji4.ARxiXTyclInFJFEJCu5s/EG8tu8undoP7PnZh/TXaKFhy9aOK',
        (SELECT MIN(id) FROM t_roles WHERE nom_role = 'ADMIN')
    ),
    (
        'operateur1',
        'OPE001',
        'operateur1@habibo.local',
        '$2a$10$ji4.ARxiXTyclInFJFEJCu5s/EG8tu8undoP7PnZh/TXaKFhy9aOK',
        (SELECT MIN(id) FROM t_roles WHERE nom_role = 'OPERATEUR')
    ),
    (
        'operateur2',
        'OPE002',
        'operateur2@habibo.local',
        '$2a$10$ji4.ARxiXTyclInFJFEJCu5s/EG8tu8undoP7PnZh/TXaKFhy9aOK',
        (SELECT MIN(id) FROM t_roles WHERE nom_role = 'OPERATEUR')
    ),
    (
        'inventoriste1',
        'INV001',
        'inventoriste1@habibo.local',
        '$2a$10$ji4.ARxiXTyclInFJFEJCu5s/EG8tu8undoP7PnZh/TXaKFhy9aOK',
        (SELECT MIN(id) FROM t_roles WHERE nom_role = 'INVENTORISTE')
    ),
    (
        'inventoriste2',
        'INV002',
        'inventoriste2@habibo.local',
        '$2a$10$ji4.ARxiXTyclInFJFEJCu5s/EG8tu8undoP7PnZh/TXaKFhy9aOK',
        (SELECT MIN(id) FROM t_roles WHERE nom_role = 'INVENTORISTE')
    )
ON DUPLICATE KEY UPDATE
    username = VALUES(username),
    email = VALUES(email),
    password_hash = VALUES(password_hash),
    role_id = VALUES(role_id);

-- ============================================================================
-- 3. SOCIETES DU GROUPE
--
-- HH, Hb et Hm sont des societes, pas des zones ni des batiments.
-- ============================================================================

INSERT INTO t_societe (nom_societe) VALUES
    ('HH'),
    ('Hb'),
    ('Hm')
ON DUPLICATE KEY UPDATE nom_societe = VALUES(nom_societe);

-- ============================================================================
-- 4. RACKS
--
-- Chaque rack contient cinq etages et cinquante emplacements.
-- ============================================================================

INSERT INTO t_rack (nom_rack, nombre_etages) VALUES
    ('RACK-A', 5),
    ('RACK-B', 5),
    ('RACK-C', 5),
    ('RACK-D', 5),
    ('RACK-E', 5)
ON DUPLICATE KEY UPDATE nombre_etages = VALUES(nombre_etages);

-- ============================================================================
-- 5. EMPLACEMENTS
--
-- Codification par rack : A-001 a A-050, ..., E-001 a E-050.
-- Repartition reguliere : dix emplacements par etage.
--   001-010 : etage 1
--   011-020 : etage 2
--   021-030 : etage 3
--   031-040 : etage 4
--   041-050 : etage 5
--
-- Un emplacement correspond directement a une place palette.
-- ============================================================================

INSERT INTO t_emplacement (nom_emplacement, rack_id, numero_etage)
WITH RECURSIVE numeros AS (
    SELECT 1 AS numero
    UNION ALL
    SELECT numero + 1
    FROM numeros
    WHERE numero < 50
),
racks_confirmes AS (
    SELECT id, 'A' AS code FROM t_rack WHERE nom_rack = 'RACK-A'
    UNION ALL
    SELECT id, 'B' AS code FROM t_rack WHERE nom_rack = 'RACK-B'
    UNION ALL
    SELECT id, 'C' AS code FROM t_rack WHERE nom_rack = 'RACK-C'
    UNION ALL
    SELECT id, 'D' AS code FROM t_rack WHERE nom_rack = 'RACK-D'
    UNION ALL
    SELECT id, 'E' AS code FROM t_rack WHERE nom_rack = 'RACK-E'
)
SELECT
    CONCAT(r.code, '-', LPAD(n.numero, 3, '0')),
    r.id,
    CEIL(n.numero / 10)
FROM racks_confirmes r
CROSS JOIN numeros n
WHERE TRUE
ON DUPLICATE KEY UPDATE
    numero_etage = VALUES(numero_etage);

-- ============================================================================
-- 6. CATALOGUE DE DEMONSTRATION
--
-- Ces articles, codes-barres et capacites sont fictifs. Ils servent uniquement
-- a disposer d'un scenario executable en attendant le vrai catalogue Habibo.
-- Regle actuelle du projet : un ArticleConditionnement par article.
-- ============================================================================

INSERT INTO t_article (
    code_bar, nom_article, type_conditionnement_id, type_produit_id
) VALUES
    ('60001548856446', 'Coca-Cola 30cl',
     (SELECT id FROM t_type_conditionnement WHERE nom_conditionnement = 'PACK'),
     (SELECT id FROM t_type_produit WHERE nom_type = 'BOISSON')),
    ('6200000000018', 'Lait Candia 1L',
     (SELECT id FROM t_type_conditionnement WHERE nom_conditionnement = 'CARTON'),
     (SELECT id FROM t_type_produit WHERE nom_type = 'ALIMENTAIRE')),
    ('6223000011111', 'Eau Vive 1.5L',
     (SELECT id FROM t_type_conditionnement WHERE nom_conditionnement = 'PACK'),
     (SELECT id FROM t_type_produit WHERE nom_type = 'BOISSON')),
    ('6333000033333', 'Savon liquide 500ml',
     (SELECT id FROM t_type_conditionnement WHERE nom_conditionnement = 'CARTON'),
     (SELECT id FROM t_type_produit WHERE nom_type = 'HYGIENE'))
ON DUPLICATE KEY UPDATE
    nom_article = VALUES(nom_article),
    type_conditionnement_id = VALUES(type_conditionnement_id),
    type_produit_id = VALUES(type_produit_id);

INSERT INTO t_article_conditionnement (
    article_id, type_conditionnement_id, code_barres, quantite_piece_standard
) VALUES
    ((SELECT id FROM t_article WHERE code_bar = '60001548856446'),
     (SELECT id FROM t_type_conditionnement WHERE nom_conditionnement = 'PACK'),
     '60001548856453', 6),
    ((SELECT id FROM t_article WHERE code_bar = '6200000000018'),
     (SELECT id FROM t_type_conditionnement WHERE nom_conditionnement = 'CARTON'),
     '6200000000025', 12),
    ((SELECT id FROM t_article WHERE code_bar = '6223000011111'),
     (SELECT id FROM t_type_conditionnement WHERE nom_conditionnement = 'PACK'),
     '6223000011128', 6),
    ((SELECT id FROM t_article WHERE code_bar = '6333000033333'),
     (SELECT id FROM t_type_conditionnement WHERE nom_conditionnement = 'CARTON'),
     '6333000033340', 12)
ON DUPLICATE KEY UPDATE
    article_id = VALUES(article_id),
    type_conditionnement_id = VALUES(type_conditionnement_id),
    quantite_piece_standard = VALUES(quantite_piece_standard);

INSERT INTO t_palette_conditionnement (article_conditionnement_id, quantite)
VALUES
    ((SELECT id FROM t_article_conditionnement WHERE code_barres = '60001548856453'), 100),
    ((SELECT id FROM t_article_conditionnement WHERE code_barres = '6200000000025'), 60),
    ((SELECT id FROM t_article_conditionnement WHERE code_barres = '6223000011128'), 80),
    ((SELECT id FROM t_article_conditionnement WHERE code_barres = '6333000033340'), 70)
ON DUPLICATE KEY UPDATE quantite = VALUES(quantite);

-- ============================================================================
-- 7. JOURNAUX DE DEMONSTRATION ET LEURS STATUTS
--
-- REC-HIST-001     : reception validee et deja rangee ;
-- REC-SCAN-001     : reception actuellement scannee ;
-- REC-ATTENTE-001  : reception terminee sur mobile, a controler sur le Web ;
-- REC-MODIFIE-001  : reception renvoyee pour modification ;
-- INV-ENCOURS-001  : inventaire actuellement compte ;
-- INV-ATTENTE-001  : inventaire termine, avec ecarts a controler ;
-- INV-VALIDE-001   : inventaire deja controle ;
-- SOR-PREP-001     : sortie en preparation, sans retrait definitif du stock.
-- ============================================================================

INSERT INTO t_journal_mouvement (
    nom_client, reference, url_piece_jointe, fournisseur_id,
    type_mouvement_journal_id, statut_journal_mouvement_id
) VALUES
    (NULL, 'REC-HIST-001', '/documents/bon-reception-historique.pdf',
     (SELECT id FROM t_societe WHERE nom_societe = 'Hb'),
     (SELECT id FROM t_type_mouvement_journal WHERE nom_type_mouvement = 'ENTREE'),
     (SELECT id FROM t_statut_journal_mouvement WHERE nom_statut = 'VALIDE')),
    (NULL, 'REC-SCAN-001', '/documents/bon-reception-scan.pdf',
     (SELECT id FROM t_societe WHERE nom_societe = 'HH'),
     (SELECT id FROM t_type_mouvement_journal WHERE nom_type_mouvement = 'ENTREE'),
     (SELECT id FROM t_statut_journal_mouvement WHERE nom_statut = 'EN COURS')),
    (NULL, 'REC-ATTENTE-001', '/documents/bon-reception-attente.pdf',
     (SELECT id FROM t_societe WHERE nom_societe = 'Hb'),
     (SELECT id FROM t_type_mouvement_journal WHERE nom_type_mouvement = 'ENTREE'),
     (SELECT id FROM t_statut_journal_mouvement WHERE nom_statut = 'EN ATTENTE')),
    (NULL, 'REC-MODIFIE-001', '/documents/bon-reception-modifie.pdf',
     (SELECT id FROM t_societe WHERE nom_societe = 'Hm'),
     (SELECT id FROM t_type_mouvement_journal WHERE nom_type_mouvement = 'ENTREE'),
     (SELECT id FROM t_statut_journal_mouvement WHERE nom_statut = 'MODIFIE')),
    (NULL, 'INV-ENCOURS-001', NULL, NULL,
     (SELECT id FROM t_type_mouvement_journal WHERE nom_type_mouvement = 'INVENTAIRE'),
     (SELECT id FROM t_statut_journal_mouvement WHERE nom_statut = 'EN COURS')),
    (NULL, 'INV-ATTENTE-001', NULL, NULL,
     (SELECT id FROM t_type_mouvement_journal WHERE nom_type_mouvement = 'INVENTAIRE'),
     (SELECT id FROM t_statut_journal_mouvement WHERE nom_statut = 'EN ATTENTE')),
    (NULL, 'INV-VALIDE-001', '/documents/rapport-inventaire-001.pdf', NULL,
     (SELECT id FROM t_type_mouvement_journal WHERE nom_type_mouvement = 'INVENTAIRE'),
     (SELECT id FROM t_statut_journal_mouvement WHERE nom_statut = 'VALIDE')),
    ('Client demonstration', 'SOR-PREP-001', '/documents/bon-commande-001.pdf', NULL,
     (SELECT id FROM t_type_mouvement_journal WHERE nom_type_mouvement = 'SORTIE'),
     (SELECT id FROM t_statut_journal_mouvement WHERE nom_statut = 'EN COURS'))
ON DUPLICATE KEY UPDATE
    nom_client = VALUES(nom_client),
    url_piece_jointe = VALUES(url_piece_jointe),
    fournisseur_id = VALUES(fournisseur_id),
    type_mouvement_journal_id = VALUES(type_mouvement_journal_id),
    statut_journal_mouvement_id = VALUES(statut_journal_mouvement_id);

-- Details scannes dans chaque session.
INSERT INTO t_detail_journal (
    journal_mouvement_id, article_id, quantite,
    quantite_conditionnement, dlc, dlv
) VALUES
    ((SELECT id FROM t_journal_mouvement WHERE reference = 'REC-HIST-001'),
     (SELECT id FROM t_article WHERE code_bar = '60001548856446'), 450, 75,
     '2026-12-20', '2026-12-10'),
    ((SELECT id FROM t_journal_mouvement WHERE reference = 'REC-HIST-001'),
     (SELECT id FROM t_article WHERE code_bar = '6200000000018'), 480, 40,
     '2026-09-30', '2026-09-25'),
    ((SELECT id FROM t_journal_mouvement WHERE reference = 'REC-HIST-001'),
     (SELECT id FROM t_article WHERE code_bar = '6223000011111'), 180, 30,
     '2027-02-15', '2027-02-01'),
    ((SELECT id FROM t_journal_mouvement WHERE reference = 'REC-SCAN-001'),
     (SELECT id FROM t_article WHERE code_bar = '6333000033333'), 72, 6,
     '2027-02-28', '2027-02-15'),
    ((SELECT id FROM t_journal_mouvement WHERE reference = 'REC-ATTENTE-001'),
     (SELECT id FROM t_article WHERE code_bar = '6223000011111'), 240, 40,
     '2027-02-15', '2027-02-01'),
    ((SELECT id FROM t_journal_mouvement WHERE reference = 'REC-MODIFIE-001'),
     (SELECT id FROM t_article WHERE code_bar = '6200000000018'), 120, 10,
     '2026-09-30', '2026-09-25'),
    ((SELECT id FROM t_journal_mouvement WHERE reference = 'INV-ENCOURS-001'),
     (SELECT id FROM t_article WHERE code_bar = '60001548856446'), 100, NULL,
     NULL, NULL),
    ((SELECT id FROM t_journal_mouvement WHERE reference = 'INV-ATTENTE-001'),
     (SELECT id FROM t_article WHERE code_bar = '60001548856446'), 355, NULL,
     NULL, NULL),
    ((SELECT id FROM t_journal_mouvement WHERE reference = 'INV-ATTENTE-001'),
     (SELECT id FROM t_article WHERE code_bar = '6200000000018'), 478, NULL,
     NULL, NULL),
    ((SELECT id FROM t_journal_mouvement WHERE reference = 'INV-VALIDE-001'),
     (SELECT id FROM t_article WHERE code_bar = '6223000011111'), 180, NULL,
     NULL, NULL),
    ((SELECT id FROM t_journal_mouvement WHERE reference = 'SOR-PREP-001'),
     (SELECT id FROM t_article WHERE code_bar = '60001548856446'), 60, 10,
     NULL, NULL)
ON DUPLICATE KEY UPDATE
    quantite = VALUES(quantite),
    quantite_conditionnement = VALUES(quantite_conditionnement),
    dlc = VALUES(dlc),
    dlv = VALUES(dlv);

-- Participants : les operateurs travaillent sur les receptions et les
-- inventoristes sur les inventaires.
INSERT INTO t_user_journal_mouvement (
    journal_mouvement_id, user_id, statut_participation, date_debut, date_fin
) VALUES
    ((SELECT id FROM t_journal_mouvement WHERE reference = 'REC-HIST-001'),
     (SELECT id FROM t_user WHERE matricule = 'OPE001'), 'TERMINE',
     '2026-09-01 08:00:00', '2026-09-01 08:45:00'),
    ((SELECT id FROM t_journal_mouvement WHERE reference = 'REC-SCAN-001'),
     (SELECT id FROM t_user WHERE matricule = 'OPE002'), 'EN_COURS',
     '2026-09-03 08:20:00', NULL),
    ((SELECT id FROM t_journal_mouvement WHERE reference = 'REC-ATTENTE-001'),
     (SELECT id FROM t_user WHERE matricule = 'OPE001'), 'TERMINE',
     '2026-09-03 07:30:00', '2026-09-03 08:10:00'),
    ((SELECT id FROM t_journal_mouvement WHERE reference = 'REC-MODIFIE-001'),
     (SELECT id FROM t_user WHERE matricule = 'OPE002'), 'TERMINE',
     '2026-09-02 14:00:00', '2026-09-02 14:25:00'),
    ((SELECT id FROM t_journal_mouvement WHERE reference = 'INV-ENCOURS-001'),
     (SELECT id FROM t_user WHERE matricule = 'INV001'), 'EN_COURS',
     '2026-09-03 09:00:00', NULL),
    ((SELECT id FROM t_journal_mouvement WHERE reference = 'INV-ATTENTE-001'),
     (SELECT id FROM t_user WHERE matricule = 'INV002'), 'TERMINE',
     '2026-09-02 09:00:00', '2026-09-02 11:15:00'),
    ((SELECT id FROM t_journal_mouvement WHERE reference = 'INV-VALIDE-001'),
     (SELECT id FROM t_user WHERE matricule = 'INV001'), 'TERMINE',
     '2026-09-01 10:00:00', '2026-09-01 11:00:00')
ON DUPLICATE KEY UPDATE
    statut_participation = VALUES(statut_participation),
    date_debut = VALUES(date_debut),
    date_fin = VALUES(date_fin);

-- ============================================================================
-- 8. STOCK ISSU DE LA RECEPTION VALIDEE
--
-- Coca-Cola : 60 packs en A-001 et 15 packs en reserve.
-- Candia    : 40 cartons en A-011.
-- Eau Vive  : 30 packs en B-001.
-- ============================================================================

INSERT INTO t_mouvement_stock (
    conditionnement_id, commentaire, date_mouvement,
    nombre_conditionnements, quantite_pieces_reelle,
    type_mouvement_id, user_id, emplacement_id, en_reserve, detail_journal_id
)
SELECT
    (SELECT id FROM t_article_conditionnement WHERE code_barres = '60001548856453'),
    'Entree Coca-Cola - REC-HIST-001', '2026-09-01 09:00:00.000000',
    60, 360,
    (SELECT id FROM t_type_mouvement WHERE nom_type_mouvement = 'ENTREE'),
    (SELECT id FROM t_user WHERE matricule = 'ADM001'),
    (SELECT e.id FROM t_emplacement e JOIN t_rack r ON r.id = e.rack_id
     WHERE r.nom_rack = 'RACK-A' AND e.nom_emplacement = 'A-001'),
    FALSE,
    (SELECT d.id FROM t_detail_journal d JOIN t_journal_mouvement j
     ON j.id = d.journal_mouvement_id JOIN t_article a ON a.id = d.article_id
     WHERE j.reference = 'REC-HIST-001' AND a.code_bar = '60001548856446')
WHERE NOT EXISTS (
    SELECT 1 FROM t_mouvement_stock WHERE commentaire = 'Entree Coca-Cola - REC-HIST-001'
);

INSERT INTO t_mouvement_stock (
    conditionnement_id, commentaire, date_mouvement,
    nombre_conditionnements, quantite_pieces_reelle,
    type_mouvement_id, user_id, emplacement_id, en_reserve, detail_journal_id
)
SELECT
    (SELECT id FROM t_article_conditionnement WHERE code_barres = '60001548856453'),
    'Reserve Coca-Cola - REC-HIST-001', '2026-09-01 09:00:00.000000',
    15, 90,
    (SELECT id FROM t_type_mouvement WHERE nom_type_mouvement = 'ENTREE'),
    (SELECT id FROM t_user WHERE matricule = 'ADM001'), NULL, TRUE,
    (SELECT d.id FROM t_detail_journal d JOIN t_journal_mouvement j
     ON j.id = d.journal_mouvement_id JOIN t_article a ON a.id = d.article_id
     WHERE j.reference = 'REC-HIST-001' AND a.code_bar = '60001548856446')
WHERE NOT EXISTS (
    SELECT 1 FROM t_mouvement_stock WHERE commentaire = 'Reserve Coca-Cola - REC-HIST-001'
);

INSERT INTO t_mouvement_stock (
    conditionnement_id, commentaire, date_mouvement,
    nombre_conditionnements, quantite_pieces_reelle,
    type_mouvement_id, user_id, emplacement_id, en_reserve, detail_journal_id
)
SELECT
    (SELECT id FROM t_article_conditionnement WHERE code_barres = '6200000000025'),
    'Entree Candia - REC-HIST-001', '2026-09-01 09:04:00.000000',
    40, 480,
    (SELECT id FROM t_type_mouvement WHERE nom_type_mouvement = 'ENTREE'),
    (SELECT id FROM t_user WHERE matricule = 'ADM001'),
    (SELECT e.id FROM t_emplacement e JOIN t_rack r ON r.id = e.rack_id
     WHERE r.nom_rack = 'RACK-A' AND e.nom_emplacement = 'A-011'),
    FALSE,
    (SELECT d.id FROM t_detail_journal d JOIN t_journal_mouvement j
     ON j.id = d.journal_mouvement_id JOIN t_article a ON a.id = d.article_id
     WHERE j.reference = 'REC-HIST-001' AND a.code_bar = '6200000000018')
WHERE NOT EXISTS (
    SELECT 1 FROM t_mouvement_stock WHERE commentaire = 'Entree Candia - REC-HIST-001'
);

INSERT INTO t_mouvement_stock (
    conditionnement_id, commentaire, date_mouvement,
    nombre_conditionnements, quantite_pieces_reelle,
    type_mouvement_id, user_id, emplacement_id, en_reserve, detail_journal_id
)
SELECT
    (SELECT id FROM t_article_conditionnement WHERE code_barres = '6223000011128'),
    'Entree Eau Vive - REC-HIST-001', '2026-09-01 09:08:00.000000',
    30, 180,
    (SELECT id FROM t_type_mouvement WHERE nom_type_mouvement = 'ENTREE'),
    (SELECT id FROM t_user WHERE matricule = 'ADM001'),
    (SELECT e.id FROM t_emplacement e JOIN t_rack r ON r.id = e.rack_id
     WHERE r.nom_rack = 'RACK-B' AND e.nom_emplacement = 'B-001'),
    FALSE,
    (SELECT d.id FROM t_detail_journal d JOIN t_journal_mouvement j
     ON j.id = d.journal_mouvement_id JOIN t_article a ON a.id = d.article_id
     WHERE j.reference = 'REC-HIST-001' AND a.code_bar = '6223000011111')
WHERE NOT EXISTS (
    SELECT 1 FROM t_mouvement_stock WHERE commentaire = 'Entree Eau Vive - REC-HIST-001'
);

-- ============================================================================
-- 9. COMPTAGES D'INVENTAIRE
--
-- create.sql ne contient pas encore cette table. Elle est donc creee ici selon
-- l'entite ComptageInventaire pour rendre la simulation SQL autonome.
-- ============================================================================

CREATE TABLE IF NOT EXISTS t_comptage_inventaire (
    id BIGINT NOT NULL AUTO_INCREMENT,
    detail_journal_id BIGINT NOT NULL,
    emplacement_id BIGINT NOT NULL,
    quantite_comptee INT NOT NULL,
    date_comptage DATETIME(6) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_comptage_detail_emplacement
        UNIQUE (detail_journal_id, emplacement_id),
    CONSTRAINT fk_comptage_detail
        FOREIGN KEY (detail_journal_id) REFERENCES t_detail_journal (id)
        ON UPDATE NO ACTION ON DELETE RESTRICT,
    CONSTRAINT fk_comptage_emplacement
        FOREIGN KEY (emplacement_id) REFERENCES t_emplacement (id)
        ON UPDATE NO ACTION ON DELETE RESTRICT
) ENGINE = InnoDB;

INSERT INTO t_comptage_inventaire (
    detail_journal_id, emplacement_id, quantite_comptee, date_comptage
) VALUES
    ((SELECT d.id FROM t_detail_journal d JOIN t_journal_mouvement j
      ON j.id = d.journal_mouvement_id JOIN t_article a ON a.id = d.article_id
      WHERE j.reference = 'INV-ENCOURS-001' AND a.code_bar = '60001548856446'),
     (SELECT e.id FROM t_emplacement e JOIN t_rack r ON r.id = e.rack_id
      WHERE r.nom_rack = 'RACK-A' AND e.nom_emplacement = 'A-001'),
     100, '2026-09-03 09:25:00.000000'),
    ((SELECT d.id FROM t_detail_journal d JOIN t_journal_mouvement j
      ON j.id = d.journal_mouvement_id JOIN t_article a ON a.id = d.article_id
      WHERE j.reference = 'INV-ATTENTE-001' AND a.code_bar = '60001548856446'),
     (SELECT e.id FROM t_emplacement e JOIN t_rack r ON r.id = e.rack_id
      WHERE r.nom_rack = 'RACK-A' AND e.nom_emplacement = 'A-001'),
     355, '2026-09-02 10:15:00.000000'),
    ((SELECT d.id FROM t_detail_journal d JOIN t_journal_mouvement j
      ON j.id = d.journal_mouvement_id JOIN t_article a ON a.id = d.article_id
      WHERE j.reference = 'INV-ATTENTE-001' AND a.code_bar = '6200000000018'),
     (SELECT e.id FROM t_emplacement e JOIN t_rack r ON r.id = e.rack_id
      WHERE r.nom_rack = 'RACK-A' AND e.nom_emplacement = 'A-011'),
     478, '2026-09-02 10:45:00.000000'),
    ((SELECT d.id FROM t_detail_journal d JOIN t_journal_mouvement j
      ON j.id = d.journal_mouvement_id JOIN t_article a ON a.id = d.article_id
      WHERE j.reference = 'INV-VALIDE-001' AND a.code_bar = '6223000011111'),
     (SELECT e.id FROM t_emplacement e JOIN t_rack r ON r.id = e.rack_id
      WHERE r.nom_rack = 'RACK-B' AND e.nom_emplacement = 'B-001'),
     180, '2026-09-01 10:35:00.000000')
ON DUPLICATE KEY UPDATE
    quantite_comptee = VALUES(quantite_comptee),
    date_comptage = VALUES(date_comptage);

COMMIT;

-- ============================================================================
-- CONTROLES RAPIDES APRES EXECUTION
-- ============================================================================

SELECT nom_societe
FROM t_societe
WHERE nom_societe IN ('HH', 'Hb', 'Hm')
ORDER BY nom_societe;

SELECT
    u.matricule,
    u.username,
    r.nom_role
FROM t_user u
JOIN t_roles r ON r.id = u.role_id
WHERE u.matricule IN ('ADM001', 'OPE001', 'OPE002', 'INV001', 'INV002')
ORDER BY u.id;

SELECT
    r.nom_rack,
    r.nombre_etages,
    COUNT(e.id) AS nombre_emplacements,
    MIN(e.numero_etage) AS premier_etage,
    MAX(e.numero_etage) AS dernier_etage
FROM t_rack r
LEFT JOIN t_emplacement e ON e.rack_id = r.id
WHERE r.nom_rack IN ('RACK-A', 'RACK-B', 'RACK-C', 'RACK-D', 'RACK-E')
GROUP BY r.id, r.nom_rack, r.nombre_etages
ORDER BY r.nom_rack;

SELECT
    j.reference,
    tmj.nom_type_mouvement AS type_session,
    sjm.nom_statut,
    COUNT(DISTINCT d.id) AS lignes,
    COUNT(DISTINCT ujm.user_id) AS participants
FROM t_journal_mouvement j
JOIN t_type_mouvement_journal tmj
    ON tmj.id = j.type_mouvement_journal_id
JOIN t_statut_journal_mouvement sjm
    ON sjm.id = j.statut_journal_mouvement_id
LEFT JOIN t_detail_journal d ON d.journal_mouvement_id = j.id
LEFT JOIN t_user_journal_mouvement ujm ON ujm.journal_mouvement_id = j.id
WHERE j.reference IN (
    'REC-HIST-001', 'REC-SCAN-001', 'REC-ATTENTE-001', 'REC-MODIFIE-001',
    'INV-ENCOURS-001', 'INV-ATTENTE-001', 'INV-VALIDE-001', 'SOR-PREP-001'
)
GROUP BY j.id, j.reference, tmj.nom_type_mouvement, sjm.nom_statut
ORDER BY tmj.nom_type_mouvement, j.reference;
