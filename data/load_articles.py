import argparse
import sys
from pathlib import Path

import pandas as pd
import pymysql
from pymysql.cursors import Cursor

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Load Kaggle news articles CSV into a MySQL RDS database."
    )

    parser.add_argument(
        "--host",
        required=True,
        help="RDS MySQL endpoint.",
    )

    parser.add_argument(
        "--port",
        type=int,
        default=3306,
        help="MySQL port. Default: 3306.",
    )

    parser.add_argument(
        "--user",
        default="admin",
        help="MySQL username. Default: admin.",
    )

    parser.add_argument(
        "--password",
        default="adminpwrd",
        help="MySQL password. Default: adminpwrd.",
    )

    parser.add_argument(
        "--database",
        default="newsdb",
        help="Target MySQL database name. Default: newsdb.",
    )

    parser.add_argument(
        "--csv",
        default="data/articles1.csv",
        help="Path to articles CSV file. Default: data/articles1.csv.",
    )

    parser.add_argument(
        "--limit",
        type=int,
        default=None,
        help="Optional row limit for testing.",
    )

    return parser.parse_args()

def create_articles_table(cursor: Cursor) -> None:
    create_table_sql = """
    CREATE TABLE IF NOT EXISTS articles (
        id INT AUTO_INCREMENT PRIMARY KEY,
        source_id VARCHAR(255),
        source_name VARCHAR(255),
        author TEXT,
        title TEXT,
        description TEXT,
        url TEXT,
        url_to_image TEXT,
        published_at DATETIME NULL,
        content TEXT,
        raw_published_at VARCHAR(255),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    """

    cursor.execute(create_table_sql)

# clean text
def clean_text(value):
    if pd.isna(value):
        return None

    value = str(value).strip()

    if value == "":
        return None

    return value

# parse dates
def parse_datetime(value):
    if pd.isna(value):
        return None

    parsed = pd.to_datetime(value, errors="coerce", utc=True)

    if pd.isna(parsed):
        return None

    return parsed.to_pydatetime().replace(tzinfo=None)

# CSV loading
def load_csv(csv_path: str, limit: int | None = None) -> pd.DataFrame:
    path = Path(csv_path)

    if not path.exists():
        raise FileNotFoundError(
            f"CSV file not found at {csv_path}. "
            "Download articles1.csv from Kaggle and place it in the data/ folder."
        )

    df = pd.read_csv(path)

    if limit is not None:
        df = df.head(limit)

    return df

def prepare_article_rows(df: pd.DataFrame) -> list[tuple]:
    rows = []

    for _, row in df.iterrows():
        source_id = None
        source_name = None

        if "source" in df.columns and not pd.isna(row.get("source")):
            source_name = clean_text(row.get("source"))

        if "source_id" in df.columns:
            source_id = clean_text(row.get("source_id"))

        if "source_name" in df.columns:
            source_name = clean_text(row.get("source_name"))

        raw_published_at = clean_text(row.get("publishedAt"))
        published_at = parse_datetime(row.get("publishedAt"))

        rows.append(
            (
                source_id,
                source_name,
                clean_text(row.get("author")),
                clean_text(row.get("title")),
                clean_text(row.get("description")),
                clean_text(row.get("url")),
                clean_text(row.get("urlToImage")),
                published_at,
                clean_text(row.get("content")),
                raw_published_at,
            )
        )

    return rows

# database insert
def insert_articles(cursor: Cursor, rows: list[tuple]) -> None:
    insert_sql = """
    INSERT INTO articles (
        source_id,
        source_name,
        author,
        title,
        description,
        url,
        url_to_image,
        published_at,
        content,
        raw_published_at
    )
    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s);
    """

    cursor.executemany(insert_sql, rows)

def main() -> int:
    args = parse_args()

    print(f"Reading CSV from {args.csv}...")
    df = load_csv(args.csv, args.limit)

    print(f"Loaded {len(df)} rows from CSV.")

    print(f"Connecting to MySQL at {args.host}:{args.port}...")
    connection = pymysql.connect(
        host=args.host,
        port=args.port,
        user=args.user,
        password=args.password,
        database=args.database,
        charset="utf8mb4",
        autocommit=False,
    )

    try:
        with connection.cursor() as cursor:
            print("Creating articles table if it does not exist...")
            create_articles_table(cursor)

            print("Preparing rows for insert...")
            rows = prepare_article_rows(df)

            print(f"Inserting {len(rows)} rows into articles table...")
            insert_articles(cursor, rows)

        connection.commit()
        print("Load complete.")

    except Exception as exc:
        connection.rollback()
        print(f"Load failed: {exc}", file=sys.stderr)
        return 1

    finally:
        connection.close()

    return 0

if __name__ == "__main__":
    raise SystemExit(main())