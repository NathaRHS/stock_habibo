-- ============================================================================
-- 03 - SIMULATION DES MOUVEMENTS (receptions)
-- ============================================================================
-- Prerequis : 01_referentiels.sql et 02_structure.sql charges.
-- Pour rejouer : executer d'abord 99_nettoyage_simulation.sql. Sinon le premier
-- INSERT echoue sur la reference unique et rien n'est ecrit.
--
-- Chaque journal reproduit ce que l'application ecrit reellement, etape par
-- etape, dans toutes les tables liees :
--
--   creation (ADMIN)          t_journal_mouvement (EN COURS)
--                             + historique EN COURS (JournalStatutService.enregistrerStatutInitial)
--                             + t_journal_user JOURNAL_CREE "<ref> (ENTREE)"
--   1er scan d'un operateur   t_user_journal_mouvement EN_COURS
--                             + t_journal_user PARTICIPATION_DEBUTEE "<ref>"
--   scans                     t_detail_journal (cumul pieces + conditionnements)
--   fin d'un operateur        participation TERMINE + date_fin
--                             + t_journal_user PARTICIPATION_TERMINEE "<ref>"
--   dernier operateur fini    statut EN ATTENTE + historique (auteur = cet operateur)
--                             + t_notification ENTREE_A_AFFECTER pour chaque ADMIN
--   validation (ADMIN)        statut VALIDE + historique + t_journal_user JOURNAL_VALIDE
--   affectation (ADMIN)       t_mouvement_stock (ENTREE) + statut AFFECTEE + historique
--                             + t_journal_user ENTREE_STOCK_VALIDEE
--
-- Regles respectees (MouvementStockService, JournalMouvementService) :
--   - dlv <= dlc ;
--   - boite incomplete : pieces dans ]n*standard - standard ; n*standard] ;
--   - somme des conditionnements affectes = detail.quantite_conditionnement ;
--   - somme des pieces des mouvements = detail.quantite, chaque mouvement
--     prenant min(pieces restantes, n * standard) ;
--   - un seul article par emplacement, capacite de palette jamais depassee.
--
-- Scenarios
--   SIM-REC-001  AFFECTEE    stock initial Rack A (Coca-Cola, Eau Vive)
--   SIM-REC-002  AFFECTEE    deux operateurs, boite incomplete (Bonbon JB)
--   SIM-REC-003  VALIDE      attend l'affectation (Coca-Cola : A-01 deja a 75/100)
--   SIM-REC-004  EN ATTENTE  attend le controle de l'administrateur
--   SIM-REC-005  EN COURS    reception ouverte, a scanner sur le mobile
--
-- Pieces jointes attendues dans Backend/uploads/ : SIM-REC-00X_bon-reception.pdf
-- ============================================================================

USE stock_habibo;

-- ----------------------------------------------------------------------------
-- 0. Identifiants lus dans la base (aucun id ecrit en dur)
-- ----------------------------------------------------------------------------

SET @adm  = (SELECT id FROM t_user WHERE matricule = 'ADM001');
SET @ope1 = (SELECT id FROM t_user WHERE matricule = 'OPE001');
SET @ope2 = (SELECT id FROM t_user WHERE matricule = 'OPE002');

SET @type_entree = (SELECT id FROM t_type_mouvement_journal WHERE nom_type_mouvement = 'ENTREE');
SET @mvt_entree  = (SELECT id FROM t_type_mouvement WHERE nom_type_mouvement = 'ENTREE');

SET @st_en_cours   = (SELECT id FROM t_statut_journal_mouvement WHERE nom = 'EN COURS');
SET @st_en_attente = (SELECT id FROM t_statut_journal_mouvement WHERE nom = 'EN ATTENTE');
SET @st_valide     = (SELECT id FROM t_statut_journal_mouvement WHERE nom = 'VALIDE');
SET @st_affectee   = (SELECT id FROM t_statut_journal_mouvement WHERE nom = 'AFFECTEE');

