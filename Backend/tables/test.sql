----------------------------+
 select * from  t_article;                  
 select * from  t_article_conditionnement;  
 select * from  t_detail_journal;           
 select * from  t_emplacement;              
 select * from  t_etage;                    
 select * from  t_journal_mouvement;        
 select * from  t_mouvement_stock;          
 select * from  t_rack;                     
 select * from  t_roles;                    
 select * from  t_societe;                  
 select * from  t_statut_journal_mouvement; 
 select * from  t_type_conditionnement;     
 select * from  t_type_mouvement;           
 select * from  t_type_mouvement_journal;   
 select * from  t_type_produit;             
 select * from  t_user;                     
 select * from  v_stock_par_etage;          
 select * from  v_stock_total_article;      
 select * from  v_structure_entrepot;    






 START TRANSACTION;

-- 1. Tables de référence

INSERT INTO t_roles (id, nom_role) VALUES
(1, 'ADMIN'),
(2, 'INVENTORY-RESPONSABLE'),
(3, 'AUDITEUR');

INSERT INTO t_statut_journal_mouvement (id, nom_statut) VALUES
(1, 'EN COURS'),
(2, 'VALIDE'),
(3, 'MODIFIE')

INSERT INTO t_type_mouvement (id, nom_type_mouvement, sens) VALUES
(1, 'ENTREE', 1),
(2, 'SORTIE', -1),
(3, 'AJUSTEMENT_POSITIF', 1),
(4, 'AJUSTEMENT_NEGATIF', -1);

INSERT INTO t_type_mouvement_journal
(id, nom_type_mouvement, sens) VALUES
(1, 'ENTREE', 1),
(2, 'SORTIE', -1);

INSERT INTO t_type_conditionnement
(id, nom_conditionnement) VALUES
(1, 'PIECE'),
(2, 'CARTON'),
(3, 'PALETTE');

INSERT INTO t_type_produit (id, nom_type) VALUES
(1, 'ALIMENTAIRE'),
(2, 'BOISSON'),
(3, 'HYGIENE');


-- 2. Sociétés/fournisseurs

INSERT INTO t_societe (id, nom_societe) VALUES
(1, 'HH'),
(2, 'HM'),
(3, 'HB');

-- 3. Articles

INSERT INTO t_article
( code_bar, nom_article, type_conditionnement_id, type_produit_id)
VALUES
( '6111000000010', 'Coca 1.5 L', 1, 2),
( '6111000000027', 'Candy +', 1, 2),
( '6111000000034', 'Macaroni 5 kg', 1, 1),
( '6111000000041', 'Savon', 1, 3);
-- 4. Conditionnements possibles des articles

INSERT INTO t_article_conditionnement
(id, article_id, type_conditionnement_id, code_barres, quantite_piece_standard)
VALUES
(1, 1, 1, '6111000000010', 1),
(2, 1, 2, '6111000001017', 12),
(3, 2, 1, '6111000000027', 1),
(4, 2, 2, '6111000001024', 6),
(5, 3, 4, '6111000000034', 1),
(6, 2, 2, '6111000001048', 24),
(7, 1, 2, '6111000001055', 10);

-- 5. Structure de l’entrepôt

INSERT INTO t_rack (id, nom_rack) VALUES
(1, 'RACK-A'),
(2, 'RACK-B'),
(3, 'RACK-C');

INSERT INTO t_emplacement (id, nom_emplacement, rack_id) VALUES
(1, 'ZONE-A1', 1),
(2, 'ZONE-A2', 1),
(3, 'ZONE-B1', 2),
(4, 'ZONE-C1', 3);

INSERT INTO t_etage (id, nom_etage, emplacement_id) VALUES
(1, 'ETAGE-A1-01', 1),
(2, 'ETAGE-A1-02', 1),
(3, 'ETAGE-A2-01', 2),
(4, 'ETAGE-B1-01', 3),
(5, 'ETAGE-C1-01', 4);

-- 6. Utilisateur de test

