# Architecture and Setup

# Exploration and Staging / Raw Data

- Problem: 658 rows from the `order_details` table reference a wrong unit price, assuming that this table references the unit price from the `products` table via the `product_id`. This can either straight up be an upstream mistake inside the data source OR it can be a legacy issue: The unit price used to be A (recorded in the `order_details` table) but now it is B (indicated by the `products` table). Since we do not know which of the two options is the case (mistake vs. legacy), we might want to fork all downstream metrics into those based on unit price A and those based on unit price B, until we know which one to get rid of.

# Transformation and Business Logic

- addresses / localisation / de-localisation / standardisation: Architecture choice between adding normalised column to a table or creating separate tables with normalised data to be joined. Since I am using PostgreSQL which is row-based, adding more columns does not significantly alter performance AND since we are dealing with a small dataset.

# Final Data Marts