SET @f_boissons = (SELECT id FROM t_societe WHERE nom_societe = 'Habibo Usine Boissons');
SET @f_alim     = (SELECT id FROM t_societe WHERE nom_societe = 'Habibo Usine Alimentaire');

SET @coca   = (SELECT id FROM t_article WHERE code_bar = '2000000000015');
SET @candia = (SELECT id FROM t_article WHERE code_bar = '2000000000022');
SET @tiko   = (SELECT id FROM t_article WHERE code_bar = '2000000000039');
SET @eau    = (SELECT id FROM t_article WHERE code_bar = '2000000000046');
SET @bonbon = (SELECT id FROM t_article WHERE code_bar = '2000000000053');

SET @c_coca   = (SELECT id FROM t_article_conditionnement WHERE code_barres = '2010000000014');
SET @c_candia = (SELECT id FROM t_article_conditionnement WHERE code_barres = '2010000000021');
SET @c_eau    = (SELECT id FROM t_article_conditionnement WHERE code_barres = '2010000000045');
SET @c_bonbon = (SELECT id FROM t_article_conditionnement WHERE code_barres = '2010000000052');

SET @rack_a = (SELECT id FROM t_rack WHERE nom_rack = 'Rack A');
SET @A01 = (SELECT id FROM t_emplacement WHERE rack_id = @rack_a AND nom_emplacement = 'A-01');
SET @A02 = (SELECT id FROM t_emplacement WHERE rack_id = @rack_a AND nom_emplacement = 'A-02');
SET @A03 = (SELECT id FROM t_emplacement WHERE rack_id = @rack_a AND nom_emplacement = 'A-03');
SET @A07 = (SELECT id FROM t_emplacement WHERE rack_id = @rack_a AND nom_emplacement = 'A-07');
SET @A09 = (SELECT id FROM t_emplacement WHERE rack_id = @rack_a AND nom_emplacement = 'A-09');

-- Arret immediat si un prerequis manque : une variable NULL declenche
-- volontairement l'erreur "Subquery returns more than 1 row". Sans ce garde-fou,
-- une colonne facultative (fournisseur_id...) serait inseree a NULL sans bruit.
SELECT IF(
    @adm IS NULL OR @ope1 IS NULL OR @ope2 IS NULL
    OR @type_entree IS NULL OR @mvt_entree IS NULL
    OR @st_en_cours IS NULL OR @st_en_attente IS NULL OR @st_valide IS NULL OR @st_affectee IS NULL
    OR @f_boissons IS NULL OR @f_alim IS NULL
    OR @coca IS NULL OR @candia IS NULL OR @tiko IS NULL OR @eau IS NULL OR @bonbon IS NULL
    OR @c_coca IS NULL OR @c_candia IS NULL OR @c_eau IS NULL OR @c_bonbon IS NULL
    OR @A01 IS NULL OR @A02 IS NULL OR @A03 IS NULL OR @A07 IS NULL OR @A09 IS NULL,
    (SELECT 1 UNION ALL SELECT 2),
    'prerequis OK') AS verification_prerequis;

START TRANSACTION;

-- ----------------------------------------------------------------------------
-- 1. Journaux, dans l'ordre chronologique de creation (l'id suit la date).
--    Le statut ecrit ici est le statut FINAL ; le parcours complet est
--    reconstitue dans l'historique plus bas.
-- ----------------------------------------------------------------------------

INSERT INTO t_journal_mouvement
    (reference, url_piece_jointe, nom_client, fournisseur_id, type_mouvement_journal_id, statut_id)
VALUES
    ('SIM-REC-001', 'SIM-REC-001_bon-reception.pdf', NULL, @f_boissons, @type_entree, @st_affectee),
    ('SIM-REC-002', 'SIM-REC-002_bon-reception.pdf', NULL, @f_alim,     @type_entree, @st_affectee),
    ('SIM-REC-003', 'SIM-REC-003_bon-reception.pdf', NULL, @f_boissons, @type_entree, @st_valide),
    ('SIM-REC-004', 'SIM-REC-004_bon-reception.pdf', NULL, @f_boissons, @type_entree, @st_en_attente),
    ('SIM-REC-005', 'SIM-REC-005_bon-reception.pdf', NULL, @f_alim,     @type_entree, @st_en_cours);

