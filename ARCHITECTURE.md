# 📊 Architecture Détaillée du Datawarehouse

## Schéma Étoile (Star Schema)

```
┌─────────────────────────────────────────────────────────────────────┐
│                        FACT TABLE (Core)                             │
│              ┌──────────────────────────────────┐                    │
│              │   fait_intoxication (~30 col)   │                    │
│              │   - id_cas (PK)                  │                    │
│              │   - id_temps (FK)                │                    │
│              │   - id_localisation (FK)         │                    │
│              │   - id_etablissement_dim (FK)    │                    │
│              │   - id_aliment (FK)              │                    │
│              │   - id_pathogene (FK)            │                    │
│              │   - id_patient (FK)              │                    │
│              │   - id_symptome_gravite (FK)     │                    │
│              │   - Mesures (exposés, malades)   │                    │
│              │   - Indicateurs (hospita., etc.) │                    │
│              └──────────────────────────────────┘                    │
└──────────────────────────────────────────────────────────────────────┘
           │              │              │              │
     ┌─────┴────┐  ┌──────┴──────┐ ┌────┴─────┐  ┌────┴──────┐
     │ dim_temps│  │dim_localisation│dim_établissement│ dim_aliment
     └──────────┘  └──────────────┘ └──────────┘  └───────────┘
     8 colonnes    3 colonnes       5 colonnes    6 colonnes
     
     ┌───────────────┐  ┌────────────┐  ┌──────────────────┐
     │ dim_pathogene │  │ dim_patient│  │dim_symptome_gravité
     └───────────────┘  └────────────┘  └──────────────────┘
     5 colonnes        4 colonnes        3 colonnes
```

## Dimensions Détaillées

### 1. dim_temps
**Calendrier complet pour analyse temporelle**

| Colonne | Type | Description |
|---------|------|-------------|
| id_temps | SERIAL | Clé primaire |
| date_complete | DATE | UNIQUE - Jour calendaire |
| jour | INT | 1-31 |
| mois | INT | 1-12 |
| trimestre | INT | 1-4 |
| annee | INT | Année fiscale |
| saison | VARCHAR | Hiver, Printemps, Été, Automne |
| semaine_annee | INT | 1-53 |

**Index** : PK + UNIQUE(date_complete)

---

### 2. dim_localisation
**Géographie épidémiologique**

| Colonne | Type | Description |
|---------|------|-------------|
| id_localisation | SERIAL | Clé primaire |
| ville | VARCHAR(100) | Municipalité |
| region | VARCHAR(100) | Province |

**Constraint** : UNIQUE(ville, region)  
**Index** : PK + UNIQUE(ville, region) + région seule

**Données** : 12 régions de Madagascar

---

### 3. dim_etablissement
**Lieux de consommation/fabrication**

| Colonne | Type | Description |
|---------|------|-------------|
| id_etablissement_dim | SERIAL | Clé primaire |
| id_etablissement_src | VARCHAR | Identifiant source |
| nom | VARCHAR(255) | Dénomination |
| type | VARCHAR(100) | Restaurant, Marché, Usine, etc. |
| id_localisation | INT | FK → dim_localisation |

**Index** : PK + FK(id_localisation) + nom

**Données** : 16 établissements impliqués

---

### 4. dim_aliment
**Produits alimentaires et catégories**

| Colonne | Type | Description |
|---------|------|-------------|
| id_aliment | SERIAL | Clé primaire |
| type | VARCHAR(100) | Catégorie (viande, fruit, etc.) |
| aliment_suspect | VARCHAR(255) | Aliment spécifique |
| categorie | VARCHAR(100) | Classification |
| marque | VARCHAR(255) | Marque commerciale |
| source | VARCHAR(100) | Provenance |

**Constraint** : UNIQUE(type, aliment_suspect, categorie)  
**Index** : PK + UNIQUE composé + type seul

---

### 5. dim_pathogene
**Agents contaminants testés**

