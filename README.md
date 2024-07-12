# Architecture and Setup

# Exploration and Staging / Raw Data

# Transformation and Business Logic

- addresses / localisation / de-localisation / standardisation: Architecture choice between adding normalised column to a table or creating separate tables with normalised data to be joined. Since I am using PostgreSQL which is row-based, adding more columns does not significantly alter performance AND since we are dealing with a small dataset.

# Final Data Marts
