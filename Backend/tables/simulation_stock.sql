-- Simulation complete pour tester :
--   1. v_stock_par_emplacement
--   2. v_stock_total_article
--
-- Resultats attendus :
--   JUS ORANGE SIMULATION : 108 pieces sur ETAGE-1, 67 sur ETAGE-2, total 175.
--   EAU SIMULATION        :  85 pieces sur ETAGE-1, total 85.

USE stock_habibo;

-- ---------------------------------------------------------------------------
-- Mise en conformite minimale avec conceptionv2
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS t_article_conditionnement (
    id BIGINT NOT NULL AUTO_INCREMENT,
    article_id BIGINT NOT NULL,
    type_conditionnement_id BIGINT NOT NULL,
    code_barres VARCHAR(255) NOT NULL,
    quantite_piece_standard INT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uk_article_conditionnement_code_barres UNIQUE (code_barres),
    CONSTRAINT ck_conditionnement_quantite_standard
        CHECK (quantite_piece_standard IS NULL OR quantite_piece_standard > 0),
    CONSTRAINT fk_conditionnement_article
        FOREIGN KEY (article_id) REFERENCES t_article (id)
        ON UPDATE NO ACTION ON DELETE RESTRICT,
    CONSTRAINT fk_conditionnement_type
        FOREIGN KEY (type_conditionnement_id) REFERENCES t_type_conditionnement (id)
        ON UPDATE NO ACTION ON DELETE RESTRICT
);

-- Ajoute conditionnement_id seulement si la colonne n'existe pas encore.
SET @conditionnement_column_exists = (
    SELECT COUNT(*)
    FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 't_mouvement_stock'
      AND column_name = 'conditionnement_id'
);

SET @add_conditionnement_column_sql = IF(
    @conditionnement_column_exists = 0,
    'ALTER TABLE t_mouvement_stock ADD COLUMN conditionnement_id BIGINT NULL AFTER id',
    'SELECT ''La colonne conditionnement_id existe deja'''
);

PREPARE add_conditionnement_column_stmt FROM @add_conditionnement_column_sql;
EXECUTE add_conditionnement_column_stmt;
DEALLOCATE PREPARE add_conditionnement_column_stmt;

-- Ajoute la cle etrangere seulement si elle n'existe pas encore.
SET @conditionnement_fk_exists = (
    SELECT COUNT(*)
    FROM information_schema.table_constraints
    WHERE constraint_schema = DATABASE()
      AND table_name = 't_mouvement_stock'
      AND constraint_name = 'fk_mouvement_conditionnement'
      AND constraint_type = 'FOREIGN KEY'
);

SET @add_conditionnement_fk_sql = IF(
    @conditionnement_fk_exists = 0,
    'ALTER TABLE t_mouvement_stock ADD CONSTRAINT fk_mouvement_conditionnement FOREIGN KEY (conditionnement_id) REFERENCES t_article_conditionnement (id) ON UPDATE NO ACTION ON DELETE RESTRICT',
    'SELECT ''La cle fk_mouvement_conditionnement existe deja'''
);

PREPARE add_conditionnement_fk_stmt FROM @add_conditionnement_fk_sql;
EXECUTE add_conditionnement_fk_stmt;
DEALLOCATE PREPARE add_conditionnement_fk_stmt;

-- ---------------------------------------------------------------------------
-- Donnees de reference indispensables
-- ---------------------------------------------------------------------------

INSERT IGNORE INTO t_roles (nom_role) VALUES ('ADMIN');

INSERT IGNORE INTO t_type_conditionnement (nom_conditionnement) VALUES
    ('PIECE'),
    ('PACK'),
    ('CARTON');

INSERT INTO t_type_mouvement (nom_type_mouvement, sens)
SELECT 'ENTREE', 1
WHERE NOT EXISTS (
    SELECT 1 FROM t_type_mouvement WHERE nom_type_mouvement = 'ENTREE'
);

INSERT INTO t_type_mouvement (nom_type_mouvement, sens)
SELECT 'SORTIE', -1
WHERE NOT EXISTS (
    SELECT 1 FROM t_type_mouvement WHERE nom_type_mouvement = 'SORTIE'
);

INSERT IGNORE INTO t_type_produit (nom_type) VALUES ('BOISSON');

-- Le compte ADM001 doit deja exister, par exemple via donnees_par_defaut.sql.
SET @admin_id = (
    SELECT id FROM t_user WHERE matricule = 'ADM001' LIMIT 1
);

-- ---------------------------------------------------------------------------
-- Rack et emplacements de simulation (un emplacement represente une palette)
-- ---------------------------------------------------------------------------

INSERT INTO t_rack (nom_rack, nombre_etages)
SELECT 'RACK-SIMULATION', 2
WHERE NOT EXISTS (
    SELECT 1 FROM t_rack WHERE nom_rack = 'RACK-SIMULATION'
);

SET @rack_id = (
    SELECT id FROM t_rack WHERE nom_rack = 'RACK-SIMULATION' ORDER BY id LIMIT 1
);

