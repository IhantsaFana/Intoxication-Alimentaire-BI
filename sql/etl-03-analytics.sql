-- ==============================================================================
-- SCHÉMA ANALYTICS : VUES DÉCISIONNELLES (DATA MARTS VIRTUELS)
-- Vues optimisées pour les outils de DataViz (PowerBI, Metabase, Grafana)
-- ==============================================================================

-- ==============================================================================
-- 1. VUE KPI GLOBAUX (Résumé Exécutif)
-- ==============================================================================
CREATE OR REPLACE VIEW analytics.v_kpi_globaux AS
SELECT 
    COUNT(DISTINCT f.id_cas) AS total_cas,
    SUM(f.nombre_personnes_exposees) AS total_personnes_exposees,
    SUM(f.nombre_personnes_malades) AS total_personnes_malades,
    ROUND(AVG(f.taux_attaque)::numeric, 2) AS taux_attaque_moyen,
    SUM(CASE WHEN f.hospitalisation = 'Oui' THEN 1 ELSE 0 END) AS cas_hospitalises,
    COUNT(DISTINCT f.id_localisation) AS regions_touchees,
    COUNT(DISTINCT f.id_etablissement_dim) AS etablissements_impliques,
    ROUND(SUM(CASE WHEN sg.gravite = 'Critique' THEN 1 ELSE 0 END)::numeric / COUNT(DISTINCT f.id_cas) * 100, 2) AS pourcentage_grave
FROM core.fait_intoxication f
LEFT JOIN core.dim_symptome_gravite sg ON f.id_symptome_gravite = sg.id_symptome_gravite;

-- ==============================================================================
-- 2. VUE ANALYSE TEMPORELLE (Tendances Épidémiologiques)
-- ==============================================================================
CREATE OR REPLACE VIEW analytics.v_analyse_temporelle AS
SELECT 
    t.annee,
    t.trimestre,
    t.mois,
    CASE t.mois 
        WHEN 1 THEN 'Janvier' WHEN 2 THEN 'Février' WHEN 3 THEN 'Mars' 
        WHEN 4 THEN 'Avril' WHEN 5 THEN 'Mai' WHEN 6 THEN 'Juin' 
        WHEN 7 THEN 'Juillet' WHEN 8 THEN 'Août' WHEN 9 THEN 'Septembre' 
        WHEN 10 THEN 'Octobre' WHEN 11 THEN 'Novembre' WHEN 12 THEN 'Décembre'
    END AS nom_mois,
    t.saison,
    COUNT(DISTINCT f.id_cas) AS nombre_cas,
    SUM(f.nombre_personnes_malades) AS total_malades,
    ROUND(AVG(f.taux_attaque)::numeric, 2) AS taux_attaque_mensuel
FROM core.fait_intoxication f
JOIN core.dim_temps t ON f.id_temps = t.id_temps
GROUP BY t.annee, t.trimestre, t.mois, t.saison
ORDER BY t.annee DESC, t.mois DESC;

-- ==============================================================================
-- 3. VUE ANALYSE GÉOGRAPHIQUE (Foyers Épidémiologiques)
-- ==============================================================================
CREATE OR REPLACE VIEW analytics.v_analyse_geographique AS
SELECT 
    loc.region,
    loc.ville,
    COUNT(DISTINCT f.id_cas) AS nombre_cas,
    SUM(f.nombre_personnes_exposees) AS total_exposes,
    SUM(f.nombre_personnes_malades) AS total_malades,
    ROUND(AVG(f.taux_attaque)::numeric, 2) AS taux_attaque_moyen,
    COUNT(DISTINCT f.id_etablissement_dim) AS etablissements_touchees,
    SUM(CASE WHEN sg.gravite = 'Critique' THEN 1 ELSE 0 END) AS cas_graves
FROM core.fait_intoxication f
JOIN core.dim_localisation loc ON f.id_localisation = loc.id_localisation
LEFT JOIN core.dim_symptome_gravite sg ON f.id_symptome_gravite = sg.id_symptome_gravite
GROUP BY loc.region, loc.ville
ORDER BY total_malades DESC;

