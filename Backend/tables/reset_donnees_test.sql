-- Remise a zero des donnees de test.
-- t_user et t_roles sont volontairement conserves.

SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE t_mouvement_stock;
TRUNCATE TABLE t_user_journal_mouvement;
TRUNCATE TABLE t_user;
TRUNCATE TABLE t_detail_journal;
TRUNCATE TABLE t_journal_mouvement;
TRUNCATE TABLE t_palette_conditionnement;
TRUNCATE TABLE t_article_conditionnement;
TRUNCATE TABLE t_article;
TRUNCATE TABLE t_emplacement;
TRUNCATE TABLE t_rack;
TRUNCATE TABLE t_societe;

TRUNCATE TABLE t_statut_journal_mouvement;
TRUNCATE TABLE t_type_mouvement;
TRUNCATE TABLE t_type_mouvement_journal;
TRUNCATE TABLE t_type_conditionnement;
TRUNCATE TABLE t_type_produit;

SET FOREIGN_KEY_CHECKS = 1;

-- Referentiels minimaux necessaires au fonctionnement et aux tests.
INSERT INTO t_statut_journal_mouvement (nom_statut) VALUES
    ('EN COURS'),
    ('VALIDE'),
    ('MODIFIE'),
    ('EN ATTENTE');

INSERT INTO t_type_mouvement (nom_type_mouvement, sens) VALUES
    ('ENTREE', 1),
    ('SORTIE', -1),
    ('AJUSTEMENT_POSITIF', 1),
    ('AJUSTEMENT_NEGATIF', -1);

INSERT INTO t_type_mouvement_journal (nom_type_mouvement, sens) VALUES
    ('ENTREE', 1),
    ('SORTIE', -1);

INSERT INTO t_type_conditionnement (nom_conditionnement) VALUES
    ('PACK'),
    ('CARTON');

INSERT INTO t_type_produit (nom_type) VALUES
    ('ALIMENTAIRE'),
    ('BOISSON'),
    ('HYGIENE');
