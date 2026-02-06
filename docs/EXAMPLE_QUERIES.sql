-- ============================================
-- Queries de Ejemplo para AWS Athena
-- dbt Dimensional Modelling - AdventureWorks
-- ============================================

-- NOTA: Ejecuta estas queries en AWS Athena Console
-- https://console.aws.amazon.com/athena/

-- ============================================
-- 1. EXPLORACIÓN BÁSICA
-- ============================================

-- Ver las primeras filas de cada tabla
SELECT * FROM adventureworks.marts.dim_product LIMIT 10;
SELECT * FROM adventureworks.marts.dim_customer LIMIT 10;
SELECT * FROM adventureworks.marts.fct_sales LIMIT 10;

-- Contar registros en cada tabla
SELECT 'dim_product' as tabla, COUNT(*) as registros FROM adventureworks.marts.dim_product
UNION ALL
SELECT 'dim_customer', COUNT(*) FROM adventureworks.marts.dim_customer
UNION ALL
SELECT 'dim_address', COUNT(*) FROM adventureworks.marts.dim_address
UNION ALL
SELECT 'dim_credit_card', COUNT(*) FROM adventureworks.marts.dim_credit_card
UNION ALL
SELECT 'dim_date', COUNT(*) FROM adventureworks.marts.dim_date
UNION ALL
SELECT 'dim_order_status', COUNT(*) FROM adventureworks.marts.dim_order_status
UNION ALL
SELECT 'fct_sales', COUNT(*) FROM adventureworks.marts.fct_sales
UNION ALL
SELECT 'obt_sales', COUNT(*) FROM adventureworks.marts.obt_sales
ORDER BY registros DESC;

-- ============================================
-- 2. ANÁLISIS CON DIMENSIONES
-- ============================================

-- Ventas por categoría de producto
SELECT 
    product_category_name,
    COUNT(DISTINCT salesorderid) as total_orders,
    COUNT(*) as total_items,
    SUM(orderqty) as total_quantity,
    SUM(revenue) as total_revenue,
    ROUND(AVG(unitprice), 2) as avg_unit_price
FROM adventureworks.marts.obt_sales
GROUP BY product_category_name
ORDER BY total_revenue DESC;

-- Ventas por país
SELECT 
    country_name,
    COUNT(DISTINCT salesorderid) as total_orders,
    SUM(revenue) as total_revenue,
    ROUND(AVG(revenue), 2) as avg_order_value
FROM adventureworks.marts.obt_sales
GROUP BY country_name
ORDER BY total_revenue DESC;

-- Top 10 productos más vendidos
SELECT 
    product_name,
    product_category_name,
    SUM(orderqty) as units_sold,
    SUM(revenue) as total_revenue
FROM adventureworks.marts.obt_sales
GROUP BY product_name, product_category_name
ORDER BY total_revenue DESC
LIMIT 10;

-- ============================================
-- 3. ANÁLISIS TEMPORAL
-- ============================================

-- Ventas por año y mes
SELECT 
    year_actual as year,
    month_name,
    COUNT(DISTINCT salesorderid) as orders,
    SUM(revenue) as revenue
FROM adventureworks.marts.obt_sales
GROUP BY year_actual, month_name, month_of_year
ORDER BY year_actual, month_of_year;

-- Ventas por día de la semana
SELECT 
    day_name,
    COUNT(DISTINCT salesorderid) as total_orders,
    SUM(revenue) as total_revenue,
    ROUND(AVG(revenue), 2) as avg_order_value
FROM adventureworks.marts.obt_sales
GROUP BY day_name, day_of_week
ORDER BY day_of_week;

-- Ventas por trimestre
SELECT 
    year_actual,
    quarter_of_year,
    SUM(revenue) as revenue,
    COUNT(DISTINCT salesorderid) as orders
FROM adventureworks.marts.obt_sales
GROUP BY year_actual, quarter_of_year
ORDER BY year_actual, quarter_of_year;

-- ============================================
-- 4. ANÁLISIS DE CLIENTES
-- ============================================

-- Top 10 clientes por revenue
SELECT 
    fullname,
    COUNT(DISTINCT salesorderid) as total_orders,
    SUM(revenue) as total_revenue,
    ROUND(AVG(revenue), 2) as avg_order_value
FROM adventureworks.marts.obt_sales
WHERE fullname IS NOT NULL
GROUP BY fullname
ORDER BY total_revenue DESC
LIMIT 10;

-- Distribución de órdenes por estado
SELECT 
    order_status_name,
    COUNT(DISTINCT salesorderid) as total_orders,
    SUM(revenue) as total_revenue,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) as percentage
FROM adventureworks.marts.obt_sales
GROUP BY order_status_name
ORDER BY total_orders DESC;

-- ============================================
-- 5. ANÁLISIS CON JOINS (usando fact + dims)
-- ============================================

