/*==============================================================
  Project: Container Fleet Commercial Finance Analytics
  File: 02_load_and_clean_data.sql
  Purpose:
  Load and clean staging data before inserting into final tables
==============================================================*/

USE container_fleet_analytics;
GO


/*==============================================================
  CLEAN CONTAINER THROUGHPUT DATA
  Remove footer/source rows and keep valid financial years only
==============================================================*/

INSERT INTO fact_container_throughput (
    financial_year,
    port,
    teu
)
SELECT
    financial_year,
    port,
    teu
FROM stg_container_throughput
WHERE financial_year LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9]';
GO


/*==============================================================
  CLEAN CARGO DATA
==============================================================*/

INSERT INTO fact_cargo_by_port (
    financial_year,
    port,
    million_tonnes,
    cargo_type
)
SELECT
    financial_year,
    port,
    million_tonnes,
    cargo_type
FROM stg_cargo_by_port
WHERE financial_year LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9]';
GO

/*==============================================================
  LOAD BRANCHES
==============================================================*/

INSERT INTO dim_branches (
    branch_id,
    branch_name,
    state
)
SELECT
    branch_id,
    branch_name,
    state
FROM stg_branches;
GO


/*==============================================================
  LOAD CONTAINER TYPES
==============================================================*/

INSERT INTO dim_container_types (
    container_type_id,
    container_type,
    teu_capacity
)
SELECT
    container_type_id,
    container_type,
    teu_capacity
FROM stg_container_types;
GO


/*==============================================================
  LOAD CUSTOMERS
==============================================================*/

INSERT INTO dim_customers (
    customer_id,
    customer_name,
    customer_segment
)
SELECT
    customer_id,
    customer_name,
    customer_segment
FROM stg_customers;
GO


/*==============================================================
  LOAD FLEET
==============================================================*/

INSERT INTO dim_fleet (
    container_id,
    container_type_id,
    branch_id,
    acquisition_date,
    asset_value,
    status
)
SELECT
    container_id,
    container_type_id,
    branch_id,
    acquisition_date,
    asset_value,
    status
FROM stg_fleet;
GO


/*==============================================================
  LOAD HIRE TRANSACTIONS
==============================================================*/

INSERT INTO fact_hire_transactions (
    hire_id,
    hire_start_date,
    hire_end_date,
    hire_days,
    customer_id,
    container_id,
    hire_revenue,
    transport_revenue,
    total_revenue,
    transport_cost,
    maintenance_cost,
    total_cost,
    gross_margin,
    gross_margin_pct
)
SELECT
    hire_id,
    hire_start_date,
    hire_end_date,
    hire_days,
    customer_id,
    container_id,
    hire_revenue,
    transport_revenue,
    total_revenue,
    transport_cost,
    maintenance_cost,
    total_cost,
    gross_margin,
    gross_margin_pct
FROM stg_hire_transactions;
GO

/*==============================================================
  LOAD BUDGET
==============================================================*/

INSERT INTO fact_budget (
    budget_year,
    budget_month,
    revenue_budget,
    cost_budget,
    gross_margin_budget
)
SELECT
    budget_year,
    budget_month,
    revenue_budget,
    cost_budget,
    gross_margin_budget
FROM stg_budget;
GO


/*==============================================================
  LOAD FORECAST
==============================================================*/

INSERT INTO fact_forecast (
    forecast_year,
    forecast_month,
    revenue_forecast,
    cost_forecast,
    gross_margin_forecast
)
SELECT
    forecast_year,
    forecast_month,
    revenue_forecast,
    cost_forecast,
    gross_margin_forecast
FROM stg_forecast;
GO


/*==============================================================
  LOAD SCENARIOS
==============================================================*/

INSERT INTO dim_scenarios (
    scenario_id,
    scenario_name,
    revenue_growth_pct,
    cost_growth_pct
)
SELECT
    scenario_id,
    scenario_name,
    revenue_growth_pct,
    cost_growth_pct
FROM stg_scenarios;
GO

