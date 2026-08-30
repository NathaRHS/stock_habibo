-- Active: 1771244146063@@127.0.0.1@3306@stock_habibo
-- Proposition de conception V2 pour la gestion de stock.
-- Le stock courant est calcule a partir des mouvements d'entree et de sortie.

CREATE TABLE IF NOT EXISTS t_type_produit (
    id BIGINT NOT NULL AUTO_INCREMENT,
    nom_type VARCHAR(255) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uk_type_produit_nom UNIQUE (nom_type)
);

CREATE TABLE IF NOT EXISTS t_article (
    id BIGINT NOT NULL AUTO_INCREMENT,
    nom_article VARCHAR(255) NOT NULL,
    type_produit_id BIGINT NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_article_type_produit
        FOREIGN KEY (type_produit_id) REFERENCES t_type_produit (id)
        ON UPDATE NO ACTION ON DELETE RESTRICT
);

-- Exemples : PIECE, PACK, CARTON.
CREATE TABLE IF NOT EXISTS t_type_conditionnement (
    id BIGINT NOT NULL AUTO_INCREMENT,
    nom_conditionnement VARCHAR(100) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uk_type_conditionnement_nom UNIQUE (nom_conditionnement)
);

-- Cette table identifie ce qui est scanne.
-- quantite_piece_standard est seulement indicative : un carton reel peut varier.
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

-- Regle globale de palettisation : un conditionnement d'article possede
-- une capacite maximale unique, appliquee a toutes les places palettes.
CREATE TABLE IF NOT EXISTS t_palette_conditionnement (
    id INT NOT NULL AUTO_INCREMENT,
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
);

-- Organisation physique : un rack possede plusieurs etages numerotes.
-- Chaque emplacement appartient a un rack et a un numero d'etage ; il represente une place palette.
CREATE TABLE IF NOT EXISTS t_rack (
    id BIGINT NOT NULL AUTO_INCREMENT,
    nom_rack VARCHAR(100) NOT NULL,
    nombre_etages INT NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uk_rack_nom UNIQUE (nom_rack),
    CONSTRAINT ck_rack_nombre_etages CHECK (nombre_etages > 0)
);

CREATE TABLE IF NOT EXISTS t_emplacement (
    id BIGINT NOT NULL AUTO_INCREMENT,
    rack_id BIGINT NOT NULL,
    nom_emplacement VARCHAR(100) NOT NULL,
    numero_etage INT NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uk_emplacement_rack_etage_nom
        UNIQUE (rack_id, numero_etage, nom_emplacement),
    CONSTRAINT ck_emplacement_numero_etage CHECK (numero_etage > 0),
    CONSTRAINT fk_emplacement_rack
        FOREIGN KEY (rack_id) REFERENCES t_rack (id)
        ON UPDATE NO ACTION ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS t_roles (
    id BIGINT NOT NULL AUTO_INCREMENT,
    nom_role VARCHAR(100) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uk_role_nom UNIQUE (nom_role)
);

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
);

CREATE TABLE IF NOT EXISTS t_type_mouvement (
    id BIGINT NOT NULL AUTO_INCREMENT,
    nom_type_mouvement VARCHAR(50) NOT NULL,
    sens SMALLINT NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uk_type_mouvement_nom UNIQUE (nom_type_mouvement),
    CONSTRAINT ck_type_mouvement_sens CHECK (sens IN (-1, 1))
);

-- Un mouvement conserve la quantite reellement comptee au moment du scan.
-- nombre_conditionnements indique par exemple 1 carton ou 3 packs.
-- quantite_pieces_reelle est la valeur utilisee pour calculer le stock.
CREATE TABLE IF NOT EXISTS t_mouvement_stock (
    id BIGINT NOT NULL AUTO_INCREMENT,
    detail_journal_id BIGINT NOT NULL,
    conditionnement_id BIGINT NOT NULL,
    type_mouvement_id BIGINT NOT NULL,
    emplacement_id BIGINT NULL,
    en_reserve BOOLEAN NOT NULL DEFAULT FALSE,
    user_id BIGINT NOT NULL,
    nombre_conditionnements INT NOT NULL DEFAULT 1,
    quantite_pieces_reelle INT NOT NULL,
    date_mouvement DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    commentaire VARCHAR(500) NULL,
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
    CONSTRAINT fk_mouvement_detail_journal
        FOREIGN KEY (detail_journal_id) REFERENCES t_detail_journal (id)
        ON UPDATE NO ACTION ON DELETE RESTRICT,
    CONSTRAINT fk_mouvement_conditionnement
        FOREIGN KEY (conditionnement_id) REFERENCES t_article_conditionnement (id)
        ON UPDATE NO ACTION ON DELETE RESTRICT,
    CONSTRAINT fk_mouvement_type
        FOREIGN KEY (type_mouvement_id) REFERENCES t_type_mouvement (id)
        ON UPDATE NO ACTION ON DELETE RESTRICT,
    CONSTRAINT fk_mouvement_emplacement
        FOREIGN KEY (emplacement_id) REFERENCES t_emplacement (id)
        ON UPDATE NO ACTION ON DELETE RESTRICT,
    CONSTRAINT fk_mouvement_user
        FOREIGN KEY (user_id) REFERENCES t_user (id)
        ON UPDATE NO ACTION ON DELETE RESTRICT
);

-- Journal technique et fonctionnel des actions importantes.
CREATE TABLE IF NOT EXISTS t_journal (
    id BIGINT NOT NULL AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    date_action DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    type_action VARCHAR(100) NOT NULL,
    entite VARCHAR(100) NULL,
    entite_id BIGINT NULL,
    description VARCHAR(500) NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_journal_user
        FOREIGN KEY (user_id) REFERENCES t_user (id)
        ON UPDATE NO ACTION ON DELETE RESTRICT
);

-- Stock en pieces par article et par emplacement (place palette).
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

-- Stock total en pieces par article, tous emplacements confondus.
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

INSERT IGNORE INTO t_roles (nom_role) VALUES
    ('SUPERVISEUR'),
    ('ADMIN'),
    ('RESPONSABLE_INVENTAIRE');

INSERT IGNORE INTO t_type_conditionnement (nom_conditionnement) VALUES
    ('PIECE'),
    ('PACK'),
    ('CARTON');

INSERT IGNORE INTO t_type_mouvement (nom_type_mouvement, sens) VALUES
    ('ENTREE', 1),
    ('SORTIE', -1);
