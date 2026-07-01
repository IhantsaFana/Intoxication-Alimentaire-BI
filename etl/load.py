from sqlalchemy import create_engine, text

def charger_donnees_postgresql(df, db_config):
    print("\n--- 3. ÉTAPE DE CHARGEMENT (PostgreSQL) ---")
    
    conn_string = f"postgresql://{db_config['user']}:{db_config['password']}@{db_config['host']}:{db_config['port']}/{db_config['database']}"
    engine = create_engine(conn_string)
    
    try:
        with engine.begin() as connection:
            connection.execute(text("CREATE SCHEMA IF NOT EXISTS staging;"))
            
            df.to_sql(
                name='stg_ventes', 
                con=connection, 
                schema='staging', 
                if_exists='replace', 
                index=False
            )
        print("✅ Données propres chargées avec succès dans [staging.stg_ventes] !")
    except Exception as error:
        print(f"❌ Erreur lors du chargement dans PostgreSQL : {error}")
        raise error