import logging
import os
import inflection
import yaml
import pandas as pd
from sqlalchemy import create_engine, text


# create a logger
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

# create a file handler
handler = logging.FileHandler("load_raw_data.log")
handler.setLevel(logging.INFO)

# create a logging format
formatter = logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")
handler.setFormatter(formatter)

# add the handlers to the logger
logger.addHandler(handler)

engine = create_engine("postgresql://postgres:postgres@localhost:5432/postgres")

with engine.connect() as conn:
    with conn.begin():
        conn.execute(text("CREATE SCHEMA IF NOT EXISTS raw_layer"))


# Load the column types from a YAML configuration file
with open("raw_data/column_types.yml", "r") as file:
    config = yaml.safe_load(file)

column_types = config["column_types"]
parse_dates = config.get("parse_dates", [])

# get the file names of all CSV files in the folder "raw_data"
raw_data_files = [file for file in os.listdir("raw_data") if file.endswith(".csv")]
logger.debug(f"Found {len(raw_data_files)} files")

for file in raw_data_files:
    file_short = file.replace(".csv", "")

    # Load the CSV file without any type inference
    df = pd.read_csv(f"raw_data/{file}", nrows=0)
    actual_columns = df.columns.tolist()

    # Filter out columns not present in the actual data
    actual_parse_dates = [col for col in parse_dates if col in actual_columns]
    actual_column_types = {
        col: dtype for col, dtype in column_types.items() if col in actual_columns
    }

    # Load your CSV file into a DataFrame with specified column types and parse dates
    try:
        df = pd.read_csv(
            f"raw_data/{file}",
            dtype=actual_column_types,
            parse_dates=actual_parse_dates,
        )
    except Exception as e:
        logger.error(f"Failed to load {file}: {e}")
        continue

    # Make column names lowercase for better SQL handling
    df.columns = [inflection.underscore(col) for col in df.columns]
    # Add an "uploaded_at" column with the current timestamp
    df["uploaded_at"] = pd.Timestamp.now()

    logger.debug(f"Successfully loaded {file}")

    with engine.connect() as conn:
        df.to_sql(
            f"{file_short}",
            engine,
            schema="raw_layer",
            if_exists="replace",
            index=False,
        )

    # Verify that the data has been inserted correctly
    with engine.connect() as conn:
        result = conn.execute(text(f"SELECT COUNT(*) FROM raw_layer.{file_short}"))
        rownumber = result.fetchone()
        assert rownumber[0] == df.shape[0], "The row number does not match!"
        logger.info(f"Successfully uploaded {file} to raw_layer as {file_short}")
