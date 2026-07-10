# 📋 Prochaines Étapes - Intoxication Alimentaire BI

**Statut actuel** : Pipeline ETL ✅ | Datawarehouse ✅ | PostgreSQL ✅  
**Prochaine phase** : Dashboards PowerBI

---

## 🎯 Phase 2 : Dashboards PowerBI

### 1. Configuration PowerBI (Connexion à PostgreSQL)

**Objectif** : Connecter PowerBI à la base PostgreSQL  
**Responsabilité** : Business Analyst / BI Developer  
**Durée estimée** : 30 min

#### Étapes :
1. [ ] Ouvrir PowerBI Desktop
2. [ ] Menu `Get Data` → `PostgreSQL database`
3. [ ] Remplir les paramètres :
   - **Server** : `localhost`
   - **Database** : `intoxication_bi`
   - **User** : `postgres`
   - **Password** : `postgres` (voir `.env`)
4. [ ] Sélectionner le schéma `analytics`
5. [ ] Charger les 10 vues :
   - `v_kpi_globaux`
   - `v_analyse_temporelle`
   - `v_analyse_geographique`
   - `v_profil_patients`
   - `v_analyse_gravite`
   - `v_aliments_suspects`
   - `v_agents_pathogenes`
   - `v_etablissements_impliques`
   - `v_croisement_region_aliment`
   - `v_tableau_bord_inspection`

**Fichier de référence** : `ARCHITECTURE.md` → Section "Vues Décisionnelles"

---

### 2. Modélisation des Données dans PowerBI

**Objectif** : Organiser les données pour une exploration fluide  
**Responsabilité** : Data Analyst  
**Durée estimée** : 1-2 heures

#### Tâches :

**A. Créer les tables (depuis les vues PostgreSQL)**
- [ ] Importer toutes les 10 vues analytics
- [ ] Nommer clairement chaque table
- [ ] Configurer le type de données

**B. Gérer les relations (si export plat)**
- [ ] Si vous utilisez la vue plate dénormalisée (`sql/ARCHITECTURE.md` - Section 13)
  - [ ] Une seule table à flat
  - [ ] Pas besoin de relations
- [ ] Si vous utilisez les vues individuelles
  - [ ] Lier sur dimensions communes (région, établissement, aliment)

**C. Créer des colonnes calculées (optionnel)**
```
Colonnes suggérées :
- Taux hospitalisation (%) = cas_hospitalises / nombre_cas * 100
- Cas par région (%) = (cas région) / (total) * 100
- Rang aliment (1-10) = RANK()
- Mois texte = TEXT(date_complete, "MMMM YYYY")
```

---

### 3. Dashboards Recommandés (5 pages)

**Durée estimée** : 4-6 heures (design + développement)

#### Page 1️⃣ : **EXECUTIVE DASHBOARD** (Accueil)
```
KPIs Cartes (Cards) :
┌─────────────┬──────────────┬──────────────┬──────────────┐
│ Total Cas   │ Hospitalisés │ Taux Gravité │ Régions      │
│ 7,981       │ 3,968        │ 24.28%       │ 12           │
└─────────────┴──────────────┴──────────────┴──────────────┘

Graphiques :
- Courbe temporelle (Cas par mois/année)
- Pie chart gravité (Léger / Modéré / Grave / Critique)
- Carte géographique (Cas par région)
```

Données source : `v_kpi_globaux` + `v_analyse_temporelle` + `v_analyse_geographique`

---

#### Page 2️⃣ : **ANALYSE GÉOGRAPHIQUE**
```
Visualisations :
- Carte Madagascar (Cas par région) → Drill-down vers villes
- Tableau villes (Région | Ville | Cas | Taux Grave)
- Top 5 régions à risque (Bar chart)

Filtres interactifs :
- Par région
- Par fourchette de cas
- Par taux de gravité
```

Données source : `v_analyse_geographique`

---

#### Page 3️⃣ : **ANALYSE ALIMENTS & PATHOGÈNES**
```
Visualisations :
- Top 10 aliments (Horizontal bar chart)
- Distribution pathogènes (Pie chart ou Donut)
- Matrice aliment × région (Heatmap)
- Pathogènes par région (Stacked bar)

Filtres :
- Par type d'aliment
- Par pathogène
- Par région
```

Données source : `v_aliments_suspects` + `v_agents_pathogenes` + `v_croisement_region_aliment`

---

#### Page 4️⃣ : **PROFIL PATIENTS & GRAVITÉ**
```
Visualisations :
- Démographie (Genre × Groupe âge) → Treemap
- Taux hospitalisation par groupe âge
- Symptômes principaux (Top symptoms)
- Gravité × Hospitalisation (Cross-tab)

Filtres :
- Par genre
- Par groupe d'âge
- Par symptôme
```

Données source : `v_profil_patients` + `v_analyse_gravite`

---

#### Page 5️⃣ : **DASHBOARD INSPECTION & ÉTABLISSEMENTS**
```
Visualisations :
- Établissements impliqués (Top 10)
- Taux d'inspection par région
- Fermetures effectuées (Count)
- Timeline inspection (Date × Actions)
- KPI inspection (Inspections / Établissements)

Filtres :
- Par établissement
- Par type (Restaurant, Marché, etc.)
- Par région
- Par statut d'inspection
```

Données source : `v_tableau_bord_inspection` + `v_etablissements_impliques`

---

### 4. Fonctionnalités Avancées (Optionnel)

**Durée estimée** : 2-4 heures

#### A. Drill-through Pages
- [ ] Cliquer sur une région → Détails complets des cas
- [ ] Cliquer sur aliment → Tous les cas liés
- [ ] Cliquer sur établissement → Historique complet

