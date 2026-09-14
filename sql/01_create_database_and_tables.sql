/*==============================================================
  Project: Container Fleet Commercial Finance Analytics
  File: 01_create_database_and_tables.sql
  Purpose: Create database and core dimension tables
==============================================================*/

IF DB_ID('container_fleet_analytics') IS NULL
BEGIN
    CREATE DATABASE container_fleet_analytics;
END;
GO

USE container_fleet_analytics;
GO


/*==============================================================
  DIMENSION: Branches
==============================================================*/

CREATE TABLE dim_branches (
    branch_id VARCHAR(10) PRIMARY KEY,
    branch_name VARCHAR(100),
    state VARCHAR(10)
);
GO


/*==============================================================
  DIMENSION: Container Types
==============================================================*/

CREATE TABLE dim_container_types (
    container_type_id VARCHAR(10) PRIMARY KEY,
    container_type VARCHAR(100),
    teu_capacity INT
);
GO


/*==============================================================
  DIMENSION: Customers
==============================================================*/

CREATE TABLE dim_customers (
    customer_id VARCHAR(10) PRIMARY KEY,
    customer_name VARCHAR(150),
    customer_segment VARCHAR(100)
);
GO


/*==============================================================
  DIMENSION: Fleet
==============================================================*/

CREATE TABLE dim_fleet (
    container_id VARCHAR(20) PRIMARY KEY,
    container_type_id VARCHAR(10),
    branch_id VARCHAR(10),
    acquisition_date DATE,
    asset_value DECIMAL(12,2),
    status VARCHAR(30),

    CONSTRAINT FK_fleet_container_type
        FOREIGN KEY (container_type_id)
        REFERENCES dim_container_types(container_type_id),

    CONSTRAINT FK_fleet_branch
        FOREIGN KEY (branch_id)
        REFERENCES dim_branches(branch_id)
);
GO
/*==============================================================
  FACT: Hire Transactions
==============================================================*/

CREATE TABLE fact_hire_transactions (
    hire_id VARCHAR(20) PRIMARY KEY,
    hire_start_date DATE,
    hire_end_date DATE,
    hire_days INT,
    customer_id VARCHAR(10),
    container_id VARCHAR(20),
    hire_revenue DECIMAL(12,2),
    transport_revenue DECIMAL(12,2),
    total_revenue DECIMAL(12,2),
    transport_cost DECIMAL(12,2),
    maintenance_cost DECIMAL(12,2),
    total_cost DECIMAL(12,2),
    gross_margin DECIMAL(12,2),
    gross_margin_pct DECIMAL(8,4),

    CONSTRAINT FK_hire_customer
        FOREIGN KEY (customer_id)
        REFERENCES dim_customers(customer_id),

    CONSTRAINT FK_hire_container
        FOREIGN KEY (container_id)
        REFERENCES dim_fleet(container_id)
);
GO


/*==============================================================
  FACT: Budget
==============================================================*/

CREATE TABLE fact_budget (
    budget_year INT,
    budget_month INT,
    revenue_budget DECIMAL(12,2),
    cost_budget DECIMAL(12,2),
    gross_margin_budget DECIMAL(12,2)
);
GO


/*==============================================================
  FACT: Forecast
==============================================================*/

CREATE TABLE fact_forecast (
    forecast_year INT,
    forecast_month INT,
    revenue_forecast DECIMAL(12,2),
    cost_forecast DECIMAL(12,2),
    gross_margin_forecast DECIMAL(12,2)
);
GO

/*==============================================================
  FACT: Container Throughput by Port
==============================================================*/

CREATE TABLE fact_container_throughput (
    financial_year VARCHAR(10),
    port VARCHAR(50),
    teu BIGINT
);
GO


/*==============================================================
  FACT: Cargo by Port
==============================================================*/

CREATE TABLE fact_cargo_by_port (
    financial_year VARCHAR(10),
    port VARCHAR(50),
    million_tonnes DECIMAL(12,6),
    cargo_type VARCHAR(30)
);
GO

/*==============================================================
  DIMENSION: Scenarios
==============================================================*/

CREATE TABLE dim_scenarios (
    scenario_id INT PRIMARY KEY,
    scenario_name VARCHAR(50),
    revenue_growth_pct DECIMAL(8,4),
    cost_growth_pct DECIMAL(8,4)
);
GO