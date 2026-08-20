-- Exemple de journal/session d'entree.
-- Ce script peut etre execute plusieurs fois sans dupliquer la reference.

USE stock_habibo;

START TRANSACTION;

-- Donnees de reference indispensables.
INSERT IGNORE INTO t_societe (nom_societe)
VALUES ('HH');

INSERT IGNORE INTO t_type_mouvement_journal (
    nom_type_mouvement,
    sens
)
VALUES ('ENTREE', 1);

INSERT IGNORE INTO t_statut_journal_mouvement (nom_statut)
VALUES ('EN_ATTENTE');

-- Creation de la session d'entree.
INSERT IGNORE INTO t_journal_mouvement (
    fournisseur_id,
    reference,
    url_piece_jointe,
    nom_client,
    statut_journal_mouvement_id,
    type_mouvement_journal_id
)
SELECT
    societe.id,
    'BR-2026-0001',
    NULL,
    NULL,
    statut.id,
    type_mouvement.id
FROM t_societe AS societe
JOIN t_statut_journal_mouvement AS statut
    ON statut.nom_statut = 'EN_ATTENTE'
JOIN t_type_mouvement_journal AS type_mouvement
    ON type_mouvement.nom_type_mouvement = 'ENTREE'
WHERE societe.nom_societe = 'HH'
  AND NOT EXISTS (
      SELECT 1
      FROM t_journal_mouvement AS journal
      WHERE journal.reference = 'BR-2026-0001'
  )
LIMIT 1;

COMMIT;

-- Verification du journal cree.
SELECT
    journal.id,
    journal.reference,
    societe.nom_societe,
    type_mouvement.nom_type_mouvement,
    statut.nom_statut,
    journal.url_piece_jointe,
    journal.nom_client
FROM t_journal_mouvement AS journal
LEFT JOIN t_societe AS societe
    ON societe.id = journal.fournisseur_id
JOIN t_type_mouvement_journal AS type_mouvement
    ON type_mouvement.id = journal.type_mouvement_journal_id
JOIN t_statut_journal_mouvement AS statut
    ON statut.id = journal.statut_journal_mouvement_id
WHERE journal.reference = 'BR-2026-0001';
