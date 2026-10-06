-- Jeu de donnees operationnelles coherent pour tester les notifications.
-- A executer apres reset_donnees_operationnelles.sql et apres le demarrage
-- du backend afin que t_notification ait ete creee par Hibernate.

START TRANSACTION;

SET @admin_id = (
    SELECT id FROM t_user
    WHERE matricule IN ('ADM-001', 'ADM001')
    ORDER BY id LIMIT 1
);
SET @entree_type_id = (
    SELECT id FROM t_type_mouvement_journal
    WHERE nom_type_mouvement = 'ENTREE' LIMIT 1
);
SET @sortie_type_id = (
    SELECT id FROM t_type_mouvement_journal
    WHERE nom_type_mouvement = 'SORTIE' LIMIT 1
);
SET @inventaire_type_id = (
    SELECT id FROM t_type_mouvement_journal
    WHERE nom_type_mouvement = 'INVENTAIRE' LIMIT 1
);
SET @valide_statut_id = (
    SELECT id FROM t_statut
    WHERE nom = 'VALIDE' LIMIT 1
);
SET @cours_statut_id = (
    SELECT id FROM t_statut
    WHERE nom = 'EN COURS' LIMIT 1
);
SET @attente_statut_id = (
    SELECT id FROM t_statut
    WHERE nom = 'EN ATTENTE' LIMIT 1
);

-- 1. Entree validee : l'admin doit encore affecter les articles.
INSERT INTO t_journal_mouvement (
    nom_client, reference, url_piece_jointe, fournisseur_id,
    type_mouvement_journal_id, statut_id
)
VALUES (
    NULL, 'REC-NOTIF-001', '/documents/rec-notif-001.pdf', NULL,
    @entree_type_id, @valide_statut_id
);

INSERT INTO t_detail_journal (
    journal_mouvement_id, article_id, quantite,
    quantite_conditionnement, dlc, dlv
)
VALUES (
    (SELECT id FROM t_journal_mouvement WHERE reference = 'REC-NOTIF-001'),
    (SELECT id FROM t_article WHERE code_bar = '60001548856446'),
    120, 20, '2026-12-15', '2026-12-05'
);

-- 2. Sortie en cours : l'operateur a termine, l'admin doit confirmer.
INSERT INTO t_journal_mouvement (
    nom_client, reference, url_piece_jointe, fournisseur_id,
    type_mouvement_journal_id, statut_id
)
VALUES (
    'CLIENT TEST', 'SOR-NOTIF-001', NULL, NULL,
    @sortie_type_id, @cours_statut_id
);

INSERT INTO t_detail_journal (
    journal_mouvement_id, article_id, quantite,
    quantite_conditionnement, dlc, dlv
)
VALUES (
    (SELECT id FROM t_journal_mouvement WHERE reference = 'SOR-NOTIF-001'),
    (SELECT id FROM t_article WHERE code_bar = '6200000000018'),
    60, 5, '2027-01-31', '2027-01-20'
);

INSERT INTO t_commande (
    etat, isChecked, quantite_demande, quantite_reel,
    remarque, article_id, journal_mouvement_id, user_id
)
VALUES (
    0, 1, 5, NULL, 'Commande de test pour confirmation de sortie',
    (SELECT id FROM t_article WHERE code_bar = '6200000000018'),
    (SELECT id FROM t_journal_mouvement WHERE reference = 'SOR-NOTIF-001'),
    NULL
);

-- 3. Inventaire en attente de traitement.
INSERT INTO t_journal_mouvement (
    nom_client, reference, url_piece_jointe, fournisseur_id,
    type_mouvement_journal_id, statut_id
)
VALUES (
    NULL, 'INV-NOTIF-001', NULL, NULL,
    @inventaire_type_id, @attente_statut_id
);

INSERT INTO t_detail_journal (
    journal_mouvement_id, article_id, quantite,
    quantite_conditionnement, dlc, dlv
)
VALUES (
    (SELECT id FROM t_journal_mouvement WHERE reference = 'INV-NOTIF-001'),
    (SELECT id FROM t_article WHERE code_bar = '6223000011111'),
    240, NULL, NULL, NULL
);

-- Notifications visibles immédiatement dans le composant React.
INSERT INTO t_notification (
    categorie, type, priorite, titre, message,
    date_creation, date_lecture, date_traitement, url_cible,
    lu, traitee, destinataire_id, journal_id, detail_journal_id, emplacement_id
)
VALUES
(
    'ENTREE', 'ENTREE_A_AFFECTER', 'ATTENTION',
    'Affectation d''entree requise',
    'Le journal REC-NOTIF-001 attend une affectation.',
    NOW(), NULL, NULL,
    CONCAT('/journaux-mouvements/',
        (SELECT id FROM t_journal_mouvement WHERE reference = 'REC-NOTIF-001'),
        '/affectation-stock'),
    FALSE, FALSE, @admin_id,
    (SELECT id FROM t_journal_mouvement WHERE reference = 'REC-NOTIF-001'),
    (SELECT id FROM t_detail_journal WHERE journal_mouvement_id =
        (SELECT id FROM t_journal_mouvement WHERE reference = 'REC-NOTIF-001') LIMIT 1),
    NULL
),
(
    'SORTIE', 'SORTIE_A_CONFIRMER', 'URGENTE',
    'Sortie a confirmer',
    'La sortie SOR-NOTIF-001 attend votre confirmation.',
    DATE_SUB(NOW(), INTERVAL 18 MINUTE), NULL, NULL,
    CONCAT('/sortie/',
        (SELECT id FROM t_journal_mouvement WHERE reference = 'SOR-NOTIF-001')),
    FALSE, FALSE, @admin_id,
    (SELECT id FROM t_journal_mouvement WHERE reference = 'SOR-NOTIF-001'),
    (SELECT id FROM t_detail_journal WHERE journal_mouvement_id =
        (SELECT id FROM t_journal_mouvement WHERE reference = 'SOR-NOTIF-001') LIMIT 1),
    NULL
),
(
    'INVENTAIRE', 'INVENTAIRE_A_REALISER', 'INFORMATION',
    'Inventaire a realiser',
    'L''inventaire INV-NOTIF-001 attend votre intervention.',
    DATE_SUB(NOW(), INTERVAL 2 HOUR), NULL, NULL,
    CONCAT('/inventaires/',
        (SELECT id FROM t_journal_mouvement WHERE reference = 'INV-NOTIF-001')),
    TRUE, FALSE, @admin_id,
    (SELECT id FROM t_journal_mouvement WHERE reference = 'INV-NOTIF-001'),
    (SELECT id FROM t_detail_journal WHERE journal_mouvement_id =
        (SELECT id FROM t_journal_mouvement WHERE reference = 'INV-NOTIF-001') LIMIT 1),
    NULL
);

COMMIT;

SELECT id, categorie, type, priorite, titre, lu, traitee,
       destinataire_id, journal_id, detail_journal_id
FROM t_notification
ORDER BY date_creation DESC;