SET @j1 = (SELECT id FROM t_journal_mouvement WHERE reference = 'SIM-REC-001');
SET @j2 = (SELECT id FROM t_journal_mouvement WHERE reference = 'SIM-REC-002');
SET @j3 = (SELECT id FROM t_journal_mouvement WHERE reference = 'SIM-REC-003');
SET @j4 = (SELECT id FROM t_journal_mouvement WHERE reference = 'SIM-REC-004');
SET @j5 = (SELECT id FROM t_journal_mouvement WHERE reference = 'SIM-REC-005');

-- ----------------------------------------------------------------------------
-- 2. Lignes scannees (pieces = quantite, conditionnements = quantite_conditionnement)
-- ----------------------------------------------------------------------------

INSERT INTO t_detail_journal
    (journal_mouvement_id, article_id, quantite, quantite_conditionnement, dlc, dlv)
VALUES
    -- SIM-REC-001 : OPE001
    (@j1, @coca,   720, 120, '2027-04-30', '2027-03-31'),   -- 120 packs x 6
    (@j1, @eau,    480,  80, '2027-09-30', '2027-08-31'),   --  80 packs x 6
    -- SIM-REC-002 : OPE001 (lait), OPE002 (bonbons)
    (@j2, @candia, 600,  50, '2027-01-15', '2026-12-31'),   --  50 cartons x 12
    (@j2, @bonbon, 710,  30, '2027-06-30', '2027-05-31'),   --  30 cartons x 24 = 720, derniere boite a 14
    -- SIM-REC-003 : OPE002
    (@j3, @tiko,   480,  40, '2027-03-31', '2027-02-28'),   --  40 cartons x 12
    (@j3, @coca,   180,  30, '2027-05-31', '2027-04-30'),   --  30 packs x 6
    -- SIM-REC-004 : OPE001 (coca, eau), OPE002 (jus)
    (@j4, @coca,   360,  60, '2027-06-30', '2027-05-31'),   --  60 packs x 6
    (@j4, @eau,    240,  40, '2027-10-31', '2027-09-30'),   --  40 packs x 6
    (@j4, @tiko,   283,  24, '2027-04-30', '2027-03-31'),   --  24 cartons x 12 = 288, derniere boite a 7
    -- SIM-REC-005 : OPE001, scan en cours
    (@j5, @candia, 240,  20, '2027-02-28', '2027-01-31');   --  20 cartons x 12

SET @d1_coca   = (SELECT id FROM t_detail_journal WHERE journal_mouvement_id = @j1 AND article_id = @coca);
SET @d1_eau    = (SELECT id FROM t_detail_journal WHERE journal_mouvement_id = @j1 AND article_id = @eau);
SET @d2_candia = (SELECT id FROM t_detail_journal WHERE journal_mouvement_id = @j2 AND article_id = @candia);
SET @d2_bonbon = (SELECT id FROM t_detail_journal WHERE journal_mouvement_id = @j2 AND article_id = @bonbon);

-- ----------------------------------------------------------------------------
-- 3. Participations des operateurs
--    date_debut = premier scan ; date_fin = clic sur "Terminer"
-- ----------------------------------------------------------------------------

INSERT INTO t_user_journal_mouvement
    (journal_mouvement_id, user_id, statut_participation, date_debut, date_fin)
VALUES
    (@j1, @ope1, 'TERMINE',  '2026-10-05 09:02:00', '2026-10-05 10:18:00'),
    (@j2, @ope1, 'TERMINE',  '2026-10-12 08:30:00', '2026-10-12 09:40:00'),
    (@j2, @ope2, 'TERMINE',  '2026-10-12 08:34:00', '2026-10-12 09:52:00'),
    (@j3, @ope2, 'TERMINE',  '2026-10-16 08:40:00', '2026-10-16 09:25:00'),
    (@j4, @ope1, 'TERMINE',  '2026-10-18 08:10:00', '2026-10-18 09:20:00'),
    (@j4, @ope2, 'TERMINE',  '2026-10-18 08:15:00', '2026-10-18 09:05:00'),
    (@j5, @ope1, 'EN_COURS', '2026-10-19 08:05:00', NULL);

