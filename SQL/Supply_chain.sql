Create Database supply_chain_data;

SELECT * FROM cleaned_supply_chain_data
LIMIT 10;

DESCRIBE cleaned_supply_chain_data;

-- Q1 -Inventory risk analysis  
SELECT product_type, Round(SUM(revenue_generated),2) as total_revenue FROM cleaned_supply_chain_data
GROUP BY product_type ORDER BY total_revenue DESC;

-- Q2 -Supplier defect analysis
SELECT supplier_name, AVG(defect_rates) as defect_rate FROM cleaned_supply_chain_data
GROUP BY supplier_name ORDER BY defect_rate DESC;

-- Q3 —Revenue analysis 
SELECT product_type, sku, stock_levels, number_of_products_sold FROM cleaned_supply_chain_data
WHERE stock_levels <10 ORDER BY number_of_products_sold DESC;

-- Q4 —Transportation mode analysis 
SELECT transportation_modes, AVG(shipping_costs) as avg_cost, AVG(shipping_times) as avg_time FROM cleaned_supply_chain_data
GROUP BY transportation_modes ; 

-- Q5 —Top SKU revenue analysis 
SELECT sku, SUM(revenue_generated) as total_revenue FROM cleaned_supply_chain_data
GROUP BY sku ORDER BY total_revenue DESC LIMIT 5; 

-- Q6 — Supplier Risk Categorization 

SELECT 
    supplier_name,
    avg_rates,
    avg_time,
    CASE 
        WHEN avg_rates > 3 OR avg_time > 7 
            THEN 'High Risk'

        WHEN avg_rates BETWEEN 2 AND 3 
             OR avg_time BETWEEN 5 AND 7 
            THEN 'Medium Risk'

        ELSE 'Low Risk'
    END AS supplier_risk

FROM (
    SELECT 
        supplier_name,
        AVG(defect_rates) AS avg_rates,
        AVG(shipping_times) AS avg_time
    FROM cleaned_supply_chain_data
    GROUP BY supplier_name
) t;

-- Q7 — Warehouse Performance Analysis
SELECT 
    location,
    COUNT(sku) AS total_products,
    AVG(shipping_times) AS avg_time,
    SUM(revenue_generated) AS total_revenue
FROM cleaned_supply_chain_data
GROUP BY location
ORDER BY total_revenue DESC;

-- Q8 — Product Category Profitability

SELECT 
    product_type,
    SUM(revenue_generated) AS total_revenue,
    SUM(costs) AS total_cost,
    SUM(revenue_generated - costs) AS estimated_profit
FROM cleaned_supply_chain_data
GROUP BY product_type
ORDER BY estimated_profit DESC;

-- Q9 — Late Shipment Detection

SELECT sku, supplier_name, shipping_times, transportation_modes
FROM cleaned_supply_chain_data
WHERE shipping_times >
(
    SELECT AVG(shipping_times)
    FROM cleaned_supply_chain_data
);

-- Q10 — Demand vs Stock Analysis

SELECT 
    sku,
    number_of_products_sold,
    stock_levels,

    CASE 
        WHEN stock_levels < number_of_products_sold 
            THEN 'Restock Needed'

        ELSE 'Stock Sufficient'
    END AS remarks

FROM cleaned_supply_chain_data
ORDER BY number_of_products_sold DESC;


-- Q11 -Top 3 products by total revenue generated

SELECT sku, total_revenue, rnk FROM(SELECT sku, SUM(revenue_generated) as total_revenue, 
DENSE_RANK()OVER(ORDER BY SUM(revenue_generated) DESC) as rnk FROM cleaned_supply_chain_data
GROUP BY sku)t WHERE rnk <=3;
 
-- Q12 — Product Revenue Contribution %
SELECT 
    sku,
    SUM(revenue_generated) AS total_revenue,

    ROUND(
        (
            SUM(revenue_generated) * 100.0
        ) 
        /
        SUM(SUM(revenue_generated)) OVER(),
        2
    ) AS revenue_contribution_pct

FROM cleaned_supply_chain_data
GROUP BY sku
ORDER BY revenue_contribution_pct DESC;

