-- ============================================================================
-- CREATION COMPLETE DU SCHEMA - WMS HABIBO
-- MySQL 8+
--
-- Ce script cree uniquement la structure. Pour charger les donnees de test,
-- executer ensuite : seeders.sql
-- ============================================================================

CREATE DATABASE IF NOT EXISTS stock_habibo
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE stock_habibo;

-- ============================================================================
-- 1. TABLES DE REFERENCE
-- ============================================================================

CREATE TABLE IF NOT EXISTS t_roles (
    id BIGINT NOT NULL AUTO_INCREMENT,
    nom_role VARCHAR(255) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uk_role_nom UNIQUE (nom_role)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS t_statut_journal_mouvement (
    id BIGINT NOT NULL AUTO_INCREMENT,
    nom_statut VARCHAR(50) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uk_statut_journal_nom UNIQUE (nom_statut)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS t_type_mouvement (
    id BIGINT NOT NULL AUTO_INCREMENT,
    nom_type_mouvement VARCHAR(50) NOT NULL,
    sens SMALLINT NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uk_type_mouvement_nom UNIQUE (nom_type_mouvement),
    CONSTRAINT ck_type_mouvement_sens CHECK (sens IN (-1, 1))
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS t_type_mouvement_journal (
    id BIGINT NOT NULL AUTO_INCREMENT,
    nom_type_mouvement VARCHAR(50) NOT NULL,
    sens SMALLINT NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uk_type_mouvement_journal_nom UNIQUE (nom_type_mouvement),
    CONSTRAINT ck_type_mouvement_journal_sens CHECK (sens IN (-1, 1))
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS t_type_conditionnement (
    id BIGINT NOT NULL AUTO_INCREMENT,
    nom_conditionnement VARCHAR(100) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uk_type_conditionnement_nom UNIQUE (nom_conditionnement)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS t_type_produit (
    id BIGINT NOT NULL AUTO_INCREMENT,
    nom_type VARCHAR(255) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uk_type_produit_nom UNIQUE (nom_type)
) ENGINE = InnoDB;

-- ============================================================================
-- 2. UTILISATEURS ET SOCIETES
-- ============================================================================

CREATE TABLE IF NOT EXISTS t_user (
    id BIGINT NOT NULL AUTO_INCREMENT,
    username VARCHAR(255) NOT NULL,
    matricule VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role_id BIGINT NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uk_user_username UNIQUE (username),
    CONSTRAINT uk_user_matricule UNIQUE (matricule),
    CONSTRAINT uk_user_email UNIQUE (email),
    CONSTRAINT fk_user_role
        FOREIGN KEY (role_id) REFERENCES t_roles (id)
        ON UPDATE NO ACTION ON DELETE RESTRICT
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS t_societe (
    id BIGINT NOT NULL AUTO_INCREMENT,
    nom_societe VARCHAR(255) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uk_societe_nom UNIQUE (nom_societe)
) ENGINE = InnoDB;

-- ============================================================================
-- 3. STRUCTURE PHYSIQUE DE L'ENTREPOT
-- Un emplacement correspond directement a une place palette.
-- ============================================================================

CREATE TABLE IF NOT EXISTS t_rack (
    id BIGINT NOT NULL AUTO_INCREMENT,
    nom_rack VARCHAR(255) NOT NULL,
    nombre_etages INT NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uk_rack_nom UNIQUE (nom_rack),
    CONSTRAINT ck_rack_nombre_etages CHECK (nombre_etages > 0)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS t_emplacement (
    id BIGINT NOT NULL AUTO_INCREMENT,
    nom_emplacement VARCHAR(255) NOT NULL,
    rack_id BIGINT NOT NULL,
    numero_etage INT NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uk_emplacement_rack_nom
        UNIQUE (rack_id, numero_etage, nom_emplacement),
    CONSTRAINT ck_emplacement_numero_etage CHECK (numero_etage > 0),
    CONSTRAINT fk_emplacement_rack
        FOREIGN KEY (rack_id) REFERENCES t_rack (id)
        ON UPDATE NO ACTION ON DELETE RESTRICT
) ENGINE = InnoDB;

-- ============================================================================
-- 4. CATALOGUE ET PALETTISATION
-- ============================================================================

CREATE TABLE IF NOT EXISTS t_article (
    id BIGINT NOT NULL AUTO_INCREMENT,
    code_bar VARCHAR(255) NOT NULL,
    nom_article VARCHAR(255) NOT NULL,
    type_conditionnement_id BIGINT NOT NULL,
    type_produit_id BIGINT NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uk_article_code_bar UNIQUE (code_bar),
    CONSTRAINT fk_article_type_conditionnement
        FOREIGN KEY (type_conditionnement_id)
        REFERENCES t_type_conditionnement (id)
        ON UPDATE NO ACTION ON DELETE RESTRICT,
    CONSTRAINT fk_article_type_produit
        FOREIGN KEY (type_produit_id) REFERENCES t_type_produit (id)
        ON UPDATE NO ACTION ON DELETE RESTRICT
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS t_article_conditionnement (
    id BIGINT NOT NULL AUTO_INCREMENT,
    article_id BIGINT NOT NULL,
    type_conditionnement_id BIGINT NOT NULL,
    code_barres VARCHAR(255) NOT NULL,
    quantite_piece_standard INT NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uk_article_conditionnement_code_barres UNIQUE (code_barres),
    CONSTRAINT ck_conditionnement_quantite_standard
        CHECK (quantite_piece_standard > 0),
    CONSTRAINT fk_conditionnement_article
        FOREIGN KEY (article_id) REFERENCES t_article (id)
        ON UPDATE NO ACTION ON DELETE RESTRICT,
    CONSTRAINT fk_conditionnement_type
        FOREIGN KEY (type_conditionnement_id)
        REFERENCES t_type_conditionnement (id)
        ON UPDATE NO ACTION ON DELETE RESTRICT
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS t_palette_conditionnement (
    id BIGINT NOT NULL AUTO_INCREMENT,
    article_conditionnement_id BIGINT NOT NULL,
    quantite INT NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uk_palette_article_conditionnement
        UNIQUE (article_conditionnement_id),
    CONSTRAINT ck_palette_conditionnement_quantite CHECK (quantite > 0),
    CONSTRAINT fk_palette_article_conditionnement
        FOREIGN KEY (article_conditionnement_id)
        REFERENCES t_article_conditionnement (id)
        ON UPDATE NO ACTION ON DELETE RESTRICT
) ENGINE = InnoDB;

-- ============================================================================
-- 5. JOURNAUX ET SESSIONS DE SCAN
-- ============================================================================

CREATE TABLE IF NOT EXISTS t_journal_mouvement (
    id BIGINT NOT NULL AUTO_INCREMENT,
    nom_client VARCHAR(255) NULL,
    reference VARCHAR(255) NOT NULL,
    url_piece_jointe VARCHAR(255) NULL,
    fournisseur_id BIGINT NULL,
    type_mouvement_journal_id BIGINT NOT NULL,
    statut_journal_mouvement_id BIGINT NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uk_journal_mouvement_reference UNIQUE (reference),
    CONSTRAINT fk_journal_fournisseur
        FOREIGN KEY (fournisseur_id) REFERENCES t_societe (id)
        ON UPDATE NO ACTION ON DELETE RESTRICT,
    CONSTRAINT fk_journal_type_mouvement
        FOREIGN KEY (type_mouvement_journal_id)
        REFERENCES t_type_mouvement_journal (id)
        ON UPDATE NO ACTION ON DELETE RESTRICT,
    CONSTRAINT fk_journal_statut
        FOREIGN KEY (statut_journal_mouvement_id)
        REFERENCES t_statut_journal_mouvement (id)
        ON UPDATE NO ACTION ON DELETE RESTRICT
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS t_detail_journal (
    id BIGINT NOT NULL AUTO_INCREMENT,
    journal_mouvement_id BIGINT NOT NULL,
    article_id BIGINT NOT NULL,
    quantite INT NOT NULL,
    quantite_conditionnement INT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_detail_journal_article
        UNIQUE (journal_mouvement_id, article_id),
    CONSTRAINT ck_detail_quantite CHECK (quantite > 0),
    CONSTRAINT ck_detail_quantite_conditionnement
        CHECK (
            quantite_conditionnement IS NULL
            OR quantite_conditionnement > 0
        ),
    CONSTRAINT fk_detail_journal
        FOREIGN KEY (journal_mouvement_id)
        REFERENCES t_journal_mouvement (id)
        ON UPDATE NO ACTION ON DELETE RESTRICT,
    CONSTRAINT fk_detail_article
        FOREIGN KEY (article_id) REFERENCES t_article (id)
        ON UPDATE NO ACTION ON DELETE RESTRICT
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS t_user_journal_mouvement (
    id BIGINT NOT NULL AUTO_INCREMENT,
    journal_mouvement_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    statut_participation VARCHAR(20) NOT NULL DEFAULT 'EN_COURS',
    date_debut DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    date_fin DATETIME NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_user_journal_mouvement
        UNIQUE (journal_mouvement_id, user_id),
    CONSTRAINT ck_participation_statut
        CHECK (statut_participation IN ('EN_COURS', 'TERMINE')),
    CONSTRAINT ck_participation_dates
        CHECK (date_fin IS NULL OR date_fin >= date_debut),
    CONSTRAINT fk_participation_journal
        FOREIGN KEY (journal_mouvement_id)
        REFERENCES t_journal_mouvement (id)
        ON UPDATE NO ACTION ON DELETE RESTRICT,
    CONSTRAINT fk_participation_user
        FOREIGN KEY (user_id) REFERENCES t_user (id)
        ON UPDATE NO ACTION ON DELETE RESTRICT
) ENGINE = InnoDB;

-- ============================================================================
-- 6. MOUVEMENTS DE STOCK
-- Le journal est accessible par detail_journal_id :
-- MouvementStock -> DetailJournal -> JournalMouvement.
-- ============================================================================

CREATE TABLE IF NOT EXISTS t_mouvement_stock (
    id BIGINT NOT NULL AUTO_INCREMENT,
    conditionnement_id BIGINT NOT NULL,
    commentaire VARCHAR(500) NULL,
    date_mouvement DATETIME(6) NOT NULL,
    nombre_conditionnements INT NOT NULL,
    quantite_pieces_reelle INT NOT NULL,
    type_mouvement_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    emplacement_id BIGINT NULL,
    en_reserve BOOLEAN NOT NULL DEFAULT FALSE,
    detail_journal_id BIGINT NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT ck_mouvement_nombre_conditionnements
        CHECK (nombre_conditionnements > 0),
    CONSTRAINT ck_mouvement_quantite_reelle
        CHECK (quantite_pieces_reelle > 0),
    CONSTRAINT ck_mouvement_destination
        CHECK (
            (en_reserve = TRUE AND emplacement_id IS NULL)
            OR (en_reserve = FALSE AND emplacement_id IS NOT NULL)
        ),
    CONSTRAINT fk_mouvement_conditionnement
        FOREIGN KEY (conditionnement_id)
        REFERENCES t_article_conditionnement (id)
        ON UPDATE NO ACTION ON DELETE RESTRICT,
    CONSTRAINT fk_mouvement_type
        FOREIGN KEY (type_mouvement_id) REFERENCES t_type_mouvement (id)
        ON UPDATE NO ACTION ON DELETE RESTRICT,
    CONSTRAINT fk_mouvement_user
        FOREIGN KEY (user_id) REFERENCES t_user (id)
        ON UPDATE NO ACTION ON DELETE RESTRICT,
    CONSTRAINT fk_mouvement_emplacement
        FOREIGN KEY (emplacement_id) REFERENCES t_emplacement (id)
        ON UPDATE NO ACTION ON DELETE RESTRICT,
    CONSTRAINT fk_mouvement_detail
        FOREIGN KEY (detail_journal_id) REFERENCES t_detail_journal (id)
        ON UPDATE NO ACTION ON DELETE RESTRICT
) ENGINE = InnoDB;

-- ============================================================================
-- 7. VUES
-- ============================================================================

CREATE OR REPLACE VIEW v_stock_par_emplacement AS
SELECT
    conditionnement.article_id,
    mouvement.emplacement_id,
    SUM(
        mouvement.quantite_pieces_reelle * type_mouvement.sens
    ) AS quantite_stock
FROM t_mouvement_stock mouvement
JOIN t_article_conditionnement conditionnement
    ON conditionnement.id = mouvement.conditionnement_id
JOIN t_type_mouvement type_mouvement
    ON type_mouvement.id = mouvement.type_mouvement_id
WHERE mouvement.en_reserve = FALSE
  AND mouvement.emplacement_id IS NOT NULL
GROUP BY conditionnement.article_id, mouvement.emplacement_id
HAVING SUM(
    mouvement.quantite_pieces_reelle * type_mouvement.sens
) <> 0;

CREATE OR REPLACE VIEW v_stock_total_article AS
SELECT
    conditionnement.article_id,
    SUM(
        mouvement.quantite_pieces_reelle * type_mouvement.sens
    ) AS quantite_stock
FROM t_mouvement_stock mouvement
JOIN t_article_conditionnement conditionnement
    ON conditionnement.id = mouvement.conditionnement_id
JOIN t_type_mouvement type_mouvement
    ON type_mouvement.id = mouvement.type_mouvement_id
GROUP BY conditionnement.article_id
HAVING SUM(
    mouvement.quantite_pieces_reelle * type_mouvement.sens
) <> 0;

CREATE OR REPLACE VIEW v_structure_entrepot AS
SELECT
    emplacement.id AS position_stockage_id,
    rack.id AS rack_id,
    rack.nom_rack,
    rack.nombre_etages,
    emplacement.id AS emplacement_id,
    emplacement.nom_emplacement,
    emplacement.numero_etage,
    CONCAT_WS(
        ' / ',
        rack.nom_rack,
        CONCAT('Etage ', emplacement.numero_etage),
        emplacement.nom_emplacement
    ) AS adresse_stockage
FROM t_emplacement emplacement
JOIN t_rack rack
    ON rack.id = emplacement.rack_id;

-- Verification rapide de la structure creee.
SHOW FULL TABLES;
