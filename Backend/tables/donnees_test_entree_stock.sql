-- Jeu de donnees complet pour tester le scan et l'entree en stock.
-- A executer apres reset_donnees_test.sql.

START TRANSACTION;

-- ---------------------------------------------------------------------------
-- Societe
-- ---------------------------------------------------------------------------
INSERT INTO t_societe (nom_societe)
VALUES ('FOURNISSEUR TEST');
SET @fournisseur_id = LAST_INSERT_ID();

-- ---------------------------------------------------------------------------
-- Structure de l'entrepot
-- ---------------------------------------------------------------------------
INSERT INTO t_rack (nom_rack, nombre_etages)
VALUES ('RACK-A', 3);
SET @rack_a_id = LAST_INSERT_ID();

INSERT INTO t_rack (nom_rack, nombre_etages)
VALUES ('RESERVE', 2);
SET @rack_reserve_id = LAST_INSERT_ID();

INSERT INTO t_emplacement (nom_emplacement, rack_id, numero_etage)
VALUES ('A-01', @rack_a_id, 1);
SET @emplacement_a01_id = LAST_INSERT_ID();

INSERT INTO t_emplacement (nom_emplacement, rack_id, numero_etage)
VALUES ('A-02', @rack_a_id, 2);
SET @emplacement_a02_id = LAST_INSERT_ID();

INSERT INTO t_emplacement (nom_emplacement, rack_id, numero_etage)
VALUES ('A-03', @rack_a_id, 3);
SET @emplacement_a03_id = LAST_INSERT_ID();

INSERT INTO t_emplacement (nom_emplacement, rack_id, numero_etage)
VALUES ('RESERVE-01', @rack_reserve_id, 1);
SET @emplacement_reserve_01_id = LAST_INSERT_ID();

INSERT INTO t_emplacement (nom_emplacement, rack_id, numero_etage)
VALUES ('RESERVE-02', @rack_reserve_id, 2);
SET @emplacement_reserve_02_id = LAST_INSERT_ID();

-- ---------------------------------------------------------------------------
-- Articles : un seul ArticleConditionnement par Article
-- ---------------------------------------------------------------------------
INSERT INTO t_article (
    code_bar,
    nom_article,
    type_conditionnement_id,
    type_produit_id
) VALUES (
    '60001548856446',
    'Coca 30cl',
    (SELECT id FROM t_type_conditionnement WHERE nom_conditionnement = 'PACK' LIMIT 1),
    (SELECT id FROM t_type_produit WHERE nom_type = 'BOISSON' LIMIT 1)
);
SET @coca_id = LAST_INSERT_ID();

INSERT INTO t_article_conditionnement (
    article_id,
    type_conditionnement_id,
    code_barres,
    quantite_piece_standard
) VALUES (
    @coca_id,
    (SELECT id FROM t_type_conditionnement WHERE nom_conditionnement = 'PACK' LIMIT 1),
    '60001548856453',
    6
);
SET @coca_conditionnement_id = LAST_INSERT_ID();

INSERT INTO t_palette_conditionnement (
    article_conditionnement_id,
    quantite
) VALUES (
    @coca_conditionnement_id,
    100
);

INSERT INTO t_article (
    code_bar,
    nom_article,
    type_conditionnement_id,
    type_produit_id
) VALUES (
    '6200000000018',
    'Lait Candia 1L',
    (SELECT id FROM t_type_conditionnement WHERE nom_conditionnement = 'CARTON' LIMIT 1),
    (SELECT id FROM t_type_produit WHERE nom_type = 'ALIMENTAIRE' LIMIT 1)
);
SET @candia_id = LAST_INSERT_ID();

INSERT INTO t_article_conditionnement (
    article_id,
    type_conditionnement_id,
    code_barres,
    quantite_piece_standard
) VALUES (
    @candia_id,
    (SELECT id FROM t_type_conditionnement WHERE nom_conditionnement = 'CARTON' LIMIT 1),
    '6200000000025',
    12
);
SET @candia_conditionnement_id = LAST_INSERT_ID();

INSERT INTO t_palette_conditionnement (
    article_conditionnement_id,
    quantite
) VALUES (
    @candia_conditionnement_id,
    60
);

