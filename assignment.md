We have been hired by a company to set up their modern data stack. In the first phase, they would like to be able to report on their sales operations.
They're selling various products to customers globally. In this repository, you will find data covering information about customers, employees, orders, products and suppliers. Please use this data for the following tasks.

Using dbt, create a project with the necessary transformations to create the following models:

   1. A transactional fact table for sales, with the grain set at the product level, and the following additional dimensions and metrics:
      1. new or returning customer
      2. number of days between first purchase and last purchase
         *I was confused as to what "the last purchase" would be in a table that is required to be at the product level.*
      
   2. A dimension table for “customers”, with the grain set at the customer_id, and the following additional dimensions and metrics:
      1. number of orders
      2. value of most expensive order
      3. whether it’s one of the top 10 customers (by revenue generated)

   3. A dimension table for monthly cohorts, with the grain set at country level and the following additional dimensions and metrics:
      1. Number of customers in the monthly cohort (customers are assigned in cohorts based on date of their first purchase)
      2. Cohort's total order value
   * Note: Every cohort should be available, even when the business didn't acquire a new customer that month (for the full timerange of order dates).
