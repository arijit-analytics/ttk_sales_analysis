-- ==========================================
--  1. Table Setup
-- ==========================================

DROP TABLE IF EXISTS ttk_orders;

CREATE TABLE IF NOT EXISTS ttk_orders (
  country_name VARCHAR(100),
  country_code VARCHAR(20),
  state_name VARCHAR(100),
  state_code VARCHAR(20),
  district_name VARCHAR(100),
  district_code VARCHAR(20),
  city_name VARCHAR(100),
  city_code VARCHAR(20),

  sr_asm_name VARCHAR(100),
  sr_asm_code BIGINT,
  so_name VARCHAR(100),
  so_code BIGINT,

  category_name VARCHAR(100),
  category_code VARCHAR(50),
  brand_name VARCHAR(100),
  brand_code VARCHAR(50),
  sub_category_name VARCHAR(100),
  sub_category_code VARCHAR(50),
  product_size_name VARCHAR(50),
  product_size_code VARCHAR(50),
  variant_name VARCHAR(100),
  variant_code VARCHAR(50),

  group_name VARCHAR(100),
  dist_code VARCHAR(50),
  dist_name VARCHAR(100),
  stockist_code VARCHAR(50),
  stockist_name VARCHAR(100),

  user_code BIGINT,
  user_name VARCHAR(100),
  dsr_code BIGINT,
  dsr_name VARCHAR(100),

  order_no VARCHAR(50),
  sfa_order_no VARCHAR(50),
  order_date DATE,
  route_code VARCHAR(50),
  route_name VARCHAR(100),
  distr_customer_code VARCHAR(50),
  customer_code VARCHAR(50),
  customer_name VARCHAR(100),
  cmp_customer_code VARCHAR(50),

  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  total_order_value NUMERIC(12,2),

  start_time TIME,
  end_time TIME,

  product_code BIGINT,
  product_name VARCHAR(200),
  product_qty INT,
  order_value NUMERIC(12,2)
);

-- ==========================================
--  2. Sales Trends & Overview
-- ==========================================

-- Monthly Sales Trend
SELECT 
    DATE_TRUNC('month', order_date) AS month,
    SUM(order_value) AS total_sales
FROM ttk_orders
GROUP BY month
ORDER BY month;

-- Sales Volume by Category & Month
SELECT 
    category_name,
    DATE_TRUNC('month', order_date) AS month,
    SUM(order_value) AS category_sales
FROM ttk_orders
GROUP BY category_name, month
ORDER BY category_name, month;

-- Sales Contribution by Category
SELECT 
    category_name,
    ROUND(SUM(order_value), 2) AS total_sales,
    ROUND(SUM(order_value) * 100.0 / (SELECT SUM(order_value) FROM ttk_orders), 2) AS contribution_percent
FROM ttk_orders
GROUP BY category_name
ORDER BY contribution_percent DESC;

-- Peak Order Time
SELECT 
    EXTRACT(HOUR FROM start_time) AS order_hour,
    COUNT(*) AS orders
FROM ttk_orders
WHERE start_time IS NOT NULL
GROUP BY order_hour
ORDER BY orders DESC;

-- ==========================================
--  3. Product-Level Analysis
-- ==========================================

-- Top 10 Products by Sales Volume
SELECT 
    product_name,
    ROUND(SUM(order_value), 2) AS total_sales,
    COUNT(DISTINCT order_no) AS unique_orders
FROM ttk_orders
GROUP BY product_name
ORDER BY total_sales DESC
LIMIT 10;

-- SKU Penetration Score
SELECT 
    product_name,
    COUNT(DISTINCT customer_code) AS retailers_ordered,
    COUNT(DISTINCT order_no) AS total_orders
FROM ttk_orders
GROUP BY product_name
ORDER BY retailers_ordered DESC;

-- ==========================================
--  4. Customer Analysis
-- ==========================================

-- Total Customers by Category
SELECT 
    category_name,
    COUNT(DISTINCT customer_code) AS unique_customers
FROM ttk_orders
GROUP BY category_name
ORDER BY unique_customers DESC;

-- Total Customers by Category & Month
SELECT 
    category_name,
    DATE_TRUNC('month', order_date) AS month,
    COUNT(DISTINCT customer_code) AS unique_customers
FROM ttk_orders
GROUP BY category_name, month;

-- Repeat vs. New Customer Analysis
WITH customer_orders AS (
    SELECT customer_code, COUNT(DISTINCT order_no) AS order_count
    FROM ttk_orders
    GROUP BY customer_code
)
SELECT 
    COUNT(*) FILTER (WHERE order_count = 1) AS new_customers,
    COUNT(*) FILTER (WHERE order_count > 1) AS repeat_customers
FROM customer_orders;

-- Top 25 Customers by Spend
SELECT 
    customer_name,
    SUM(order_value) AS total_spent
FROM ttk_orders
GROUP BY customer_name
ORDER BY total_spent DESC
LIMIT 25;

-- ==========================================
--  5. DSR (Sales Rep) Analysis
-- ==========================================

-- Unique Orders by DSR
SELECT 
    dsr_name,
    COUNT(DISTINCT order_no) AS total_unique_orders
FROM ttk_orders
GROUP BY dsr_name
ORDER BY total_unique_orders DESC;

-- DSR-wise Average Order Value
WITH order_totals AS (
    SELECT 
        dsr_name,
        order_no,
        SUM(order_value) AS order_total
    FROM ttk_orders
    GROUP BY dsr_name, order_no
)
SELECT 
    dsr_name,
    COUNT(order_no) AS total_orders,
    ROUND(SUM(order_total)::NUMERIC, 2) AS total_sales,
    ROUND(AVG(order_total)::NUMERIC, 2) AS avg_order_value
FROM order_totals
GROUP BY dsr_name
ORDER BY avg_order_value DESC;

-- DSR Performance Dashboard
SELECT 
    dsr_name,
    COUNT(DISTINCT order_no) AS orders,
    COUNT(DISTINCT customer_code) AS customers,
    ROUND(SUM(order_value), 2) AS total_sales,
    ROUND(AVG(order_value), 2) AS avg_line_value
FROM ttk_orders
GROUP BY dsr_name
ORDER BY total_sales DESC;

-- Average Time Spent per Order (Visit Duration)
SELECT 
    dsr_name,
    ROUND(AVG(EXTRACT(EPOCH FROM (end_time - start_time))/60), 2) AS avg_visit_duration_mins,
    COUNT(DISTINCT order_no) AS visits
FROM ttk_orders
WHERE end_time IS NOT NULL AND start_time IS NOT NULL
GROUP BY dsr_name
ORDER BY avg_visit_duration_mins DESC;

-- ==========================================
--  6. Order Value Metrics
-- ==========================================

-- Average Order Value (AOV)
WITH order_totals AS (
    SELECT 
        order_no,
        DATE_TRUNC('month', order_date) AS month,
        SUM(order_value) AS order_total
    FROM ttk_orders
    GROUP BY order_no, month
)
SELECT 
    month,
    ROUND(SUM(order_total)::NUMERIC, 2) AS total_sales,
    COUNT(order_no) AS total_orders,
    ROUND(AVG(order_total)::NUMERIC, 2) AS avg_order_value
FROM order_totals
GROUP BY month
ORDER BY month;
