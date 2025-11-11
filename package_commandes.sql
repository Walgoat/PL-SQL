-- API commandes : créer, ajouter des lignes, valider

CREATE OR REPLACE PACKAGE pkg_commande AS
  PROCEDURE creer_commande(p_client_id IN NUMBER, p_commande_id OUT NUMBER);
  PROCEDURE ajouter_ligne(p_commande_id IN NUMBER, p_produit_id IN NUMBER, p_qte IN NUMBER);
  PROCEDURE valider_commande(p_commande_id IN NUMBER);
END pkg_commande;
/
CREATE OR REPLACE PACKAGE BODY pkg_commande AS
  PROCEDURE creer_commande(p_client_id IN NUMBER, p_commande_id OUT NUMBER) IS
  BEGIN
    INSERT INTO COMMANDE(client_id) VALUES (p_client_id)
    RETURNING commande_id INTO p_commande_id;
  END;

  PROCEDURE ajouter_ligne(p_commande_id IN NUMBER, p_produit_id IN NUMBER, p_qte IN NUMBER) IS
    v_prix NUMBER(10,2);
  BEGIN
    SELECT prix_ht INTO v_prix FROM PRODUIT WHERE produit_id = p_produit_id;
    INSERT INTO LIGNE_COMMANDE(commande_id,produit_id,qte,prix_unitaire_ht)
    VALUES (p_commande_id, p_produit_id, p_qte, v_prix);
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      UPDATE LIGNE_COMMANDE
         SET qte = qte + p_qte
       WHERE commande_id = p_commande_id AND produit_id = p_produit_id;
  END;

  PROCEDURE valider_commande(p_commande_id IN NUMBER) IS
    v_statut COMMANDE.statut%TYPE;
  BEGIN
    SELECT statut INTO v_statut FROM COMMANDE WHERE commande_id = p_commande_id FOR UPDATE;
    IF v_statut <> 'EN_COURS' THEN
      RAISE_APPLICATION_ERROR(-20001, 'Commande non modifiable (statut='||v_statut||')');
    END IF;

    FOR r IN (
      SELECT lc.produit_id, lc.qte, s.quantite AS stock
      FROM LIGNE_COMMANDE lc
      JOIN STOCK s ON s.produit_id = lc.produit_id
      WHERE lc.commande_id = p_commande_id
    ) LOOP
      IF r.stock < r.qte THEN
        RAISE_APPLICATION_ERROR(-20002, 'Stock insuffisant pour produit '||r.produit_id);
      END IF;
    END LOOP;

    FOR r IN (
      SELECT produit_id, qte FROM LIGNE_COMMANDE WHERE commande_id = p_commande_id
    ) LOOP
      UPDATE STOCK SET quantite = quantite - r.qte WHERE produit_id = r.produit_id;
      INSERT INTO MOUV_STOCK(produit_id,type_mouv,qte,source,ref_source)
      VALUES (r.produit_id,'SORTIE',r.qte,'VALIDATION_COMMANDE',p_commande_id);
    END LOOP;

    UPDATE COMMANDE SET statut = 'VALIDE' WHERE commande_id = p_commande_id;
  END;
END pkg_commande;
/
