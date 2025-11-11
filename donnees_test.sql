-- Données de test (clients, produits, stock)

INSERT INTO CLIENT(nom,email) VALUES ('ACME','contact@acme.test');
INSERT INTO CLIENT(nom,email) VALUES ('Globex','it@globex.test');

INSERT INTO PRODUIT(ref,libelle,prix_ht,tva_pourcent) VALUES ('P-USB','Clé USB 64Go',9.90,20);
INSERT INTO PRODUIT(ref,libelle,prix_ht,tva_pourcent) VALUES ('P-MON','Ecran 27"',189.00,20);
INSERT INTO PRODUIT(ref,libelle,prix_ht,tva_pourcent) VALUES ('P-SUP','Support écran',29.00,20);

INSERT INTO STOCK(produit_id,quantite)
SELECT produit_id,
       CASE ref WHEN 'P-USB' THEN 500 WHEN 'P-MON' THEN 30 ELSE 100 END
FROM PRODUIT;

COMMIT;

-- Contrôles de base
SELECT nom, email FROM CLIENT;
SELECT p.ref, s.quantite FROM PRODUIT p JOIN STOCK s ON s.produit_id=p.produit_id ORDER BY p.ref;
