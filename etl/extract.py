from pathlib import Path

import pandas as pd


def extraire_donnees(chemin_fichier=None):
    """Charge un fichier CSV de données brutes dans un DataFrame pandas."""
    if chemin_fichier is None:
        chemin_fichier = Path(__file__).resolve().parents[1] / "dataset" / "data_intoxication.csv"

    chemin_fichier = Path(chemin_fichier)
    if not chemin_fichier.is_absolute():
        chemin_fichier = (Path(__file__).resolve().parents[1] / chemin_fichier).resolve()

    if not chemin_fichier.exists():
        raise FileNotFoundError(f"Fichier introuvable : {chemin_fichier}")

    df = pd.read_csv(chemin_fichier)
    print(f"[EXTRACT] Données lues depuis : {chemin_fichier}")
    print(f"[EXTRACT] Forme du DataFrame : {df.shape}")
    return df
