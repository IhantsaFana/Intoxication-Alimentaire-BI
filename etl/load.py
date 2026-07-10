from pathlib import Path

import pandas as pd


def charger_donnees_postgresql(df, config=None, output_path=None):
    """
    Charge le DataFrame directement dans PostgreSQL (table staging.intoxication_raw).
    Exécute également les scripts SQL pour remplir le datawarehouse.
    """
    if config is None:
        print("Erreur postgres")

    try:
        import psycopg2
        from sqlalchemy import create_engine, text

        # Chaîne de connexion SQLAlchemy
        connection_string = f"postgresql://{config['user']}:{config['password']}@{config['host']}:{config['port']}/{config['database']}"
        engine = create_engine(connection_string, echo=False)

        # 0. D'ABORD créer les schémas et tables
        sql_dir = Path(__file__).resolve().parents[1] / "sql"
        creation_script = sql_dir / "etl-01-schema.sql"
        
        print("[LOAD] Création des schémas et tables...")
        if creation_script.exists():
            with open(creation_script, "r", encoding="utf-8") as f:
                sql_content = f.read()
            with engine.begin() as conn:
                conn.execute(text(sql_content))
            print("[LOAD] Schémas et tables créés.")
        
        # 1. Vider la table staging (optionnel)
        with engine.begin() as conn:
            conn.execute(text("TRUNCATE TABLE staging.intoxication_raw CASCADE;"))
        print("[LOAD] Table staging.intoxication_raw vidée.")

        # 2. Charger le DataFrame dans PostgreSQL
        df.to_sql(
            "intoxication_raw",
            engine,
            schema="staging",
            if_exists="append",
            index=False,
            chunksize=1000,
        )
        print(f"[LOAD] {len(df)} lignes chargées dans staging.intoxication_raw")

        # 3. Exécuter les scripts SQL pour remplir core et analytics
        sql_scripts = [
            "etl-02-load-core.sql",
            "etl-03-analytics.sql",
        ]

        for script_file in sql_scripts:
            script_path = sql_dir / script_file
            if script_path.exists():
                with open(script_path, "r", encoding="utf-8") as f:
                    sql_content = f.read()
                print(f"[LOAD] Exécution de {script_file}...")
                with engine.begin() as conn:
                    conn.execute(text(sql_content))
                print(f"[LOAD] {script_file} exécuté avec succès.")
            else:
                print(f"[LOAD] ⚠️ Fichier SQL non trouvé : {script_path}")

        engine.dispose()
        print("[LOAD] ✅ Chargement PostgreSQL terminé avec succès.")
        return "PostgreSQL"

    except ImportError:
        print(
            "[LOAD] ⚠️ sqlalchemy ou psycopg2 non installés. Fallback sur sauvegarde CSV."
        )
        return charger_donnees_csv(df, output_path)
    except Exception as exc:
        print(f"[LOAD] ❌ Erreur PostgreSQL : {exc}")
        print("[LOAD] Fallback sur sauvegarde CSV...")
        return charger_donnees_csv(df, output_path)


def charger_donnees_csv(df, output_path=None):
    """Sauvegarde le DataFrame en CSV comme fallback."""
    if output_path is None:
        output_path = (
            Path(__file__).resolve().parents[1]
            / "output"
            / "data_intoxication_nettoyee.csv"
        )

    output_path = Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(output_path, index=False, encoding="utf-8-sig")
    print(f"[LOAD] Données sauvegardées localement : {output_path}")
    return str(output_path)
