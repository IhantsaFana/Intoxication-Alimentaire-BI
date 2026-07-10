
--        ANALYSES SQL — PROJET INTOXICATION ALIMENTAIRE

 
-- 1) VUE GÉNÉRAL

-- Total des cas
SELECT COUNT(*) AS total_cas FROM intoxication;
 
-- Cas par année
SELECT EXTRACT(YEAR FROM date_cas::date) AS annee, COUNT(*) AS nb_cas
FROM intoxication
GROUP BY annee
ORDER BY annee;
 
-- Cas par mois
SELECT EXTRACT(MONTH FROM date_cas::date) AS mois, COUNT(*) AS nb_cas
FROM intoxication
WHERE date_cas IS NOT NULL
GROUP BY mois
ORDER BY mois;
 


-- 2) ANALYSE GÉOGRAPHIQUE

-- Nombre de cas par région
SELECT region, COUNT(*) AS nb_cas
FROM intoxication
GROUP BY region
ORDER BY nb_cas DESC;
 
-- Nombre de cas par ville
SELECT ville, COUNT(*) AS nb_cas
FROM intoxication
GROUP BY ville
ORDER BY nb_cas DESC;
 
-- Villes les plus touchées par les intoxications graves
SELECT ville,
       COUNT(*) AS total_cas,
       SUM(CASE WHEN gravite = 'Critique' THEN 1 ELSE 0 END) AS cas_critiques,
       SUM(CASE WHEN gravite = 'Sévère'   THEN 1 ELSE 0 END) AS cas_severes,
       ROUND(AVG(gravite_score)::numeric, 2) AS gravite_moyenne
FROM intoxication
GROUP BY ville
ORDER BY gravite_moyenne DESC;
 


-- 3) PROFIL DES PERSONNES LES PLUS TOUCHÉES

-- Par genre
SELECT genre_patient, COUNT(*) AS nb_cas,
       ROUND(COUNT(*) * 100.0 / 8000, 2) AS pourcentage
FROM intoxication
GROUP BY genre_patient;
 
-- Âge moyen, min, max
SELECT ROUND(AVG(age_patient)::numeric, 1) AS age_moyen,
       MIN(age_patient) AS age_min,
       MAX(age_patient) AS age_max
FROM intoxication
WHERE age_patient IS NOT NULL;
 
-- Par tranche d'âge
SELECT
    CASE
        WHEN age_patient < 10  THEN '0-9 ans'
        WHEN age_patient < 18  THEN '10-17 ans'
        WHEN age_patient < 30  THEN '18-29 ans'
        WHEN age_patient < 50  THEN '30-49 ans'
        WHEN age_patient < 65  THEN '50-64 ans'
        ELSE '65 ans et plus'
    END AS tranche_age,
    COUNT(*) AS nb_cas,
    ROUND(AVG(gravite_score)::numeric, 2) AS gravite_moyenne
FROM intoxication
WHERE age_patient IS NOT NULL
GROUP BY tranche_age
ORDER BY nb_cas DESC;
 
-- Profil complet (genre + catégorie âge + gravité)
SELECT genre_patient,
    CASE
        WHEN age_patient < 18  THEN 'Mineur'
        WHEN age_patient < 65  THEN 'Adulte'
        ELSE 'Senior'
    END AS categorie_age,
    gravite,
    COUNT(*) AS nb_cas
FROM intoxication
WHERE age_patient IS NOT NULL
GROUP BY genre_patient, categorie_age, gravite
ORDER BY nb_cas DESC
LIMIT 10;
 

-- 4. RÉPARTITION DES CAS SELON LA GRAVITÉ

-- Répartition globale
SELECT gravite, COUNT(*) AS nb_cas,
       ROUND(COUNT(*) * 100.0 / 8000, 2) AS pourcentage
FROM intoxication
GROUP BY gravite, gravite_score
ORDER BY gravite_score DESC;
 
-- Gravité par genre
SELECT genre_patient, gravite, COUNT(*) AS nb_cas
FROM intoxication
GROUP BY genre_patient, gravite
ORDER BY genre_patient, nb_cas DESC;
 
