-- Ajoute et initialise l'ordre physique des emplacements deja existants.
-- A executer une seule fois sur une base creee avant l'ajout de ce champ.

USE stock_habibo;

SET @colonne_ordre_existe = (
    SELECT COUNT(*)
    FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 't_emplacement'
      AND column_name = 'ordre_dans_etage'
);

SET @ajouter_colonne_ordre = IF(
    @colonne_ordre_existe = 0,
    'ALTER TABLE t_emplacement ADD COLUMN ordre_dans_etage INT NULL AFTER numero_etage',
    'SELECT ''La colonne ordre_dans_etage existe deja'''
);

PREPARE instruction_ajout_colonne FROM @ajouter_colonne_ordre;
EXECUTE instruction_ajout_colonne;
DEALLOCATE PREPARE instruction_ajout_colonne;

CREATE TEMPORARY TABLE tmp_ordre_emplacement AS
SELECT
    id,
    ROW_NUMBER() OVER (
        PARTITION BY rack_id, numero_etage
        ORDER BY nom_emplacement, id
    ) AS ordre_calcule
FROM t_emplacement;

UPDATE t_emplacement emplacement
JOIN tmp_ordre_emplacement ordre ON ordre.id = emplacement.id
SET emplacement.ordre_dans_etage = ordre.ordre_calcule;

DROP TEMPORARY TABLE tmp_ordre_emplacement;

ALTER TABLE t_emplacement
    MODIFY COLUMN ordre_dans_etage INT NOT NULL;

SET @contrainte_unique_existe = (
    SELECT COUNT(*)
    FROM information_schema.table_constraints
    WHERE constraint_schema = DATABASE()
      AND table_name = 't_emplacement'
      AND constraint_name = 'uk_emplacement_rack_etage_ordre'
);

SET @ajouter_contrainte_unique = IF(
    @contrainte_unique_existe = 0,
    'ALTER TABLE t_emplacement ADD CONSTRAINT uk_emplacement_rack_etage_ordre UNIQUE (rack_id, numero_etage, ordre_dans_etage)',
    'SELECT ''La contrainte unique des ordres existe deja'''
);

PREPARE instruction_contrainte_unique FROM @ajouter_contrainte_unique;
EXECUTE instruction_contrainte_unique;
DEALLOCATE PREPARE instruction_contrainte_unique;

SET @contrainte_check_existe = (
    SELECT COUNT(*)
    FROM information_schema.table_constraints
    WHERE constraint_schema = DATABASE()
      AND table_name = 't_emplacement'
      AND constraint_name = 'ck_emplacement_ordre'
);

SET @ajouter_contrainte_check = IF(
    @contrainte_check_existe = 0,
    'ALTER TABLE t_emplacement ADD CONSTRAINT ck_emplacement_ordre CHECK (ordre_dans_etage > 0)',
    'SELECT ''La contrainte de validation de l ordre existe deja'''
);

PREPARE instruction_contrainte_check FROM @ajouter_contrainte_check;
EXECUTE instruction_contrainte_check;
DEALLOCATE PREPARE instruction_contrainte_check;
