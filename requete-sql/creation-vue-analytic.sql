-- ==============================================================================
-- SCHÉMA ANALYTICS : VUES DÉCISIONNELLES (DATA MARTS VIRTUELS)
-- Ces vues simplifient l'accès aux données pour les outils de DataViz (PowerBI, Metabase)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. VUE : KPI GLOBAUX (Résumé Exécutif)
-- Objectif : Alimenter les cartes de scores (Scorecards) en haut d'un dashboard.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW analytics.v_kpi_globaux AS
SELECT 
    SUM(f.montant_total) AS chiffre_affaires_total,               -- CA Global cumulé
    SUM(f.quantite_vendue) AS total_articles_vendus,              -- Volume total de pièces vendues
    COUNT(DISTINCT f.id_facture) AS nombre_total_commandes,       -- Nombre total de transactions uniques
    
    -- Calcul du Panier Moyen : Chiffre d'Affaires / Nombre de factures uniques
    ROUND(SUM(f.montant_total) / COUNT(DISTINCT f.id_facture), 2) AS panier_moyen_global,
    
    COUNT(DISTINCT p.id_produit) AS catalogue_articles_actifs,    -- Nombre de références produits vendues
    COUNT(DISTINCT m.id_magasin) AS nombre_magasins               -- Nombre total de points de vente actifs
FROM core.fait_ventes f
JOIN core.dim_produit p ON f.id_produit = p.id_produit
JOIN core.dim_magasin m ON f.id_magasin = m.id_magasin;


-- ------------------------------------------------------------------------------
-- 2. VUE : ANALYSE TEMPORELLE (Courbes et Saisonnalité)
-- Objectif : Étudier les tendances commerciales et la saisonnalité mois par mois.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW analytics.v_analyse_temporelle AS
SELECT 
    t.annee,
    t.trimestre,
    t.mois,
    -- Traduction des numéros de mois en texte pour faciliter l'affichage des axes graphiques
    CASE t.mois 
        WHEN 1 THEN 'Janvier' WHEN 2 THEN 'Février' WHEN 3 THEN 'Mars' 
        WHEN 4 THEN 'Avril' WHEN 5 THEN 'Mai' WHEN 6 THEN 'Juin' 
        WHEN 7 THEN 'Juillet' WHEN 8 THEN 'Août' WHEN 9 THEN 'Septembre' 
        WHEN 10 THEN 'Octobre' WHEN 11 THEN 'Novembre' WHEN 12 THEN 'Décembre'
    END AS nom_mois,
    SUM(f.montant_total) AS chiffre_affaires,                     -- CA mensuel
    SUM(f.quantite_vendue) AS quantites_vendues,                  -- Quantités mensuelles
    COUNT(DISTINCT f.id_facture) AS nombre_factures                -- Volume de ventes par mois
FROM core.fait_ventes f
JOIN core.dim_temps t ON f.id_temps = t.id_temps
GROUP BY t.annee, t.trimestre, t.mois
ORDER BY t.annee, t.mois;


-- ------------------------------------------------------------------------------
-- 3. VUE : PALMARÈS PRODUITS (Top / Flop & Analyse de Performance)
-- Objectif : Identifier les produits vedettes et classer les articles dans leur catégorie.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW analytics.v_palmares_produits AS
SELECT 
    p.famille_produit,
    p.description_article,
    SUM(f.quantite_vendue) AS total_quantite_vendue,              -- Quantité totale écoulée par article
    SUM(f.montant_total) AS total_chiffre_affaires,               -- CA total généré par l'article
    ROUND(AVG(f.prix_unitaire_brut), 2) AS prix_moyen_pratique,   -- Prix unitaire moyen appliqué
    
    -- Fonction de fenêtrage (Window Function) : Classe les articles par CA au sein de chaque famille
    RANK() OVER (PARTITION BY p.famille_produit ORDER BY SUM(f.montant_total) DESC) AS rang_dans_famille
FROM core.fait_ventes f
JOIN core.dim_produit p ON f.id_produit = p.id_produit
GROUP BY p.famille_produit, p.description_article;


-- ------------------------------------------------------------------------------
-- 4. VUE : PERFORMANCE DES VILLES (Analyse Géographique)
-- Objectif : Représenter les performances par région ou point de vente (Cartes/Maps).
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW analytics.v_performance_villes AS
SELECT 
    m.magasin_ville,
    SUM(f.montant_total) AS chiffre_affaires,                     -- CA total réalisé par ville
    SUM(f.quantite_vendue) AS total_pieces,                       -- Nombre d'articles vendus par ville
    COUNT(DISTINCT f.id_facture) AS volume_clients,               -- Nombre de passages en caisse uniques
    -- Calcul du Panier Moyen spécifique à chaque magasin
    ROUND(SUM(f.montant_total) / COUNT(DISTINCT f.id_facture), 2) AS panier_moyen_ville
FROM core.fait_ventes f
JOIN core.dim_magasin m ON f.id_magasin = m.id_magasin
GROUP BY m.magasin_ville;


-- ------------------------------------------------------------------------------
-- 5. VUE : CROISEMENT PRODUIT par VILLE (Matrice / Tableaux Croisés)
-- Objectif : Analyser les préférences locales (ex : "Quel type de produit se vend le mieux à Paris ?")
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW analytics.v_croisement_produit_ville AS
SELECT 
    m.magasin_ville,
    p.famille_produit,
    SUM(f.quantite_vendue) AS quantite_vendue,                    -- Volume vendu par couple (Ville, Famille)
    SUM(f.montant_total) AS chiffre_affaires                      -- CA généré par couple (Ville, Famille)
FROM core.fait_ventes f
JOIN core.dim_produit p ON f.id_produit = p.id_produit
JOIN core.dim_magasin m ON f.id_magasin = m.id_magasin
GROUP BY m.magasin_ville, p.famille_produit;


-- ------------------------------------------------------------------------------
-- 6. VUE : DISTRIBUTION DES COMMANDES (Segmentation Comportementale)
-- Objectif : Analyser l'envergure des achats pour comprendre la typologie de commande.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW analytics.v_distribution_commandes AS
SELECT 
    f.id_facture,
    m.magasin_ville,
    SUM(f.quantite_vendue) AS total_articles_facture,             -- Nombre d'articles sur la facture
    SUM(f.montant_total) AS montant_total_facture,                -- Montant total TTC de la facture
    
    -- Segmentation dynamique basée sur le volume d'articles achetés
    CASE 
        WHEN SUM(f.quantite_vendue) <= 2 THEN 'Petite commande (1-2 art.)'
        WHEN SUM(f.quantite_vendue) <= 5 THEN 'Commande Moyenne (3-5 art.)'
        ELSE 'Grosse commande (6+ art.)'
    END AS segment_taille_commande
FROM core.fait_ventes f
JOIN core.dim_magasin m ON f.id_magasin = m.id_magasin
GROUP BY f.id_facture, m.magasin_ville;