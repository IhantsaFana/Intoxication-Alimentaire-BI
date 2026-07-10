-- ==============================================================================
-- PIPELINE INTRABASE : VENTILATION VERS LE MODÈLE EN ÉTOILE
-- Remplit les dimensions et la table de faits depuis staging.intoxication_raw
-- ==============================================================================

-- ==============================================================================
-- A. REMPLISSAGE DES DIMENSIONS
-- ==============================================================================

-- 1. Dimension Temps
INSERT INTO core.dim_temps (date_complete, jour, mois, trimestre, annee, saison, semaine_annee)
SELECT DISTINCT 
    raw.date_cas::DATE,
    raw.jour,
    raw.mois,
    CASE 
        WHEN raw.mois IN (1,2,3) THEN 1
        WHEN raw.mois IN (4,5,6) THEN 2
        WHEN raw.mois IN (7,8,9) THEN 3
        ELSE 4
    END,
    raw.annee,
    raw.saison,
    EXTRACT(WEEK FROM raw.date_cas::DATE)
FROM staging.intoxication_raw raw
WHERE raw.date_cas IS NOT NULL
ON CONFLICT (date_complete) DO NOTHING;

-- 2. Dimension Localisation
INSERT INTO core.dim_localisation (ville, region)
SELECT DISTINCT raw.ville, raw.region
FROM staging.intoxication_raw raw
WHERE raw.ville IS NOT NULL AND raw.region IS NOT NULL
ON CONFLICT (ville, region) DO NOTHING;

-- 3. Dimension Établissement
INSERT INTO core.dim_etablissement (id_etablissement_src, nom_etablissement, type_etablissement, id_localisation)
SELECT DISTINCT 
    raw.id_etablissement,
    raw.nom_etablissement,
    raw.type_etablissement,
    loc.id_localisation
FROM staging.intoxication_raw raw
JOIN core.dim_localisation loc 
    ON raw.ville = loc.ville AND raw.region = loc.region
WHERE raw.id_etablissement IS NOT NULL
ON CONFLICT (id_etablissement_src) DO NOTHING;

-- 4. Dimension Aliment
INSERT INTO core.dim_aliment (type_aliment, aliment_suspect, categorie_aliment, marque_aliment, source_alimentaire)
SELECT DISTINCT 
    raw.type_aliment,
    raw.aliment_suspect,
    raw.categorie_aliment,
    raw.marque_aliment,
    raw.source_alimentaire
FROM staging.intoxication_raw raw
WHERE raw.aliment_suspect IS NOT NULL
ON CONFLICT (type_aliment, aliment_suspect, categorie_aliment) DO NOTHING;

-- 5. Dimension Pathogène
INSERT INTO core.dim_pathogene (agent_pathogene, type_test_salmonella, type_test_e_coli, type_test_listeria, type_test_norovirus)
SELECT DISTINCT 
    raw.agent_pathogene_suspecte,
    raw.salmonella,
    raw.e_coli,
    raw.listeria,
    raw.norovirus
FROM staging.intoxication_raw raw
WHERE raw.agent_pathogene_suspecte IS NOT NULL AND raw.agent_pathogene_suspecte != ''
ON CONFLICT (agent_pathogene) DO NOTHING;

-- 6. Dimension Patient
INSERT INTO core.dim_patient (age_patient, groupe_age, genre_patient)
SELECT DISTINCT 
    raw.age_patient,
    raw.groupe_age,
    raw.genre_patient
FROM staging.intoxication_raw raw
WHERE raw.age_patient IS NOT NULL
ON CONFLICT (age_patient, genre_patient) DO NOTHING;

-- 7. Dimension Symptôme & Gravité
INSERT INTO core.dim_symptome_gravite (symptome_principal, gravite)
SELECT DISTINCT 
    raw.symptome_principal,
    raw.gravite
FROM staging.intoxication_raw raw
WHERE raw.symptome_principal IS NOT NULL AND raw.gravite IS NOT NULL
ON CONFLICT (symptome_principal, gravite) DO NOTHING;

-- ==============================================================================
-- B. REMPLISSAGE DE LA TABLE DE FAITS
-- ==============================================================================
INSERT INTO core.fait_intoxication (
    id_cas,
    id_temps,
    id_localisation,
    id_etablissement_dim,
    id_aliment,
    id_pathogene,
    id_patient_dim,
    id_symptome_gravite,
    nombre_personnes_exposees,
    nombre_personnes_malades,
    taux_attaque,
    temperature_patient,
    duree_symptomes_heures,
    hospitalisation,
    inspection_effectuee,
    fermeture_etablissement,
    date_achat,
    date_consomation,
    date_declaration,
    heure_cas,
    heure_consomation,
    traitement_administre,
    medicament_administre,
    analyse_laboratoire,
    resultat_analyse,
    resultat_inspection,
    mesures_prises,
    source_signalement,
    anomalie
)
SELECT 
    raw.id_cas,
    t.id_temps,
    loc.id_localisation,
    etab.id_etablissement_dim,
    alim.id_aliment,
    path.id_pathogene,
    pat.id_patient_dim,
    sg.id_symptome_gravite,
    raw.nombre_personnes_exposees,
    raw.nombre_personnes_malades,
    raw.taux_attaque,
    raw.temperature_patient,
    raw.duree_symptomes_heures,
    raw.hospitalisation,
    raw.inspection_effectuee,
    raw.fermeture_etablissement,
    raw.date_achat,
    raw.date_consomation,
    raw.date_declaration,
    raw.heure_cas,
    raw.heure_consomation,
    raw.traitement_administre,
    raw.medicament_administre,
    raw.analyse_laboratoire,
    raw.resultat_analyse,
    raw.resultat_inspection,
    raw.mesures_prises,
    raw.source_signalement,
    raw.anomalie
FROM staging.intoxication_raw raw
LEFT JOIN core.dim_temps t 
    ON raw.date_cas::DATE = t.date_complete
LEFT JOIN core.dim_localisation loc 
    ON raw.ville = loc.ville AND raw.region = loc.region
LEFT JOIN core.dim_etablissement etab 
    ON raw.id_etablissement = etab.id_etablissement_src
LEFT JOIN core.dim_aliment alim 
    ON raw.type_aliment = alim.type_aliment 
    AND raw.aliment_suspect = alim.aliment_suspect 
    AND raw.categorie_aliment = alim.categorie_aliment
LEFT JOIN core.dim_pathogene path 
    ON raw.agent_pathogene_suspecte = path.agent_pathogene
LEFT JOIN core.dim_patient pat 
    ON raw.age_patient = pat.age_patient 
    AND raw.genre_patient = pat.genre_patient
LEFT JOIN core.dim_symptome_gravite sg 
    ON raw.symptome_principal = sg.symptome_principal 
    AND raw.gravite = sg.gravite
ON CONFLICT (id_cas) DO NOTHING;

-- ==============================================================================
-- C. MAINTENANCE DES STATISTIQUES POUR L'OPTIMISEUR POSTGRESQL
-- ==============================================================================
ANALYZE core.fait_intoxication;
ANALYZE core.dim_temps;
ANALYZE core.dim_localisation;
ANALYZE core.dim_etablissement;
ANALYZE core.dim_aliment;
ANALYZE core.dim_pathogene;
ANALYZE core.dim_patient;
ANALYZE core.dim_symptome_gravite;