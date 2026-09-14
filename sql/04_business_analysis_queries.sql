/*==============================================================
  Project: Container Fleet Commercial Finance Analytics
  File: 04_business_analysis_queries.sql
  Purpose:
  Business analysis queries for commercial finance insights
==============================================================*/

USE container_fleet_analytics;
GO


/*==============================================================
  1. OVERALL FINANCIAL PERFORMANCE
==============================================================*/

SELECT
    SUM(total_revenue) AS total_revenue,
    SUM(total_cost) AS total_cost,
    SUM(gross_margin) AS total_gross_margin,

    CASE
        WHEN SUM(total_revenue) = 0 THEN 0
        ELSE SUM(gross_margin) / SUM(total_revenue)
    END AS gross_margin_pct

FROM fact_hire_transactions;
GO


/*==============================================================
  2. FINANCIAL PERFORMANCE BY BRANCH
==============================================================*/

SELECT
    b.branch_name,

    COUNT(DISTINCT h.hire_id) AS total_hires,

    SUM(h.total_revenue) AS total_revenue,
    SUM(h.total_cost) AS total_cost,
    SUM(h.gross_margin) AS gross_margin,

    CASE
        WHEN SUM(h.total_revenue) = 0 THEN 0
        ELSE SUM(h.gross_margin) / SUM(h.total_revenue)
    END AS gross_margin_pct

FROM fact_hire_transactions h

LEFT JOIN dim_fleet f
    ON h.container_id = f.container_id

LEFT JOIN dim_branches b
    ON f.branch_id = b.branch_id

GROUP BY
    b.branch_name

ORDER BY
    total_revenue DESC;
GO


/*==============================================================
  3. FINANCIAL PERFORMANCE BY CUSTOMER
==============================================================*/

SELECT
    c.customer_name,

    COUNT(DISTINCT h.hire_id) AS total_hires,

    SUM(h.total_revenue) AS total_revenue,
    SUM(h.total_cost) AS total_cost,
    SUM(h.gross_margin) AS gross_margin,

    CASE
        WHEN SUM(h.total_revenue) = 0 THEN 0
        ELSE SUM(h.gross_margin) / SUM(h.total_revenue)
    END AS gross_margin_pct

FROM fact_hire_transactions h

LEFT JOIN dim_customers c
    ON h.customer_id = c.customer_id

GROUP BY
    c.customer_name

ORDER BY
    total_revenue DESC;
GO

/*==============================================================
  4. FINANCIAL PERFORMANCE BY CONTAINER TYPE
==============================================================*/

SELECT
    ct.container_type,

    COUNT(DISTINCT h.hire_id) AS total_hires,

    SUM(h.total_revenue) AS total_revenue,
    SUM(h.total_cost) AS total_cost,
    SUM(h.gross_margin) AS gross_margin,

    CASE
        WHEN SUM(h.total_revenue) = 0 THEN 0
        ELSE SUM(h.gross_margin) / SUM(h.total_revenue)
    END AS gross_margin_pct

FROM fact_hire_transactions h

LEFT JOIN dim_fleet f
    ON h.container_id = f.container_id

LEFT JOIN dim_container_types ct
    ON f.container_type_id = ct.container_type_id

GROUP BY
    ct.container_type

ORDER BY
    total_revenue DESC;
GO


/*==============================================================
  5. YEARLY FINANCIAL PERFORMANCE
==============================================================*/

SELECT
    YEAR(hire_start_date) AS financial_year,

    COUNT(DISTINCT hire_id) AS total_hires,

    SUM(total_revenue) AS total_revenue,
    SUM(total_cost) AS total_cost,
    SUM(gross_margin) AS gross_margin,

    CASE
        WHEN SUM(total_revenue) = 0 THEN 0
        ELSE SUM(gross_margin) / SUM(total_revenue)
    END AS gross_margin_pct

FROM fact_hire_transactions

GROUP BY
    YEAR(hire_start_date)

ORDER BY
    financial_year;
