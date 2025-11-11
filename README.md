# BackOffice Oracle PL/SQL (exemple)

Un petit projet pour s'entraîner : commandes → facturation → paiements, avec gestion de stock.

## Scripts
- `creation_tables.sql` : tables, contraintes, index
- `donnees_test.sql` : données de test
- `package_commandes.sql` : API commandes
- `package_facturation.sql` : API facturation
- `trigger_et_fonctions.sql` : trigger + fonction utilitaire
- `vue_reste_a_payer.sql` : vue de synthèse
- `import_csv_commandes.sql` : import CSV + injection
- `import_commandes.csv` : exemple de fichier

## Démarrage
```sql
CONNECT BO_APP/"Bo_App#2025"@localhost:1521/XEPDB1
@creation_tables.sql
@donnees_test.sql
@package_commandes.sql
@package_facturation.sql
@trigger_et_fonctions.sql
@vue_reste_a_payer.sql
-- Optionnel : préparer un DIRECTORY en SYSTEM, copier le CSV, puis :
-- @import_csv_commandes.sql
```

## Notes
- `REGLEMENT.mode_paiement` évite le mot réservé `mode`.
- Pour `DBMS_XPLAN.DISPLAY_CURSOR`, accorder quelques SELECT sur V$ depuis SYSTEM.
