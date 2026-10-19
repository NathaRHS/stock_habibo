-- ============================================================================
-- 02 - STRUCTURE (socle d'exploitation)
-- ============================================================================
-- Prerequis : 01_referentiels.sql charge, backend demarre au moins une fois
-- (tables creees par Hibernate, unites g/kg/mL/cL/L creees par InitialiseurUnites).
--
-- Uniquement des INSERT. Rejouable : chaque insertion est gardee par
-- WHERE NOT EXISTS sur une colonne unique. INSERT IGNORE est volontairement
-- evite : il masquerait une cle etrangere introuvable ou une colonne NOT NULL
-- vide en simple avertissement.
--
-- Regles du code respectees ici :
--   - un seul conditionnement par article : l'affectation lit
--     getArticleConditionnements().get(0) ;
--   - une capacite de palette par conditionnement, sinon l'affectation
--     echoue en erreur 500 ;
--   - le type de conditionnement de l'article = celui de son conditionnement ;
--   - codes-barres EAN-13 valides, prefixe 200/201 (usage interne GS1),
--     distincts entre article et conditionnement ;
--   - emplacements uniques par (rack, etage, nom) et (rack, etage, ordre).
--
-- Comptes (mot de passe commun : password, hash genere par BCryptPasswordEncoder)
--   ADM001  administrateur
--   OPE001  operateur
--   OPE002  operateur
-- ============================================================================

USE stock_habibo;

START TRANSACTION;

-- ----------------------------------------------------------------------------
-- 1. Catalogues metier
-- ----------------------------------------------------------------------------

INSERT INTO t_type_produit (nom_type)
SELECT v.nom FROM (VALUES ROW('BOISSON'), ROW('ALIMENTAIRE')) AS v(nom)
WHERE NOT EXISTS (SELECT 1 FROM t_type_produit t WHERE t.nom_type = v.nom);

INSERT INTO t_type_conditionnement (nom_conditionnement)
SELECT v.nom FROM (VALUES ROW('PACK'), ROW('CARTON')) AS v(nom)
WHERE NOT EXISTS (SELECT 1 FROM t_type_conditionnement t WHERE t.nom_conditionnement = v.nom);

INSERT INTO t_famille (nom)
SELECT v.nom FROM (VALUES
    ROW('Boissons gazeuses'),
    ROW('Produits laitiers'),
    ROW('Jus de fruits'),
    ROW('Eaux'),
    ROW('Confiserie')) AS v(nom)
WHERE NOT EXISTS (SELECT 1 FROM t_famille f WHERE f.nom = v.nom);

-- Fournisseurs : usines du groupe (a renommer selon les vraies usines).
INSERT INTO t_societe (nom_societe)
SELECT v.nom FROM (VALUES
    ROW('Habibo Usine Boissons'),
    ROW('Habibo Usine Alimentaire')) AS v(nom)
WHERE NOT EXISTS (SELECT 1 FROM t_societe s WHERE s.nom_societe = v.nom);

-- ----------------------------------------------------------------------------
-- 2. Utilisateurs
-- ----------------------------------------------------------------------------

INSERT INTO t_user (username, matricule, email, password_hash, role_id)
SELECT v.username, v.matricule, v.email,
       '$2a$10$Ch5wMabqyf434jwWAgyhj.HIPZ.ou7sDalIlZqjDYNRi95cJC9mZ.',
       r.id
FROM (VALUES
    ROW('admin',      'ADM001', 'admin@habibo.test',      'ADMIN'),
    ROW('operateur1', 'OPE001', 'operateur1@habibo.test', 'OPERATEUR'),
    ROW('operateur2', 'OPE002', 'operateur2@habibo.test', 'OPERATEUR')
) AS v(username, matricule, email, role)
JOIN t_roles r ON r.nom_role = v.role
WHERE NOT EXISTS (
    SELECT 1 FROM t_user u
    WHERE u.matricule = v.matricule OR u.username = v.username OR u.email = v.email);

-- ----------------------------------------------------------------------------
-- 3. Entrepot : 2 racks de 3 niveaux x 6 emplacements
--    Niveau 1 : X-01..X-06, niveau 2 : X-07..X-12, niveau 3 : X-13..X-18
-- ----------------------------------------------------------------------------

INSERT INTO t_rack (nom_rack, nombre_etages, ordre)
SELECT v.nom, 3, v.ordre FROM (VALUES ROW('Rack A', 1), ROW('Rack B', 2)) AS v(nom, ordre)
WHERE NOT EXISTS (SELECT 1 FROM t_rack r WHERE r.nom_rack = v.nom);

INSERT INTO t_emplacement (nom_emplacement, rack_id, numero_etage, ordre_dans_etage)
SELECT
    CONCAT(SUBSTRING(r.nom_rack, 6, 1), '-', LPAD((e.etage - 1) * 6 + o.ordre, 2, '0')),
    r.id,
    e.etage,
    o.ordre
FROM t_rack r
CROSS JOIN (VALUES ROW(1), ROW(2), ROW(3)) AS e(etage)
CROSS JOIN (VALUES ROW(1), ROW(2), ROW(3), ROW(4), ROW(5), ROW(6)) AS o(ordre)
WHERE r.nom_rack IN ('Rack A', 'Rack B')
  AND NOT EXISTS (
      SELECT 1 FROM t_emplacement x
      WHERE x.rack_id = r.id AND x.numero_etage = e.etage AND x.ordre_dans_etage = o.ordre);

-- ----------------------------------------------------------------------------
-- 4. Articles, conditionnements, capacites de palette
--    capacite = nombre de conditionnements qu'un emplacement peut recevoir
-- ----------------------------------------------------------------------------

INSERT INTO t_article (
    nom_article, code_bar, type_produit_id, type_conditionnement_id,
    famille_id, contenance_valeur, unite_id)
SELECT v.nom, v.code, tp.id, tc.id, f.id, v.contenance, u.id
FROM (VALUES
    ROW('Coca-Cola 30 cl', '2000000000015', 'BOISSON',     'PACK',   'Boissons gazeuses', 30.000,  'cL'),
    ROW('Lait Candia 1 L', '2000000000022', 'ALIMENTAIRE', 'CARTON', 'Produits laitiers', 1.000,   'L'),
    ROW('Jus Tiko 1 L',    '2000000000039', 'BOISSON',     'CARTON', 'Jus de fruits',     1.000,   'L'),
    ROW('Eau Vive 1,5 L',  '2000000000046', 'BOISSON',     'PACK',   'Eaux',              1.500,   'L'),
    ROW('Bonbon JB 500 g', '2000000000053', 'ALIMENTAIRE', 'CARTON', 'Confiserie',        500.000, 'g')
) AS v(nom, code, type_produit, type_cond, famille, contenance, unite)
JOIN t_type_produit tp         ON tp.nom_type = v.type_produit
JOIN t_type_conditionnement tc ON tc.nom_conditionnement = v.type_cond
JOIN t_famille f               ON f.nom = v.famille
JOIN t_unite u                 ON u.nom_unite = v.unite
WHERE NOT EXISTS (SELECT 1 FROM t_article a WHERE a.code_bar = v.code);

-- Un conditionnement par article, du meme type que l'article.
INSERT INTO t_article_conditionnement (
    article_id, type_conditionnement_id, code_barres, quantite_piece_standard)
SELECT a.id, a.type_conditionnement_id, v.code_cond, v.pieces
FROM (VALUES
    ROW('2000000000015', '2010000000014', 6),
    ROW('2000000000022', '2010000000021', 12),
    ROW('2000000000039', '2010000000038', 12),
    ROW('2000000000046', '2010000000045', 6),
    ROW('2000000000053', '2010000000052', 24)
) AS v(code_article, code_cond, pieces)
JOIN t_article a ON a.code_bar = v.code_article
WHERE NOT EXISTS (
    SELECT 1 FROM t_article_conditionnement c WHERE c.code_barres = v.code_cond);

INSERT INTO t_palette_conditionnement (article_conditionnement_id, quantite)
SELECT c.id, v.capacite
FROM (VALUES
    ROW('2010000000014', 100),
    ROW('2010000000021', 60),
    ROW('2010000000038', 60),
    ROW('2010000000045', 80),
    ROW('2010000000052', 50)
) AS v(code_cond, capacite)
JOIN t_article_conditionnement c ON c.code_barres = v.code_cond
WHERE NOT EXISTS (
    SELECT 1 FROM t_palette_conditionnement p WHERE p.article_conditionnement_id = c.id);

COMMIT;

-- ----------------------------------------------------------------------------
-- Controles : chaque requete doit renvoyer le nombre indique
-- ----------------------------------------------------------------------------
SELECT 'utilisateurs (3)' AS controle, COUNT(*) AS resultat
FROM t_user WHERE matricule IN ('ADM001', 'OPE001', 'OPE002')
UNION ALL
SELECT 'emplacements (36)', COUNT(*)
FROM t_emplacement e JOIN t_rack r ON r.id = e.rack_id
WHERE r.nom_rack IN ('Rack A', 'Rack B')
UNION ALL
SELECT 'articles complets (5)', COUNT(*)
FROM t_article a
JOIN t_article_conditionnement c ON c.article_id = a.id
JOIN t_palette_conditionnement p ON p.article_conditionnement_id = c.id
WHERE a.code_bar LIKE '200%'
UNION ALL
-- Doit valoir 0 : un article ne doit avoir qu'un conditionnement.
SELECT 'articles a plusieurs conditionnements (0)', COUNT(*)
FROM (SELECT article_id FROM t_article_conditionnement
      GROUP BY article_id HAVING COUNT(*) > 1) x;
