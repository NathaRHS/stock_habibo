-- Active: 1786994780822@@127.0.0.1@3307@stock_habibo
-- Migration a executer apres le premier demarrage Hibernate ayant ajoute :
-- t_rack.nombre_etages, t_emplacement.numero_etage et
-- t_mouvement_stock.emplacement_id.
-- Faire une sauvegarde de la base avant execution.

DROP VIEW IF EXISTS v_structure_entrepot;
DROP VIEW IF EXISTS v_stock_par_etage;

UPDATE t_rack rack
LEFT JOIN (
    SELECT emplacement.rack_id, MAX(structure.nombre_etages) AS nombre_etages
    FROM t_emplacement emplacement
    JOIN (
        SELECT emplacement_id, COUNT(*) AS nombre_etages
        FROM t_etage
        GROUP BY emplacement_id
    ) structure ON structure.emplacement_id = emplacement.id
    GROUP BY emplacement.rack_id
) structure_rack ON structure_rack.rack_id = rack.id
SET rack.nombre_etages = COALESCE(structure_rack.nombre_etages, 1);

-- Chaque ancien etage devient un emplacement (une place palette).
INSERT INTO t_emplacement (rack_id, nom_emplacement, numero_etage)
SELECT
    ancien_emplacement.rack_id,
    CONCAT(ancien_emplacement.nom_emplacement, '-', ancien_etage.nom_etage),
    (
        SELECT COUNT(*)
        FROM t_etage etage_precedent
        WHERE etage_precedent.emplacement_id = ancien_etage.emplacement_id
          AND etage_precedent.id <= ancien_etage.id
    )
FROM t_etage ancien_etage
JOIN t_emplacement ancien_emplacement
    ON ancien_emplacement.id = ancien_etage.emplacement_id
WHERE ancien_emplacement.numero_etage = 0;

UPDATE t_mouvement_stock mouvement
JOIN t_etage ancien_etage ON ancien_etage.id = mouvement.etage_id
JOIN t_emplacement ancien_emplacement
    ON ancien_emplacement.id = ancien_etage.emplacement_id
JOIN t_emplacement nouvel_emplacement
    ON nouvel_emplacement.rack_id = ancien_emplacement.rack_id
   AND nouvel_emplacement.nom_emplacement = CONCAT(
       ancien_emplacement.nom_emplacement, '-', ancien_etage.nom_etage)
SET mouvement.emplacement_id = nouvel_emplacement.id;

-- Supprime la cle etrangere vers t_etage, meme si Hibernate lui a donne
-- un nom genere automatiquement.
SET @ancienne_fk_etage = (
    SELECT contrainte.CONSTRAINT_NAME
    FROM information_schema.KEY_COLUMN_USAGE contrainte
    WHERE contrainte.CONSTRAINT_SCHEMA = DATABASE()
      AND contrainte.TABLE_NAME = 't_mouvement_stock'
      AND contrainte.COLUMN_NAME = 'etage_id'
      AND contrainte.REFERENCED_TABLE_NAME = 't_etage'
    LIMIT 1
);
SET @sql_suppression_fk = IF(
    @ancienne_fk_etage IS NULL,
    'SELECT 1',
    CONCAT('ALTER TABLE t_mouvement_stock DROP FOREIGN KEY `', @ancienne_fk_etage, '`')
);
PREPARE suppression_fk FROM @sql_suppression_fk;
EXECUTE suppression_fk;
DEALLOCATE PREPARE suppression_fk;

ALTER TABLE t_mouvement_stock DROP COLUMN etage_id;
DROP TABLE t_etage;
DELETE FROM t_emplacement WHERE numero_etage = 0;

ALTER TABLE t_mouvement_stock
    ADD CONSTRAINT fk_mouvement_emplacement
        FOREIGN KEY (emplacement_id) REFERENCES t_emplacement (id)
        ON UPDATE NO ACTION ON DELETE RESTRICT;

CREATE OR REPLACE VIEW v_stock_par_emplacement AS
SELECT
    article_conditionnement.article_id,
    mouvement.emplacement_id,
    SUM(mouvement.quantite_pieces_reelle * type_mouvement.sens) AS quantite_stock
FROM t_mouvement_stock mouvement
JOIN t_article_conditionnement article_conditionnement
    ON article_conditionnement.id = mouvement.conditionnement_id
JOIN t_type_mouvement type_mouvement
    ON type_mouvement.id = mouvement.type_mouvement_id
GROUP BY article_conditionnement.article_id, mouvement.emplacement_id;

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
JOIN t_rack rack ON rack.id = emplacement.rack_id;
