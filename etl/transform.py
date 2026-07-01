import pandas as pd

def transformer_donnees(df):
    print("\n--- 2. ÉTAPE DE TRANSFORMATION ---")
    
    # 1. Nettoyage des Doublons
    df = df.drop_duplicates()
    
    # 2. Suppression des colonnes inutiles
    colonnes_utiles = ['ID_Facture', 'Date_Achat', 'Description_Article', 'Famille_Produit', 'Quantite_Vendue', 'Prix_Unitaire_Brut', 'Magasin_Ville']
    df = df[colonnes_utiles].copy()
    
    # 3. Gestion des valeurs manquantes
    df['Magasin_Ville'] = df['Magasin_Ville'].fillna('Inconnu')
    df['Famille_Produit'] = df['Famille_Produit'].fillna('Inconnu')
    
    # 4. Correction des "Espaces Fantômes" et Casse
    df['Famille_Produit'] = df['Famille_Produit'].astype(str).str.strip().str.title()
    df['Magasin_Ville'] = df['Magasin_Ville'].astype(str).str.strip().str.title()
    
    # 5. Correction du Type de Donnée (Prix)
    df['Prix_Unitaire_Brut'] = df['Prix_Unitaire_Brut'].astype(str).str.replace(' EUR', '', regex=False)
    df['Prix_Unitaire_Brut'] = df['Prix_Unitaire_Brut'].str.replace(',', '.', regex=False)
    df['Prix_Unitaire_Brut'] = df['Prix_Unitaire_Brut'].replace('nan', '0.0')
    df['Prix_Unitaire_Brut'] = pd.to_numeric(df['Prix_Unitaire_Brut'], errors='coerce').fillna(0.0)
    
    # 6. Correction de Date
    df = df.dropna(subset=['Date_Achat'])
    df['Date_Achat'] = df['Date_Achat'].astype(str).str.strip().str.replace('/', '-', regex=False).str.slice(0, 10)
    df['Date_Achat'] = pd.to_datetime(df['Date_Achat'], format='mixed', errors='coerce')
    df = df.dropna(subset=['Date_Achat'])
    df['Date_Achat'] = df['Date_Achat'].dt.strftime('%Y-%m-%d')

    # 7. Traitement des valeurs aberrantes
    df['Quantite_Vendue'] = pd.to_numeric(df['Quantite_Vendue'], errors='coerce').fillna(0).astype(int)
    df = df[df['Quantite_Vendue'] > 0]
    
    # 8. Enrichissement
    df['Montant_Total'] = df['Quantite_Vendue'] * df['Prix_Unitaire_Brut']
    
    print("Transformation et nettoyage terminés.")
    return df