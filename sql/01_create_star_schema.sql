-- Star schema for the e-commerce data warehouse (PostgreSQL 16)
-- 4 dimension tables + 1 fact table

DROP TABLE IF EXISTS fact_orders CASCADE;
DROP TABLE IF EXISTS dim_customer CASCADE;
DROP TABLE IF EXISTS dim_product CASCADE;
DROP TABLE IF EXISTS dim_date CASCADE;
DROP TABLE IF EXISTS dim_payment CASCADE;

CREATE TABLE dim_customer (
    customer_id SERIAL PRIMARY KEY,
    customer_name VARCHAR(150),
    customer_email VARCHAR(150),
    customer_city VARCHAR(100),
    customer_segment VARCHAR(50)
);

CREATE TABLE dim_product (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(150),
    product_category VARCHAR(100)
);

CREATE TABLE dim_date (
    date_id SERIAL PRIMARY KEY,
    full_date DATE UNIQUE,
    day INT,
    month INT,
    year INT,
    quarter INT
);

CREATE TABLE dim_payment (
    payment_id SERIAL PRIMARY KEY,
    payment_method VARCHAR(100) UNIQUE
);

CREATE TABLE fact_orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id INT REFERENCES dim_customer(customer_id),
    product_id INT REFERENCES dim_product(product_id),
    date_id INT REFERENCES dim_date(date_id),
    payment_id INT REFERENCES dim_payment(payment_id),
    quantity INT,
    unit_price NUMERIC(12,2),
    total_amount NUMERIC(12,2),
    shipping_city VARCHAR(100),
    order_status VARCHAR(50)
);
