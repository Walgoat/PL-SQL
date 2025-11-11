-- Vue de suivi des paiements

CREATE OR REPLACE VIEW V_RESTE_A_PAYER AS
SELECT
    f.facture_id,
    f.total_ttc,
    NVL(SUM(r.montant), 0) AS deja_paye,
    f.total_ttc - NVL(SUM(r.montant), 0) AS reste_a_payer
FROM FACTURE f
LEFT JOIN REGLEMENT r
       ON r.facture_id = f.facture_id
GROUP BY f.facture_id, f.total_ttc;

SELECT * FROM V_RESTE_A_PAYER ORDER BY facture_id DESC;