INSERT INTO t_emplacement (rack_id, nom_emplacement, numero_etage)
SELECT @rack_id, 'EMPLACEMENT-SIMULATION-1', 1
WHERE NOT EXISTS (
    SELECT 1
    FROM t_emplacement
    WHERE rack_id = @rack_id
      AND nom_emplacement = 'EMPLACEMENT-SIMULATION-1'
      AND numero_etage = 1
);

INSERT INTO t_emplacement (rack_id, nom_emplacement, numero_etage)
SELECT @rack_id, 'EMPLACEMENT-SIMULATION-2', 2
WHERE NOT EXISTS (
    SELECT 1
    FROM t_emplacement
    WHERE rack_id = @rack_id
      AND nom_emplacement = 'EMPLACEMENT-SIMULATION-2'
      AND numero_etage = 2
);

SET @emplacement_1_id = (
    SELECT id
    FROM t_emplacement
    WHERE rack_id = @rack_id
      AND nom_emplacement = 'EMPLACEMENT-SIMULATION-1'
      AND numero_etage = 1
    LIMIT 1
);

SET @emplacement_2_id = (
    SELECT id
    FROM t_emplacement
    WHERE rack_id = @rack_id
      AND nom_emplacement = 'EMPLACEMENT-SIMULATION-2'
      AND numero_etage = 2
    LIMIT 1
);

-- ---------------------------------------------------------------------------
-- Articles et codes-barres de simulation
-- ---------------------------------------------------------------------------

SET @type_produit_id = (
    SELECT id FROM t_type_produit WHERE nom_type = 'BOISSON' LIMIT 1
);

SET @type_piece_id = (
    SELECT id FROM t_type_conditionnement WHERE nom_conditionnement = 'PIECE' LIMIT 1
);

SET @type_pack_id = (
    SELECT id FROM t_type_conditionnement WHERE nom_conditionnement = 'PACK' LIMIT 1
);

SET @type_carton_id = (
    SELECT id FROM t_type_conditionnement WHERE nom_conditionnement = 'CARTON' LIMIT 1
);

-- Les colonnes code_bar et type_conditionnement_id existent actuellement dans
-- l'entite Article du projet, meme si conceptionv2 les place normalement dans
-- t_article_conditionnement.
INSERT INTO t_article (
    nom_article,
    code_bar,
    type_conditionnement_id,
    type_produit_id
)
SELECT
    'JUS ORANGE SIMULATION',
    'SIM-ARTICLE-JUS',
    @type_piece_id,
    @type_produit_id
WHERE NOT EXISTS (
    SELECT 1 FROM t_article WHERE code_bar = 'SIM-ARTICLE-JUS'
);

INSERT INTO t_article (
    nom_article,
    code_bar,
    type_conditionnement_id,
    type_produit_id
)
SELECT
    'EAU SIMULATION',
    'SIM-ARTICLE-EAU',
    @type_piece_id,
    @type_produit_id
WHERE NOT EXISTS (
    SELECT 1 FROM t_article WHERE code_bar = 'SIM-ARTICLE-EAU'
);

SET @article_jus_id = (
    SELECT id FROM t_article WHERE code_bar = 'SIM-ARTICLE-JUS' LIMIT 1
);

SET @article_eau_id = (
    SELECT id FROM t_article WHERE code_bar = 'SIM-ARTICLE-EAU' LIMIT 1
);

INSERT IGNORE INTO t_article_conditionnement (
    article_id, type_conditionnement_id, code_barres, quantite_piece_standard
) VALUES
    (@article_jus_id, @type_piece_id,  'SIM-JUS-PIECE',  1),
    (@article_jus_id, @type_pack_id,   'SIM-JUS-PACK',   6),
    (@article_jus_id, @type_carton_id, 'SIM-JUS-CARTON', 24),
    (@article_eau_id, @type_piece_id,  'SIM-EAU-PIECE',  1),
    (@article_eau_id, @type_pack_id,   'SIM-EAU-PACK',   6),
    (@article_eau_id, @type_carton_id, 'SIM-EAU-CARTON', 12);

SET @jus_piece_id = (
    SELECT id FROM t_article_conditionnement WHERE code_barres = 'SIM-JUS-PIECE'
);

SET @jus_pack_id = (
    SELECT id FROM t_article_conditionnement WHERE code_barres = 'SIM-JUS-PACK'
);

SET @jus_carton_id = (
    SELECT id FROM t_article_conditionnement WHERE code_barres = 'SIM-JUS-CARTON'
);

SET @eau_piece_id = (
    SELECT id FROM t_article_conditionnement WHERE code_barres = 'SIM-EAU-PIECE'
);

SET @eau_carton_id = (
    SELECT id FROM t_article_conditionnement WHERE code_barres = 'SIM-EAU-CARTON'
);

SET @entree_id = (
    SELECT id FROM t_type_mouvement WHERE nom_type_mouvement = 'ENTREE' LIMIT 1
);