-- Température moyenne par gravité
SELECT gravite,
       ROUND(AVG(temperature_patient)::numeric, 2) AS temp_moyenne
FROM intoxication
WHERE temperature_patient IS NOT NULL
GROUP BY gravite
ORDER BY temp_moyenne DESC;
 
-- Durée moyenne des symptômes par gravité
SELECT gravite,
       ROUND(AVG(duree_symptomes_heures)::numeric, 1) AS duree_moyenne_heures
FROM intoxication
GROUP BY gravite
ORDER BY duree_moyenne_heures DESC;


-- 5. ALIMENTS, MARQUES ET SOURCES LES PLUS IMPLIQUÉS

-- Aliments les plus suspects
SELECT aliment_suspect, COUNT(*) AS nb_cas
FROM intoxication
GROUP BY aliment_suspect
ORDER BY nb_cas DESC;
 
-- Aliments les plus associés aux cas graves
SELECT aliment_suspect,
       COUNT(*) AS total_cas,
       SUM(CASE WHEN gravite IN ('Critique', 'Sévère') THEN 1 ELSE 0 END) AS cas_graves,
       ROUND(AVG(gravite_score)::numeric, 2) AS gravite_moyenne
FROM intoxication
GROUP BY aliment_suspect
ORDER BY gravite_moyenne DESC;
 
-- Type d'aliment le plus dangereux (cas critiques)
SELECT type_aliment, COUNT(*) AS nb_critiques
FROM intoxication
WHERE gravite = 'Critique'
GROUP BY type_aliment
ORDER BY nb_critiques DESC;
 
-- Marques les plus impliquées
SELECT marque_aliment, COUNT(*) AS nb_cas
FROM intoxication
GROUP BY marque_aliment
ORDER BY nb_cas DESC;
 
-- Sources alimentaires les plus impliquées
SELECT source_alimentaire, COUNT(*) AS nb_cas,
       ROUND(AVG(gravite_score)::numeric, 2) AS gravite_moyenne
FROM intoxication
GROUP BY source_alimentaire
ORDER BY nb_cas DESC;
 

-- 6. ÉTABLISSEMENTS LES PLUS CONCERNÉS

-- Établissements avec le plus de cas
SELECT nom_etablissement, type_etablissement,
       COUNT(*) AS nb_cas,
       ROUND(AVG(gravite_score)::numeric, 2) AS gravite_moyenne
FROM intoxication
GROUP BY nom_etablissement, type_etablissement
ORDER BY nb_cas DESC;
 
-- Établissements avec le plus de cas critiques
SELECT nom_etablissement, COUNT(*) AS nb_critiques
FROM intoxication
WHERE gravite = 'Critique'
GROUP BY nom_etablissement
ORDER BY nb_critiques DESC;
 