-- Le hash ci-dessous est un hash BCrypt.
-- Tu peux le remplacer par un hash généré par ton application.

INSERT INTO t_user
(id, email, matricule, password_hash, username, role_id)
VALUES
(
    1,
    'admin@habibo.com',
    'ADM-001',
    '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
    'admin',
    1
);

-- 7. Journaux de mouvement

INSERT INTO t_journal_mouvement
(
    id,
    nom_client,
    reference,
    url_piece_jointe,
    fournisseur_id,
    type_mouvement_journal_id,
    statut_journal_mouvement_id
)
VALUES
(
    1,
    NULL,
    'ENT-2026-0001',
    '/pieces/bon-livraison-001.pdf',
    1,
    2,
    1
),
(
    2,
    NULL,
    'ENT-2026-0002',
    '/pieces/bon-livraison-002.pdf',
    2,
    1,
    2
);

-- 8. Détails des journaux

INSERT INTO t_detail_journal
(id, quantite, article_id, journal_mouvement_id)
VALUES
(1, 120, 1, 1),
(2, 60, 2, 1),
(3, 40, 3, 2),
(4, 12, 1, 3),
(6, 25, 4, 4);

-- 9. Mouvements de stock

UPDATE t_article set id = 1 where id = 2; 
UPDATE t_article set id = 2 where id = 3; 
UPDATE t_article set id = 3 where id = 4; 
UPDATE t_article set id = 4 where id = 5; 


INSERT INTO t_mouvement_stock
(
    id,
    conditionnement_id,
    commentaire,
    date_mouvement,
    nombre_conditionnements,
    quantite_pieces_reelle,
    etage_id,
    type_mouvement_id,
    user_id
)
VALUES
(
    1,
    2,
    'Réception de 10 cartons d''eau',
    NOW(),
    10,
    120,
    1,
    1,
    1
),
(
    2,
    4,
    'Réception de 10 cartons de jus',
    NOW(),
    10,
    60,
    2,
    1,
    1
),
(
    3,
    2,
    'Sortie d''un carton d''eau',
    NOW(),
    1,
    12,
    1,
    2,
    1
),
(
    3,
    7,
    'Sortie d''un carton de claviers',
    NOW(),
    1,
    10,
    5,
    2,
    1
);

COMMIT;


SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE t_detail_journal;
TRUNCATE TABLE t_mouvement_stock;
TRUNCATE TABLE t_article_conditionnement;
TRUNCATE TABLE t_journal_mouvement;
TRUNCATE TABLE t_article;
TRUNCATE TABLE t_etage;
TRUNCATE TABLE t_emplacement;
TRUNCATE TABLE t_rack;
TRUNCATE TABLE t_user;
TRUNCATE TABLE t_societe;
TRUNCATE TABLE t_statut_journal_mouvement;
TRUNCATE TABLE t_type_mouvement_journal;
TRUNCATE TABLE t_type_mouvement;
TRUNCATE TABLE t_type_conditionnement;
TRUNCATE TABLE t_type_produit;
TRUNCATE TABLE t_roles;

SET FOREIGN_KEY_CHECKS = 1;


INSERT INTO t_mouvement_stock
    -> (
    ->     conditionnement_id,
    ->     commentaire,
    ->     date_mouvement,
    ->     nombre_conditionnements,
    ->     quantite_pieces_reelle,
    ->     etage_id,
    ->     type_mouvement_id,
    ->     user_id
    -> )
    -> SELECT
    ->     6,
    ->     'Réception de 10 cartons',
    ->     NOW(),
    ->     10,
    ->     120,
    ->     e.id,
    ->     tm.id,
    ->     u.id
    -> FROM t_etage e
    -> CROSS JOIN t_type_mouvement tm
    -> CROSS JOIN t_user u
    -> WHERE tm.nom_type_mouvement = 'ENTREE'
    ->   AND u.matricule = 'ADM-001'
    -> ORDER BY e.id
    -> LIMIT 1;