-- Active: 1786994780822@@127.0.0.1@3307@stock_habibo
-- Statuts du cycle de vie d'une session de mouvement.
-- Ce script peut etre execute plusieurs fois sans creer de doublons.

USE stock_habibo;

START TRANSACTION;

INSERT IGNORE INTO t_statut (nom)
VALUES
    ('EN COURS'),
    ('EN ATTENTE'),
    ('VALIDE'),
    ('MODIFIE');

COMMIT;

SELECT id, nom
FROM t_statut
ORDER BY id;