#### B. Paramètres de Filtre Globaux
- [ ] Date range slider (année/mois)
- [ ] Multi-select région
- [ ] Toggle gravité (Léger/Modéré/Grave/Critique)

#### C. Visualisations Géospatiales
- [ ] Carte shapefile Madagascar
- [ ] Bubble map (Cas × Hospitalisation × Région)
- [ ] ArcGIS integration (si licence disponible)

#### D. Rapports Exportables
- [ ] PDF automatique (Dashboard summary)
- [ ] Excel export (Données détaillées)
- [ ] Subscription email (Alertes critiques)

---

### 5. Alertes & Seuils (Optionnel)

**Durée estimée** : 1-2 heures

```
Règles à créer :
- 🔴 ALERTE : Taux gravité > 30% dans région
- 🟡 AVERTISSEMENT : Établissement fermé (anomalie détectée)
- 🔵 INFO : Nouvelle région touchée
```

Implémentation :
- [ ] Règles PowerBI (Data alerts)
- [ ] Ou requête PostgreSQL + notification email

---

### 6. Publication & Partage

**Durée estimée** : 30 min - 1 heure

#### Option A : PowerBI Service (Cloud - Recommandé)
- [ ] Créer compte Power BI Premium / Pro
- [ ] Publier rapport `.pbix` → PowerBI Service
- [ ] Configurer permissions d'accès
- [ ] Partager lien aux stakeholders

#### Option B : PowerBI Report Server (On-premise)
- [ ] Installer PBRS sur serveur interne
- [ ] Publier rapport PBIX
- [ ] Configurer authentification Active Directory

#### Option C : Fichier local `.pbix`
- [ ] Distribuer fichier PowerBI Desktop
- [ ] Créer guide d'utilisation utilisateurs

---

## 📝 Checklist de Déploiement

### Avant Publication
- [ ] Tester toutes les connexions PostgreSQL
- [ ] Vérifier performance requêtes (< 5 sec par page)
- [ ] Valider calculs vs données brutes
- [ ] Tester tous les filtres interactifs
- [ ] Vérifier performances sous charge

### Documentation
- [ ] Guide utilisateur PowerBI (2-3 pages)
- [ ] Dictionnaire des colonnes/mesures
- [ ] FAQ troubleshooting
- [ ] Contact support technique

### Utilisateurs Finaux
- [ ] Former 3-5 power users
- [ ] Créer guide d'exploration
- [ ] Établir process de mise à jour (refresh schedule)
- [ ] Support email/chat pour questions

---

## 🔄 Maintenance Continue

### Refresh du Datawarehouse
```
Fréquence recommandée : Quotidienne (ou selon besoins)
Horaire : 02:00 AM (hors heures business)
Processus :
  1. Trigger pipeline Python (cron job)
  2. Extract → Transform → Load PostgreSQL
  3. PowerBI refresh automatique
  4. Notifications utilisateurs si erreur
```

**Script cron (Linux/WSL)** :
```bash
0 2 * * * cd /opt/intoxication-bi && python etl/main.py >> logs/etl.log 2>&1
```

**Task Scheduler (Windows)** :
```
Action: C:\Python\python.exe D:\projects\intoxication-bi\etl\main.py
Horaire: Quotidien 02:00 AM
```

### Monitorer les Données
- [ ] Créer alertes si cas > seuil historique
- [ ] Vérifier complétude données (% manquants)
- [ ] Valider FK integrity (orphelins)
- [ ] Checkpoint mensuel (Data quality report)

---

## 📊 Timeline Recommandée

| Phase | Durée | Dates |
|-------|-------|-------|
| Configuration PowerBI | 0.5h | J+1 |
| Modélisation données | 1-2h | J+1-2 |
| Dashboard design | 4-6h | J+2-3 |
| Tests & validation | 2h | J+3 |
| Documentation | 1-2h | J+3-4 |
| Formation utilisateurs | 1-2h | J+4-5 |
| **Publication en prod** | - | **J+5** |
| Support & iteration | Continu | J+5+ |

**Durée totale estimée** : 2-3 semaines (avec 1-2 BI developers)

---

## 📚 Ressources & Références

### PowerBI
- [Microsoft Power BI Documentation](https://docs.microsoft.com/en-us/power-bi/)
- [Best Practices for Data Models](https://docs.microsoft.com/en-us/power-bi/guidance/power-bi-optimization)
- [DAX Function Reference](https://dax.guide/)

### PostgreSQL & Données
- Voir `ARCHITECTURE.md` pour schéma détaillé
- Voir `README.md` pour setup technique
- Requêtes d'exploration dans `ARCHITECTURE.md` (Section 11-13)

### Équipe Projet
- **Data Engineer** : Maintenance ETL + PostgreSQL
- **BI Developer** : Design + développement PowerBI
- **Business Analyst** : Validation métier + specs dashboard

---

## ❓ Questions Fréquentes

**Q: À quelle fréquence rafraîchir les données ?**  
R: Quotidienne (02:00 AM) recommandé. Peut être ajustée selon les besoins.

**Q: Quelle est la latence données dans PowerBI ?**  
R: Quelques secondes après refresh PostgreSQL (dépend de la complexité des DAX).

**Q: Peut-on combiner les 10 vues dans PowerBI ?**  
R: Oui, deux approches :
  - Import vue plate dénormalisée (simple, parfait pour cas d'usage)
  - Import 10 vues + create relationships (complexe, plus flexible)

**Q: Et pour les alertes d'anomalies ?**  
R: À implémenter après dashboard initial. Utiliser Power Automate ou règles PostgreSQL.

---

**Prochaine réunion** : Validation specs dashboards avec stakeholders  
**Deadline cible** : 2026-07-24  
**Responsable** : BI Lead / Data Analytics Manager

---

*Document créé : 2026-07-10*  
*Dernière MAJ : 2026-07-10*
