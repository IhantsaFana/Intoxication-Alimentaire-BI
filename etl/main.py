from extract import extraire_donnees
from transform import transformer_donnees
from load import charger_donnees_postgresql


if __name__ == "__main__":
    fichier_entree = "./dataset/data_intoxication.csv"

    config_postgres = {
        "user": "postgres",
        "password": "0000",
        "host": "localhost",
        "port": 5432,
        "database": "postgres",
    }

    try:
        print("======= DEBUT DU PIPELINE ETL =======")
        df_brut = extraire_donnees(fichier_entree)
        df_propre = transformer_donnees(df_brut)
        sortie = charger_donnees_postgresql(df_propre, config_postgres)
        print("\n[SUCCESS] Le pipeline ETL s'est exécuté de bout en bout.")
        print(f"[SUCCESS] Fichier de sortie : {sortie}")
    except Exception as exc:
        print(f"\n[FAILURE] Le pipeline a échoué : {exc}")