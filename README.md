# 🏥 Intoxication Alimentaire - Business Intelligence

Datawarehouse épidémiologique pour l'analyse des intoxications alimentaires à Madagascar.

## 📋 Architecture

### Modèle en Étoile (Star Schema)

```
                      ┌─── dim_temps
                      │
                      ├─── dim_localisation
                      │
                      ├─── dim_etablissement
    fait_intoxication ┤
                      ├─── dim_aliment
                      │
                      ├─── dim_pathogene
                      │
                      ├─── dim_patient
                      │
                      └─── dim_symptome_gravite
```

### Schémas PostgreSQL

| Schéma | Rôle | Contenu |
|--------|------|---------|
| **staging** | Zone d'import brut | Table `intoxication_raw` (51 colonnes) |
| **core** | Modèle en étoile | 8 dimensions + 1 table de faits |
| **analytics** | Couche de présentation | 10 vues décisionnelles |

## 🗂️ Structure du Projet

```
Intoxication-Alimentaire-BI/
├── dataset/
│   └── data_intoxication.csv          # Données brutes (8000 lignes)
├── etl/
│   ├── extract.py                     # Lecture du CSV
│   ├── transform.py                   # Nettoyage & transformation (40+ opérations)
│   ├── load.py                        # Chargement PostgreSQL + SQL execution
│   └── main.py                        # Orchestration du pipeline
├── sql/
│   ├── etl-01-schema.sql              # DDL: Schémas, tables, indexes (25+)
│   ├── etl-02-load-core.sql           # DML: Population des dimensions + fact
│   ├── etl-03-analytics.sql           # DDL: 10 vues décisionnelles
│   └── analyse_données.sql            # Requêtes d'exploration
├── .env                               # Configuration (variables d'environnement)
├── .env.example                       # Template de configuration
└── README.md                          # Cette documentation
```

## ⚙️ Installation & Configuration

### 1. Prérequis

- Python 3.8+
- PostgreSQL 12+
- pip ou virtualenv

### 2. Installation de l'environnement

```bash
# Créer l'environnement virtuel
python -m venv .venv

# Activer l'environnement
.venv\Scripts\activate  # Windows
source .venv/bin/activate  # Linux/Mac

# Installer les dépendances
pip install -r requirements.txt
```

### 3. Configuration PostgreSQL

Créer la base de données :

```sql
CREATE DATABASE intoxication_bi;
```

Configurer les variables d'environnement dans `.env` :

```env
INPUT_FILE=./dataset/data_intoxication.csv
OUTPUT_FILE=./output/data_intoxication_nettoyee.csv
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DATABASE=intoxication_bi
```

## 🚀 Exécution du Pipeline

### Lancer le pipeline complet

```bash
python .\etl\main.py
```

**Séquence d'exécution** :

1. **EXTRACT** : Lecture du CSV (8000 lignes)
2. **TRANSFORM** : Nettoyage & enrichissement (7981 lignes après validation)
3. **LOAD** :
   - Création des schémas & tables
   - Chargement vers `staging.intoxication_raw`
   - Exécution de `etl-02-load-core.sql` (population dimensions + fact)
   - Exécution de `etl-03-analytics.sql` (création vues)

**Résultat attendu** :

```
[SUCCESS] Le pipeline ETL s'est exécuté de bout en bout.
[SUCCESS] Fichier de sortie : PostgreSQL
```

## 📊 Vues Décisionnelles (Analytics)

### 10 Vues pour la BI

```sql
-- KPIs Exécutifs
SELECT * FROM analytics.v_kpi_globaux;

-- Tendances Temporelles
SELECT * FROM analytics.v_analyse_temporelle;

-- Géographie Épidémiologique
SELECT * FROM analytics.v_analyse_geographique;

-- Profil des Patients
SELECT * FROM analytics.v_profil_patients;

-- Analyse de Gravité
SELECT * FROM analytics.v_analyse_gravite;

-- Aliments à Risque
SELECT * FROM analytics.v_aliments_suspects;

-- Distribution des Pathogènes
SELECT * FROM analytics.v_agents_pathogenes;

-- Établissements Impliqués
SELECT * FROM analytics.v_etablissements_impliques;

-- Analyse Région × Aliment
SELECT * FROM analytics.v_croisement_region_aliment;

-- Dashboard Inspection
SELECT * FROM analytics.v_tableau_bord_inspection;
```

## 🔍 Transformation des Données

### 40+ Opérations de Nettoyage

**Validation & Détection** :
- ✅ Vérification des doublons (0 détecté)
- ✅ Analyse des valeurs manquantes
- ✅ Détection des outliers (IQR)

**Imputation** :
- Symptômes vides → "Non spécifié"
- Champs hôpital vides → "À vérifier"

**Normalisation Textuelle** :
- Suppression espaces (23 colonnes)
- Conversion casse (MAJUSCULES, minuscules)
- Standardisation des énumérations

**Conversions de Type** :
- DateTime : `date_cas`, `date_achat`, `date_consomation`, `date_declaration`
- Time : `heure_cas`, `heure_consomation`
- Numériques : `age`, `temperature`, durées

**Validation Métier** :
- Âge : 0-120 ans
- Température : 35-42°C
- Exposition/maladie : counts ≥ 0
- Région via mapping ville→région (12 villes)

**Enrichissement** :
- Calcul `taux_attaque` = malades / exposés
- Catégorisation `groupe_age` : Enfant, Adulte, Senior
- Extraction composants DATE : jour, mois, année, trimestre, saison

## 📈 Statistiques du Dataset