-- ==============================================================================
-- 4. VUE PROFIL DES PATIENTS (Épidémiologie Démographique)
-- ==============================================================================
CREATE OR REPLACE VIEW analytics.v_profil_patients AS
SELECT 
    pat.genre_patient,
    pat.groupe_age,
    COUNT(DISTINCT f.id_cas) AS nombre_cas,
    ROUND(AVG(pat.age_patient)::numeric, 1) AS age_moyen,
    SUM(CASE WHEN f.hospitalisation = 'Oui' THEN 1 ELSE 0 END) AS cas_hospitalises,
    ROUND(AVG(f.temperature_patient)::numeric, 2) AS temperature_moyenne,
    ROUND(AVG(f.duree_symptomes_heures)::numeric, 1) AS duree_moyenne_symptomes_heures
FROM core.fait_intoxication f
LEFT JOIN core.dim_patient pat ON f.id_patient_dim = pat.id_patient_dim
WHERE pat.genre_patient IS NOT NULL AND pat.groupe_age IS NOT NULL
GROUP BY pat.genre_patient, pat.groupe_age
ORDER BY nombre_cas DESC;

-- ==============================================================================
-- 5. VUE ANALYSE DE GRAVITÉ (Classification Clinique)
-- ==============================================================================
CREATE OR REPLACE VIEW analytics.v_analyse_gravite AS
SELECT 
    sg.symptome_principal,
    sg.gravite,
    COUNT(DISTINCT f.id_cas) AS nombre_cas,
    SUM(f.nombre_personnes_malades) AS total_malades,
    SUM(CASE WHEN f.hospitalisation = 'Oui' THEN 1 ELSE 0 END) AS cas_hospitalises,
    ROUND(SUM(CASE WHEN f.hospitalisation = 'Oui' THEN 1 ELSE 0 END)::numeric / COUNT(DISTINCT f.id_cas) * 100, 2) AS taux_hospitalisation_pct,
    ROUND(AVG(f.temperature_patient)::numeric, 2) AS temperature_moyenne,
    ROUND(AVG(f.duree_symptomes_heures)::numeric, 1) AS duree_moyenne_heures
FROM core.fait_intoxication f
LEFT JOIN core.dim_symptome_gravite sg ON f.id_symptome_gravite = sg.id_symptome_gravite
WHERE sg.symptome_principal IS NOT NULL AND sg.gravite IS NOT NULL
GROUP BY sg.symptome_principal, sg.gravite
ORDER BY nombre_cas DESC;

-- ==============================================================================
-- 6. VUE ALIMENTS SUSPECTS (Analyse de Produit)
-- ==============================================================================
CREATE OR REPLACE VIEW analytics.v_aliments_suspects AS
SELECT 
    alim.type_aliment,
    alim.aliment_suspect,
    alim.categorie_aliment,
    alim.marque_aliment,
    alim.source_alimentaire,
    COUNT(DISTINCT f.id_cas) AS nombre_intoxications,
    SUM(f.nombre_personnes_malades) AS total_malades,
    ROUND(AVG(f.taux_attaque)::numeric, 2) AS taux_attaque_moyen,
    COUNT(DISTINCT f.id_localisation) AS regions_affectees,
    RANK() OVER (ORDER BY COUNT(DISTINCT f.id_cas) DESC) AS rang_risque
FROM core.fait_intoxication f
LEFT JOIN core.dim_aliment alim ON f.id_aliment = alim.id_aliment
WHERE alim.aliment_suspect IS NOT NULL
GROUP BY alim.type_aliment, alim.aliment_suspect, alim.categorie_aliment, alim.marque_aliment, alim.source_alimentaire
ORDER BY nombre_intoxications DESC;

-- ==============================================================================
-- 7. VUE AGENTS PATHOGÈNES (Microbiologie)
-- ==============================================================================
CREATE OR REPLACE VIEW analytics.v_agents_pathogenes AS
SELECT 
    path.agent_pathogene,
    COUNT(DISTINCT f.id_cas) AS nombre_cas_suspects,
    SUM(f.nombre_personnes_malades) AS total_malades,
    COUNT(DISTINCT f.id_aliment) AS aliments_impliques,
    COUNT(DISTINCT f.id_etablissement_dim) AS etablissements_impliques,
    ROUND(AVG(f.temperature_patient)::numeric, 2) AS temperature_moyenne,
    ROUND(AVG(f.duree_symptomes_heures)::numeric, 1) AS duree_moyenne_heures