| Colonne | Type | Description |
|---------|------|-------------|
| id_pathogene | SERIAL | Clé primaire |
| agent_pathogene | VARCHAR(100) | UNIQUE - Pathogène (ex: Salmonella) |
| test_salmonella | BOOLEAN | Testé |
| test_e_coli | BOOLEAN | Testé |
| test_listeria | BOOLEAN | Testé |
| test_norovirus | BOOLEAN | Testé |

**Données** : 4 pathogènes majeurs

---

### 6. dim_patient
**Profil démographique des cas**

| Colonne | Type | Description |
|---------|------|-------------|
| id_patient | SERIAL | Clé primaire |
| age | INT | Années (0-120) |
| groupe_age | VARCHAR(50) | Enfant, Adulte, Senior |
| genre | VARCHAR(10) | Homme, Femme |

**Constraint** : UNIQUE(age, genre)  
**Index** : PK + UNIQUE(age, genre) + groupe_age

---

### 7. dim_symptome_gravite
**Classification clinique**

| Colonne | Type | Description |
|---------|------|-------------|
| id_symptome_gravite | SERIAL | Clé primaire |
| symptome_principal | VARCHAR(100) | Diarrhée, Vomissements, etc. |
| gravite | VARCHAR(50) | Léger, Modéré, Grave, Critique |

**Constraint** : UNIQUE(symptome_principal, gravite)  
**Index** : PK + UNIQUE pair + gravité seule

---

## Fact Table : fait_intoxication

### Identifiants & Clés Étrangères (~10 colonnes)

| Colonne | Type | Description |
|---------|------|-------------|
| id_cas | VARCHAR(50) | PK - Identifiant unique du cas |
| id_temps | INT | FK → dim_temps |
| id_localisation | INT | FK → dim_localisation |
| id_etablissement_dim | INT | FK → dim_etablissement |
| id_aliment | INT | FK → dim_aliment |
| id_pathogene | INT | FK → dim_pathogene |
| id_patient | INT | FK → dim_patient |
| id_symptome_gravite | INT | FK → dim_symptome_gravite |

### Mesures (~5 colonnes)

| Colonne | Type | Description |
|---------|------|-------------|
| nombre_personnes_exposees | INT | Taille population risque |
| nombre_personnes_malades | INT | Cas confirmés |
| taux_attaque | DECIMAL | % malades/exposés |
| temperature_patient | DECIMAL | °C moyenne |
| duree_symptomes_heures | INT | Durée clinique |

### Indicateurs (~5 colonnes booléens/énumérés)

| Colonne | Type | Description |
|---------|------|-------------|
| hospitalisation | VARCHAR | Oui/Non |
| inspection_effectuee | VARCHAR | Oui/Non |
| fermeture_etablissement | VARCHAR | Oui/Non |
| anomalie | BOOLEAN | Flag anomalie |

### Traçabilité (~7 colonnes)

| Colonne | Type | Description |
|---------|------|-------------|
| traitement | VARCHAR | Traitement reçu |
| medicament | VARCHAR | Médicaments |
| analyse_laboratoire | VARCHAR | Type analyse |
| resultat_analyse | VARCHAR | Résultat (+/-) |
| source_signalement | VARCHAR | Source découverte |
| mesures_prises | VARCHAR | Actions correctives |
| resultat_inspection | VARCHAR | Résultat visite |

---

## Indexes pour Performance OLAP

### Par Type

| Type | Nombre | Exemples |
|------|--------|----------|
| Primary Keys | 8 | Chaque table |
| Foreign Keys | 7 | fait_intoxication → dimensions |
| Unique Constraints | 7 | Natural keys de dimensions |
| Simple Filters | 8 | region, gravité, année, type_etablissement |
| Measures | 3 | taux_attaque, hospitalisation, anomalie |
| Compound | 2+ | (region, gravité), (annee, region) |
| **TOTAL** | **35+** | |

