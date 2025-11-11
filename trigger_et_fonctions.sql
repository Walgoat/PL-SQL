-- Règles de sécurité + aides

-- Interdire la suppression d'un produit s'il reste du stock
CREATE OR REPLACE TRIGGER trg_produit_nosuppr_stock
BEFORE DELETE ON PRODUIT
FOR EACH ROW
DECLARE
  v_qte NUMBER;
BEGIN
  SELECT quantite INTO v_qte
  FROM STOCK
  WHERE produit_id = :OLD.produit_id;

  IF v_qte > 0 THEN
    RAISE_APPLICATION_ERROR(-20020, 'Suppression interdite: '||:OLD.ref||' a encore '||v_qte||' en stock.');
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    NULL; -- pas de ligne en stock => OK
END;
/
-- Retourner la quantité en stock pour une référence produit
CREATE OR REPLACE FUNCTION get_stock(p_ref IN VARCHAR2)
RETURN NUMBER
IS
  v_produit_id  PRODUIT.produit_id%TYPE;
  v_quantite    STOCK.quantite%TYPE;
BEGIN
  SELECT produit_id INTO v_produit_id
  FROM PRODUIT
  WHERE ref = p_ref;

  BEGIN
    SELECT quantite INTO v_quantite
    FROM STOCK
    WHERE produit_id = v_produit_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_quantite := 0;
  END;

  RETURN v_quantite;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20030, 'Produit inconnu: '||p_ref);
  WHEN TOO_MANY_ROWS THEN
    RAISE_APPLICATION_ERROR(-20031, 'Référence non unique: '||p_ref);
END;
/
