-- Une ligne de cette vue represente une position physique de stockage.
-- Hierarchie : Rack -> Emplacement -> Etage.

CREATE OR REPLACE VIEW v_structure_entrepot AS
SELECT
    etage.id AS position_stockage_id,
    rack.id AS rack_id,
    rack.nom_rack,
    emplacement.id AS emplacement_id,
    emplacement.nom_emplacement,
    etage.id AS etage_id,
    etage.nom_etage,
    CONCAT_WS(
        ' / ',
        rack.nom_rack,
        emplacement.nom_emplacement,
        etage.nom_etage
    ) AS adresse_stockage,
FROM t_etage AS etage
INNER JOIN t_emplacement AS emplacement
    ON emplacement.id = etage.emplacement_id
INNER JOIN t_rack AS rack
    ON rack.id = emplacement.rack_id;


SELECT count(rack_id)
FROM v_structure_entrepot;
-- Exemple d'utilisation :
-- SELECT *
-- FROM v_structure_entrepot
-- ORDER BY nom_rack, nom_emplacement, nom_etage;



 SELECT rack_id , COUNT(DISTINCT emplacement_id) from v_structure_entrepot group by rack_id;
 SELECT emplacement_id , COUNT(etage_id) from v_structure_entrepot group by emplacement_id;