-- ---------------------------------------------------------------------------
-- Journal historique : cree le stock initial de 30 packs de Coca sur A-01
-- ---------------------------------------------------------------------------
INSERT INTO t_journal_mouvement (
    nom_client,
    reference,
    url_piece_jointe,
    fournisseur_id,
    type_mouvement_journal_id,
    statut_journal_mouvement_id
) VALUES (
    NULL,
    'STOCK-INITIAL-001',
    NULL,
    @fournisseur_id,
    (SELECT id FROM t_type_mouvement_journal WHERE nom_type_mouvement = 'ENTREE' LIMIT 1),
    (SELECT id FROM t_statut_journal_mouvement WHERE nom_statut = 'VALIDE' LIMIT 1)
);
SET @journal_initial_id = LAST_INSERT_ID();

INSERT INTO t_detail_journal (
    quantite,
    article_id,
    journal_mouvement_id,
    quantite_conditionnement
) VALUES (
    180,
    @coca_id,
    @journal_initial_id,
    30
);
SET @detail_initial_coca_id = LAST_INSERT_ID();

INSERT INTO t_mouvement_stock (
    conditionnement_id,
    commentaire,
    date_mouvement,
    nombre_conditionnements,
    quantite_pieces_reelle,
    type_mouvement_id,
    user_id,
    journal_mouvement_id,
    emplacement_id,
    detail_journal_id
) VALUES (
    @coca_conditionnement_id,
    'Stock initial pour les tests',
    '2026-08-27 08:00:00',
    30,
    180,
    (SELECT id FROM t_type_mouvement WHERE nom_type_mouvement = 'ENTREE' LIMIT 1),
    (SELECT id FROM t_user WHERE matricule = 'ADM-001' LIMIT 1),
    @journal_initial_id,
    @emplacement_a01_id,
    @detail_initial_coca_id
);

-- ---------------------------------------------------------------------------
-- Journal VALIDE a utiliser pour tester l'affectation des emplacements
-- Coca : 75 packs / 450 pieces
-- Candia : 40 cartons / 480 pieces
-- ---------------------------------------------------------------------------
INSERT INTO t_journal_mouvement (
    nom_client,
    reference,
    url_piece_jointe,
    fournisseur_id,
    type_mouvement_journal_id,
    statut_journal_mouvement_id
) VALUES (
    NULL,
    'REC-TEST-001',
    NULL,
    @fournisseur_id,
    (SELECT id FROM t_type_mouvement_journal WHERE nom_type_mouvement = 'ENTREE' LIMIT 1),
    (SELECT id FROM t_statut_journal_mouvement WHERE nom_statut = 'VALIDE' LIMIT 1)
);
SET @journal_test_id = LAST_INSERT_ID();

INSERT INTO t_detail_journal (
    quantite,
    article_id,
    journal_mouvement_id,
    quantite_conditionnement
) VALUES
    (450, @coca_id, @journal_test_id, 75),
    (480, @candia_id, @journal_test_id, 40);

INSERT INTO t_user_journal_mouvement (
    journal_mouvement_id,
    user_id,
    statut_participation,
    date_debut,
    date_fin
) VALUES (
    @journal_test_id,
    (SELECT id FROM t_user WHERE matricule = 'STG-0144' LIMIT 1),
    'TERMINE',
    '2026-08-27 08:30:00',
    '2026-08-27 09:00:00'
);

-- ---------------------------------------------------------------------------
-- Journal vide EN COURS pour tester les scans Flutter
-- ---------------------------------------------------------------------------
INSERT INTO t_journal_mouvement (
    nom_client,
    reference,
    url_piece_jointe,
    fournisseur_id,
    type_mouvement_journal_id,
    statut_journal_mouvement_id
) VALUES (
    NULL,
    'REC-SCAN-001',
    NULL,
    @fournisseur_id,
    (SELECT id FROM t_type_mouvement_journal WHERE nom_type_mouvement = 'ENTREE' LIMIT 1),
    (SELECT id FROM t_statut_journal_mouvement WHERE nom_statut = 'EN COURS' LIMIT 1)
);

COMMIT;

-- Informations utiles pour construire le JSON de test.
SELECT
    journal.id AS journal_id,
    journal.reference,
    detail.id AS detail_journal_id,
    article.nom_article,
    detail.quantite_conditionnement
FROM t_journal_mouvement journal
LEFT JOIN t_detail_journal detail
    ON detail.journal_mouvement_id = journal.id
LEFT JOIN t_article article
    ON article.id = detail.article_id
ORDER BY journal.id, detail.id;

SELECT
    emplacement.id AS emplacement_id,
    rack.nom_rack,
    emplacement.nom_emplacement,
    emplacement.numero_etage
FROM t_emplacement emplacement
JOIN t_rack rack ON rack.id = emplacement.rack_id
ORDER BY rack.id, emplacement.numero_etage;



id
detail_journal_id
article_conditionnement_id
nombre_conditionnements
quantite_pieces_reelle
date_entree