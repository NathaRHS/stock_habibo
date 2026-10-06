-- Migration du statut de picking : colonne texte t_picking.statut
-- vers une table de statuts t_statut_picking (cle etrangere statut_id),
-- avec premiere ligne d'historique pour chaque picking existant.
--
-- A executer UNE SEULE FOIS, backend ARRETE, AVANT le prochain demarrage.
-- Faire une sauvegarde avant : les ALTER TABLE MySQL ne sont pas annulables.

USE stock_habibo;

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

ALTER TABLE t_picking
    ADD COLUMN statut_id BIGINT NULL;

UPDATE t_picking picking
JOIN t_statut_picking statut ON statut.nom = picking.statut
SET picking.statut_id = statut.id;

-- Doit retourner 0 avant de continuer (sinon un statut texte est inconnu).
SELECT COUNT(*) AS pickings_sans_statut
FROM t_picking
WHERE statut_id IS NULL;

ALTER TABLE t_picking
    MODIFY statut_id BIGINT NOT NULL;

ALTER TABLE t_picking
    ADD CONSTRAINT fk_picking_statut
        FOREIGN KEY (statut_id)
        REFERENCES t_statut_picking (id)
        ON UPDATE NO ACTION
        ON DELETE RESTRICT;

ALTER TABLE t_picking
    DROP COLUMN statut;

-- Table d'historique (identique a ce que Hibernate genererait).
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

-- Premiere ligne d'historique pour les pickings existants (rejouable).
INSERT INTO t_historique_picking_statut
    (picking_id, statut_id, date_changement, user_id)
SELECT picking.id, picking.statut_id, NOW(), NULL
FROM t_picking picking
WHERE NOT EXISTS (
    SELECT 1
    FROM t_historique_picking_statut historique
    WHERE historique.picking_id = picking.id
);

-- Verification.
SELECT picking.id, statut.nom AS statut_actuel, COUNT(historique.id) AS nb_lignes_historique
FROM t_picking picking
JOIN t_statut_picking statut ON statut.id = picking.statut_id
LEFT JOIN t_historique_picking_statut historique ON historique.picking_id = picking.id
GROUP BY picking.id, statut.nom
ORDER BY picking.id;