-- Revenue por producto y país (usando joins explícitos)
SELECT 
    p.product_category_name,
    a.country_name,
    SUM(f.revenue) as total_revenue,
    COUNT(DISTINCT f.salesorderid) as total_orders
FROM adventureworks.marts.fct_sales f
INNER JOIN adventureworks.marts.dim_product p ON f.product_key = p.product_key
INNER JOIN adventureworks.marts.dim_address a ON f.ship_address_key = a.address_key
GROUP BY p.product_category_name, a.country_name
ORDER BY total_revenue DESC
LIMIT 20;

-- Análisis de método de pago
SELECT 
    COALESCE(cc.cardtype, 'No Card') as payment_method,
    COUNT(DISTINCT f.salesorderid) as orders,
    SUM(f.revenue) as revenue
FROM adventureworks.marts.fct_sales f
LEFT JOIN adventureworks.marts.dim_credit_card cc ON f.creditcard_key = cc.creditcard_key
GROUP BY COALESCE(cc.cardtype, 'No Card')
ORDER BY revenue DESC;

-- ============================================
-- 6. MÉTRICAS AVANZADAS
-- ============================================

-- KPIs generales de ventas
SELECT 
    COUNT(DISTINCT salesorderid) as total_orders,
    COUNT(DISTINCT customerid) as total_customers,
    SUM(revenue) as total_revenue,
    ROUND(AVG(revenue), 2) as avg_order_value,
    ROUND(SUM(revenue) / COUNT(DISTINCT customerid), 2) as revenue_per_customer,
    MIN(date_day) as first_order_date,
    MAX(date_day) as last_order_date
FROM adventureworks.marts.obt_sales;

-- Productos con mejor margen (simplificado - asumiendo cost = 60% del precio)
SELECT 
    product_name,
    product_category_name,
    SUM(revenue) as total_revenue,
    SUM(revenue * 0.40) as estimated_profit,
    ROUND(100.0 * 0.40, 2) as profit_margin_pct
FROM adventureworks.marts.obt_sales
GROUP BY product_name, product_category_name
ORDER BY estimated_profit DESC
LIMIT 10;

-- Análisis cohort por mes de primera compra
WITH first_purchase AS (
    SELECT 
        customerid,
        MIN(date_day) as first_purchase_date,
        DATE_FORMAT(MIN(date_day), '%Y-%m') as cohort_month
    FROM adventureworks.marts.obt_sales
    WHERE customerid IS NOT NULL
    GROUP BY customerid
)
SELECT 
    fp.cohort_month,
    COUNT(DISTINCT fp.customerid) as customers_in_cohort,
    SUM(o.revenue) as total_revenue
FROM first_purchase fp
INNER JOIN adventureworks.marts.obt_sales o ON fp.customerid = o.customerid
GROUP BY fp.cohort_month
ORDER BY fp.cohort_month;

-- ============================================
-- 7. QUERIES PARA VALIDACIÓN DE CALIDAD
-- ============================================

-- Verificar que no hay valores nulos en keys
SELECT 
    'fct_sales' as tabla,
    SUM(CASE WHEN sales_key IS NULL THEN 1 ELSE 0 END) as null_sales_keys,
    SUM(CASE WHEN product_key IS NULL THEN 1 ELSE 0 END) as null_product_keys,
    SUM(CASE WHEN customer_key IS NULL THEN 1 ELSE 0 END) as null_customer_keys
FROM adventureworks.marts.fct_sales;

-- Verificar duplicados en dimensiones
SELECT 
    productid,
    COUNT(*) as count
FROM adventureworks.marts.dim_product
GROUP BY productid
HAVING COUNT(*) > 1;

-- Rango de fechas en los datos
SELECT 
    MIN(date_day) as min_date,
    MAX(date_day) as max_date,
    DATE_DIFF('day', MIN(date_day), MAX(date_day)) as days_span
FROM adventureworks.marts.dim_date;

-- ============================================
-- 8. QUERIES DE OPTIMIZACIÓN (para aprender)
-- ============================================

-- Ver el tamaño de las tablas en S3
-- (Ejecutar en AWS CLI o boto3, no funciona directo en Athena)
-- aws s3 ls s3://dbt-adventureworks-silver-{ACCOUNT_ID}/marts/ --recursive --human-readable --summarize

-- Ver estadísticas de las tablas
SHOW TBLPROPERTIES adventureworks.marts.fct_sales;

-- Ver la estructura de una tabla
DESCRIBE adventureworks.marts.fct_sales;
DESCRIBE FORMATTED adventureworks.marts.fct_sales;

-- ============================================
-- TIPS PARA ESTUDIANTES:
-- ============================================
-- 1. Usa LIMIT cuando explores datos nuevos
-- 2. Athena cobra por datos escaneados, usa WHERE cuando sea posible
-- 3. Las tablas en formato Parquet son más rápidas y económicas
-- 4. Guarda tus queries útiles en la carpeta analyses/ del proyecto dbt
-- 5. Usa EXPLAIN para ver el plan de ejecución de queries complejas
-- ============================================