### Stratégie d'Indexation

```sql
-- FK pour jointures rapides
CREATE INDEX ON core.fait_intoxication(id_temps);
CREATE INDEX ON core.fait_intoxication(id_localisation);
...

-- Filtres courants
CREATE INDEX ON core.dim_localisation(region);
CREATE INDEX ON core.dim_symptome_gravite(gravite);

-- Composés pour requêtes multi-critères
CREATE INDEX ON analytics.v_analyse_geographique(region, gravite);
```

---

## Flux de Données

```
CSV (8000 lignes)
    ↓
[EXTRACT] → df (pandas)
    ↓
[TRANSFORM] (40+ opérations) → df_clean (7981 lignes)
    ↓
[LOAD]
    ├─ staging.intoxication_raw ← 7981 lignes
    │
    ├─ etl-02-load-core.sql
    │   ├─ INSERT INTO dim_temps
    │   ├─ INSERT INTO dim_localisation
    │   ├─ INSERT INTO dim_etablissement
    │   ├─ INSERT INTO dim_aliment
    │   ├─ INSERT INTO dim_pathogene
    │   ├─ INSERT INTO dim_patient
    │   ├─ INSERT INTO dim_symptome_gravite
    │   └─ INSERT INTO fait_intoxication
    │
    └─ etl-03-analytics.sql
        ├─ CREATE VIEW v_kpi_globaux
        ├─ CREATE VIEW v_analyse_temporelle
        ├─ CREATE VIEW v_analyse_geographique
        ├─ CREATE VIEW v_profil_patients
        ├─ CREATE VIEW v_analyse_gravite
        ├─ CREATE VIEW v_aliments_suspects
        ├─ CREATE VIEW v_agents_pathogenes
        ├─ CREATE VIEW v_etablissements_impliques
        ├─ CREATE VIEW v_croisement_region_aliment
        └─ CREATE VIEW v_tableau_bord_inspection
```

---

## Requêtes Analytiques Communes

### 1. Top 5 Aliments à Risque
```sql
SELECT * FROM analytics.v_aliments_suspects 
LIMIT 5;
```

### 2. Tendance Mensuelle
```sql
SELECT annee, mois, nombre_cas, taux_attaque_mensuel 
FROM analytics.v_analyse_temporelle 
ORDER BY annee DESC, mois DESC;
```

### 3. Épidémiologie Régionale
```sql
SELECT region, nombre_cas, taux_gravite 
FROM analytics.v_analyse_geographique 
WHERE nombre_cas > 100
ORDER BY nombre_cas DESC;
```

### 4. Profil des Patients Hospitalisés
```sql
SELECT genre, groupe_age, count_hospitalises 
FROM analytics.v_profil_patients 
WHERE count_hospitalises > 0;
```

### 5. Dashboard KPI Exécutif
```sql
SELECT * FROM analytics.v_kpi_globaux;
```

---

## Cardinalités (Données Réelles)

| Table | Lignes | Clé |
|-------|--------|-----|
| fact_intoxication | 7,981 | id_cas |
| dim_temps | ~150 | date_complete |
| dim_localisation | 12 | ville + région |
| dim_etablissement | 16 | id_etablissement_src |
| dim_aliment | ~50 | type + aliment + categorie |
| dim_pathogene | 4 | agent_pathogene |
| dim_patient | ~500 | age + genre |
| dim_symptome_gravite | ~12 | symptôme + gravité |

---

## Notes d'Optimisation

1. **Star Schema** : Miniaturisation dimensions → jointures rapides
2. **Indexation stratégique** : FK + axes de filtrage courants
3. **Vues matérialisables** : Si requêtes répétitives, créer MATERIALIZED VIEW
4. **Partitionnement** : Si > 1M lignes, partitioner par année/région
5. **Statistics** : ANALYZE après chaque chargement

---

**Dernière MAJ** : 2026-07-10