SET @sortie_id = (
    SELECT id FROM t_type_mouvement WHERE nom_type_mouvement = 'SORTIE' LIMIT 1
);

-- ---------------------------------------------------------------------------
-- Mouvements de simulation
-- ---------------------------------------------------------------------------

-- Permet de rejouer le script sans additionner plusieurs fois la simulation.
DELETE FROM t_mouvement_stock
WHERE commentaire LIKE 'SIMULATION_VUES:%';

-- JUS, ETAGE-1 : +120 -12 = 108 pieces.
INSERT INTO t_mouvement_stock (
    conditionnement_id,
    type_mouvement_id,
    emplacement_id,
    user_id,
    nombre_conditionnements,
    quantite_pieces_reelle,
    date_mouvement,
    commentaire
) VALUES
    (@jus_carton_id, @entree_id, @emplacement_1_id, @admin_id,
     5, 120, CURRENT_TIMESTAMP, 'SIMULATION_VUES: entree de 5 cartons de jus'),
    (@jus_pack_id, @sortie_id, @emplacement_1_id, @admin_id,
     2, 12, CURRENT_TIMESTAMP, 'SIMULATION_VUES: sortie de 2 packs de jus');

-- JUS, ETAGE-2 : +72 -5 = 67 pieces.
INSERT INTO t_mouvement_stock (
    conditionnement_id,
    type_mouvement_id,
    emplacement_id,
    user_id,
    nombre_conditionnements,
    quantite_pieces_reelle,
    date_mouvement,
    commentaire
) VALUES
    (@jus_carton_id, @entree_id, @emplacement_2_id, @admin_id,
     3, 72, CURRENT_TIMESTAMP, 'SIMULATION_VUES: entree de 3 cartons de jus'),
    (@jus_piece_id, @sortie_id, @emplacement_2_id, @admin_id,
     5, 5, CURRENT_TIMESTAMP, 'SIMULATION_VUES: sortie de 5 pieces de jus');

-- EAU, ETAGE-1 : +100 -15 = 85 pieces.
INSERT INTO t_mouvement_stock (
    conditionnement_id,
    type_mouvement_id,
    emplacement_id,
    user_id,
    nombre_conditionnements,
    quantite_pieces_reelle,
    date_mouvement,
    commentaire
) VALUES
    (@eau_carton_id, @entree_id, @emplacement_1_id, @admin_id,
     9, 100, CURRENT_TIMESTAMP, 'SIMULATION_VUES: entree reelle de 100 bouteilles'),
    (@eau_piece_id, @sortie_id, @emplacement_1_id, @admin_id,
     15, 15, CURRENT_TIMESTAMP, 'SIMULATION_VUES: sortie de 15 bouteilles');

-- Rend la relation obligatoire une fois tous les mouvements correctement lies.
ALTER TABLE t_mouvement_stock
    MODIFY COLUMN conditionnement_id BIGINT NOT NULL;

-- ---------------------------------------------------------------------------
-- Vues de stock
-- ---------------------------------------------------------------------------

CREATE OR REPLACE VIEW v_stock_par_emplacement AS
SELECT
    ac.article_id,
    ms.emplacement_id,
    SUM(ms.quantite_pieces_reelle * tm.sens) AS quantite_stock
FROM t_mouvement_stock ms
JOIN t_article_conditionnement ac
    ON ac.id = ms.conditionnement_id
JOIN t_type_mouvement tm
    ON tm.id = ms.type_mouvement_id
GROUP BY ac.article_id, ms.emplacement_id;

CREATE OR REPLACE VIEW v_stock_total_article AS
SELECT
    ac.article_id,
    SUM(ms.quantite_pieces_reelle * tm.sens) AS quantite_stock
FROM t_mouvement_stock ms
JOIN t_article_conditionnement ac
    ON ac.id = ms.conditionnement_id
JOIN t_type_mouvement tm
    ON tm.id = ms.type_mouvement_id
GROUP BY ac.article_id;

-- ---------------------------------------------------------------------------
-- Resultats lisibles pour verifier la simulation
-- ---------------------------------------------------------------------------

SELECT
    a.id AS article_id,
    a.nom_article,
    r.nom_rack,
    e.nom_emplacement,
    e.numero_etage,
    spe.quantite_stock
FROM v_stock_par_emplacement spe
JOIN t_article a ON a.id = spe.article_id
JOIN t_emplacement e ON e.id = spe.emplacement_id
JOIN t_rack r ON r.id = e.rack_id
WHERE a.code_bar IN ('SIM-ARTICLE-JUS', 'SIM-ARTICLE-EAU')
ORDER BY a.id, e.numero_etage, e.id;

SELECT
    a.id AS article_id,
    a.nom_article,
    sta.quantite_stock
FROM v_stock_total_article sta
JOIN t_article a ON a.id = sta.article_id
WHERE a.code_bar IN ('SIM-ARTICLE-JUS', 'SIM-ARTICLE-EAU')
ORDER BY a.id;