FROM core.fait_intoxication f
LEFT JOIN core.dim_pathogene path ON f.id_pathogene = path.id_pathogene
WHERE path.agent_pathogene IS NOT NULL AND path.agent_pathogene != ''
GROUP BY path.agent_pathogene
ORDER BY nombre_cas_suspects DESC;

-- ==============================================================================
-- 8. VUE ÉTABLISSEMENTS IMPLIQUÉS (Traçabilité Source)
-- ==============================================================================
CREATE OR REPLACE VIEW analytics.v_etablissements_impliques AS
SELECT 
    etab.nom_etablissement,
    etab.type_etablissement,
    loc.ville,
    loc.region,
    COUNT(DISTINCT f.id_cas) AS nombre_intoxications,
    SUM(f.nombre_personnes_malades) AS total_malades,
    ROUND(AVG(f.taux_attaque)::numeric, 2) AS taux_attaque_moyen,
    SUM(CASE WHEN f.inspection_effectuee = 'Oui' THEN 1 ELSE 0 END) AS inspections_effectuees,
    SUM(CASE WHEN f.fermeture_etablissement = 'Oui' THEN 1 ELSE 0 END) AS fermetures,
    ROUND(SUM(CASE WHEN f.fermeture_etablissement = 'Oui' THEN 1 ELSE 0 END)::numeric / COUNT(DISTINCT f.id_cas) * 100, 2) AS taux_fermeture_pct
FROM core.fait_intoxication f
LEFT JOIN core.dim_etablissement etab ON f.id_etablissement_dim = etab.id_etablissement_dim
LEFT JOIN core.dim_localisation loc ON f.id_localisation = loc.id_localisation
WHERE etab.nom_etablissement IS NOT NULL
GROUP BY etab.nom_etablissement, etab.type_etablissement, loc.ville, loc.region
ORDER BY total_malades DESC;

-- ==============================================================================
-- 9. VUE CROISSEMENT RÉGION × ALIMENT (Analyse Locale)
-- ==============================================================================
CREATE OR REPLACE VIEW analytics.v_croisement_region_aliment AS
SELECT 
    loc.region,
    alim.categorie_aliment,
    COUNT(DISTINCT f.id_cas) AS nombre_cas,
    SUM(f.nombre_personnes_malades) AS total_malades,
    ROUND(AVG(f.taux_attaque)::numeric, 2) AS taux_attaque
FROM core.fait_intoxication f
LEFT JOIN core.dim_localisation loc ON f.id_localisation = loc.id_localisation
LEFT JOIN core.dim_aliment alim ON f.id_aliment = alim.id_aliment
WHERE loc.region IS NOT NULL AND alim.categorie_aliment IS NOT NULL
GROUP BY loc.region, alim.categorie_aliment
ORDER BY nombre_cas DESC;

-- ==============================================================================
-- 10. VUE TABLEAU DE BORD INSPECTION (Suivi Sanitaire)
-- ==============================================================================
CREATE OR REPLACE VIEW analytics.v_tableau_bord_inspection AS
SELECT 
    COUNT(DISTINCT f.id_cas) AS total_cas,
    SUM(CASE WHEN f.inspection_effectuee = 'Oui' THEN 1 ELSE 0 END) AS inspections_effectuees,
    ROUND(SUM(CASE WHEN f.inspection_effectuee = 'Oui' THEN 1 ELSE 0 END)::numeric / COUNT(DISTINCT f.id_cas) * 100, 2) AS taux_inspection_pct,
    SUM(CASE WHEN f.fermeture_etablissement = 'Oui' THEN 1 ELSE 0 END) AS etablissements_fermes,
    SUM(CASE WHEN f.hospitalisation = 'Oui' THEN 1 ELSE 0 END) AS personnes_hospitalisees,
    COUNT(DISTINCT CASE WHEN f.anomalie = true THEN f.id_cas END) AS cas_avec_anomalie
FROM core.fait_intoxication f;