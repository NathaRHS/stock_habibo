-- Active: 1786994780822@@127.0.0.1@3307@stock_habibo
-- Statuts du cycle de vie d'une session de mouvement.
-- Ce script peut etre execute plusieurs fois sans creer de doublons.

USE stock_habibo;

START TRANSACTION;

INSERT IGNORE INTO t_statut_journal_mouvement (nom_statut)
VALUES
    ('EN_ATTENTE'),
    ('EN_COURS'),
    ('A_VALIDER'),
    ('VALIDEE'),
    ('CLOTUREE');

COMMIT;

SELECT id, nom_statut
FROM t_statut_journal_mouvement
ORDER BY id;