-- Taux de fermeture par type d'établissement
SELECT type_etablissement,
       COUNT(*) AS nb_cas,
       SUM(CASE WHEN fermeture_etablissement THEN 1 ELSE 0 END) AS nb_fermetures,
       ROUND(SUM(CASE WHEN fermeture_etablissement THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS taux_fermeture
FROM intoxication
GROUP BY type_etablissement
ORDER BY taux_fermeture DESC;




-- 8. AGENTS PATHOGÈNES LES PLUS FRÉQUENTS 

-- Agents suspects
SELECT agent_pathogene_suspecte, COUNT(*) AS nb_cas,
       ROUND(COUNT(*) * 100.0 / 8000, 2) AS pourcentage
FROM intoxication
GROUP BY agent_pathogene_suspecte
ORDER BY nb_cas DESC;
 
-- Taux de positivité des 4 tests
SELECT 'Salmonella' AS agent,
    SUM(CASE WHEN salmonella_positif THEN 1 ELSE 0 END) AS nb_positifs,
    ROUND(SUM(CASE WHEN salmonella_positif THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS taux_positivite
FROM intoxication
UNION ALL
SELECT 'E. Coli',
    SUM(CASE WHEN e_coli_positif THEN 1 ELSE 0 END),
    ROUND(SUM(CASE WHEN e_coli_positif THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2)
FROM intoxication
UNION ALL
SELECT 'Listeria',
    SUM(CASE WHEN listeria_positif THEN 1 ELSE 0 END),
    ROUND(SUM(CASE WHEN listeria_positif THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2)
FROM intoxication
UNION ALL
SELECT 'Norovirus',
    SUM(CASE WHEN norovirus_positif THEN 1 ELSE 0 END),
    ROUND(SUM(CASE WHEN norovirus_positif THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2)
FROM intoxication
ORDER BY nb_positifs DESC;
 
-- Nombre moyen de personnes malades par cas
SELECT ROUND(AVG(nombre_personnes_malades)::numeric, 1) AS moy_malades,
       ROUND(AVG(nombre_personnes_exposees)::numeric, 1) AS moy_exposes,
       ROUND(AVG(nombre_personnes_malades * 100.0 / nombre_personnes_exposees)::numeric, 2) AS taux_attaque_moyen
FROM intoxication;
 


-- 9. HÔPITAUX AYANT ACCUEILLI LE PLUS DE PATIENTS

-- Taux d'hospitalisation
SELECT hospitalisation, COUNT(*) AS nb,
       ROUND(COUNT(*) * 100.0 / 8000, 2) AS pourcentage
FROM intoxication
GROUP BY hospitalisation;
 
-- Hôpitaux les plus sollicités
SELECT nom_hopital, COUNT(*) AS nb_patients,
       ROUND(AVG(gravite_score)::numeric, 2) AS gravite_moyenne,
       ROUND(AVG(age_patient)::numeric, 1) AS age_moyen
FROM intoxication
WHERE nom_hopital NOT IN ('Non hospitalisé', 'Inconnu')
GROUP BY nom_hopital
ORDER BY nb_patients DESC;
 

  

-- 10. ÉVALUATION DE L'EFFICACITÉ DES TRAITEMENTS
 
-- Traitement vs durée des symptômes
SELECT traitement_administre,
       COUNT(*) AS nb_cas,
       ROUND(AVG(duree_symptomes_heures)::numeric, 1) AS duree_moyenne_heures,
       ROUND(AVG(gravite_score)::numeric, 2) AS gravite_moyenne
FROM intoxication
GROUP BY traitement_administre
ORDER BY duree_moyenne_heures ASC;
 
-- Médicament vs durée des symptômes
SELECT medicament_administre,
       COUNT(*) AS nb_cas,
       ROUND(AVG(duree_symptomes_heures)::numeric, 1) AS duree_moyenne_heures
FROM intoxication
GROUP BY medicament_administre
ORDER BY duree_moyenne_heures ASC;
 


-- 11. CONTEXTES D'APPARITION (FÊTES, CANTINES, ETC.)
 
SELECT lieu_consommation,
       COUNT(*) AS nb_cas,
       ROUND(COUNT(*) * 100.0 / 8000, 2) AS pourcentage,
       ROUND(AVG(gravite_score)::numeric, 2) AS gravite_moyenne,
       ROUND(AVG(nombre_personnes_malades)::numeric, 1) AS moy_personnes_malades
FROM intoxication
GROUP BY lieu_consommation
ORDER BY nb_cas DESC;
 

-- 12. LIEUX AVEC LE PLUS DE RÉSULTATS D'INSPECTION 

SELECT nom_etablissement, ville, type_etablissement,
       COUNT(*) AS nb_inspections,
       SUM(CASE WHEN resultat_inspection = 'Conforme'               THEN 1 ELSE 0 END) AS conformes,
       SUM(CASE WHEN resultat_inspection = 'Non conforme'           THEN 1 ELSE 0 END) AS non_conformes,
       SUM(CASE WHEN resultat_inspection = 'Partiellement conforme' THEN 1 ELSE 0 END) AS partiellement_conformes,
       SUM(CASE WHEN resultat_inspection = 'En attente'             THEN 1 ELSE 0 END) AS en_attente,
       SUM(CASE WHEN resultat_inspection = 'Non effectuée'          THEN 1 ELSE 0 END) AS non_effectuees
FROM intoxication
WHERE inspection_effectuee = 'Oui'
GROUP BY nom_etablissement, ville, type_etablissement
ORDER BY nb_inspections DESC;
 
-- Résultats globaux des inspections
SELECT resultat_inspection, COUNT(*) AS nb
FROM intoxication
GROUP BY resultat_inspection
ORDER BY nb DESC;
 
-- Mesures prises les plus fréquentes
SELECT mesures_prises, COUNT(*) AS nb
FROM intoxication
GROUP BY mesures_prises
ORDER BY nb DESC;
 


-- 13. DÉTECTION D'ANOMALIES

-- Cas marqués comme anomalies
SELECT COUNT(*) AS nb_anomalies
FROM intoxication
WHERE anomalie = TRUE;
 
-- Anomalies par ville
SELECT ville, COUNT(*) AS nb_anomalies
FROM intoxication
WHERE anomalie = TRUE
GROUP BY ville
ORDER BY nb_anomalies DESC;
 
-- Cas critiques non hospitalisés
SELECT COUNT(*) AS critiques_non_hospitalises
FROM intoxication
WHERE gravite = 'Critique' AND hospitalisation = 'Non';


-- 14 Analyse de Risque

-- Taux d'attaque par aliment (malades/exposés)
SELECT aliment_suspect,
       SUM(nombre_personnes_malades) AS total_malades,
       SUM(nombre_personnes_exposees) AS total_exposes,
       ROUND(SUM(nombre_personnes_malades) * 100.0 /
             NULLIF(SUM(nombre_personnes_exposees), 0), 2) AS taux_attaque
FROM intoxication
GROUP BY aliment_suspect
ORDER BY taux_attaque DESC;

-- Taux d'attaque par lieu de consommation
SELECT lieu_consommation,
       SUM(nombre_personnes_malades) AS total_malades,
       SUM(nombre_personnes_exposees) AS total_exposes,
       ROUND(SUM(nombre_personnes_malades) * 100.0 /
             NULLIF(SUM(nombre_personnes_exposees), 0), 2) AS taux_attaque
FROM intoxication
GROUP BY lieu_consommation
ORDER BY taux_attaque DESC;

-- Taux d'hospitalisation par gravité
SELECT gravite,
       COUNT(*) AS nb_cas,
       SUM(CASE WHEN hospitalisation = 'Oui' THEN 1 ELSE 0 END) AS nb_hospitalises,
       ROUND(SUM(CASE WHEN hospitalisation = 'Oui' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS taux_hospitalisation
FROM intoxication
GROUP BY gravite
ORDER BY gravite_score DESC;

-- Taux d'hospitalisation par tranche d'âge
SELECT
    CASE
        WHEN age_patient < 18  THEN 'Mineur'
        WHEN age_patient < 65  THEN 'Adulte'
        ELSE 'Senior'
    END AS categorie_age,
    COUNT(*) AS nb_cas,
    SUM(CASE WHEN hospitalisation = 'Oui' THEN 1 ELSE 0 END) AS nb_hospitalises,
    ROUND(SUM(CASE WHEN hospitalisation = 'Oui' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS taux_hospitalisation
FROM intoxication
WHERE age_patient IS NOT NULL
GROUP BY categorie_age
ORDER BY taux_hospitalisation DESC;



-- 15. ANALYSES DES SYMPTÔMES

-- Symptôme principal le plus fréquent
SELECT symptome_principal, COUNT(*) AS nb_cas,
       ROUND(COUNT(*) * 100.0 / 8000, 2) AS pourcentage
FROM intoxication
GROUP BY symptome_principal
ORDER BY nb_cas DESC;
 
-- Symptôme principal par gravité
SELECT gravite, symptome_principal, COUNT(*) AS nb_cas
FROM intoxication
GROUP BY gravite, symptome_principal
ORDER BY gravite, nb_cas DESC;
 
-- Durée des symptômes par agent pathogène
SELECT agent_pathogene_suspecte,
       ROUND(AVG(duree_symptomes_heures)::numeric, 1) AS duree_moyenne_heures,
       MIN(duree_symptomes_heures) AS duree_min,
       MAX(duree_symptomes_heures) AS duree_max
FROM intoxication
GROUP BY agent_pathogene_suspecte
ORDER BY duree_moyenne_heures DESC;
 