-- ----------------------------------------------------------------------------
-- 4. Historique des statuts. Le passage a EN ATTENTE est attribue au DERNIER
--    operateur qui a termine (UserJournalMouvementService.terminerParticipation).
-- ----------------------------------------------------------------------------

INSERT INTO t_historique_journal_mouvement_statut
    (journal_mouvement_id, statut_id, date_changement, user_id)
VALUES
    (@j1, @st_en_cours,   '2026-10-05 08:15:00', @adm),
    (@j1, @st_en_attente, '2026-10-05 10:18:00', @ope1),
    (@j1, @st_valide,     '2026-10-05 10:41:00', @adm),
    (@j1, @st_affectee,   '2026-10-05 11:32:00', @adm),

    (@j2, @st_en_cours,   '2026-10-12 07:50:00', @adm),
    (@j2, @st_en_attente, '2026-10-12 09:52:00', @ope2),
    (@j2, @st_valide,     '2026-10-12 10:12:00', @adm),
    (@j2, @st_affectee,   '2026-10-12 10:45:00', @adm),

    (@j3, @st_en_cours,   '2026-10-16 08:05:00', @adm),
    (@j3, @st_en_attente, '2026-10-16 09:25:00', @ope2),
    (@j3, @st_valide,     '2026-10-16 09:58:00', @adm),

    (@j4, @st_en_cours,   '2026-10-18 07:45:00', @adm),
    (@j4, @st_en_attente, '2026-10-18 09:20:00', @ope1),

    (@j5, @st_en_cours,   '2026-10-19 07:30:00', @adm);

-- ----------------------------------------------------------------------------
-- 5. Mouvements de stock (affectations de SIM-REC-001 et SIM-REC-002)
--    commentaire et date identiques a ceux de MouvementStockService.
-- ----------------------------------------------------------------------------

INSERT INTO t_mouvement_stock
    (type_mouvement_id, emplacement_id, en_reserve, user_id, nombre_conditionnements,
     conditionnement_id, quantite_pieces_reelle, date_mouvement, commentaire, detail_journal_id)
VALUES
    -- SIM-REC-001 : Coca 120 packs repartis 75 + 45, Eau Vive 80 packs (palette pleine)
    (@mvt_entree, @A01, FALSE, @adm, 75, @c_coca, 450, '2026-10-05 11:32:00',
     'Entree en stock du journal SIM-REC-001', @d1_coca),
    (@mvt_entree, @A02, FALSE, @adm, 45, @c_coca, 270, '2026-10-05 11:32:00',
     'Entree en stock du journal SIM-REC-001', @d1_coca),
    (@mvt_entree, @A03, FALSE, @adm, 80, @c_eau,  480, '2026-10-05 11:32:00',
     'Entree en stock du journal SIM-REC-001', @d1_eau),
    -- SIM-REC-002 : la boite incomplete suit ses 710 pieces reelles
    (@mvt_entree, @A07, FALSE, @adm, 50, @c_candia, 600, '2026-10-12 10:45:00',
     'Entree en stock du journal SIM-REC-002', @d2_candia),
    (@mvt_entree, @A09, FALSE, @adm, 30, @c_bonbon, 710, '2026-10-12 10:45:00',
     'Entree en stock du journal SIM-REC-002', @d2_bonbon);

-- ----------------------------------------------------------------------------
-- 6. Notifications ENTREE_A_AFFECTER, une par administrateur, au passage
--    EN ATTENTE. Titre, message et URL identiques a NotificationService.
-- ----------------------------------------------------------------------------

