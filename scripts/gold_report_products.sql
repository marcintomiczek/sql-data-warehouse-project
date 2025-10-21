CREATE VIEW gold.report_products AS
WITH product_sales AS (
  SELECT
    p.product_key,
    p.product_name,
    p.category,
    p.subcategory,
    p.cost,
    f.order_number,
    f.sales_amount,
    f.quantity,
    f.customer_key,
    f.order_date,
    CASE WHEN sales_amount - cost * quantity > 1000 THEN 'High-Performers'
    	 WHEN sales_amount - cost * quantity > 100 THEN 'Mid-Range'
    	 ELSE 'Low-Performers'
    END as revenue
  FROM gold.fact_sales f
  LEFT JOIN gold.dim_products p
  ON f.product_key = p.product_key
  WHERE order_date IS NOT NULL
),
base_query AS (
  SELECT
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    COUNT(DISTINCT order_number) total_orders,
    SUM(sales_amount) total_sales,
    SUM(quantity) total_quantity,
    COUNT(DISTINCT customer_key) total_customers,
    DATEDIFF(month, MIN(order_date), MAX(order_date)) lifespan,
    MAX(order_date) AS last_sale_date,
    ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)), 1) AS avg_selling_price
  FROM product_sales
  GROUP BY product_key, product_name, category, subcategory, cost
)

SELECT
  product_key,
  product_name,
  category,
  subcategory,
  cost,
  last_sale_date,
  DATEDIFF(MONTH, last_sale_date, GETDATE()) AS recency_in_months,
  CASE WHEN total_sales > 50000 THEN 'High-Performers'
  	 WHEN total_sales >= 10000 THEN 'Mid-Range'
  	 ELSE 'Low-Performers'
  END as product_segment,
  lifespan,
  total_orders,
  total_customers,
  total_sales,
  total_quantity,
  avg_selling_price,
  -- Average order revenue
  CASE
  	WHEN total_orders = 0 THEN 0
  	ELSE total_sales / total_orders
  END as avg_order_revenue,
  -- Average Monthly revenue
  CASE
  	WHEN lifespan = 0 THEN total_sales
  	ELSE total_sales / lifespan
  END as avg_monthly_revenue
FROM base_query
