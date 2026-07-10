# 📊 Guide Power BI pour débuter avec votre projet Intoxication Alimentaire

Ce document explique simplement ce qu'il faut faire pour utiliser Power BI avec la base PostgreSQL déjà créée.

Il est pensé pour un débutant qui ne connaît rien à Power BI.

---

## 1. Qu'est-ce que Power BI ?

Power BI est un outil Microsoft qui permet de créer des tableaux de bord interactifs à partir de données.

Avec Power BI, vous pouvez :
- connecter une base de données,
- importer ou lire des données,
- créer des graphiques,
- filtrer les données,
- partager des tableaux de bord.

Dans votre projet, la base de données PostgreSQL contient déjà les données nettoyées et organisées. Power BI va servir à transformer ces données en tableaux de bord faciles à lire.

---

## 2. Modélisation des Données dans PowerBI

La modélisation des données, c'est l'étape où on organise les données avant de créer les graphiques.

### 2.1. Comprendre le rôle de la modélisation

Avant de faire des graphiques, il faut répondre à cette question :

- Quelles données devons-nous afficher ?
- Quels filtres les utilisateurs vont-ils utiliser ?
- Quelles relations doivent exister entre les données ?

Sans modélisation, les graphiques peuvent être incompréhensibles ou incorrects.

### 2.2. Ce que vous allez importer dans Power BI

À partir de la base PostgreSQL, vous allez utiliser les vues créées dans le schéma `analytics`.

Ces vues correspondent déjà à des requêtes prêtes à l'emploi pour l'analyse.

Exemples de vues à utiliser :
- `v_kpi_globaux` : pour les indicateurs clés
- `v_analyse_temporelle` : pour les tendances dans le temps
- `v_analyse_geographique` : pour les régions touchées
- `v_aliments_suspects` : pour les aliments à risque
- `v_agents_pathogenes` : pour les agents pathogènes
- `v_profil_patients` : pour les profils des patients
- `v_analyse_gravite` : pour la gravité des cas
- `v_etablissements_impliques` : pour les établissements concernés
- `v_croisement_region_aliment` : pour les combinaisons région/aliment
- `v_tableau_bord_inspection` : pour les inspections

### 2.3. Étapes simples pour importer les données

1. Ouvrir Power BI Desktop.
2. Cliquer sur “Obtenir des données”.
3. Choisir “Base de données PostgreSQL”.
4. Entrer :
   - le nom du serveur : `localhost`
   - le nom de la base : `intoxication_bi`
   - l’utilisateur : `postgres`
   - le mot de passe : celui défini dans votre `.env`
5. Choisir le schéma `analytics`.
6. Charger les vues nécessaires.

### 2.4. Comprendre les tables dans Power BI

Après importation, Power BI affiche généralement des tables.

Chaque table correspond à une vue PostgreSQL.

Par exemple :
- une table `v_kpi_globaux` contient les KPI globaux,
- une table `v_analyse_geographique` contient les données par région,
- une table `v_aliments_suspects` contient les aliments à risque.

### 2.5. Vérifier les types de données

Il faut vérifier que chaque colonne a le bon type.

Exemples :
- une colonne de nombres doit être définie en “Nombre”,
- une colonne de texte doit être “Texte”,
- une colonne de date doit être “Date”.

Si un type est mal défini, les graphiques peuvent être faux.

### 2.6. Les relations entre tables

En Power BI, les relations servent à relier les données entre elles.

Par exemple :
- une table “Régions” peut être liée à une table “Cas”,
- une table “Aliments” peut être liée à une table “Cas”,
- une table “Temps” peut être liée à une table “Cas”.

Mais dans votre cas, vous pouvez aussi commencer de façon simple :
- utiliser une seule table plate si vous voulez aller vite,
- ou utiliser plusieurs vues si vous voulez faire un modèle plus propre.

### 2.7. Recommandation simple pour débuter

