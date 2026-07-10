from pathlib import Path

import numpy as np
import pandas as pd


def check_duplicates(df, name, verbose=True):
    duplicates = int(df.duplicated().sum())
    if verbose:
        print(f"Doublons dans {name} : {duplicates}")
    return duplicates


def check_missing_values(df, name, verbose=True):
    missing_values = df.isnull().sum()
    total_values = df.shape[0]
    missing_percentage = (missing_values / total_values) * 100 if total_values else 0
    if verbose:
        print(f"Valeurs manquantes dans {name} :\n{missing_percentage}\n")
    return missing_values, missing_percentage


def check_outliers(df, name, verbose=True):
    numeric_columns = df.select_dtypes(include=["int64", "float64"]).columns
    results = {}

    for col in numeric_columns:
        q1 = df[col].quantile(0.25)
        q3 = df[col].quantile(0.75)
        iqr = q3 - q1
        lower_bound = q1 - 1.5 * iqr
        upper_bound = q3 + 1.5 * iqr
        nb_outliers = int(((df[col] < lower_bound) | (df[col] > upper_bound)).sum())
        results[col] = nb_outliers

    if verbose:
        print(f"Outliers in {name}:\n{pd.Series(results)}\n")
    return results


def transformer_donnees(df):
    """Applique le nettoyage et l'enrichissement du jeu de données."""
    df = df.copy()

    check_duplicates(df, "data_intoxication", verbose=False)
    check_missing_values(df, "data_intoxication", verbose=False)

    # Valeurs manquantes métier
    if "symptomes" in df.columns:
        df["symptomes"] = df["symptomes"].fillna("Non spécifié")

    if {"analyse_laboratoire", "resultat_analyse"}.issubset(df.columns):
        df.loc[
            (df["analyse_laboratoire"] == "Aucune analyse") & (df["resultat_analyse"].isna()),
            "resultat_analyse",
        ] = "Non applicable"

    if {"inspection_effectuee", "mesures_prises"}.issubset(df.columns):
        df.loc[
            (df["inspection_effectuee"] == "Non") & (df["mesures_prises"].isna()),
            "mesures_prises",
        ] = "Non applicable"

    if {"hospitalisation", "id_hopital"}.issubset(df.columns):
        df.loc[(df["hospitalisation"] == "Non") & (df["id_hopital"].isna()), "id_hopital"] = "N/A"
    if {"hospitalisation", "nom_hopital"}.issubset(df.columns):
        df.loc[(df["hospitalisation"] == "Non") & (df["nom_hopital"].isna()), "nom_hopital"] = "Non hospitalisé"

    if {"hospitalisation", "id_hopital"}.issubset(df.columns):
        df.loc[(df["hospitalisation"] == "Oui") & (df["id_hopital"].isna()), "id_hopital"] = "À vérifier"
    if {"hospitalisation", "nom_hopital"}.issubset(df.columns):
        df.loc[(df["hospitalisation"] == "Oui") & (df["nom_hopital"].isna()), "nom_hopital"] = "À vérifier"

    for col in ["id_hopital", "nom_hopital"]:
        if col in df.columns:
            df[col] = df[col].fillna("À vérifier")

    # Nettoyage des espaces et casse
    colonnes_texte = [
        "ville",
        "region",
        "nom_etablissement",
        "type_etablissement",
        "lieu_consommation",
        "type_aliment",
        "aliment_suspect",
        "categorie_aliment",
        "marque_aliment",
        "source_alimentaire",
        "symptome_principal",
        "gravite",
        "hospitalisation",
        "nom_hopital",
        "traitement_administre",
        "medicament_administre",
        "analyse_laboratoire",
        "resultat_analyse",
        "agent_pathogene_suspecte",
        "source_signalement",
        "inspection_effectuee",
        "resultat_inspection",
        "mesures_prises",
        "fermeture_etablissement",
        "symptomes",
    ]

    for col in colonnes_texte:
        if col in df.columns:
            df[col] = (
                df[col]
                .astype("string")
                .str.replace(r"\s+", " ", regex=True)
                .str.strip()
            )

    if "saison" in df.columns:
        df["saison"] = df["saison"].astype("string").str.strip().str.capitalize()

    for col in df.select_dtypes(include="object").columns:
        df[col] = df[col].astype("string").str.strip()

    if "ville" in df.columns:
        df["ville"] = df["ville"].astype("string").str.title()
    if "region" in df.columns:
        df["region"] = df["region"].astype("string").str.title()
    if "gravite" in df.columns:
        df["gravite"] = df["gravite"].astype("string").str.capitalize()

    mapping_oui_non = {
        "oui": "Oui",
        "non": "Non",
        "yes": "Oui",
        "no": "Non",
        "true": "Oui",
        "false": "Non",
    }
    for col in ["hospitalisation", "fermeture_etablissement", "inspection_effectuee"]:
        if col in df.columns:
            df[col] = (
                df[col]
                .astype("string")
                .str.lower()
                .map(mapping_oui_non)
                .fillna(df[col])
            )

    if "genre_patient" in df.columns:
        df["genre_patient"] = (
            df["genre_patient"]
            .astype("string")
            .str.strip()
            .str.upper()
            .map({"F": "Femme", "M": "Homme"})
            .fillna(df["genre_patient"])
        )

    # Conversion des types
    colonnes_dates = ["date_cas", "date_achat", "date_consomation", "date_declaration"]
    for col in colonnes_dates:
        if col in df.columns:
            df[col] = pd.to_datetime(df[col], format="%Y-%m-%d", errors="coerce")

    colonnes_heures = ["heure_cas", "heure_consomation"]
    for col in colonnes_heures:
        if col in df.columns:
            df[col] = pd.to_datetime(df[col], format="%H:%M", errors="coerce").dt.time

    colonnes_int = [
        "age_patient",
        "nombre_personnes_exposees",
        "nombre_personnes_malades",
        "duree_symptomes_heures",
        "jour",
        "mois",
        "annee",
    ]
    for col in colonnes_int:
        if col in df.columns:
            df[col] = pd.to_numeric(df[col], errors="coerce")

    if "temperature_patient" in df.columns:
        df["temperature_patient"] = pd.to_numeric(df["temperature_patient"], errors="coerce")

    if "anomalie" in df.columns:
        df["anomalie"] = (
            df["anomalie"]
            .astype("string")
            .str.strip()
            .str.upper()
            .map({"TRUE": True, "FALSE": False})
        )

    # Contrôle de cohérence des dates
    if "date_cas" in df.columns:
        df = df.dropna(subset=["date_cas"])

    if {"date_achat", "date_consomation"}.issubset(df.columns):
        df.loc[df["date_achat"] > df["date_consomation"], "date_achat"] = pd.NaT
    if {"date_consomation", "date_cas"}.issubset(df.columns):
        df.loc[df["date_consomation"] > df["date_cas"], "date_consomation"] = pd.NaT
    if {"date_cas", "date_declaration"}.issubset(df.columns):
        df.loc[df["date_cas"] > df["date_declaration"], "date_declaration"] = pd.NaT

    # Traitement des valeurs aberrantes
    if "age_patient" in df.columns:
        df.loc[(df["age_patient"] < 0) | (df["age_patient"] > 120), "age_patient"] = pd.NA
    if "temperature_patient" in df.columns:
        df.loc[(df["temperature_patient"] < 35) | (df["temperature_patient"] > 42), "temperature_patient"] = pd.NA
    if "nombre_personnes_exposees" in df.columns:
        df.loc[df["nombre_personnes_exposees"] <= 0, "nombre_personnes_exposees"] = pd.NA
    if {"nombre_personnes_malades", "nombre_personnes_exposees"}.issubset(df.columns):
        df.loc[
            (df["nombre_personnes_malades"] < 0)
            | (df["nombre_personnes_malades"] > df["nombre_personnes_exposees"]),
            "nombre_personnes_malades",
        ] = pd.NA
    if "duree_symptomes_heures" in df.columns:
        df.loc[(df["duree_symptomes_heures"] < 0) | (df["duree_symptomes_heures"] > 336), "duree_symptomes_heures"] = pd.NA

    # Enrichissement
    if {"nombre_personnes_malades", "nombre_personnes_exposees"}.issubset(df.columns):
        df["taux_attaque"] = (
            df["nombre_personnes_malades"].div(df["nombre_personnes_exposees"]).mul(100).round(2)
        )

    if "age_patient" in df.columns:
        conditions = [
            df["age_patient"] <= 12,
            (df["age_patient"] >= 13) & (df["age_patient"] <= 17),
            (df["age_patient"] >= 18) & (df["age_patient"] <= 35),
            (df["age_patient"] >= 36) & (df["age_patient"] <= 59),
            df["age_patient"] >= 60,
        ]
        categories = ["Enfant", "Adolescent", "Jeune adulte", "Adulte", "Senior"]
        df["groupe_age"] = np.select(conditions, categories, default="Non renseigné")

    # Correction des régions à partir de la ville
    mapping_correct = {
        "Antananarivo": "Analamanga",
        "Antsirabe": "Vakinankaratra",
        "Fianarantsoa": "Haute Matsiatra",
        "Toamasina": "Atsinanana",
        "Mahajanga": "Boeny",
        "Toliara": "Atsimo-Andrefana",
        "Antsiranana": "Diana",
        "Morondava": "Menabe",
        "Antalaha": "Sava",
        "Maroantsetra": "Analanjirofo",
        "Ambatondrazaka": "Alaotra-Mangoro",
        "Manakara": "Vatovavy",
    }
    if {"ville", "region"}.issubset(df.columns):
        df["region"] = df["ville"].map(mapping_correct).fillna(df["region"])

    print("[TRANSFORM] Transformation terminée.")
    print(f"[TRANSFORM] Lignes finales : {len(df)}")
    print(f"[TRANSFORM] Colonnes finales : {len(df.columns)}")
    return df