-- Q13 — Rank Suppliers by Defect Rate

SELECT supplier_name, avg_rates, DENSE_RANK() OVER(ORDER BY avg_rates DESC) as supplier_rank FROM 
(SELECT supplier_name,AVG(defect_rates) as avg_rates FROM cleaned_supply_chain_data GROUP BY supplier_name)t;

-- Q14 — Find Highest Revenue Product in Each Product Type

SELECT 
    product_type,
    sku,
    total_revenue
FROM
(
    SELECT 
        sku,
        product_type,
        SUM(revenue_generated) AS total_revenue,

        ROW_NUMBER() OVER(
            PARTITION BY product_type
            ORDER BY SUM(revenue_generated) DESC
        ) AS rnk

    FROM cleaned_supply_chain_data
    GROUP BY sku, product_type
) t
WHERE rnk = 1;


-- Q15 — Moving Average of Defect Rates

SELECT 
    supplier_name,
    defect_rates,

    AVG(defect_rates) OVER(
        ORDER BY defect_rates
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_avg_defect_rate

FROM cleaned_supply_chain_data;

-- Q16 — Supplier Contribution to Total Revenue

SELECT 
    supplier_name,

    SUM(revenue_generated) * 100.0
    /
    SUM(SUM(revenue_generated)) OVER() AS pct_cont,

    DENSE_RANK() OVER(
        ORDER BY SUM(revenue_generated) DESC
    ) AS supplier_rank

FROM cleaned_supply_chain_data

GROUP BY supplier_name;


-- Q17 — Supplier Revenue Classification Using CTE

WITH category AS
(
    SELECT 
        supplier_name,
        SUM(revenue_generated) AS total_revenue
    FROM cleaned_supply_chain_data
    GROUP BY supplier_name
)

SELECT
    supplier_name,
    total_revenue,

    CASE
        WHEN total_revenue > 100000 THEN 'High Revenue'
        WHEN total_revenue BETWEEN 45000 AND 65000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category

FROM category;

-- Q18. Find Top 3 Products by Revenue in Each Product Type

SELECT product_type, sku, total_revenue FROM (SELECT product_type,sku, SUM(revenue_generated) as total_revenue, 
DENSE_RANK() OVER(partition by product_type Order by SUM(revenue_generated) DESC) as rnk FROM cleaned_supply_chain_data
GROUP BY product_type,sku)t WHERE rnk<=3;

-- Q19. Running Total Revenue by Products
WITH product_revenue AS (
    SELECT 
        sku,
        SUM(revenue_generated) AS total_revenue
    FROM cleaned_supply_chain_data
    GROUP BY sku
)

SELECT 
    sku,
    total_revenue,
    
    SUM(total_revenue) OVER(
        ORDER BY total_revenue DESC
    ) AS running_total
    
FROM product_revenue;

-- Q20. Suppliers Contributing More Than Average Revenue
-- Write a query to find suppliers whose total revenue contribution is greater than the average supplier revenue.
SELECT 
    supplier_name,
    SUM(revenue_generated) AS total_rev
    
FROM cleaned_supply_chain_data

GROUP BY supplier_name

HAVING SUM(revenue_generated) > (

    SELECT AVG(total_rev)
    FROM (
        SELECT 
            supplier_name,
            SUM(revenue_generated) AS total_rev
        FROM cleaned_supply_chain_data
        GROUP BY supplier_name
    ) t
);

-- Q21. Find Products With Revenue Higher Than Product-Type Average

-- Write a query to find products (SKU) whose revenue is greater than the average revenue of their own product category.

WITH product_revenue AS (
    
    SELECT 
        product_type,
        sku,
        SUM(revenue_generated) AS total_rev
    FROM cleaned_supply_chain_data
    GROUP BY product_type, sku
),

category_avg AS (
    
    SELECT 
        product_type,
        AVG(total_rev) AS avg_revenue
    FROM product_revenue
    GROUP BY product_type
)

SELECT 
    p.product_type,
    p.sku,
    p.total_rev,
    c.avg_revenue
    
FROM product_revenue p
JOIN category_avg c
ON p.product_type = c.product_type

WHERE p.total_rev > c.avg_revenue;