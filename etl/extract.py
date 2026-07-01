import pandas as pd
import os

def extraire_donnees(chemin_fichier):
    print("--- 1. ÉTAPE D'EXTRACTION ---")
    if not os.path.exists(chemin_fichier):
        raise FileNotFoundError(f"Le fichier source est introuvable : {chemin_fichier}")
        
    df = pd.read_excel(chemin_fichier)
    print(f"Données extraites avec succès. Nombre de lignes : {len(df)}")
    return df