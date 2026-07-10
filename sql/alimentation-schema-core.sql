-- ==============================================================================
-- 5. PIPELINE INTRABASE : VENTILATION VERS LE MODÈLE EN ÉTOILE
-- ==============================================================================

-- A. Remplissage des Dimensions (Uniquement les valeurs distinctes)
INSERT INTO core.dim_produit (description_article, famille_produit)
SELECT DISTINCT "Description_Article", "Famille_Produit" 
FROM staging.stg_ventes
ON CONFLICT (description_article, famille_produit) DO NOTHING;

INSERT INTO core.dim_magasin (magasin_ville)
SELECT DISTINCT "Magasin_Ville" 
FROM staging.stg_ventes
ON CONFLICT (magasin_ville) DO NOTHING;

INSERT INTO core.dim_temps (date_complete, jour, mois, trimestre, annee)
SELECT DISTINCT 
    "Date_Achat"::DATE,
    EXTRACT(DAY FROM "Date_Achat"::DATE),
    EXTRACT(MONTH FROM "Date_Achat"::DATE),
    EXTRACT(QUARTER FROM "Date_Achat"::DATE),
    EXTRACT(YEAR FROM "Date_Achat"::DATE)
FROM staging.stg_ventes
ON CONFLICT (date_complete) DO NOTHING;

-- B. Remplissage de la Table de Faits (Calcul des clés techniques via jointures)
INSERT INTO core.fait_ventes (id_facture, id_produit, id_magasin, id_temps, quantite_vendue, prix_unitaire_brut, montant_total)
SELECT 
    stg."ID_Facture",
    p.id_produit,
    m.id_magasin,
    t.id_temps,
    stg."Quantite_Vendue",
    stg."Prix_Unitaire_Brut",
    stg."Montant_Total"
FROM staging.stg_ventes stg
JOIN core.dim_produit p 
    ON stg."Description_Article" = p.description_article 
   AND stg."Famille_Produit" = p.famille_produit
JOIN core.dim_magasin m 
    ON stg."Magasin_Ville" = m.magasin_ville
JOIN core.dim_temps t 
    ON stg."Date_Achat"::DATE = t.date_complete
ON CONFLICT (id_facture, id_produit) DO NOTHING;

-- C. Maintenance des statistiques pour l'optimiseur PostgreSQL
ANALYZE core.fait_ventes;
ANALYZE core.dim_produit;
ANALYZE core.dim_magasin;
ANALYZE core.dim_temps;