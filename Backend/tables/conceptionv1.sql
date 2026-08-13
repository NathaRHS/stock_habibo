CREATE TABLE
	IF NOT EXISTS `t_typeProduit` (
		`id` BIGINT,
		`nomType` VARCHAR(255),
		PRIMARY KEY (`id`)
	);

CREATE TABLE
	IF NOT EXISTS `t_stock` (
		`id` BIGINT,
		`Article_id` VARCHAR(255),
		`etage_id` BIGINT,
		`Quantite` INTEGER,
		PRIMARY KEY (`id`)
	);

CREATE TABLE
	IF NOT EXISTS `t_article` (
		`id` BIGINT,
		`nomArticle` VARCHAR(255),
		`type` BIGINT,
		PRIMARY KEY (`id`)
	);

CREATE TABLE
	IF NOT EXISTS `t_Unite` (
		`id` BIGINT,
		`nom_Unite` VARCHAR(255),
		PRIMARY KEY (`id`)
	);

CREATE TABLE
	IF NOT EXISTS `t_type_mouvement` (
		`id` BIGINT,
		`nomTypeMouve` VARCHAR(255),
		PRIMARY KEY (`id`)
	);

CREATE TABLE
	IF NOT EXISTS `t_mouvement_stock` (
		`id` BIGINT,
		`id_conditionnement` BIGINT,
		`id_type_mouvement` BIGINT,
		`Date` DATETIME,
		PRIMARY KEY (`id`)
	);

CREATE TABLE
	IF NOT EXISTS `t_rak` (
		`id` BIGINT,
		`nomRak` VARCHAR(255),
		PRIMARY KEY (`id`)
	);

CREATE TABLE
	IF NOT EXISTS `t_emp` (
		`id` BIGINT,
		`emp_nom` VARCHAR(255),
		`idRak` BIGINT,
		PRIMARY KEY (`id`)
	);

CREATE TABLE
	IF NOT EXISTS `t_etage` (
		`id` BIGINT,
		`nomEtage` VARCHAR(255),
		`id_rak` BIGINT,
		PRIMARY KEY (`id`)
	);



CREATE TABLE
	IF NOT EXISTS `t_article_conditionnement` (
		`id` BIGINT,
		`id_article` BIGINT NOT NULL,
		`id_unite` BIGINT NOT NULL,
		`code_barres` VARCHAR(255) UNIQUE,
		`quantite_piece` INTEGER NOT NULL,
		PRIMARY KEY (`id`)
	);

CREATE TABLE
	IF NOT EXISTS `t_roles` (
		`id` BIGINT NOT NULL AUTO_INCREMENT,
		`nomRole` VARCHAR(255),
		PRIMARY KEY (`id`)
	);

CREATE TABLE
	IF NOT EXISTS `t_user` (
		`id` BIGINT NOT NULL AUTO_INCREMENT,
		`role` BIGINT,
		`matricule` VARCHAR(255),
		PRIMARY KEY (`id`)
	);

	ALTER TABLE  t_user ADD FOREIGN KEY (role) REFERENCES t_roles(id) ON UPDATE NO ACTION ON DELETE NO ACTION;


CREATE TABLE
	IF NOT EXISTS `t_typeInfo` (
		`id` BIGINT NOT NULL AUTO_INCREMENT,
		`NomInfo` VARCHAR(255),
		PRIMARY KEY (`id`)
	);

CREATE TABLE
	IF NOT EXISTS `t_journal` (
		`id` BIGINT AUTO_INCREMENT,
		`date_action` DATETIME NOT NULL,
		`id_user` BIGINT,
		`type_action` VARCHAR(50) NOT NULL,
		`entite` VARCHAR(50),
		`entite_id` BIGINT,
		`description` VARCHAR(500),
		PRIMARY KEY (`id`)
	);

ALTER TABLE `t_article` ADD FOREIGN KEY (`type`) REFERENCES `t_typeProduit` (`id`) ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE `t_emp` ADD FOREIGN KEY (`idRak`) REFERENCES `t_rak` (`id`) ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE `t_etage` ADD FOREIGN KEY (`id_rak`) REFERENCES `t_emp` (`id`) ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE `t_etage` ADD FOREIGN KEY (`id_rak`) REFERENCES `t_emp` (`id`) ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE `t_stock` ADD FOREIGN KEY (`id`) REFERENCES `t_etage` (`id`) ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE `t_article_conditionnement` ADD FOREIGN KEY (`id_article`) REFERENCES `t_article` (`id`) ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE `t_article_conditionnement` ADD FOREIGN KEY (`id_unite`) REFERENCES `t_Unite` (`id`) ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE `t_mouvement_stock` ADD FOREIGN KEY (`id_type_mouvement`) REFERENCES `t_type_mouvement` (`id`) ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE `t_article_conditionnement` ADD FOREIGN KEY (`id`) REFERENCES `t_mouvement_stock` (`id_conditionnement`) ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE `t_roles` ADD FOREIGN KEY (`id`) REFERENCES `t_user` (`role`) ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE `t_journal` ADD FOREIGN KEY (`id_info`) REFERENCES `t_typeInfo` (`id`) ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE `t_user` ADD COLUMN `role_id` BIGINT;
ALTER TABLE `t_user` ADD FOREIGN KEY (`role_id`) REFERENCES `t_roles` (`id`) ON UPDATE NO ACTION ON DELETE NO ACTION;

CREATE VIEW
	v_stock_parEtage AS
SELECT
	ac.id_article,
	ms.id_etage,
	SUM(
		CASE
			WHEN tm.nomTypeMouve = 'ENTREE' THEN ms.quantite_piece
			WHEN tm.nomTypeMouve = 'SORTIE' THEN - ms.quantite_piece
			ELSE 0
		END
	) AS quantite_stock
FROM
	t_mouvement_stock ms
	JOIN t_article_conditionnement ac ON ac.id = ms.id_conditionnement
	JOIN t_type_mouvement tm ON tm.id = ms.id_type_mouvement
GROUP BY
	ac.id_article,
	ms.id_etage;

CREATE VIEW
	v_stock_parEtage AS
SELECT
	ac.id_article,
	ms.id_etage,
	SUM(
		CASE
			WHEN tm.nomTypeMouve = 'ENTREE' THEN ms.quantite_piece
			WHEN tm.nomTypeMouve = 'SORTIE' THEN - ms.quantite_piece
			ELSE 0
		END
	) AS quantite_stock
FROM
	t_mouvement_stock ms
	JOIN t_article_conditionnement ac ON ac.id = ms.id_conditionnement
	JOIN t_type_mouvement tm ON tm.id = ms.id_type_mouvement
GROUP BY
	ac.id_article;


INSERT INTO t_roles VALUES
(1, 'ADMIN'),
(2, 'USER');