INSERT INTO t_notification
    (categorie, type, priorite, titre, message, url_cible,
     date_creation, date_lecture, date_traitement, lu, traitee,
     destinataire_id, journal_id, detail_journal_id, emplacement_id)
SELECT 'ENTREE', 'ENTREE_A_AFFECTER', 'ATTENTION',
       'Affectation d''entree requise',
       CONCAT('Le journal ', j.reference, ' attend une validation.'),
       CONCAT('/journaux-mouvements/', j.id),
       v.creation, v.lecture, v.traitement, v.lu, v.traitee,
       admin.id, j.id, NULL, NULL
FROM (VALUES
    -- traitee apres l'affectation
    ROW('SIM-REC-001', '2026-10-05 10:18:00', '2026-10-05 10:31:00', '2026-10-05 11:34:00', TRUE,  TRUE),
    ROW('SIM-REC-002', '2026-10-12 09:52:00', '2026-10-12 10:05:00', '2026-10-12 10:47:00', TRUE,  TRUE),
    -- lue, validee, mais affectation pas encore faite
    ROW('SIM-REC-003', '2026-10-16 09:25:00', '2026-10-16 09:50:00', NULL,                  TRUE,  FALSE),
    -- pas encore ouverte par l'administrateur
    ROW('SIM-REC-004', '2026-10-18 09:20:00', NULL,                  NULL,                  FALSE, FALSE)
) AS v(reference, creation, lecture, traitement, lu, traitee)
JOIN t_journal_mouvement j ON j.reference = v.reference
CROSS JOIN t_user admin
JOIN t_roles r ON r.id = admin.role_id AND r.nom_role = 'ADMIN';

-- ----------------------------------------------------------------------------
-- 7. Journal d'activite (t_journal_user). Details au format exact du code :
--    "<ref> (ENTREE)" pour les decisions, "<ref>" pour les participations.
--    EN COURS et EN ATTENTE n'y figurent pas (JournalStatutService).
-- ----------------------------------------------------------------------------

INSERT INTO t_journal_user
    (user_id, matricule_saisi, type, cible_type, cible_id, details, date_evenement)
