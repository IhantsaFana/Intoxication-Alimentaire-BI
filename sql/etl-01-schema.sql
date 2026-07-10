-- ==============================================================================
-- DATAWAREHOUSE - INTOXICATION ALIMENTAIRE À MADAGASCAR
-- Architecture : Modèle en étoile (Star Schema)
-- ==============================================================================

-- ==============================================================================
-- 1. ARCHITECTURE ET STRUCTURE DES SCHÉMAS
-- ==============================================================================
CREATE SCHEMA IF NOT EXISTS staging;      -- Zone d'import des données brutes
CREATE SCHEMA IF NOT EXISTS core;         -- Zone de stockage du modèle en étoile
CREATE SCHEMA IF NOT EXISTS analytics;   -- Zone de présentation (Vues pour BI)

-- ==============================================================================
-- 2. TABLE DE STAGING (Import depuis Python/ETL)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS staging.intoxication_raw (
    id_cas VARCHAR(50) PRIMARY KEY,
    date_cas DATE,
    heure_cas TIME,
    id_patient VARCHAR(50),
    age_patient INT,
    genre_patient VARCHAR(10),
    ville VARCHAR(100),
    region VARCHAR(100),
    id_etablissement VARCHAR(50),
    nom_etablissement VARCHAR(255),
    type_etablissement VARCHAR(100),
    lieu_consommation VARCHAR(100),
    type_aliment VARCHAR(100),
    aliment_suspect VARCHAR(255),
    categorie_aliment VARCHAR(100),
    marque_aliment VARCHAR(100),
    date_achat DATE,
    date_consomation DATE,
    heure_consomation TIME,
    source_alimentaire VARCHAR(100),
    nombre_personnes_exposees INT,
    nombre_personnes_malades INT,
    symptomes TEXT,
    symptome_principal VARCHAR(100),
    gravite VARCHAR(50),
    temperature_patient NUMERIC(5,2),
    duree_symptomes_heures INT,
    hospitalisation VARCHAR(10),
    id_hopital VARCHAR(50),
    nom_hopital VARCHAR(255),
    traitement_administre VARCHAR(255),
    medicament_administre VARCHAR(255),
    analyse_laboratoire VARCHAR(100),
    resultat_analyse VARCHAR(100),
    agent_pathogene_suspecte VARCHAR(100),
    salmonella VARCHAR(20),
    e_coli VARCHAR(20),
    listeria VARCHAR(20),
    norovirus VARCHAR(20),
    date_declaration DATE,
    source_signalement VARCHAR(100),
    inspection_effectuee VARCHAR(10),
    resultat_inspection VARCHAR(100),
    mesures_prises VARCHAR(255),
    fermeture_etablissement VARCHAR(10),
    jour INT,
    mois INT,
    annee INT,
    saison VARCHAR(50),
    anomalie BOOLEAN,
    taux_attaque NUMERIC(5,2),
    groupe_age VARCHAR(50)
);

-- Index sur staging pour les recherches lors du ETL
CREATE INDEX IF NOT EXISTS idx_staging_intoxication_date ON staging.intoxication_raw(date_cas);
CREATE INDEX IF NOT EXISTS idx_staging_intoxication_region ON staging.intoxication_raw(region);

-- ==============================================================================
-- 3. CRÉATION DES DIMENSIONS (Schéma core)
-- ==============================================================================

