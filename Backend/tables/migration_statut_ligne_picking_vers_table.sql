-- Migration du statut de ligne de picking : colonne texte t_ligne_picking.statut
-- vers une table de statuts t_statut_ligne_picking (cle etrangere statut_id),
-- avec premiere ligne d'historique pour chaque ligne existante.
--
-- A executer UNE SEULE FOIS, backend ARRETE, AVANT le prochain demarrage.
-- Faire une sauvegarde avant : les ALTER TABLE MySQL ne sont pas annulables.

USE stock_habibo;

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

ALTER TABLE t_ligne_picking
    ADD COLUMN statut_id BIGINT NULL;

UPDATE t_ligne_picking ligne
JOIN t_statut_ligne_picking statut ON statut.nom = ligne.statut
SET ligne.statut_id = statut.id;

-- Doit retourner 0 avant de continuer (sinon un statut texte est inconnu).
SELECT COUNT(*) AS lignes_sans_statut
FROM t_ligne_picking
WHERE statut_id IS NULL;

ALTER TABLE t_ligne_picking
    MODIFY statut_id BIGINT NOT NULL;

ALTER TABLE t_ligne_picking
    ADD CONSTRAINT fk_ligne_picking_statut
        FOREIGN KEY (statut_id)
        REFERENCES t_statut_ligne_picking (id)
        ON UPDATE NO ACTION
        ON DELETE RESTRICT;

ALTER TABLE t_ligne_picking
    DROP COLUMN statut;

-- Table d'historique (identique a ce que Hibernate genererait).
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

-- Premiere ligne d'historique pour les lignes existantes (rejouable).
INSERT INTO t_historique_ligne_picking_statut
    (ligne_picking_id, statut_id, date_changement, user_id)
SELECT ligne.id, ligne.statut_id, NOW(), NULL
FROM t_ligne_picking ligne
WHERE NOT EXISTS (
    SELECT 1
    FROM t_historique_ligne_picking_statut historique
    WHERE historique.ligne_picking_id = ligne.id
);

-- Verification.
SELECT ligne.id, statut.nom AS statut_actuel, COUNT(historique.id) AS nb_lignes_historique
FROM t_ligne_picking ligne
JOIN t_statut_ligne_picking statut ON statut.id = ligne.statut_id
LEFT JOIN t_historique_ligne_picking_statut historique ON historique.ligne_picking_id = ligne.id
GROUP BY ligne.id, statut.nom
ORDER BY ligne.id;