| Métrique | Valeur |
|----------|--------|
| Cas entrée | 8,000 |
| Cas valides | 7,981 |
| Cas supprimés | 19 (date_cas manquante) |
| Colonnes brutes | 50 |
| Colonnes enrichies | 52 |
| Régions | 12 |
| Établissements | 16 |
| Pathogènes testés | 4 (Salmonelle, E.coli, Listeria, Norovirus) |

**KPIs Globaux** :
- Taux d'attaque moyen : **49.81%**
- Taux de gravité (Critique) : **24.28%**
- Personnes exposées : **203,595**
- Personnes malades : **89,241**
- Hospitalisations : **3,968 cas**

## 🗄️ Schéma de Base de Données

### Tables du Schéma Core

#### Dimensions

**dim_temps**
- Calendrier complet avec jour/mois/année/trimestre/saison
- Clé : `id_temps`
- UNIQUE : `date_complete`

**dim_localisation**
- Géographie (ville, région)
- Clé : `id_localisation`
- UNIQUE : ville + région

**dim_etablissement**
- Établissements alimentaires
- Clé : `id_etablissement_dim`
- FK vers `dim_localisation`

**dim_aliment**
- Produits alimentaires suspects
- Clé : `id_aliment`
- UNIQUE : type + suspect + catégorie

**dim_pathogene**
- Agents contaminants (Salmonelle, E.coli, etc.)
- Clé : `id_pathogene`
- UNIQUE : `agent_pathogene`

**dim_patient**
- Démographie des patients
- Clé : `id_patient`
- UNIQUE : âge + genre

**dim_symptome_gravite**
- Symptômes principals et gravité
- Clé : `id_symptome_gravite`
- UNIQUE : symptôme + gravité

#### Fact Table

**fait_intoxication** (~30 colonnes)
- Clé : `id_cas` (VARCHAR)
- FKs : Toutes les 7 dimensions
- Mesures : nombre_exposés, nombre_malades, taux_attaque, température
- Indicateurs : hospitalisation, inspection, fermeture, anomalie
- Traçabilité : traitement, médicament, analyse, résultat, signalement

### Indexes (25+)

| Type | Nombre | Détail |
|------|--------|--------|
| FK | 7 | Fact → chaque dimension |
| Colonnes simples | 8 | Filtres courants (région, gravité, etc.) |
| Mesures/Indicateurs | 3 | taux_attaque, hospitalisation, anomalie |
| Composés | 2+ | region + gravité, temps + région |

## 🔧 Scripts SQL

### `etl-01-schema.sql` (~400 lignes)

Crée l'architecture complète :
- 3 schémas (staging, core, analytics)
- 1 table staging
- 8 dimensions + 1 fact table
- 25+ indexes
- Constraints d'intégrité

### `etl-02-load-core.sql` (~150 lignes)

Remplissage du datawarehouse :
- INSERT DISTINCT sur chaque dimension (idempotent)
- Jointure sur clés naturelles pour resolution d'IDs
- LEFT JOINs (tolérance aux NULLs)
- ANALYZE pour optimisation

### `etl-03-analytics.sql` (~250 lignes)

Vues pour la BI :
- 10 vues avec LEFT JOINs pour sécurité
- RANK() OVER pour classements
- ROUND() pour lisibilité
- Agrégations et CASE WHEN pour calculs

## 🐍 Modules Python

### `extract.py`

```python
def extraire_donnees(chemin_fichier=None) -> pd.DataFrame
```

Lit le CSV brut depuis `dataset/`.

### `transform.py`

```python
def transformer_donnees(df: pd.DataFrame) -> pd.DataFrame
```

Pipelines de nettoyage et validation (~9600 bytes).

Fonctions helpers :
- `check_duplicates()` - Détection doublons
- `check_missing_values()` - Analyse NULLs
- `check_outliers()` - Détection IQR

### `load.py`

```python
def charger_donnees_postgresql(df, config, output_path)
```

Charge directement dans PostgreSQL + exécute SQL + fallback CSV.

### `main.py`

Orchestration ETL avec variables `.env` :
- Charge config depuis `.env`
- Execute extract → transform → load
- Affiche logs structurés `[STAGE]`

## 📡 Intégration BI

### PowerBI

```
Data Source: PostgreSQL
- Host: localhost
- Database: intoxication_bi
- Query Tables from: analytics schema
```

### Metabase

```
Setup Database Connection → PostgreSQL
→ Select Tables from analytics schema
→ Create Dashboards from v_* views
```

### Grafana

```
Data Source: PostgreSQL
Queries: SELECT * FROM analytics.v_*
```

## 🔄 Fallback CSV

Si PostgreSQL indisponible, le pipeline sauvegarde automatiquement en CSV :

```
output/data_intoxication_nettoyee.csv
```

## 📝 Logs

Les logs sont affichés en console avec préfixe de stage :

```
[CONFIG]    - Lecture configuration
[EXTRACT]   - Extraction des données
[TRANSFORM] - Transformation & nettoyage
[LOAD]      - Chargement PostgreSQL
[SUCCESS]   - Exécution réussie
```

## 🐛 Troubleshooting

### Erreur de connexion PostgreSQL

```
Vérifier : .env (credentials) et PostgreSQL est running
```

### Données manquantes dans PostgreSQL

```
Exécuter : \dt staging.*; \dt core.*; \dv analytics.*;
```

### Vues non créées

```
Vérifier : etl-03-analytics.sql dans le répertoire sql/
```

## 📚 Ressources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Star Schema Design](https://en.wikipedia.org/wiki/Star_schema)
- [Python ETL Patterns](https://pandas.pydata.org/)
