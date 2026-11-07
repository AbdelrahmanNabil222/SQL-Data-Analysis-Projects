# Sales Data Analysis with SQL (SQL Server)

A set of T-SQL queries that analyze sales performance over time, product performance, category contribution, and customer behavior using window functions, CTEs, and conditional segmentation.

## Business Questions
- How do sales, customers, and quantity change month over month and year over year?
- What is the cumulative sales trend?
- Which products are growing or declining compared with the previous year and with their own average?
- Which categories contribute the most to total sales?
- How are products distributed across cost ranges?
- How many customers are VIP, Regular, or New?

## Data Model
A star schema with three tables:

| Table | Type | Key columns |
|-------|------|-------------|
| `fact_sales` | Fact | order_number, order_date, product_key, customer_key, sales_amount, quantity, price |
| `dim_customers` | Dimension | customer_key, first_name, last_name, country, birthdate |
| `dim_products` | Dimension | product_key, product_id, product_name, category, cost |

## Tools
Microsoft SQL Server, T-SQL, SSMS

## Analyses and SQL Techniques

| # | Analysis | Techniques |
|---|----------|------------|
| 1 | Change over time (monthly sales, customers, quantity) | `YEAR()`, `MONTH()`, `DATETRUNC()`, `FORMAT()`, `GROUP BY` |
| 2 | Cumulative analysis (running total and running average) | Window functions: `SUM() OVER`, `AVG() OVER`, subquery |
| 3 | Performance analysis (year over year and vs average per product) | CTE, `LAG()`, `PARTITION BY`, `CASE WHEN` |
| 4 | Part-to-whole (category share of total sales) | CTE, `SUM() OVER ()`, percentage calculation |
| 5 | Product segmentation by cost range | `CASE WHEN`, aggregation |
| 6 | Customer segmentation (VIP / Regular / New) | CTE, `DATEDIFF()`, `CASE WHEN` |
| 7 | Customer base query (core report columns) | `JOIN`, `CONCAT()`, age calculation |

### Customer Segmentation Rules
- **VIP:** at least 12 months of history and total spending above 5,000
- **Regular:** at least 12 months of history and total spending of 5,000 or less
- **New:** less than 12 months of history

## Sample Query

```sql
-- Yearly sales per product vs previous year
WITH yearly_product_sales AS (
    SELECT
        YEAR(s.order_date)  AS order_year,
        p.product_name,
        SUM(s.sales_amount) AS current_sales
    FROM fact_sales s
    INNER JOIN dim_products p ON p.product_key = s.product_key
    WHERE s.order_date IS NOT NULL
    GROUP BY YEAR(s.order_date), p.product_name
)
SELECT
    order_year,
    product_name,
    current_sales,
    LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS previous_year_sales
FROM yearly_product_sales;
