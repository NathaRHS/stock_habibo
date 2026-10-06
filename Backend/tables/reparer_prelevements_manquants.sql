-- Repare un journal de sortie dont des lignes de picking sont PRELEVEE
-- alors qu'aucun prelevement n'existe dans t_prelevement.
--
-- Cause : l'INSERT de simulation_mois_operations.sql utilisait la colonne
-- quantite_pieces_prelevee, qui n'existe pas (la vraie colonne est
-- quantitePiecesPrelevee). Les lignes ont ete creees, pas les prelevements.
--
-- Rejouable : une ligne qui a deja un prelevement est ignoree.
-- Changer @journal_id pour reparer un autre journal.

USE stock_habibo;

SET @journal_id = 5;

-- ---------------------------------------------------------------------
-- 1. A LIRE AVANT DE CONTINUER : mouvements de SORTIE deja enregistres
-- ---------------------------------------------------------------------
-- Si ce nombre est superieur a 0, la sortie de ce journal a deja touche le
-- stock : ne PAS valider la sortie apres la reparation (double sortie).
SELECT COUNT(*) AS mouvements_sortie_deja_presents
FROM t_mouvement_stock mouvement
JOIN t_type_mouvement type_mouvement ON type_mouvement.id = mouvement.type_mouvement_id
JOIN t_ligne_picking ligne ON ligne.detail_journal_source_id = mouvement.detail_journal_id
JOIN t_picking picking ON picking.id = ligne.picking_id
WHERE picking.journal_mouvement_id = @journal_id
  AND type_mouvement.nom_type_mouvement = 'SORTIE';

-- ---------------------------------------------------------------------
-- 2. Creation des prelevements manquants (un par ligne PRELEVEE)
-- ---------------------------------------------------------------------
SET @statut_confirme = (
    SELECT id FROM t_statut_prelevement WHERE nom_statut = 'CONFIRME' LIMIT 1
);

INSERT INTO t_prelevement
    (commande_id, ligne_picking_id, emplacement_id, statut_prelevement_id,
     quantitePiecesPrelevee, user_id, date_prelevement, dlc, dlv)
SELECT ligne.commande_id,
       ligne.id,
       ligne.emplacement_id,
       @statut_confirme,
       ligne.quantite_pieces_a_prelever,
       picking.user_id,
       COALESCE(picking.date_fin, ligne.date_reservation),
       detail.dlc,
       detail.dlv
FROM t_ligne_picking ligne
JOIN t_statut_ligne_picking statut ON statut.id = ligne.statut_id
JOIN t_picking picking ON picking.id = ligne.picking_id
JOIN t_detail_journal detail ON detail.id = ligne.detail_journal_source_id
WHERE picking.journal_mouvement_id = @journal_id
  AND statut.nom = 'PRELEVEE'
  AND NOT EXISTS (
      SELECT 1 FROM t_prelevement existant WHERE existant.ligne_picking_id = ligne.id
  );

-- ---------------------------------------------------------------------
-- 3. Verification : chaque ligne PRELEVEE doit avoir 1 prelevement
-- ---------------------------------------------------------------------
SELECT ligne.id AS ligne, statut.nom AS statut_ligne,
       ligne.quantite_pieces_a_prelever AS pieces_prevues,
       COUNT(prelevement.id) AS nb_prelevements,
       SUM(prelevement.quantitePiecesPrelevee) AS pieces_prelevees
FROM t_ligne_picking ligne
JOIN t_statut_ligne_picking statut ON statut.id = ligne.statut_id
JOIN t_picking picking ON picking.id = ligne.picking_id
LEFT JOIN t_prelevement prelevement ON prelevement.ligne_picking_id = ligne.id
WHERE picking.journal_mouvement_id = @journal_id
GROUP BY ligne.id, statut.nom, ligne.quantite_pieces_a_prelever
ORDER BY ligne.id;
