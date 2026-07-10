import os
from pathlib import Path

from dotenv import load_dotenv

from extract import extraire_donnees
from transform import transformer_donnees
from load import charger_donnees_postgresql


# Charger les variables d'environnement depuis .env
env_path = Path(__file__).resolve().parents[1] / ".env"
load_dotenv(env_path)


if __name__ == "__main__":
    # Fichiers d'entrée/sortie
    fichier_entree = os.getenv("INPUT_FILE")
    fichier_sortie = os.getenv("OUTPUT_FILE")

    # Configuration PostgreSQL depuis variables d'environnement
    config_postgres = {
        "user": os.getenv("POSTGRES_USER"),
        "password": os.getenv("POSTGRES_PASSWORD"),
        "host": os.getenv("POSTGRES_HOST"),
        "port": int(os.getenv("POSTGRES_PORT")),
        "database": os.getenv("POSTGRES_DATABASE"),
    }

    try:
        print("======= DEBUT DU PIPELINE ETL =======")
        print(f"[CONFIG] Fichier d'entrée : {fichier_entree}")
        print(f"[CONFIG] Fichier de sortie : {fichier_sortie}")
        
        df_brut = extraire_donnees(fichier_entree)
        df_propre = transformer_donnees(df_brut)
        sortie = charger_donnees_postgresql(df_propre, config_postgres, fichier_sortie)
        
        print("\n[SUCCESS] Le pipeline ETL s'est exécuté de bout en bout.")
        print(f"[SUCCESS] Fichier de sortie : {sortie}")
    except Exception as exc:
        print(f"\n[FAILURE] Le pipeline a échoué : {exc}")