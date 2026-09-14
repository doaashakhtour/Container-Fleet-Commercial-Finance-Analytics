/*==============================================================
  Project: Container Fleet Commercial Finance Analytics
  File: 03_create_views.sql
  Purpose: Create reporting views used by Power BI
==============================================================*/

USE container_fleet_analytics;
GO


/*==============================================================
  VIEW: Financial Performance
==============================================================*/

CREATE VIEW vw_financial_performance AS

SELECT
    h.hire_id,
    h.hire_start_date,
    h.hire_end_date,
    h.hire_days,

    c.customer_id,
    c.customer_name,
    c.customer_segment,

    f.container_id,

    ct.container_type,

    b.branch_id,
    b.branch_name,
    b.state,

    h.hire_revenue,
    h.transport_revenue,
    h.total_revenue,

    h.transport_cost,
    h.maintenance_cost,
    h.total_cost,

    h.gross_margin,
    h.gross_margin_pct

FROM fact_hire_transactions h

LEFT JOIN dim_customers c
    ON h.customer_id = c.customer_id

LEFT JOIN dim_fleet f
    ON h.container_id = f.container_id

LEFT JOIN dim_container_types ct
    ON f.container_type_id = ct.container_type_id

LEFT JOIN dim_branches b
    ON f.branch_id = b.branch_id;
GO

/*==============================================================
  VIEW: Budget vs Actual
==============================================================*/

CREATE VIEW vw_budget_vs_actual AS

SELECT
    b.budget_year,
    b.budget_month,

    b.revenue_budget,

    COALESCE(a.actual_revenue, 0) AS actual_revenue,

    COALESCE(a.actual_revenue, 0) - b.revenue_budget
        AS revenue_variance,

    CASE
        WHEN b.revenue_budget = 0 THEN 0
        ELSE
            (COALESCE(a.actual_revenue, 0) - b.revenue_budget)
            / b.revenue_budget
    END AS revenue_variance_pct,

    b.cost_budget,

    COALESCE(a.actual_cost, 0) AS actual_cost,

    COALESCE(a.actual_cost, 0) - b.cost_budget
        AS cost_variance,

    b.gross_margin_budget,

    COALESCE(a.actual_gross_margin, 0) AS actual_gross_margin,

    COALESCE(a.actual_gross_margin, 0) - b.gross_margin_budget
        AS gross_margin_variance,

    CASE
        WHEN b.gross_margin_budget = 0 THEN 0
        ELSE
            (COALESCE(a.actual_gross_margin, 0) - b.gross_margin_budget)
            / b.gross_margin_budget
    END AS gross_margin_variance_pct

FROM fact_budget b

LEFT JOIN (
    SELECT
        YEAR(hire_start_date) AS actual_year,
        MONTH(hire_start_date) AS actual_month,

        SUM(total_revenue) AS actual_revenue,
        SUM(total_cost) AS actual_cost,
        SUM(gross_margin) AS actual_gross_margin

    FROM fact_hire_transactions

    GROUP BY
        YEAR(hire_start_date),
        MONTH(hire_start_date)

) a
    ON b.budget_year = a.actual_year
    AND b.budget_month = a.actual_month;
GO

/*==============================================================
  VIEW: Scenario Analysis
==============================================================*/

CREATE VIEW vw_scenario_analysis AS

WITH Actual2025 AS (
    SELECT
        SUM(total_revenue) AS actual_revenue,
        SUM(total_cost) AS actual_cost,
        SUM(gross_margin) AS actual_gross_margin
    FROM fact_hire_transactions
    WHERE YEAR(hire_start_date) = 2025
)

SELECT
    s.scenario_id,
    s.scenario_name,
    s.revenue_growth_pct,
    s.cost_growth_pct,

    a.actual_revenue
        * (1 + s.revenue_growth_pct)
        AS forecast_revenue,

    a.actual_cost
        * (1 + s.cost_growth_pct)
        AS forecast_cost,

    (
        a.actual_revenue * (1 + s.revenue_growth_pct)
        -
        a.actual_cost * (1 + s.cost_growth_pct)
    ) AS forecast_gross_margin,

    CASE
        WHEN a.actual_revenue * (1 + s.revenue_growth_pct) = 0
            THEN 0
        ELSE
            (
                a.actual_revenue * (1 + s.revenue_growth_pct)
                -
                a.actual_cost * (1 + s.cost_growth_pct)
            )
            /
            (
                a.actual_revenue * (1 + s.revenue_growth_pct)
            )
    END AS forecast_margin_pct,

    CASE
        WHEN a.actual_gross_margin = 0
            THEN 0
        ELSE
            (
                (
                    a.actual_revenue * (1 + s.revenue_growth_pct)
                    -
                    a.actual_cost * (1 + s.cost_growth_pct)
                )
                -
                a.actual_gross_margin
            )
            /
            a.actual_gross_margin
    END AS gross_margin_growth_pct

FROM dim_scenarios s

CROSS JOIN Actual2025 a;
GO