VALUES
    (@adm,  NULL, 'JOURNAL_CREE',           'JOURNAL', @j1, 'SIM-REC-001 (ENTREE)', '2026-10-05 08:15:00'),
    (@ope1, NULL, 'PARTICIPATION_DEBUTEE',  'JOURNAL', @j1, 'SIM-REC-001',          '2026-10-05 09:02:00'),
    (@ope1, NULL, 'PARTICIPATION_TERMINEE', 'JOURNAL', @j1, 'SIM-REC-001',          '2026-10-05 10:18:00'),
    (@adm,  NULL, 'JOURNAL_VALIDE',         'JOURNAL', @j1, 'SIM-REC-001 (ENTREE)', '2026-10-05 10:41:00'),
    (@adm,  NULL, 'ENTREE_STOCK_VALIDEE',   'JOURNAL', @j1, 'SIM-REC-001 (ENTREE)', '2026-10-05 11:32:00'),

    (@adm,  NULL, 'JOURNAL_CREE',           'JOURNAL', @j2, 'SIM-REC-002 (ENTREE)', '2026-10-12 07:50:00'),
    (@ope1, NULL, 'PARTICIPATION_DEBUTEE',  'JOURNAL', @j2, 'SIM-REC-002',          '2026-10-12 08:30:00'),
    (@ope2, NULL, 'PARTICIPATION_DEBUTEE',  'JOURNAL', @j2, 'SIM-REC-002',          '2026-10-12 08:34:00'),
    (@ope1, NULL, 'PARTICIPATION_TERMINEE', 'JOURNAL', @j2, 'SIM-REC-002',          '2026-10-12 09:40:00'),
    (@ope2, NULL, 'PARTICIPATION_TERMINEE', 'JOURNAL', @j2, 'SIM-REC-002',          '2026-10-12 09:52:00'),
    (@adm,  NULL, 'JOURNAL_VALIDE',         'JOURNAL', @j2, 'SIM-REC-002 (ENTREE)', '2026-10-12 10:12:00'),
    (@adm,  NULL, 'ENTREE_STOCK_VALIDEE',   'JOURNAL', @j2, 'SIM-REC-002 (ENTREE)', '2026-10-12 10:45:00'),

    (@adm,  NULL, 'JOURNAL_CREE',           'JOURNAL', @j3, 'SIM-REC-003 (ENTREE)', '2026-10-16 08:05:00'),
    (@ope2, NULL, 'PARTICIPATION_DEBUTEE',  'JOURNAL', @j3, 'SIM-REC-003',          '2026-10-16 08:40:00'),
    (@ope2, NULL, 'PARTICIPATION_TERMINEE', 'JOURNAL', @j3, 'SIM-REC-003',          '2026-10-16 09:25:00'),
    (@adm,  NULL, 'JOURNAL_VALIDE',         'JOURNAL', @j3, 'SIM-REC-003 (ENTREE)', '2026-10-16 09:58:00'),

    (@adm,  NULL, 'JOURNAL_CREE',           'JOURNAL', @j4, 'SIM-REC-004 (ENTREE)', '2026-10-18 07:45:00'),
    (@ope1, NULL, 'PARTICIPATION_DEBUTEE',  'JOURNAL', @j4, 'SIM-REC-004',          '2026-10-18 08:10:00'),
    (@ope2, NULL, 'PARTICIPATION_DEBUTEE',  'JOURNAL', @j4, 'SIM-REC-004',          '2026-10-18 08:15:00'),
    (@ope2, NULL, 'PARTICIPATION_TERMINEE', 'JOURNAL', @j4, 'SIM-REC-004',          '2026-10-18 09:05:00'),
    (@ope1, NULL, 'PARTICIPATION_TERMINEE', 'JOURNAL', @j4, 'SIM-REC-004',          '2026-10-18 09:20:00'),

    (@adm,  NULL, 'JOURNAL_CREE',           'JOURNAL', @j5, 'SIM-REC-005 (ENTREE)', '2026-10-19 07:30:00'),
    (@ope1, NULL, 'PARTICIPATION_DEBUTEE',  'JOURNAL', @j5, 'SIM-REC-005',          '2026-10-19 08:05:00');

COMMIT;

-- ============================================================================
-- CONTROLES DE COHERENCE : chaque ligne doit afficher "OK"
-- ============================================================================

SELECT '1. somme des conditionnements affectes = detail' AS controle,
       IF(COUNT(*) = 0, 'OK', CONCAT(COUNT(*), ' ecart(s)')) AS resultat
FROM (SELECT d.id FROM t_detail_journal d
      JOIN t_journal_mouvement j ON j.id = d.journal_mouvement_id
      JOIN t_mouvement_stock m ON m.detail_journal_id = d.id
      WHERE j.reference LIKE 'SIM-%'
      GROUP BY d.id, d.quantite_conditionnement, d.quantite
      HAVING SUM(m.nombre_conditionnements) <> d.quantite_conditionnement
          OR SUM(m.quantite_pieces_reelle) <> d.quantite) x
UNION ALL
SELECT '2. journaux AFFECTEE entierement affectes',
       IF(COUNT(*) = 0, 'OK', CONCAT(COUNT(*), ' detail(s) sans mouvement'))
FROM t_detail_journal d
JOIN t_journal_mouvement j ON j.id = d.journal_mouvement_id
JOIN t_statut_journal_mouvement s ON s.id = j.statut_id
WHERE j.reference LIKE 'SIM-%' AND s.nom = 'AFFECTEE'
  AND NOT EXISTS (SELECT 1 FROM t_mouvement_stock m WHERE m.detail_journal_id = d.id)
UNION ALL
SELECT '3. aucun mouvement hors journal AFFECTEE',
       IF(COUNT(*) = 0, 'OK', CONCAT(COUNT(*), ' mouvement(s) en trop'))
