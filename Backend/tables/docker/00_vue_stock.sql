-- ============================================================================
-- 00 - VUE DE STOCK
-- ============================================================================
-- Seul CREATE du lot : Hibernate cree les tables mais jamais les vues, alors
-- que le code lit v_stock_par_emplacement (StockRepository, EmplacementRepository).
-- A charger apres le premier demarrage du backend (les tables doivent exister).
-- Rejouable : CREATE OR REPLACE.
--
-- Le stock n'est stocke nulle part : il est la somme des mouvements
-- (pieces x sens du type de mouvement), par article et par emplacement.
--
-- Les trois clauses suivantes sont indispensables :
--   en_reserve = FALSE ........ la reserve n'est pas du stock physique ;
--   emplacement_id IS NOT NULL  sinon GET /stocks/emplacements renvoie une
--                               ligne sans emplacement et l'ecran d'inventaire
--                               mobile plante (emplacementId lu comme num) ;
--   HAVING ... <> 0 ........... un emplacement vide n'est plus liste.
--
-- Pas de DEFINER explicite : la vue appartient a l'utilisateur qui execute
-- le script, ce qui evite toute dependance a un compte MySQL precis.
-- ============================================================================

USE stock_habibo;

CREATE OR REPLACE VIEW v_stock_par_emplacement AS
SELECT
    conditionnement.article_id,
    mouvement.emplacement_id,
    SUM(mouvement.quantite_pieces_reelle * type_mouvement.sens) AS quantite_stock
FROM t_mouvement_stock mouvement
JOIN t_article_conditionnement conditionnement
    ON conditionnement.id = mouvement.conditionnement_id
JOIN t_type_mouvement type_mouvement
    ON type_mouvement.id = mouvement.type_mouvement_id
WHERE mouvement.en_reserve = FALSE
  AND mouvement.emplacement_id IS NOT NULL
GROUP BY conditionnement.article_id, mouvement.emplacement_id
HAVING SUM(mouvement.quantite_pieces_reelle * type_mouvement.sens) <> 0;

-- Controle : la vue doit exister
SELECT TABLE_NAME AS vue_creee
FROM information_schema.VIEWS
WHERE TABLE_SCHEMA = 'stock_habibo' AND TABLE_NAME = 'v_stock_par_emplacement';
