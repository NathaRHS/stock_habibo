-- Un mouvement en reserve n'a pas encore d'emplacement physique.
ALTER TABLE t_mouvement_stock
    MODIFY COLUMN emplacement_id BIGINT NULL;

ALTER TABLE t_mouvement_stock
    ADD COLUMN en_reserve BOOLEAN NOT NULL DEFAULT FALSE
        AFTER emplacement_id;

ALTER TABLE t_mouvement_stock
    ADD CONSTRAINT ck_mouvement_destination
    CHECK (
        (en_reserve = TRUE AND emplacement_id IS NULL)
        OR (en_reserve = FALSE AND emplacement_id IS NOT NULL)
    );
