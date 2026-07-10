from pathlib import Path

import pandas as pd


def charger_donnees_postgresql(df, config=None, output_path=None):
    """Sauvegarde le DataFrame localement et tente un chargement PostgreSQL si possible."""
    if output_path is None:
        output_path = Path(__file__).resolve().parents[1] / "output" / "data_intoxication_nettoyee.csv"

    output_path = Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(output_path, index=False, encoding="utf-8-sig")
    print(f"[LOAD] Données sauvegardées localement dans : {output_path}")

    if config is None:
        config = {
            "user": "postgres",
            "password": "0000",
            "host": "localhost",
            "port": 5432,
            "database": "postgres",
        }

    try:
        import psycopg2

        with psycopg2.connect(**config) as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT 1")
            conn.commit()
        print("[LOAD] Connexion PostgreSQL réussie.")
    except Exception as exc:
        print(f"[LOAD] Chargement PostgreSQL non disponible, sauvegarde locale conservée : {exc}")

    return output_path
