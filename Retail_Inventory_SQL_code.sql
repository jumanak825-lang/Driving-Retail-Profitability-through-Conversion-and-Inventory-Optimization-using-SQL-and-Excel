-- CREATE DATABASE
CREATE DATABASE retail_profitability;
USE retail_profitability;

-- CREATE TABLES
CREATE TABLE stores (
    store_id INT PRIMARY KEY,
    store_name VARCHAR(100) NOT NULL,
    conversion_rate DECIMAL(5,2) NOT NULL CHECK (conversion_rate >= 0 AND conversion_rate <= 100)
);

CREATE TABLE product_categories (
    category_id INT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL
);

CREATE TABLE sales (
    sale_id INT PRIMARY KEY,
    store_id INT NOT NULL,
    category_id INT NOT NULL,
    sale_date DATE NOT NULL,
    units_sold INT NOT NULL,
    revenue DECIMAL(12,2) NOT NULL,
    FOREIGN KEY (store_id) REFERENCES stores(store_id),
    FOREIGN KEY (category_id) REFERENCES product_categories(category_id)
);

CREATE TABLE inventory (
    inventory_id INT PRIMARY KEY,
    store_id INT NOT NULL,
    category_id INT NOT NULL,
    stock_qty INT NOT NULL,
    reorder_point INT NOT NULL,
    risk_level VARCHAR(20) CHECK (risk_level IN ('Healthy', 'Overstock', 'Stockout')),
    FOREIGN KEY (store_id) REFERENCES stores(store_id),
    FOREIGN KEY (category_id) REFERENCES product_categories(category_id)
);

-- INSERT: STORES
INSERT INTO stores (store_id, store_name, conversion_rate) VALUES
(101, 'Greenwood', 25.4),
(102, 'Oakridge', 27.0),
(103, 'Lakeside', 26.5),
(104, 'Uptown', 30.1),
(105, 'Maplewood', 28.3);

-- INSERT: PRODUCT CATEGORIES
INSERT INTO product_categories (category_id, category_name) VALUES
(1, 'Electronics'),
(2, 'Apparel'),
(3, 'Sports'),
(4, 'Beauty'),
(5, 'Home & Kitchen');

-- INSERT: SALES
INSERT INTO sales (sale_id, store_id, category_id, sale_date, units_sold, revenue) VALUES
(1,104,1,'2025-06-21',40,144000),
(2,105,2,'2025-06-21',60,90000),
(3,102,5,'2025-06-21',20,40000),
(4,101,3,'2025-06-20',30,30000),
(5,103,4,'2025-06-18',25,50000),
(6,104,2,'2025-06-15',10,15000),
(7,105,1,'2025-06-22',5,5000),
(8,102,3,'2025-06-23',40,80000),
(9,103,1,'2025-07-01',15,60000),
(10,101,5,'2025-07-02',7,21000);

-- INSERT: INVENTORY
INSERT INTO inventory (inventory_id, store_id, category_id, stock_qty, reorder_point, risk_level) VALUES
(1,101,2,120,50,'Overstock'),
(2,102,1,250,100,'Overstock'),
(3,103,3,5,40,'Stockout'),
(4,101,1,120,100,'Healthy'),
(5,101,3,45,40,'Healthy'),
(6,101,4,35,30,'Healthy'),
(7,101,5,60,60,'Healthy'),
(8,102,2,50,50,'Healthy'),
(9,102,3,45,40,'Healthy'),
(10,102,4,30,30,'Healthy'),
(11,102,5,61,60,'Healthy'),
(12,103,1,100,100,'Healthy');

-- ANALYSIS QUERY 1: STORE PERFORMANCE
SELECT 
    s.store_id,
    s.store_name,
    SUM(sa.revenue) AS total_sales,
    ROUND(SUM(sa.revenue) / COUNT(DISTINCT sa.sale_date),2) AS avg_daily_sales,
    s.conversion_rate
FROM stores s
LEFT JOIN sales sa ON s.store_id = sa.store_id
GROUP BY s.store_id, s.store_name, s.conversion_rate
ORDER BY total_sales DESC;

-- ANALYSIS QUERY 2: DAILY SALES TREND
SELECT sale_date, SUM(revenue) AS daily_sales
FROM sales
GROUP BY sale_date
ORDER BY sale_date;

-- ANALYSIS QUERY 3: PEAK SALES DAY
SELECT sale_date, SUM(revenue) AS total
FROM sales
GROUP BY sale_date
ORDER BY total DESC
LIMIT 1;

-- ANALYSIS QUERY 4: CATEGORY-WISE REVENUE SHARE
SELECT 
    pc.category_name,
    SUM(s.revenue) AS category_sales,
    ROUND(100 * SUM(s.revenue) / (SELECT SUM(revenue) FROM sales), 2) AS pct_share
FROM sales s
JOIN product_categories pc ON s.category_id = pc.category_id
GROUP BY pc.category_name
ORDER BY category_sales DESC;

-- ANALYSIS QUERY 5: INVENTORY RISK SUMMARY
SELECT 
    pc.category_name,
    i.risk_level,
    COUNT(*) AS count_items
FROM inventory i
JOIN product_categories pc ON i.category_id = pc.category_id
GROUP BY pc.category_name, i.risk_level
ORDER BY pc.category_name, i.risk_level;

-- ANALYSIS QUERY 6: CATEGORIES WITH RISK
SELECT 
    pc.category_name,
    SUM(CASE WHEN i.risk_level = 'Overstock' THEN 1 ELSE 0 END) AS overstock_count,
    SUM(CASE WHEN i.risk_level = 'Stockout' THEN 1 ELSE 0 END) AS stockout_count
FROM inventory i
JOIN product_categories pc ON i.category_id = pc.category_id
GROUP BY pc.category_name
HAVING overstock_count > 0 OR stockout_count > 0;

-- ANALYSIS QUERY 7: HIGH-PERFORMING STORES WITH INVENTORY ISSUES
SELECT 
    s.store_id,
    s.store_name,
    SUM(sa.revenue) AS total_sales,
    COUNT(CASE WHEN i.risk_level IN ('Overstock','Stockout') THEN 1 END) AS risky_items
FROM stores s
JOIN sales sa ON s.store_id = sa.store_id
JOIN inventory i ON s.store_id = i.store_id
GROUP BY s.store_id, s.store_name
HAVING total_sales > (SELECT AVG(revenue) FROM sales)
   AND risky_items > 0
ORDER BY total_sales DESC;

-- ANALYSIS QUERY 8: DEMAND MISMATCH (HIGH STOCK, LOW SALES)
SELECT
    i.store_id,
    i.category_id,
    i.stock_qty,
    COALESCE(SUM(s.units_sold),0) AS units_sold
FROM inventory i
LEFT JOIN sales s ON i.store_id = s.store_id AND i.category_id = s.category_id
GROUP BY i.store_id, i.category_id, i.stock_qty
HAVING i.stock_qty > 2 * COALESCE(SUM(s.units_sold),0);

-- ANALYSIS QUERY 9: DEAD STOCK (NO SALES)
SELECT 
    i.store_id,
    i.category_id,
    i.stock_qty
FROM inventory i
LEFT JOIN sales s ON i.store_id = s.store_id AND i.category_id = s.category_id
GROUP BY i.store_id, i.category_id, i.stock_qty
HAVING SUM(s.units_sold) IS NULL OR SUM(s.units_sold) = 0;