Pour un débutant, la meilleure approche est :

- importer les vues nécessaires,
- vérifier les colonnes,
- utiliser une seule table plate pour les premiers tableaux de bord,
- puis améliorer le modèle plus tard.

Cette approche est plus simple à comprendre.

### 2.8. Les notions importantes à apprendre

Voici les concepts essentiels à retenir :

- Table : ensemble de données importées.
- Colonne : une variable (par exemple région, âge, cas).
- Mesure : un calcul (par exemple total des cas, moyenne, pourcentage).
- Filtre : permet de restreindre les données affichées.
- Visualisation : un graphique, une carte ou un tableau.

### 2.9. Exemple concret de modélisation simple

Supposons que vous voulez créer un tableau de bord sur les cas par région.

Vous pouvez :
- importer la table `v_analyse_geographique`,
- utiliser la colonne `region` comme axe,
- utiliser la colonne `nombre_cas` comme valeur,
- ajouter un filtre sur `annee` ou `saison` si disponible.

C’est déjà un bon début.

---

## 3. Dashboards Recommandés (5 pages)

Le but d’un tableau de bord est de présenter les informations de façon claire et rapide.

Comme vous débutez, il est conseillé de créer un tableau de bord en 5 pages, chacune ayant un objectif précis.

### 3.1. Page 1 : Tableau de bord exécutif

Cette page sert à donner un aperçu rapide de la situation.

#### À afficher :
- le nombre total de cas,
- le nombre de personnes malades,
- le nombre d’hospitalisations,
- le taux d’attaque,
- les régions les plus touchées.

#### Graphiques recommandés :
- carte des régions,
- graphique en barre pour les cas par région,
- graphique en courbe pour l’évolution dans le temps,
- cartes KPI pour les indicateurs clés.

#### Objectif :
Donner une vue globale en une minute.

### 3.2. Page 2 : Analyse géographique

Cette page permet de voir où les cas sont concentrés.

#### À afficher :
- les régions les plus touchées,
- les villes concernées,
- le nombre de cas par région,
- la gravité des cas selon la zone.

#### Graphiques recommandés :
- carte de Madagascar,
- histogramme par région,
- tableau par ville,
- graphique de gravité par région.

#### Objectif :
Identifier les zones à risque.

### 3.3. Page 3 : Analyse des aliments et des pathogènes

Cette page répond à la question :

- Quels aliments sont suspects ?
- Quels agents pathogènes sont impliqués ?

#### À afficher :
- les aliments les plus suspects,
- les pathogènes les plus fréquents,
- les aliments associés à des cas graves,
- les régions où certains aliments sont plus présents.

#### Graphiques recommandés :
- graphique en barre pour les aliments,
- graphique circulaire ou donut pour les pathogènes,
- graphique en chaleur (heatmap) si possible,
- graphique en barre empilée par région.

#### Objectif :
Repérer les aliments et agents à risque.

### 3.4. Page 4 : Profil des patients et gravité

Cette page permet d’étudier les personnes concernées.

#### À afficher :
- le sexe des patients,
- la catégorie d’âge,
- la gravité des symptômes,
- le nombre d’hospitalisations.

#### Graphiques recommandés :
- graphique en arbre ou treemap,
- graphique en barre pour les groupes d’âge,
- graphique de gravité,
- graphique comparatif hospitalisation vs non hospitalisation.

#### Objectif :
Comprendre le profil des patients et la sévérité des cas.

### 3.5. Page 5 : Inspection et établissements

Cette page permet de voir ce qui se passe côté contrôle et suivi.

#### À afficher :
- les établissements impliqués,
- les inspections effectuées,
- les fermetures d’établissements,
- les anomalies signalées.

#### Graphiques recommandés :
- tableau des établissements,
- graphique des inspections par région,
- graphique des fermetures,
- graphique des anomalies détectées.

#### Objectif :
Suivre les actions de contrôle et la conformité.

