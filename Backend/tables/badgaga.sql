-- =====================================================================
-- badgaga.sql : migration complete vers le modele "historique des statuts"
--
--   Journal         t_statut -> t_statut_journal_mouvement + historique
--   Picking         colonne texte statut -> t_statut_picking + historique
--   Ligne picking   colonne texte statut -> t_statut_ligne_picking + historique
--
-- Chaque etape verifie d'abord si elle est deja faite : le script peut etre
-- rejoue sans risque.
--
-- A executer backend ARRETE, AVANT le prochain demarrage.
-- Faire une sauvegarde avant : les ALTER TABLE MySQL ne sont pas annulables.
-- Si une etape echoue, corriger la cause puis relancer le script en entier.
-- =====================================================================

USE stock_habibo;

-- =====================================================================
-- 1. JOURNAL : t_statut devient t_statut_journal_mouvement
-- =====================================================================

-- 1a. Si une table t_statut_journal_mouvement existe deja (ancienne conception
--     ou table vide creee par Hibernate) alors que t_statut existe encore, on la
--     met de cote sous le nom t_statut_journal_mouvement_ancien.
SET @sql = IF(
    (SELECT COUNT(*) FROM information_schema.TABLES
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 't_statut') = 1
    AND (SELECT COUNT(*) FROM information_schema.TABLES
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 't_statut_journal_mouvement') = 1
    AND (SELECT COUNT(*) FROM information_schema.TABLES
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 't_statut_journal_mouvement_ancien') = 0,
    'RENAME TABLE t_statut_journal_mouvement TO t_statut_journal_mouvement_ancien',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 1b. Renommage de t_statut (les cles etrangeres suivent le renommage).
SET @sql = IF(
    (SELECT COUNT(*) FROM information_schema.TABLES
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 't_statut') = 1
    AND (SELECT COUNT(*) FROM information_schema.TABLES
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 't_statut_journal_mouvement') = 0,
    'RENAME TABLE t_statut TO t_statut_journal_mouvement',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 1c. Les 6 statuts du journal (ceux de l'enum StatutJournalMouvementCode).
INSERT INTO t_statut_journal_mouvement (nom)
SELECT valeurs.nom
FROM (
    SELECT 'EN COURS' AS nom
    UNION ALL SELECT 'EN ATTENTE'
    UNION ALL SELECT 'VALIDE'
    UNION ALL SELECT 'MODIFIE'
    UNION ALL SELECT 'AFFECTEE'
    UNION ALL SELECT 'CLOTURE'
) valeurs
WHERE NOT EXISTS (
    SELECT 1 FROM t_statut_journal_mouvement existant WHERE existant.nom = valeurs.nom
);

-- 1d. Table d'historique du journal.
CREATE TABLE IF NOT EXISTS t_historique_journal_mouvement_statut (
    id BIGINT NOT NULL AUTO_INCREMENT,
    journal_mouvement_id BIGINT NOT NULL,
    statut_id BIGINT NOT NULL,
    date_changement DATETIME(6) NOT NULL,
    user_id BIGINT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_hist_journal FOREIGN KEY (journal_mouvement_id) REFERENCES t_journal_mouvement (id),
    CONSTRAINT fk_hist_journal_statut FOREIGN KEY (statut_id) REFERENCES t_statut_journal_mouvement (id),
    CONSTRAINT fk_hist_journal_user FOREIGN KEY (user_id) REFERENCES t_user (id)
) ENGINE = InnoDB;

-- 1e. Premiere ligne d'historique pour les journaux qui n'en ont pas.
INSERT INTO t_historique_journal_mouvement_statut
    (journal_mouvement_id, statut_id, date_changement, user_id)
SELECT journal.id, journal.statut_id, NOW(), NULL
FROM t_journal_mouvement journal
WHERE NOT EXISTS (
    SELECT 1
    FROM t_historique_journal_mouvement_statut historique
    WHERE historique.journal_mouvement_id = journal.id
);


-- =====================================================================
-- 2. PICKING : colonne texte statut -> t_statut_picking (statut_id)
-- =====================================================================

CREATE TABLE IF NOT EXISTS t_statut_picking (
    id BIGINT NOT NULL AUTO_INCREMENT,
    nom VARCHAR(50) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uk_statut_picking_nom UNIQUE (nom)
) ENGINE = InnoDB;

INSERT IGNORE INTO t_statut_picking (nom) VALUES
    ('GENERE'),
    ('EN_COURS'),
    ('TERMINE'),
    ('ANNULE');

-- 2a. Ajout de statut_id s'il n'existe pas encore.
SET @sql = IF(
    (SELECT COUNT(*) FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 't_picking' AND COLUMN_NAME = 'statut_id') = 0,
    'ALTER TABLE t_picking ADD COLUMN statut_id BIGINT NULL',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 2b. Conversion du texte en identifiant (seulement si l'ancienne colonne existe).
SET @sql = IF(
    (SELECT COUNT(*) FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 't_picking' AND COLUMN_NAME = 'statut') = 1,
    'UPDATE t_picking picking JOIN t_statut_picking statut ON statut.nom = picking.statut SET picking.statut_id = statut.id',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 2c. Doit afficher 0. Sinon un picking a un statut texte inconnu : corriger
--     avant de continuer (l'etape suivante echouera).
SELECT COUNT(*) AS pickings_sans_statut
FROM t_picking
WHERE statut_id IS NULL;

ALTER TABLE t_picking MODIFY statut_id BIGINT NOT NULL;

-- 2d. Cle etrangere (ignoree si une cle existe deja sur statut_id).
SET @sql = IF(
    (SELECT COUNT(*) FROM information_schema.KEY_COLUMN_USAGE
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 't_picking'
        AND COLUMN_NAME = 'statut_id' AND REFERENCED_TABLE_NAME IS NOT NULL) = 0,
    'ALTER TABLE t_picking ADD CONSTRAINT fk_picking_statut FOREIGN KEY (statut_id) REFERENCES t_statut_picking (id) ON UPDATE NO ACTION ON DELETE RESTRICT',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 2e. Suppression de l'ancienne colonne texte.
SET @sql = IF(
    (SELECT COUNT(*) FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 't_picking' AND COLUMN_NAME = 'statut') = 1,
    'ALTER TABLE t_picking DROP COLUMN statut',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 2f. Historique du picking.
CREATE TABLE IF NOT EXISTS t_historique_picking_statut (
    id BIGINT NOT NULL AUTO_INCREMENT,
    picking_id BIGINT NOT NULL,
    statut_id BIGINT NOT NULL,
    date_changement DATETIME(6) NOT NULL,
    user_id BIGINT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_hist_picking FOREIGN KEY (picking_id) REFERENCES t_picking (id),
    CONSTRAINT fk_hist_picking_statut FOREIGN KEY (statut_id) REFERENCES t_statut_picking (id),
    CONSTRAINT fk_hist_picking_user FOREIGN KEY (user_id) REFERENCES t_user (id)
) ENGINE = InnoDB;

INSERT INTO t_historique_picking_statut
    (picking_id, statut_id, date_changement, user_id)
SELECT picking.id, picking.statut_id, NOW(), NULL
FROM t_picking picking
WHERE NOT EXISTS (
    SELECT 1
    FROM t_historique_picking_statut historique
    WHERE historique.picking_id = picking.id
);


-- =====================================================================
-- 3. LIGNE DE PICKING : colonne texte statut -> t_statut_ligne_picking
-- =====================================================================

CREATE TABLE IF NOT EXISTS t_statut_ligne_picking (
    id BIGINT NOT NULL AUTO_INCREMENT,
    nom VARCHAR(50) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uk_statut_ligne_picking_nom UNIQUE (nom)
) ENGINE = InnoDB;

INSERT IGNORE INTO t_statut_ligne_picking (nom) VALUES
    ('RESERVEE'),
    ('EN_COURS'),
    ('PRELEVEE'),
    ('ANNULEE'),
    ('IMPOSSIBLE');

-- 3a. Ajout de statut_id s'il n'existe pas encore.
SET @sql = IF(
    (SELECT COUNT(*) FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 't_ligne_picking' AND COLUMN_NAME = 'statut_id') = 0,
    'ALTER TABLE t_ligne_picking ADD COLUMN statut_id BIGINT NULL',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 3b. Conversion du texte en identifiant (seulement si l'ancienne colonne existe).
SET @sql = IF(
    (SELECT COUNT(*) FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 't_ligne_picking' AND COLUMN_NAME = 'statut') = 1,
    'UPDATE t_ligne_picking ligne JOIN t_statut_ligne_picking statut ON statut.nom = ligne.statut SET ligne.statut_id = statut.id',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 3c. Doit afficher 0.
SELECT COUNT(*) AS lignes_sans_statut
FROM t_ligne_picking
WHERE statut_id IS NULL;

ALTER TABLE t_ligne_picking MODIFY statut_id BIGINT NOT NULL;

-- 3d. Cle etrangere (ignoree si une cle existe deja sur statut_id).
SET @sql = IF(
    (SELECT COUNT(*) FROM information_schema.KEY_COLUMN_USAGE
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 't_ligne_picking'
        AND COLUMN_NAME = 'statut_id' AND REFERENCED_TABLE_NAME IS NOT NULL) = 0,
    'ALTER TABLE t_ligne_picking ADD CONSTRAINT fk_ligne_picking_statut FOREIGN KEY (statut_id) REFERENCES t_statut_ligne_picking (id) ON UPDATE NO ACTION ON DELETE RESTRICT',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 3e. Suppression de l'ancienne colonne texte.
SET @sql = IF(
    (SELECT COUNT(*) FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 't_ligne_picking' AND COLUMN_NAME = 'statut') = 1,
    'ALTER TABLE t_ligne_picking DROP COLUMN statut',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 3f. Historique de la ligne de picking.
CREATE TABLE IF NOT EXISTS t_historique_ligne_picking_statut (
    id BIGINT NOT NULL AUTO_INCREMENT,
    ligne_picking_id BIGINT NOT NULL,
    statut_id BIGINT NOT NULL,
    date_changement DATETIME(6) NOT NULL,
    user_id BIGINT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_hist_ligne_picking FOREIGN KEY (ligne_picking_id) REFERENCES t_ligne_picking (id),
    CONSTRAINT fk_hist_ligne_picking_statut FOREIGN KEY (statut_id) REFERENCES t_statut_ligne_picking (id),
    CONSTRAINT fk_hist_ligne_picking_user FOREIGN KEY (user_id) REFERENCES t_user (id)
) ENGINE = InnoDB;

INSERT INTO t_historique_ligne_picking_statut
    (ligne_picking_id, statut_id, date_changement, user_id)
SELECT ligne.id, ligne.statut_id, NOW(), NULL
FROM t_ligne_picking ligne
WHERE NOT EXISTS (
    SELECT 1
    FROM t_historique_ligne_picking_statut historique
    WHERE historique.ligne_picking_id = ligne.id
);


-- =====================================================================
-- 4. VERIFICATIONS (chaque ligne doit avoir au moins 1 ligne d'historique)
-- =====================================================================

SELECT 'journal' AS entite, COUNT(*) AS total,
       SUM(historique.nb = 0) AS sans_historique
FROM (
    SELECT journal.id, COUNT(h.id) AS nb
    FROM t_journal_mouvement journal
    LEFT JOIN t_historique_journal_mouvement_statut h ON h.journal_mouvement_id = journal.id
    GROUP BY journal.id
) historique
UNION ALL
SELECT 'picking', COUNT(*), SUM(historique.nb = 0)
FROM (
    SELECT picking.id, COUNT(h.id) AS nb
    FROM t_picking picking
    LEFT JOIN t_historique_picking_statut h ON h.picking_id = picking.id
    GROUP BY picking.id
) historique
UNION ALL
SELECT 'ligne_picking', COUNT(*), SUM(historique.nb = 0)
FROM (
    SELECT ligne.id, COUNT(h.id) AS nb
    FROM t_ligne_picking ligne
    LEFT JOIN t_historique_ligne_picking_statut h ON h.ligne_picking_id = ligne.id
    GROUP BY ligne.id
) historique;

SELECT 't_statut_journal_mouvement' AS table_statuts, id, nom FROM t_statut_journal_mouvement
UNION ALL
SELECT 't_statut_picking', id, nom FROM t_statut_picking
UNION ALL
SELECT 't_statut_ligne_picking', id, nom FROM t_statut_ligne_picking
ORDER BY 1, 2;
