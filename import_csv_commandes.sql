-- Import CSV via external table + injection

-- À faire en SYSTEM (une fois) : créer un DIRECTORY vers le dossier du CSV et donner les droits à votre schéma.

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE EXT_LIGNE_COMMANDE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
CREATE TABLE EXT_LIGNE_COMMANDE (
  commande_ref  VARCHAR2(50),
  client_nom    VARCHAR2(100),
  produit_ref   VARCHAR2(50),
  qte           NUMBER(10,0)
)
ORGANIZATION EXTERNAL
  ( TYPE ORACLE_LOADER
    DEFAULT DIRECTORY BO_EXT_DIR
    ACCESS PARAMETERS (
      RECORDS DELIMITED BY NEWLINE
      BADFILE BO_EXT_DIR:'import_commandes.bad'
      LOGFILE BO_EXT_DIR:'import_commandes.log'
      FIELDS TERMINATED BY ';'
      OPTIONALLY ENCLOSED BY '"'
      MISSING FIELD VALUES ARE NULL
      ( commande_ref CHAR(50),
        client_nom   CHAR(100),
        produit_ref  CHAR(50),
        qte          INTEGER EXTERNAL
      )
    )
    LOCATION ('import_commandes.csv')
  )
REJECT LIMIT UNLIMITED;

-- Lecture simple
SELECT * FROM EXT_LIGNE_COMMANDE;

-- Injection (création/validation/facturation)
SET SERVEROUTPUT ON
DECLARE
  CURSOR c_cmd IS
    SELECT commande_ref, client_nom
    FROM EXT_LIGNE_COMMANDE
    GROUP BY commande_ref, client_nom
    ORDER BY commande_ref;

  CURSOR c_lignes(p_commande_ref VARCHAR2) IS
    SELECT produit_ref, qte
    FROM EXT_LIGNE_COMMANDE
    WHERE commande_ref = p_commande_ref;

  v_client_id   CLIENT.client_id%TYPE;
  v_commande_id COMMANDE.commande_id%TYPE;
  v_prod_id     PRODUIT.produit_id%TYPE;
  v_facture_id  FACTURE.facture_id%TYPE;
BEGIN
  FOR cmd IN c_cmd LOOP
    SELECT client_id INTO v_client_id
    FROM CLIENT
    WHERE nom = cmd.client_nom;

    pkg_commande.creer_commande(v_client_id, v_commande_id);

    FOR l IN c_lignes(cmd.commande_ref) LOOP
      SELECT produit_id INTO v_prod_id
      FROM PRODUIT
      WHERE ref = l.produit_ref;

      pkg_commande.ajouter_ligne(v_commande_id, v_prod_id, l.qte);
    END LOOP;

    pkg_commande.valider_commande(v_commande_id);
    pkg_facturation.generer_facture(v_commande_id, v_facture_id);
  END LOOP;
END;
/
