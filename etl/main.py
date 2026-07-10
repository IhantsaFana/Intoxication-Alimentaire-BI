# Importation des modules locaux
from extract import extraire_donnees
from transform import transformer_donnees
from load import charger_donnees_postgresql

if __name__ == "__main__":
    # Paramètres globaux
    fichier_entree = "./data/ventes_fournitures.csv"
    
    config_postgres = {
        "user": "postgres",
        "password": "0000",
        "host": "localhost",
        "port": 5432,
        "database": "dwh_vente_fourniture"
    }
    
    try:
        print("======= DEBUT DU PIPELINE ETL =======")
        
        # 1. Extraction
        df_brut = extraire_donnees(fichier_entree)
        
        # 2. Transformation
        df_propre = transformer_donnees(df_brut)
        
        # 3. Chargement
        charger_donnees_postgresql(df_propre, config_postgres)
        
        print("\n🚀 [SUCCESS] Le pipeline ETL s'est exécuté de bout en bout !")
        
    except Exception as e:
        print(f"\n💥 [FAILURE] Le pipeline a échoué à cause de l'erreur suivante : {e}")