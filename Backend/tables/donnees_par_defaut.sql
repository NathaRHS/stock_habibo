-- Active: 1771244146063@@127.0.0.1@3306
-- Donnees initiales pour l'environnement de developpement.
-- Ce script peut etre execute plusieurs fois sans creer de doublons.

USE stock_habibo;

START TRANSACTION;

-- Roles utilises par Spring Security.
INSERT IGNORE INTO t_roles (nom_role) VALUES
    ('ADMIN'),
    ('SUPERVISEUR'),
    ('RESPONSABLE_INVENTAIRE');

-- Conditionnements disponibles par defaut.
INSERT IGNORE INTO t_type_conditionnement (nom_conditionnement) VALUES
    ('PIECE'),
    ('PACK'),
    ('CARTON');

-- Le sens 1 augmente le stock et le sens -1 le diminue.
INSERT IGNORE INTO t_type_mouvement (nom_type_mouvement, sens) VALUES
    ('ENTREE', 1),
    ('SORTIE', -1);

-- Exemples de types de produit utiles pour les premiers tests.
INSERT IGNORE INTO t_type_produit (nom_type) VALUES
    ('ALIMENTAIRE'),
    ('BOISSON'),
    ('ENTRETIEN');

-- Administrateur initial de developpement.
-- Matricule : ADM001
-- Mot de passe : password
-- Le mot de passe est stocke sous forme de hash BCrypt et doit etre change.
INSERT INTO t_user (
    username,
    matricule,
    email,
    password_hash,
    role_id
)
SELECT
    'admin',
    'ADM001',
    'admin@example.com',
    '$2a$10$ji4.ARxiXTyclInFJFEJCu5s/EG8tu8undoP7PnZh/TXaKFhy9aOK',
    r.id
FROM t_roles r
WHERE r.nom_role = 'ADMIN'
  AND NOT EXISTS (
      SELECT 1
      FROM t_user u
      WHERE u.matricule = 'ADM001'
         OR u.username = 'admin'
         OR u.email = 'admin@example.com'
  );

COMMIT;

-- Verification rapide apres execution.
SELECT id, nom_role FROM t_roles ORDER BY id;
SELECT id, nom_conditionnement FROM t_type_conditionnement ORDER BY id;
SELECT id, nom_type_mouvement, sens FROM t_type_mouvement ORDER BY id;
SELECT id, username, matricule, email, role_id FROM t_user ORDER BY id;
