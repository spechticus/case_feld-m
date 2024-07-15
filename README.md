# Architecture

## Database
I opted for a PostgreSQL database since I am very familiar with it and it is a very widespread and free solution. Postgres is fine for smaller analytical workloads and the datasets you have provided are definitely within the capabilities of it.

As an alternative, I considered DuckDB because you can just save it as a file in a local repository and thus have less overhead in an assignment like this that focusses on data modelling. In the end, I went with Postgres as it was a) explicitly stated in the assignment as a possible option and b) to model the situation where dbt needs to access a (remote) database (which is a much more realistic scenario).

## Environment
For reproducibility reasons, I set up a Docker stack with ``docker-compose`` including a Postges container and a dbt container that is run through Docker.

In the repository itself I use Python for all necessary tooling work and have set up a virtual environment with the necessary packages as a `requirements.txt`.

To streamline the handling of the project, I set up a `Makefile` for wrapping the most important console commands.

# Setup: How to install and use
0. Make sure you have the Docker engine up and running and Python 3.11 with pyenv installed. The scripts also just work on a Unix-based System, so MacOS or Linux. You would have to adapt the commands if you are on Windows.
1. Use `make setup` to initialise a new local Python virtual environment, install all dependencies, set up the Docker stack and install the dbt dependencies inside the container. In the Makefile, you can specify a later Python version you want to use if you do not have/want Python 3.11, but  Python<3.11 does not work.
2. Use `make check_dbt` to run `dbt debug` in both the local version (for checking `profiles.yml` and `dbt_project.yml`) and the in-container version. The connection check on the local version will fail because it cannot directly access Postgres inside the container but **that is okay**, as long as the dbt version inside the container can connect.
3. Before we can use our raw data inside the container, we now need to execute the upload script from the `raw_data/` folder using `make load_rawdata`. After it's done, you can inspect the results in the `./load_raw_data.log`.
4. For a complete build run, you can execute `make build_dbt` which will just snapshot, run, and test the entire DAG.
5. N.B. in this example, some of the source tests I have written will fail because there are inconsistencies in the source data you provided (see explanation and handling below), that's why the final data marts are skipped in `dbt build`. You can still run and inspect them by using `make run_dbt` which uses `dbt run` under the hood. 
6. You can inspect the built models using any datbase management tool (e.g. DBeaver or TablePlus) on: `postgresql://postgres:postgres@localhost:5432/postgres`, as the Postgres container exposes port 5432.
7. If you want to execute dbt commands inside the container with flags such as `--select`, you can pass the `$SELECTION` environmental variable, e.g. `make run_dbt SELECTION='-s path:models/data_marts'`



# Workflow
I will now explain the individual steps I went through in my process and how they are reflected in the files in this repository.

>**A quick word about scope and effort of this project**: 
Not all of these steps were absolutely necessary to merely fulfil the assignment. However, if we assume that this is not a one-off analysis of static CSV files (for which dbt would be overkill anyway), but a pipeline that will regularly process new data, the following workflow will provide a robust framework.

## Workflow Step 1: Exploration of Raw Data
As a first step, I looked at the raw data through a Jupyter notebook `exploration.ipynb` that illustrates my thought process when I first get my hands on new data.
I tried figuring out these questions for each file:
- Which business entity or process is modelled here and at which grain are we looking at it?
- What is the content of the columns and which aspect of the entity or process do they represent?
- What is the data type of the columns?
- Which connection / relation exists to the other columns in the file and in other files (foreign keys, references, ...)
- Which expectations about the data that we can test later can we formulate?
- Can I think of useful possible features/columns that be directly calculated from the data at hand?
- Which problems / caveats for later usage about the data can I anticipate?

Looking at the data in this way ensures that we know what to do later in dbt, which source tests to write, and which data types to assign.

For some projects, I would then design an entity-relationship diagram based on my exploration, but since this project was quite straightforward about the entity relations I skipped this step here in the interest of time.

## Workflow Step 2: Data Loading
Since we are running dbt and our database inside a Docker container, we need to get the raw data in there somehow.

A simple solution would be to create a Docker volume that exchanges files with the surrounding environment. We could just insert our CSV files there and import them into our database as local files.
I decided to use a Python script to load the CSV files into the database through the `pandas` library to maintain full control over the loading process and how the CSV files are handled.

