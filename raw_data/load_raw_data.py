import logging
import os
import inflection
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

# get the file names of all CSV files in the folder "raw_data"
raw_data_files = [file for file in os.listdir("raw_data") if file.endswith(".csv")]
logger.debug(f"Found {len(raw_data_files)} files")

for file in raw_data_files:
    file_short = file.replace(".csv", "")
    # Load your CSV file into a DataFrame
    df = pd.read_csv(f"raw_data/{file}")
    # Make column names lowercase for better SQL handling
    df.columns = [inflection.underscore(col) for col in df.columns]
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
