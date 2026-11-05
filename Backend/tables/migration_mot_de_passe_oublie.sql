-- Mot de passe oublie : nouveau type de notification, nouvelle categorie et
-- nouvel evenement du journal d'activite.
--
-- Hibernate (ddl-auto=update) n'agrandit pas une colonne ENUM deja creee :
-- sans ce script, MySQL refuse les nouvelles valeurs (MOT_DE_PASSE_OUBLIE,
-- COMPTE, MOT_DE_PASSE_REINITIALISE). Rejouable : passer une colonne en
-- VARCHAR sans changer son contenu est sans danger, meme si elle l'est deja.
--
-- A lancer une fois, sur la base stock_habibo.
--
-- Pour voir l'etat actuel avant :
--   SHOW CREATE TABLE t_notification;
--   SHOW CREATE TABLE t_journal_user;

ALTER TABLE t_notification
    MODIFY COLUMN categorie VARCHAR(40) NOT NULL,
    MODIFY COLUMN type      VARCHAR(60) NOT NULL;

ALTER TABLE t_journal_user
    MODIFY COLUMN type VARCHAR(40) NOT NULL;

-- Si t_journal_user a une contrainte CHECK sur la colonne type (SHOW CREATE TABLE
-- la montre), supprimez-la : ALTER TABLE t_journal_user DROP CHECK <nom_affiche>;