FROM t_mouvement_stock m
JOIN t_detail_journal d ON d.id = m.detail_journal_id
JOIN t_journal_mouvement j ON j.id = d.journal_mouvement_id
JOIN t_statut_journal_mouvement s ON s.id = j.statut_id
WHERE j.reference LIKE 'SIM-%' AND s.nom <> 'AFFECTEE'
UNION ALL
SELECT '4. un seul article par emplacement',
       IF(COUNT(*) = 0, 'OK', CONCAT(COUNT(*), ' emplacement(s) mixte(s)'))
FROM (SELECT emplacement_id FROM v_stock_par_emplacement
      GROUP BY emplacement_id HAVING COUNT(DISTINCT article_id) > 1) x
UNION ALL
SELECT '5. capacite de palette respectee',
       IF(COUNT(*) = 0, 'OK', CONCAT(COUNT(*), ' depassement(s)'))
FROM (SELECT m.emplacement_id, m.conditionnement_id,
             SUM(m.nombre_conditionnements * t.sens) AS presents
      FROM t_mouvement_stock m
      JOIN t_type_mouvement t ON t.id = m.type_mouvement_id
      WHERE m.emplacement_id IS NOT NULL
      GROUP BY m.emplacement_id, m.conditionnement_id) x
JOIN t_palette_conditionnement p ON p.article_conditionnement_id = x.conditionnement_id
WHERE x.presents > p.quantite
UNION ALL
SELECT '6. dlv <= dlc',
       IF(COUNT(*) = 0, 'OK', CONCAT(COUNT(*), ' ligne(s) invalide(s)'))
FROM t_detail_journal d
JOIN t_journal_mouvement j ON j.id = d.journal_mouvement_id
WHERE j.reference LIKE 'SIM-%' AND d.dlv > d.dlc
UNION ALL
SELECT '7. au plus une boite incomplete par ligne',
       IF(COUNT(*) = 0, 'OK', CONCAT(COUNT(*), ' ligne(s) invalide(s)'))
FROM t_detail_journal d
JOIN t_journal_mouvement j ON j.id = d.journal_mouvement_id
JOIN t_article_conditionnement c ON c.article_id = d.article_id
WHERE j.reference LIKE 'SIM-%'
  AND (d.quantite > d.quantite_conditionnement * c.quantite_piece_standard
    OR d.quantite <= (d.quantite_conditionnement - 1) * c.quantite_piece_standard)
UNION ALL
SELECT '8. EN ATTENTE et au-dela : tous les operateurs ont termine',
       IF(COUNT(*) = 0, 'OK', CONCAT(COUNT(*), ' participation(s) ouverte(s)'))
FROM t_user_journal_mouvement p
JOIN t_journal_mouvement j ON j.id = p.journal_mouvement_id
JOIN t_statut_journal_mouvement s ON s.id = j.statut_id
WHERE j.reference LIKE 'SIM-%' AND s.nom <> 'EN COURS'
  AND (p.statut_participation <> 'TERMINE' OR p.date_fin IS NULL)
UNION ALL
SELECT '9. dernier historique = statut courant',
       IF(COUNT(*) = 0, 'OK', CONCAT(COUNT(*), ' journal(aux) incoherent(s)'))
FROM t_journal_mouvement j
WHERE j.reference LIKE 'SIM-%'
  AND j.statut_id <> (SELECT h.statut_id FROM t_historique_journal_mouvement_statut h
                      WHERE h.journal_mouvement_id = j.id
                      ORDER BY h.date_changement DESC, h.id DESC LIMIT 1);

-- Stock obtenu (attendu : A-01 Coca 450, A-02 Coca 270, A-03 Eau 480,
-- A-07 Candia 600, A-09 Bonbon 710)
SELECT e.nom_emplacement, a.nom_article, v.quantite_stock AS pieces
FROM v_stock_par_emplacement v
JOIN t_emplacement e ON e.id = v.emplacement_id
JOIN t_article a     ON a.id = v.article_id
ORDER BY e.nom_emplacement;
