-- ============================================================================
-- JOURNAL D'ACTIVITE DES UTILISATEURS
-- Une ligne par action importante : qui, quoi, sur quoi, quand.
-- Table en ajout seul : on n'y modifie ni ne supprime jamais de ligne.
--
-- Hibernate (ddl-auto=update) sait aussi la creer a partir de l'entite
-- JournalUser ; ce script sert a la creer a la main, avec ses contraintes.
-- ============================================================================

CREATE TABLE IF NOT EXISTS t_journal_user (
    id BIGINT NOT NULL AUTO_INCREMENT,
    user_id BIGINT NULL,
    matricule_saisi VARCHAR(100) NULL,
    type VARCHAR(40) NOT NULL,
    cible_type VARCHAR(40) NULL,
    cible_id BIGINT NULL,
    details VARCHAR(500) NULL,
    date_evenement DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),

    -- Chaque ligne dit toujours "qui" : l'utilisateur, ou ce qui a ete tape
    -- (connexion echouee), ou une action du systeme.
    CONSTRAINT ck_journal_user_acteur CHECK (
        user_id IS NOT NULL
        OR matricule_saisi IS NOT NULL
        OR type LIKE 'SYSTEME%'
    ),

    -- Meme liste que l'enum Java TypeEvenementUser.
    CONSTRAINT ck_journal_user_type CHECK (type IN (
        'CONNEXION_REUSSIE',
        'CONNEXION_ECHOUEE',
        'DECONNEXION',
        'COMPTE_CREE',
        'PHOTO_UTILISATEUR_CHANGEE',
        'ARTICLE_CREE',
        'VARIANTE_CREEE',
        'ARTICLE_SUPPRIME',
        'PHOTO_ARTICLE_CHANGEE',
        'JOURNAL_CREE',
        'JOURNAL_MODIFIE',
        'JOURNAL_SUPPRIME',
        'JOURNAL_VALIDE',
        'MODIFICATION_DEMANDEE',
        'ENTREE_STOCK_VALIDEE',
        'SORTIE_CONFIRMEE',
        'PARTICIPATION_DEBUTEE',
        'PARTICIPATION_TERMINEE',
        'COMMANDES_AJOUTEES',
        'PARCOURS_GENERE',
        'AUCUN_PRODUIT_DECLARE',
        'REFERENTIEL_CREE',
        'REFERENTIEL_MODIFIE',
        'REFERENTIEL_SUPPRIME'
    )),

    CONSTRAINT fk_journal_user_user
        FOREIGN KEY (user_id) REFERENCES t_user (id)
        ON UPDATE NO ACTION ON DELETE RESTRICT
) ENGINE = InnoDB;

CREATE INDEX idx_journal_user_user_date ON t_journal_user (user_id, date_evenement);
CREATE INDEX idx_journal_user_date ON t_journal_user (date_evenement);
