-- API facturation : générer la facture et calculer les totaux

CREATE OR REPLACE PACKAGE pkg_facturation AS
  PROCEDURE generer_facture(p_commande_id IN NUMBER, p_facture_id OUT NUMBER);
END pkg_facturation;
/
CREATE OR REPLACE PACKAGE BODY pkg_facturation AS
  PROCEDURE generer_facture(p_commande_id IN NUMBER, p_facture_id OUT NUMBER) IS
    v_statut COMMANDE.statut%TYPE;
    v_total_ht  NUMBER := 0;
    v_total_tva NUMBER := 0;
    v_total_ttc NUMBER := 0;
  BEGIN
    SELECT statut INTO v_statut FROM COMMANDE WHERE commande_id = p_commande_id;
    IF v_statut <> 'VALIDE' THEN
      RAISE_APPLICATION_ERROR(-20010, 'La commande doit être VALIDE pour être facturée');
    END IF;

    INSERT INTO FACTURE(commande_id,total_ht,total_tva,total_ttc)
    VALUES(p_commande_id,0,0,0)
    RETURNING facture_id INTO p_facture_id;

    FOR r IN (
      SELECT lc.produit_id, lc.qte, lc.prix_unitaire_ht, p.tva_pourcent
      FROM LIGNE_COMMANDE lc
      JOIN PRODUIT p ON p.produit_id = lc.produit_id
      WHERE lc.commande_id = p_commande_id
    ) LOOP
      INSERT INTO LIGNE_FACTURE(facture_id,produit_id,qte,prix_unitaire_ht)
      VALUES (p_facture_id, r.produit_id, r.qte, r.prix_unitaire_ht);

      v_total_ht  := v_total_ht  + (r.qte * r.prix_unitaire_ht);
      v_total_tva := v_total_tva + (r.qte * r.prix_unitaire_ht * r.tva_pourcent/100);
    END LOOP;

    v_total_ttc := v_total_ht + v_total_tva;

    UPDATE FACTURE
       SET total_ht = v_total_ht, total_tva = v_total_tva, total_ttc = v_total_ttc
     WHERE facture_id = p_facture_id;

    UPDATE COMMANDE SET statut = 'FACTUREE' WHERE commande_id = p_commande_id;
  END;
END pkg_facturation;
/
