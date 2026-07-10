-- ==============================================================================
-- 1. ARCHITECTURE ET STRUCTURE DES SCHÉMAS
-- ==============================================================================
-- Note : Le schéma 'staging' est déjà créé par le script Python.
CREATE SCHEMA IF NOT EXISTS staging;      -- Zone de stockage du modèle en étoile
CREATE SCHEMA IF NOT EXISTS core;      -- Zone de stockage du modèle en étoile
CREATE SCHEMA IF NOT EXISTS analytics; -- Zone de présentation (Vues pour la BI)

-- ==============================================================================
-- 2. CRÉATION DES TABLES DE DIMENSIONS (Schéma core)
-- ==============================================================================

-- Dimension Produit
CREATE TABLE core.dim_produit (
    id_produit SERIAL PRIMARY KEY,
    description_article VARCHAR(255) NOT NULL,
    famille_produit VARCHAR(100) NOT NULL,
    CONSTRAINT uq_produit UNIQUE (description_article, famille_produit)
);

-- Dimension Magasin
CREATE TABLE core.dim_magasin (
    id_magasin SERIAL PRIMARY KEY,
    magasin_ville VARCHAR(100) NOT NULL UNIQUE
);

-- Dimension Temps (Cruciale pour l'analyse chronologique)
CREATE TABLE core.dim_temps (
    id_temps SERIAL PRIMARY KEY,
    date_complete DATE NOT NULL UNIQUE,
    jour INT NOT NULL,
    mois INT NOT NULL,
    trimestre INT NOT NULL,
    annee INT NOT NULL
);

-- ==============================================================================
-- 3. CRÉATION DE LA TABLE DE FAITS (Schéma core)
-- ==============================================================================
CREATE TABLE core.fait_ventes (
    id_facture VARCHAR(50) NOT NULL,
    id_produit INT REFERENCES core.dim_produit(id_produit),
    id_magasin INT REFERENCES core.dim_magasin(id_magasin),
    id_temps INT REFERENCES core.dim_temps(id_temps),
    quantite_vendue INT NOT NULL,
    prix_unitaire_brut NUMERIC(10, 2) NOT NULL, -- NUMERIC évite les erreurs d'arrondi
    montant_total NUMERIC(12, 2) NOT NULL,      -- contrairement au type FLOAT
    PRIMARY KEY (id_facture, id_produit)         -- Clé primaire composite
);

-- ==============================================================================
-- 4. OPTIMISATION OLAP : CRÉATION DES INDEX
-- ==============================================================================
-- Les index sur les clés étrangères sont indispensables pour accélérer les jointures (JOIN)
CREATE INDEX idx_fait_ventes_produit ON core.fait_ventes(id_produit);
CREATE INDEX idx_fait_ventes_magasin ON core.fait_ventes(id_magasin);
CREATE INDEX idx_fait_ventes_temps ON core.fait_ventes(id_temps);

-- Index sur les axes de filtrage fréquents dans les dimensions
CREATE INDEX idx_dim_temps_annee_mois ON core.dim_temps(annee, mois);
CREATE INDEX idx_dim_produit_famille ON core.dim_produit(famille_produit);