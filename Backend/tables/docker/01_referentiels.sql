-- ============================================================================
-- 01 - REFERENTIELS (valeurs imposees par le code)
-- ============================================================================
-- A charger APRES le premier demarrage du backend : les tables sont creees par
-- Hibernate (ddl-auto=update), ce script ne contient que des INSERT.
-- Rejouable : toutes les colonnes "nom" sont UNIQUE, INSERT IGNORE evite les doublons.
-- Aucun identifiant n'est ecrit en dur.
--
-- Source des valeurs :
--   statuts de journal ....... StatutJournalMouvementCode
--   statuts de picking ....... StatutPickingCode
--   statuts de ligne ......... StatutLignePickingCode
--   statuts de prelevement ... CommandeService ("PRELEVE"), LignePickingService ("CONFIRME")
--   roles .................... SecurityConfig (+ filtre du mobile : OPERATEUR, INVENTORISTE)
-- ============================================================================

USE stock_habibo;

START TRANSACTION;

INSERT IGNORE INTO t_roles (nom_role) VALUES
    ('ADMIN'),
    ('OPERATEUR'),
    ('INVENTORISTE'),
    ('AUDITEUR');

INSERT IGNORE INTO t_statut_journal_mouvement (nom) VALUES
    ('EN COURS'),
    ('EN ATTENTE'),
    ('VALIDE'),
    ('MODIFIE'),
    ('AFFECTEE'),
    ('CLOTURE');

INSERT IGNORE INTO t_statut_picking (nom) VALUES
    ('GENERE'),
    ('EN_COURS'),
    ('TERMINE'),
    ('ANNULE');

INSERT IGNORE INTO t_statut_ligne_picking (nom) VALUES
    ('RESERVEE'),
    ('EN_COURS'),
    ('PRELEVEE'),
    ('ANNULEE'),
    ('IMPOSSIBLE');

INSERT IGNORE INTO t_statut_prelevement (nom_statut) VALUES
    ('PRELEVE'),
    ('CONFIRME');

-- Le sens vaut 1 (le stock augmente) ou -1 (il diminue).
INSERT IGNORE INTO t_type_mouvement (nom_type_mouvement, sens) VALUES
    ('ENTREE', 1),
    ('SORTIE', -1);

-- Types de journal. Le code impose seulement sens = 1 ou -1 (verifierSens).
-- INVENTAIRE n'agit pas sur le stock (aucun mouvement cree) : son sens n'a
-- aucun effet de calcul, il sert uniquement a l'affichage.
INSERT IGNORE INTO t_type_mouvement_journal (nom_type_mouvement, sens) VALUES
    ('ENTREE', 1),
    ('SORTIE', -1),
    ('INVENTAIRE', 1);

COMMIT;

-- Controle rapide
SELECT 'roles' AS table_cible, COUNT(*) AS lignes FROM t_roles
UNION ALL SELECT 'statuts journal', COUNT(*) FROM t_statut_journal_mouvement
UNION ALL SELECT 'statuts picking', COUNT(*) FROM t_statut_picking
UNION ALL SELECT 'statuts ligne picking', COUNT(*) FROM t_statut_ligne_picking
UNION ALL SELECT 'statuts prelevement', COUNT(*) FROM t_statut_prelevement
UNION ALL SELECT 'types mouvement stock', COUNT(*) FROM t_type_mouvement
UNION ALL SELECT 'types mouvement journal', COUNT(*) FROM t_type_mouvement_journal;