---

## 4. Fonctionnalités Avancées (Optionnel)

Une fois que vous avez compris les bases, vous pouvez ajouter des fonctions plus avancées.

### 4.1. Drill-through

Le drill-through permet de cliquer sur un élément dans un graphique pour ouvrir une page plus détaillée.

Exemple :
- vous cliquez sur une région,
- Power BI ouvre une page avec les détails de cette région.

C’est très utile pour explorer les données en profondeur.

### 4.2. Filtres interactifs

Les filtres permettent aux utilisateurs de restreindre les données.

Exemples :
- filtre par région,
- filtre par année,
- filtre par type d’aliment,
- filtre par gravité.

C’est un moyen simple de rendre le tableau de bord dynamique.

### 4.3. Cartes géographiques

Power BI peut afficher des cartes.

Vous pouvez utiliser :
- une carte simple des régions,
- une carte avec bulles,
- une carte plus avancée si vous avez des données géographiques précises.

Cela est très pratique pour montrer où les cas se concentrent.

### 4.4. Mesures DAX

DAX est le langage de calcul dans Power BI.

Il sert à créer des mesures comme :
- total des cas,
- pourcentage d’hospitalisation,
- taux de gravité,
- variation par rapport au mois précédent.

Exemple simple :
- Total des cas = SUM(nombre_cas)
- Taux de gravité = DIVIDE(total_grave, total_cas)

Pour un débutant, vous n’êtes pas obligé d’utiliser DAX tout de suite.

### 4.5. Rapports exportables

Power BI peut exporter les données ou les rapports en PDF ou en Excel.

Cela est utile si vous devez partager les résultats avec des personnes qui n’utilisent pas Power BI.

### 4.6. Mise à jour automatique

Une fois le tableau de bord prêt, vous pouvez faire en sorte que les données se rafraîchissent automatiquement depuis PostgreSQL.

C’est important pour garder le dashboard à jour.

---

## 5. Conseils pratiques pour débuter

### Commencer petit
Ne cherchez pas à faire un dashboard parfait dès le début.

Commencez par :
1. une page d’accueil,
2. un graphique par région,
3. un graphique par mois,
4. un tableau des aliments suspects.

### Utiliser des visuels simples
Pour débuter, privilégiez :
- graphiques en barre,
- cartes,
- graphiques en ligne,
- cartes KPI.

### Éviter la surcharge
Un tableau de bord trop chargé est difficile à lire.

Il vaut mieux :
- peu de graphiques par page,
- couleurs cohérentes,
- titres clairs,
- filtres utiles.

### Tester avec de vraies données
Après chaque ajout de graphique, vérifiez si :
- le résultat est logique,
- les totaux correspondent à la base,
- les filtres fonctionnent correctement.

---

## 6. Plan de progression recommandé

### Étape 1 : Se connecter à la base
- installer Power BI Desktop,
- se connecter à PostgreSQL,
- importer les vues analytics.

### Étape 2 : Créer une première page
- afficher les KPI globaux,
- ajouter un graphique par région,
- ajouter un graphique par mois.

### Étape 3 : Ajouter les autres pages
- page géographique,
- page aliments/pathogènes,
- page patients/gravité,
- page inspections.

### Étape 4 : Ajouter les filtres
- région,
- mois,
- type d’aliment,
- gravité.

### Étape 5 : Publier et partager
- publier le fichier `.pbix`,
- partager avec l’équipe,
- utiliser le dashboard en réunion.

---

## 7. Résumé

Pour un débutant, voici la logique à suivre :

1. connecter Power BI à PostgreSQL,
2. importer les vues analytics,
3. vérifier les types de colonnes,
4. créer une première page simple,
5. ajouter peu à peu les graphiques,
6. améliorer le design et les interactions.

Le plus important n’est pas de faire un dashboard parfait tout de suite, mais de commencer avec des visuels simples, utiles et compréhensibles.
