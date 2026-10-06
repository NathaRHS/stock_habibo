-- Migration des statuts de journal vers le referentiel commun t_statut.
-- A executer une seule fois sur une base existante, backend arrete.
-- Effectuer une sauvegarde avant execution : les ALTER TABLE MySQL valident
-- implicitement leurs changements et ne sont pas annulables par ROLLBACK.

USE stock_habibo;

CREATE TABLE IF NOT EXISTS t_statut (
    id BIGINT NOT NULL AUTO_INCREMENT,
    nom VARCHAR(50) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uk_statut_nom UNIQUE (nom)
) ENGINE = InnoDB;

INSERT IGNORE INTO t_statut (nom)
SELECT nom_statut
FROM t_statut_journal_mouvement;

ALTER TABLE t_journal_mouvement
    ADD COLUMN statut_id BIGINT NULL;

UPDATE t_journal_mouvement journal
JOIN t_statut_journal_mouvement ancien_statut
    ON ancien_statut.id = journal.statut_journal_mouvement_id
JOIN t_statut nouveau_statut
    ON nouveau_statut.nom = ancien_statut.nom_statut
SET journal.statut_id = nouveau_statut.id;

-- La migration doit s'arreter ici si un journal n'a pas obtenu de statut_id.
-- Ce SELECT doit retourner 0 avant d'executer les ALTER TABLE suivants.
SELECT COUNT(*) AS journaux_sans_statut
FROM t_journal_mouvement
WHERE statut_id IS NULL;

ALTER TABLE t_journal_mouvement
    MODIFY statut_id BIGINT NOT NULL;

ALTER TABLE t_journal_mouvement
    DROP FOREIGN KEY fk_journal_statut;

ALTER TABLE t_journal_mouvement
    DROP COLUMN statut_journal_mouvement_id;

ALTER TABLE t_journal_mouvement
    ADD CONSTRAINT fk_journal_statut
        FOREIGN KEY (statut_id)
        REFERENCES t_statut (id)
        ON UPDATE NO ACTION
        ON DELETE RESTRICT;

SELECT journal.id,
       journal.reference,
       statut.id AS statut_id,
       statut.nom AS statut
FROM t_journal_mouvement journal
JOIN t_statut statut ON statut.id = journal.statut_id
ORDER BY journal.id;
