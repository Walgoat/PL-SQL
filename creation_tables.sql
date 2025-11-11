-- Schéma BackOffice : tables, contraintes, index
-- À exécuter sous votre schéma (ex: BO_APP@XEPDB1)

-- Nettoyage léger si vous rejouez le script
BEGIN EXECUTE IMMEDIATE 'DROP VIEW V_CA_PAR_CLIENT'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW V_RESTE_A_PAYER'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
  FOR t IN (
    SELECT table_name FROM user_tables
    WHERE table_name IN ('LIGNE_FACTURE','FACTURE','REGLEMENT',
                         'LIGNE_COMMANDE','COMMANDE',
                         'MOUV_STOCK','STOCK','PRODUIT','CLIENT')
  ) LOOP
    EXECUTE IMMEDIATE 'DROP TABLE '||t.table_name||' CASCADE CONSTRAINTS';
  END LOOP;
END;
/

-- Référentiels simples
CREATE TABLE CLIENT (
  client_id     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nom           VARCHAR2(100)         NOT NULL,
  email         VARCHAR2(200) UNIQUE  NOT NULL,
  date_creation DATE DEFAULT SYSDATE  NOT NULL,
  statut        VARCHAR2(20) DEFAULT 'ACTIF' CHECK (statut IN ('ACTIF','SUSPENDU'))
);

CREATE TABLE PRODUIT (
  produit_id   NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  ref          VARCHAR2(50) UNIQUE NOT NULL,
  libelle      VARCHAR2(200) NOT NULL,
  prix_ht      NUMBER(10,2)  NOT NULL CHECK (prix_ht >= 0),
  tva_pourcent NUMBER(5,2)   DEFAULT 20 NOT NULL CHECK (tva_pourcent IN (0,5.5,10,20))
);

-- Stock courant par produit
CREATE TABLE STOCK (
  produit_id NUMBER PRIMARY KEY REFERENCES PRODUIT(produit_id),
  quantite   NUMBER(12,0) NOT NULL CHECK (quantite >= 0)
);

-- Commandes (en-tête)
CREATE TABLE COMMANDE (
  commande_id   NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  client_id     NUMBER NOT NULL REFERENCES CLIENT(client_id),
  statut        VARCHAR2(20) DEFAULT 'EN_COURS' CHECK (statut IN ('EN_COURS','VALIDE','FACTUREE','ANNULEE')),
  date_creation DATE DEFAULT SYSDATE NOT NULL
);

-- Commandes (lignes)
CREATE TABLE LIGNE_COMMANDE (
  ligne_commande_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  commande_id       NUMBER NOT NULL REFERENCES COMMANDE(commande_id) ON DELETE CASCADE,
  produit_id        NUMBER NOT NULL REFERENCES PRODUIT(produit_id),
  qte               NUMBER(10,0) NOT NULL CHECK (qte > 0),
  prix_unitaire_ht  NUMBER(10,2) NOT NULL CHECK (prix_unitaire_ht >= 0),
  UNIQUE (commande_id, produit_id)
);

-- Facturation
CREATE TABLE FACTURE (
  facture_id    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  commande_id   NUMBER UNIQUE NOT NULL REFERENCES COMMANDE(commande_id),
  date_facture  DATE DEFAULT SYSDATE NOT NULL,
  total_ht      NUMBER(12,2) NOT NULL,
  total_tva     NUMBER(12,2) NOT NULL,
  total_ttc     NUMBER(12,2) NOT NULL
);

CREATE TABLE LIGNE_FACTURE (
  ligne_facture_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  facture_id       NUMBER NOT NULL REFERENCES FACTURE(facture_id) ON DELETE CASCADE,
  produit_id       NUMBER NOT NULL REFERENCES PRODUIT(produit_id),
  qte              NUMBER(10,0) NOT NULL CHECK (qte > 0),
  prix_unitaire_ht NUMBER(10,2) NOT NULL CHECK (prix_unitaire_ht >= 0)
);

-- Paiements
CREATE TABLE REGLEMENT (
  reglement_id   NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  facture_id     NUMBER NOT NULL REFERENCES FACTURE(facture_id),
  date_reglt     DATE DEFAULT SYSDATE NOT NULL,
  montant        NUMBER(12,2) NOT NULL CHECK (montant > 0),
  mode_paiement  VARCHAR2(20) CHECK (mode_paiement IN ('CB','VIREMENT','CHEQUE','ESPECES'))
);

-- Traçabilité des mouvements de stock
CREATE TABLE MOUV_STOCK (
  mouv_id     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  produit_id  NUMBER NOT NULL REFERENCES PRODUIT(produit_id),
  type_mouv   VARCHAR2(10) CHECK (type_mouv IN ('ENTREE','SORTIE')),
  qte         NUMBER(10,0) NOT NULL CHECK (qte > 0),
  source      VARCHAR2(30) NOT NULL, -- ex: VALIDATION_COMMANDE
  ref_source  NUMBER,
  date_mouv   DATE DEFAULT SYSDATE NOT NULL
);

-- Index utiles
CREATE INDEX idx_commande_client ON COMMANDE(client_id);
CREATE INDEX idx_ligne_cmd_cmd   ON LIGNE_COMMANDE(commande_id);
CREATE INDEX idx_ligne_cmd_prod  ON LIGNE_COMMANDE(produit_id);
CREATE INDEX idx_facture_cmd     ON FACTURE(commande_id);
CREATE INDEX idx_mouv_stock_prod ON MOUV_STOCK(produit_id);