GO


/*==============================================================
  6. 2025 BUDGET VS ACTUAL
==============================================================*/

SELECT
    budget_year,
    budget_month,

    revenue_budget,
    actual_revenue,
    revenue_variance,
    revenue_variance_pct,

    cost_budget,
    actual_cost,
    cost_variance,

    gross_margin_budget,
    actual_gross_margin,
    gross_margin_variance,
    gross_margin_variance_pct

FROM vw_budget_vs_actual

WHERE budget_year = 2025

ORDER BY
    budget_month;
GO

/*==============================================================
  7. 2025 FLEET UTILISATION BY BRANCH
==============================================================*/

WITH HiredDays2025 AS (
    SELECT
        f.branch_id,
        h.container_id,

        SUM(
            DATEDIFF(
                DAY,
                CASE
                    WHEN h.hire_start_date < '2025-01-01'
                        THEN '2025-01-01'
                    ELSE h.hire_start_date
                END,
                CASE
                    WHEN h.hire_end_date > '2026-01-01'
                        THEN '2026-01-01'
                    ELSE h.hire_end_date
                END
            )
        ) AS hired_days

    FROM fact_hire_transactions h

    INNER JOIN dim_fleet f
        ON h.container_id = f.container_id

    WHERE
        h.hire_end_date > '2025-01-01'
        AND h.hire_start_date < '2026-01-01'

    GROUP BY
        f.branch_id,
        h.container_id
),

BranchUtilisation AS (
    SELECT
        b.branch_name,
        COUNT(DISTINCT f.container_id) AS fleet_size,
        COALESCE(SUM(h.hired_days), 0) AS hired_days,
        COUNT(DISTINCT f.container_id) * 365 AS available_days

    FROM dim_fleet f

    LEFT JOIN dim_branches b
        ON f.branch_id = b.branch_id

    LEFT JOIN HiredDays2025 h
        ON f.container_id = h.container_id

    GROUP BY
        b.branch_name
)

SELECT
    branch_name,
    fleet_size,
    hired_days,
    available_days,

    CAST(hired_days AS DECIMAL(12,2))
        / NULLIF(available_days, 0)
        AS utilisation_pct

FROM BranchUtilisation

ORDER BY
    utilisation_pct DESC;
GO


/*==============================================================
  8. 2025 REVENUE PER CONTAINER BY BRANCH
==============================================================*/

SELECT
    b.branch_name,

    COUNT(DISTINCT f.container_id) AS fleet_size,

    SUM(h.total_revenue) AS total_revenue,

    SUM(h.total_revenue)
        / NULLIF(COUNT(DISTINCT f.container_id), 0)
        AS revenue_per_container

FROM fact_hire_transactions h

INNER JOIN dim_fleet f
    ON h.container_id = f.container_id

INNER JOIN dim_branches b
    ON f.branch_id = b.branch_id

WHERE
    YEAR(h.hire_start_date) = 2025

GROUP BY
    b.branch_name

ORDER BY
    revenue_per_container DESC;
GO


/*==============================================================
  9. SCENARIO ANALYSIS
==============================================================*/

SELECT
    scenario_name,
    revenue_growth_pct,
    cost_growth_pct,
    forecast_revenue,
    forecast_cost,
    forecast_gross_margin,
    forecast_margin_pct,
    gross_margin_growth_pct

FROM vw_scenario_analysis

ORDER BY
    scenario_id;
GO


/*==============================================================
  10. CONTAINER THROUGHPUT MARKET CONTEXT
==============================================================*/

SELECT
    financial_year,
    port,
    teu

FROM fact_container_throughput

ORDER BY
    financial_year,
    port;
GO


/*==============================================================
  11. MARITIME CARGO MARKET CONTEXT
==============================================================*/

SELECT
    financial_year,
    port,
    cargo_type,
    million_tonnes

FROM fact_cargo_by_port

ORDER BY
    financial_year,
    port,
    cargo_type;
GO