This was useful for two concrete reasons:
1. **Schema handling**: I used a `column_types.yml` file to specify the `dtype`s of the columns to ensure all columns are loaded into the database with a suitable data type.
2. **Adding a timestamp column**: To ensure proper snapshotting of changing dimensions, I added a `uploaded_at` column with the current timestamp to the raw data before uploading.

The script itself simply iterates over all .csv files in the "raw data" folder, extracts the datatypes of the present columns from the `column_types.yml`, and uploads the resulting dataframe to the database.

## Workflow Step 3: Testing the raw data in dbt
After the data has been loaded, we can now continue working with it in dbt.
As a first step, We can now formalise our expectations about the raw data in source tests in the `models/src_rawdata.yml` file. For this, I also wrote some custom tests that live in the `tests/generic/` folder.

When looking at the results of our source tests, we encounter the following problems:

- **Mismatching unit prices**: 658 rows from the `order_details` table reference a wrong unit price, assuming that this table references the unit price from the `products` table via the `product_id`. This can either straight up be an upstream mistake inside the data source OR it can be a legacy issue: The unit price used to be A at the time of placing the order (recorded in the `order_details` table) but now in the meantime it has changed to B (according to the `products` table). Since we do not know which of the two options is the case (mistake vs. legacy), we might want to fork all downstream metrics into those based on unit price A and those based on unit price B, until we know which one to get rid of.
- **Mismatching customer information:** In the `orders` table there are a lot of inconsistencies about customers compared to the customer ID's respective properties in the `customers` table:

    - 65 orders with mismatching shipping addresses for 8 customers in total: If we look at the concrete data here, we see that sometimes we have different addresses altogether, but sometimes we simply have differing formats for the same address. Example: `customer_id` == 'COMMI' has `ship_address` "Av. dos Lusíadas 23" in the `orders` table, but "23 Av. dos Lusíadas" in the `customers` table (house number in front or at the back). While the latter case could simply be fixed by agreeing to the versions from one column, or by defining a country-dependent standard and creating a macro to re-order all non-matching address formats, the former case is not to be determined from the data alone. We face the same problem: Error vs. legacy; the customer could have simply moved house since the order was placed. In this case, we would always prefer the current address most likely saved in the `customers` table. If it was an error, however, we cannot do anything to determine which of the two addresses is currently correct.

    - 42 cases of mismatching postal code for 4 customers: These are almost all the above customers who have a completely different address, which is weak evidence for them actually moving house, or for the address being different altogether, i.e. the postcode of the inconsistencies might match the street of the inconsitencies.

    - 22 cases of mismatching cities for two customers: One has different cities, the other is just a typo / format error.

    - 34 cases of mismatching customer names for 5 customers: All of them are just formatting mistakes: missing apostrophes, missing special characters, typos. Normalising could eliminate most of them.

- TODO finish cleaning up dimensions (e.g. getting rid of numbers in cities)

## Workflow Step 4: Snapshotting
In accordance with the [dbt best practices on snapshotting](https://docs.getdbt.com/docs/build/snapshots#snapshot-query-best-practices), we are snapshotting our raw data BEFORE staging and do not alter the data if not absolutely necessary (resulting in a simple `SELECT *` query).

I opted for a "timestamp" strategy and used the `uploaded_at` column we created earlier in our Python loading script.

This gives us the ability to determine the point in time of certain state changes in our raw data, which might be necessary for legacy reports or reports over a longer period of time. If a customer moved house to a different state, they might contribute to different "sales by state" dimensions depending on the timeframe in question.

Also more transaction-oriented tables like `order_details` might benefit from snapshotting if e.g. the discount or the quantity demanded for a product in a given order would change.

## Workflow Step 5: Staging the raw data
After testing and snapshotting, we want to extract the snapshotted raw data into intermediary views, often called "staging".

I added a couple of columns, mostly related to stripping special local characters (like Umlaute or so) from name columns for easier searching and matching AND because we have seen in our source tests above that this has been indeed a problem for data consistency (as in: mismatching data due to the presence and absence of special characters). 
For this, I wrote some custom macros.

>**Adding columns vs. joining from lookup tables:** When transforming central columns like names, or addresses that might be used by multiple models, the 

## Workflow Step 6: Transformation and Business Logic

- addresses / localisation / de-localisation / standardisation: Architecture choice between adding normalised column to a table or creating separate tables with normalised data to be joined. Since I am using PostgreSQL which is row-based, adding more columns does not significantly alter performance AND since we are dealing with a small dataset.

- TODO tests for business logic

## Workflow Step 7: Final Data Marts as specified in the assignment
- TODO: Indices