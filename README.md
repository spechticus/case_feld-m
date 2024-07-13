# Architecture and Setup

# Exploration and Staging / Raw Data

- Problem: 658 rows from the `order_details` table reference a wrong unit price, assuming that this table references the unit price from the `products` table via the `product_id`. This can either straight up be an upstream mistake inside the data source OR it can be a legacy issue: The unit price used to be A at the time of placing the order (recorded in the `order_details` table) but now in the meantime it has changed to B (according to the `products` table). Since we do not know which of the two options is the case (mistake vs. legacy), we might want to fork all downstream metrics into those based on unit price A and those based on unit price B, until we know which one to get rid of.
- Additionally, in the `orders` table there are a lot of inconsistencies about customers compared to the customer ID's respective properties in the `customers` table:
    - 65 orders with mismatching shipping addresses for 8 customers in total: If we look at the concrete data here, we see that sometimes we have different addresses altogether, but sometimes we simply have differing formats for the same address. Example: `customer_id` == 'COMMI' has `ship_address` "Av. dos Lusíadas 23" in the `orders` table, but "23 Av. dos Lusíadas" in the `customers` table (house number in front or at the back). While the latter case could simply be fixed by agreeing to the versions from one column, or by defining a country-dependent standard and creating a macro to re-order all non-matching address formats, the former case is not to be determined from the data alone. We face the same problem: Error vs. legacy; the customer could have simply moved house since the order was placed. In this case, we would always prefer the current address most likely saved in the `customers` table. If it was an error, however, we cannot do anything to determine which of the two addresses is currently correct.
    - 42 cases of mismatching postal code for 4 customers: These are almost all the above customers who have a completely different address, which is weak evidence for them actually moving house, or for the address being different altogether, i.e. the postcode of the inconsistencies might match the street of the inconsitencies.
    - 22 cases of mismatching cities for two customers: One has different cities, the other is just a typo / format error.
    - 34 cases of mismatching customer names for 5 customers: All of them are just formatting mistakes: missing apostrophes, missing special characters, typos. Normalising could eliminate most of them.

# Transformation and Business Logic

- addresses / localisation / de-localisation / standardisation: Architecture choice between adding normalised column to a table or creating separate tables with normalised data to be joined. Since I am using PostgreSQL which is row-based, adding more columns does not significantly alter performance AND since we are dealing with a small dataset.

# Final Data Marts
