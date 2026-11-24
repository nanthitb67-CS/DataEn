-- =====================================================================
-- TastyGo SQL Course Schema (PostgreSQL)
-- Running case: same TastyGo (food delivery) dataset used across the
-- Data Engineering course. Loaded once at the start of the SQL module
-- and reused/extended chapter by chapter (raw -> clean -> warehouse).
-- =====================================================================

DROP TABLE IF EXISTS fact_orders CASCADE;
DROP TABLE IF EXISTS dim_date CASCADE;
DROP TABLE IF EXISTS dim_rider CASCADE;
DROP TABLE IF EXISTS dim_restaurant CASCADE;
DROP TABLE IF EXISTS dim_customer CASCADE;
DROP TABLE IF EXISTS activity_log CASCADE;
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS raw_orders CASCADE;
DROP TABLE IF EXISTS riders CASCADE;
DROP TABLE IF EXISTS restaurants CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

-- --------------------------------------------------------- reference --
CREATE TABLE customers (
    customer_id   VARCHAR(10) PRIMARY KEY,
    customer_name TEXT,
    email         TEXT,
    phone         TEXT,
    city          TEXT,
    referred_by   VARCHAR(10) REFERENCES customers(customer_id),
    signup_date   DATE
);

CREATE TABLE restaurants (
    restaurant_id   VARCHAR(10) PRIMARY KEY,
    restaurant_name TEXT NOT NULL,
    category        TEXT,
    area            TEXT,
    tags            TEXT[],
    is_active       BOOLEAN DEFAULT TRUE
);

CREATE TABLE riders (
    rider_id       VARCHAR(10) PRIMARY KEY,
    rider_name     TEXT,
    vehicle_type   TEXT CHECK (vehicle_type IN ('motorcycle', 'bicycle', 'car')),
    current_status TEXT CHECK (current_status IN ('available', 'on_delivery', 'offline')),
    updated_at     TIMESTAMP
);

-- ----------------------------------------------------- raw / staging --
-- Mirrors data/tastygo_orders.csv column-for-column, all TEXT on purpose:
-- Chapter 2 (CAST) and Chapter 8 (Data Cleaning) start from this table.
CREATE TABLE raw_orders (
    order_id      TEXT,
    customer_id   TEXT,
    restaurant_id TEXT,
    total_amount  TEXT,
    delivery_fee  TEXT,
    order_date    TEXT,
    area          TEXT,
    order_status  TEXT,
    loaded_at     TIMESTAMP DEFAULT now()
);

-- --------------------------------------------------------- OLTP-ish ---
-- Built FROM raw_orders during the course (Chapter 2 / Chapter 13 workshops).
-- Created empty here so the schema can be inspected from Chapter 1 onward.
CREATE TABLE orders (
    order_id      VARCHAR(10) PRIMARY KEY,
    customer_id   VARCHAR(10) REFERENCES customers(customer_id),
    restaurant_id VARCHAR(10) REFERENCES restaurants(restaurant_id),
    total_amount  NUMERIC(10, 2),
    delivery_fee  NUMERIC(10, 2),
    order_date    DATE,
    area          TEXT,
    order_status  TEXT CHECK (order_status IN ('pending', 'paid', 'delivered', 'cancelled')),
    rider_id      VARCHAR(10) REFERENCES riders(rider_id)
);

CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id      TEXT,                 -- not FK on purpose: some reference raw_orders' dirty ids
    menu_item     TEXT,
    category      TEXT,
    quantity      INT,
    unit_price    NUMERIC(10, 2)
);

CREATE TABLE payments (
    payment_id VARCHAR(14) PRIMARY KEY,
    order_id   TEXT,                    -- not FK on purpose: a few rows are intentionally orphaned
    status     TEXT,
    amount     NUMERIC(10, 2),
    paid_at    TIMESTAMP,
    loaded_at  TIMESTAMP DEFAULT now()
);

CREATE TABLE activity_log (
    log_id     SERIAL PRIMARY KEY,
    event_time TIMESTAMP,
    user_id    TEXT,                    -- not FK on purpose: some events come from guests
    action     TEXT,
    status     TEXT,
    metadata   JSONB
);

-- ---------------------------------------------------- warehouse (Ch14) --
-- Left empty: Chapter 13/14 workshops populate these with INSERT SELECT.
CREATE TABLE dim_customer (
    customer_key   SERIAL PRIMARY KEY,
    customer_id    VARCHAR(10) NOT NULL,
    customer_name  TEXT,
    city           TEXT,
    effective_date DATE NOT NULL,
    end_date       DATE,
    is_current     BOOLEAN DEFAULT TRUE
);

CREATE TABLE dim_restaurant (
    restaurant_key  SERIAL PRIMARY KEY,
    restaurant_id   VARCHAR(10) NOT NULL,
    restaurant_name TEXT,
    category        TEXT,
    area            TEXT,
    effective_date  DATE NOT NULL,
    end_date        DATE,
    is_current      BOOLEAN DEFAULT TRUE
);

CREATE TABLE dim_rider (
    rider_key    SERIAL PRIMARY KEY,
    rider_id     VARCHAR(10) NOT NULL,
    rider_name   TEXT,
    vehicle_type TEXT
);

CREATE TABLE dim_date (
    date_key    INT PRIMARY KEY,
    full_date   DATE NOT NULL,
    day         INT,
    month       INT,
    quarter     INT,
    year        INT,
    day_of_week TEXT,
    is_weekend  BOOLEAN
);

CREATE TABLE fact_orders (
    order_id        VARCHAR(10) PRIMARY KEY,
    customer_key    INT REFERENCES dim_customer(customer_key),
    restaurant_key  INT REFERENCES dim_restaurant(restaurant_key),
    rider_key       INT REFERENCES dim_rider(rider_key),
    date_key        INT REFERENCES dim_date(date_key),
    total_amount    NUMERIC(10, 2),
    delivery_fee    NUMERIC(10, 2),
    order_status    TEXT
);
