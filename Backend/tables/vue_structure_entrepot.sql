-- Une ligne de cette vue represente une position physique de stockage.
-- Hierarchie : Rack -> numero d'etage -> Emplacement (place palette).

CREATE OR REPLACE VIEW v_structure_entrepot AS
SELECT
    emplacement.id AS position_stockage_id,
    rack.id AS rack_id,
    rack.nom_rack,
    emplacement.id AS emplacement_id,
    emplacement.nom_emplacement,
    emplacement.numero_etage,
    CONCAT_WS(
        ' / ',
        rack.nom_rack,
        CONCAT('Etage ', emplacement.numero_etage),
        emplacement.nom_emplacement
    ) AS adresse_stockage
FROM t_emplacement AS emplacement
INNER JOIN t_rack AS rack
    ON rack.id = emplacement.rack_id;


SELECT count(rack_id)
FROM v_structure_entrepot;
-- Exemple d'utilisation :
-- SELECT *
-- FROM v_structure_entrepot
-- ORDER BY nom_rack, numero_etage, nom_emplacement;



 SELECT rack_id , COUNT(DISTINCT emplacement_id) from v_structure_entrepot group by rack_id;
 SELECT rack_id, numero_etage, COUNT(emplacement_id)
 FROM v_structure_entrepot
 GROUP BY rack_id, numero_etage;