-- Dimension Temps (Cruciale pour l'analyse épidémiologique)
CREATE TABLE IF NOT EXISTS core.dim_temps (
    id_temps SERIAL PRIMARY KEY,
    date_complete DATE NOT NULL UNIQUE,
    jour INT NOT NULL,
    mois INT NOT NULL,
    trimestre INT NOT NULL,
    annee INT NOT NULL,
    saison VARCHAR(50),
    semaine_annee INT
);

-- Dimension Localisation (Géographie)
CREATE TABLE IF NOT EXISTS core.dim_localisation (
    id_localisation SERIAL PRIMARY KEY,
    ville VARCHAR(100) NOT NULL,
    region VARCHAR(100) NOT NULL,
    CONSTRAINT uq_localisation UNIQUE (ville, region)
);

-- Dimension Établissement (Source de l'intoxication)
CREATE TABLE IF NOT EXISTS core.dim_etablissement (
    id_etablissement_dim SERIAL PRIMARY KEY,
    id_etablissement_src VARCHAR(50),
    nom_etablissement VARCHAR(255),
    type_etablissement VARCHAR(100),
    id_localisation INT REFERENCES core.dim_localisation(id_localisation),
    CONSTRAINT uq_etablissement UNIQUE (id_etablissement_src)
);

-- Dimension Aliment (Produit suspect)
CREATE TABLE IF NOT EXISTS core.dim_aliment (
    id_aliment SERIAL PRIMARY KEY,
    type_aliment VARCHAR(100),
    aliment_suspect VARCHAR(255),
    categorie_aliment VARCHAR(100),
    marque_aliment VARCHAR(100),
    source_alimentaire VARCHAR(100),
    CONSTRAINT uq_aliment UNIQUE (type_aliment, aliment_suspect, categorie_aliment)
);

-- Dimension Pathogène (Agent contaminant)
CREATE TABLE IF NOT EXISTS core.dim_pathogene (
    id_pathogene SERIAL PRIMARY KEY,
    agent_pathogene VARCHAR(100) NOT NULL UNIQUE,
    type_test_salmonella VARCHAR(20),
    type_test_e_coli VARCHAR(20),
    type_test_listeria VARCHAR(20),
    type_test_norovirus VARCHAR(20)
);

-- Dimension Patient (Profil épidémiologique)
CREATE TABLE IF NOT EXISTS core.dim_patient (
    id_patient_dim SERIAL PRIMARY KEY,
    age_patient INT,
    groupe_age VARCHAR(50),
    genre_patient VARCHAR(10),
    CONSTRAINT uq_patient UNIQUE (age_patient, genre_patient)
);

-- Dimension Symptôme & Gravité (Classification clinique)
CREATE TABLE IF NOT EXISTS core.dim_symptome_gravite (
    id_symptome_gravite SERIAL PRIMARY KEY,
    symptome_principal VARCHAR(100),
    gravite VARCHAR(50),
    CONSTRAINT uq_symptome_gravite UNIQUE (symptome_principal, gravite)
);

-- ==============================================================================
-- 4. CRÉATION DE LA TABLE DE FAITS (Schéma core)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS core.fait_intoxication (
    id_cas VARCHAR(50) NOT NULL PRIMARY KEY,
    id_temps INT REFERENCES core.dim_temps(id_temps),
    id_localisation INT REFERENCES core.dim_localisation(id_localisation),
    id_etablissement_dim INT REFERENCES core.dim_etablissement(id_etablissement_dim),
    id_aliment INT REFERENCES core.dim_aliment(id_aliment),
    id_pathogene INT REFERENCES core.dim_pathogene(id_pathogene),
    id_patient_dim INT REFERENCES core.dim_patient(id_patient_dim),
    id_symptome_gravite INT REFERENCES core.dim_symptome_gravite(id_symptome_gravite),
    
    -- Mesures (Faits mesurables)
    nombre_personnes_exposees INT,
    nombre_personnes_malades INT,
    taux_attaque NUMERIC(5,2),
    temperature_patient NUMERIC(5,2),
    duree_symptomes_heures INT,
    
    -- Indicateurs
    hospitalisation VARCHAR(10),
    inspection_effectuee VARCHAR(10),
    fermeture_etablissement VARCHAR(10),
    
    -- Dates additionnelles
    date_achat DATE,
    date_consomation DATE,
    date_declaration DATE,
    heure_cas TIME,
    heure_consomation TIME,
    
    -- Traçabilité
    traitement_administre VARCHAR(255),
    medicament_administre VARCHAR(255),
    analyse_laboratoire VARCHAR(100),
    resultat_analyse VARCHAR(100),
    resultat_inspection VARCHAR(100),
    mesures_prises VARCHAR(255),
    source_signalement VARCHAR(100),
    anomalie BOOLEAN
);

-- ==============================================================================
-- 5. OPTIMISATION OLAP : CRÉATION DES INDEX (CRITIQUE pour perf)
-- ==============================================================================

-- INDEX SUR LES CLÉS ÉTRANGÈRES (Accélère les jointures)
CREATE INDEX IF NOT EXISTS idx_fait_intoxication_temps ON core.fait_intoxication(id_temps);
CREATE INDEX IF NOT EXISTS idx_fait_intoxication_localisation ON core.fait_intoxication(id_localisation);
CREATE INDEX IF NOT EXISTS idx_fait_intoxication_etablissement ON core.fait_intoxication(id_etablissement_dim);
CREATE INDEX IF NOT EXISTS idx_fait_intoxication_aliment ON core.fait_intoxication(id_aliment);
CREATE INDEX IF NOT EXISTS idx_fait_intoxication_pathogene ON core.fait_intoxication(id_pathogene);
CREATE INDEX IF NOT EXISTS idx_fait_intoxication_patient ON core.fait_intoxication(id_patient_dim);
CREATE INDEX IF NOT EXISTS idx_fait_intoxication_symptome_gravite ON core.fait_intoxication(id_symptome_gravite);

-- INDEX SUR LES AXES DE FILTRAGE FRÉQUENTS
CREATE INDEX IF NOT EXISTS idx_dim_temps_annee_mois ON core.dim_temps(annee, mois);
CREATE INDEX IF NOT EXISTS idx_dim_temps_saison ON core.dim_temps(saison);
CREATE INDEX IF NOT EXISTS idx_dim_localisation_region ON core.dim_localisation(region);
CREATE INDEX IF NOT EXISTS idx_dim_localisation_ville ON core.dim_localisation(ville);
CREATE INDEX IF NOT EXISTS idx_dim_etablissement_type ON core.dim_etablissement(type_etablissement);
CREATE INDEX IF NOT EXISTS idx_dim_aliment_categorie ON core.dim_aliment(categorie_aliment);
CREATE INDEX IF NOT EXISTS idx_dim_patient_groupe_age ON core.dim_patient(groupe_age);
CREATE INDEX IF NOT EXISTS idx_dim_symptome_gravite_gravite ON core.dim_symptome_gravite(gravite);

-- INDEX SUR LES COLONNES DE MESURE (Optimise les agrégations)
CREATE INDEX IF NOT EXISTS idx_fait_intoxication_hospitalisation ON core.fait_intoxication(hospitalisation);
CREATE INDEX IF NOT EXISTS idx_fait_intoxication_inspection ON core.fait_intoxication(inspection_effectuee);
CREATE INDEX IF NOT EXISTS idx_fait_intoxication_anomalie ON core.fait_intoxication(anomalie);

-- INDEX COMPOSÉ (Optimise requêtes multi-colonnes fréquentes)
CREATE INDEX IF NOT EXISTS idx_fait_intoxication_region_gravite 
    ON core.fait_intoxication(id_localisation, id_symptome_gravite);

CREATE INDEX IF NOT EXISTS idx_fait_intoxication_temps_region 
    ON core.fait_intoxication(id_temps, id_localisation);