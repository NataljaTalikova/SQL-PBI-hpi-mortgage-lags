-- 1) mart_hpi: HPI level + MoM% + YoY% aligned to dim_date
CREATE OR REPLACE VIEW mart.mart_hpi AS
WITH h AS (
    SELECT
        d.ym,
        r.area_code,
        r.region_name,
        r.nuts1,
        s.hpi_index,
        s.average_price,

        LAG(s.hpi_index, 1)  OVER (PARTITION BY r.area_code ORDER BY d.ym)  AS hpi_index_lag1,
        LAG(s.hpi_index, 12) OVER (PARTITION BY r.area_code ORDER BY d.ym)  AS hpi_index_lag12
    FROM dim.dim_date d
    JOIN dim.dim_region r
      ON 1 = 1
    LEFT JOIN stg.hpi_scope s
      ON s.ym = d.ym
     AND s.area_code = r.area_code
)
SELECT
    ym,
    area_code,
    region_name,
    nuts1,
    hpi_index,
    average_price,

    CASE
        WHEN hpi_index_lag1 IS NULL OR hpi_index_lag1 = 0 THEN NULL
        ELSE 100.0 * (hpi_index / hpi_index_lag1 - 1)
    END AS hpi_mom_pct,

    CASE
        WHEN hpi_index_lag12 IS NULL OR hpi_index_lag12 = 0 THEN NULL
        ELSE 100.0 * (hpi_index / hpi_index_lag12 - 1)
    END AS hpi_yoy_pct
FROM h;

--checkups
SELECT * FROM mart.mart_hpi LIMIT 15



-- create mart.mart_rate aligned to dim.dim_date, using stg.rate_core (so rates are on the same monthly spine as HPI)
CREATE OR REPLACE VIEW mart.mart_rate AS
SELECT
  d.ym,
  r.rate_code,
  r.rate_name,
  r.rate
FROM dim.dim_date d
LEFT JOIN stg.rate_core r
  ON r.ym = d.ym;

--checkups
SELECT * FROM mart.mart_rate LIMIT 5

---corrections
DROP VIEW IF EXISTS mart.mart_lag_corr CASCADE;
DROP VIEW IF EXISTS mart.mart_lag_pairs CASCADE;
DROP VIEW IF EXISTS mart.mart_lag_eval  CASCADE;


--join HPI to YoY rate
CREATE OR REPLACE VIEW mart.mart_lag_eval  AS
WITH base AS (
  SELECT
    h.ym,
    h.area_code,
    h.region_name,
    h.nuts1,

    r.rate_code,
    r.rate_name,

    h.hpi_index,
    h.average_price,
    h.hpi_mom_pct,
    h.hpi_yoy_pct,

    r.rate
  FROM mart.mart_hpi h
  JOIN mart.mart_rate r
    ON r.ym = h.ym
  WHERE r.rate_code IS NOT NULL
)
SELECT
  ym,
  area_code,
  region_name,
  nuts1,
  rate_code,
  rate_name,
  hpi_index,
  average_price,
  hpi_mom_pct,
  hpi_yoy_pct,

  rate AS rate_lag_0,
  LAG(rate,  1) OVER (PARTITION BY area_code, rate_code ORDER BY ym) AS rate_lag_1,
  LAG(rate,  2) OVER (PARTITION BY area_code, rate_code ORDER BY ym) AS rate_lag_2,
  LAG(rate,  3) OVER (PARTITION BY area_code, rate_code ORDER BY ym) AS rate_lag_3,
  LAG(rate,  6) OVER (PARTITION BY area_code, rate_code ORDER BY ym) AS rate_lag_6,
  LAG(rate, 12) OVER (PARTITION BY area_code, rate_code ORDER BY ym) AS rate_lag_12,
  LAG(rate, 18) OVER (PARTITION BY area_code, rate_code ORDER BY ym) AS rate_lag_18,
  LAG(rate, 24) OVER (PARTITION BY area_code, rate_code ORDER BY ym) AS rate_lag_24
FROM base;

--checkup
SELECT * FROM mart.mart_lag_eval LIMIT 10;
SELECT COUNT(*) FROM mart.mart_lag_eval;


--- structural correlation HPI YoYpm per area to 8 lagged values pm accross all time intervals, mart 
CREATE OR REPLACE VIEW mart.mart_lag_corr AS
WITH long_lags AS (
  SELECT
    area_code,
    region_name,
    nuts1,
    rate_code,
    rate_name,
    lag_m,
    hpi_yoy_pct,
    rate_val
  FROM mart.mart_lag_eval
  CROSS JOIN LATERAL (VALUES
    (0,  rate_lag_0),
    (1,  rate_lag_1),
    (2,  rate_lag_2),
    (3,  rate_lag_3),
    (6,  rate_lag_6),
    (12, rate_lag_12),
    (18, rate_lag_18),
    (24, rate_lag_24)
  ) v(lag_m, rate_val)
),
corrs AS (
  SELECT
    area_code,
    region_name,
    nuts1,
    rate_code,
    rate_name,
    lag_m,
    COUNT(*) FILTER (WHERE hpi_yoy_pct IS NOT NULL AND rate_val IS NOT NULL) AS n_overlap,
    CORR(hpi_yoy_pct, rate_val) AS corr_val
  FROM long_lags
  GROUP BY 1,2,3,4,5,6
),
ranked AS (
  SELECT
    *,
    ABS(corr_val) AS abs_corr,
    ROW_NUMBER() OVER (
      PARTITION BY area_code, rate_code
      ORDER BY ABS(corr_val) DESC NULLS LAST, n_overlap DESC, lag_m ASC
    ) AS rn
  FROM corrs
)
SELECT
  area_code,
  region_name,
  nuts1,
  rate_code,
  rate_name,
  lag_m,
  n_overlap,
  corr_val,
  abs_corr,
  (rn = 1) AS is_best_lag,
  FIRST_VALUE(lag_m)    OVER (PARTITION BY area_code, rate_code ORDER BY rn) AS best_lag_m,
  FIRST_VALUE(corr_val) OVER (PARTITION BY area_code, rate_code ORDER BY rn) AS best_corr_val
FROM ranked
ORDER BY area_code, rate_code, lag_m;


---checkup
SELECT * FROM mart.mart_lag_corr WHERE region_name = 'City of London';
SELECT COUNT (*) FROM mart.mart_lag_corr WHERE rate_code IS NULL;

---temporal correlation
CREATE OR REPLACE VIEW mart.mart_lag_corr_year AS
WITH long_lags AS (
  SELECT
    EXTRACT(YEAR FROM ym)::int AS year,
    area_code,
    region_name,
    nuts1,
    rate_code,
    rate_name,
    lag_m,
    hpi_yoy_pct,
    rate_val
  FROM mart.mart_lag_eval
  CROSS JOIN LATERAL (VALUES
    (0,  rate_lag_0),
    (1,  rate_lag_1),
    (2,  rate_lag_2),
    (3,  rate_lag_3),
    (6,  rate_lag_6),
    (12, rate_lag_12),
    (18, rate_lag_18),
    (24, rate_lag_24)
  ) v(lag_m, rate_val)
),
corrs AS (
  SELECT
    year,
    area_code,
    region_name,
    nuts1,
    rate_code,
    rate_name,
    lag_m,
    COUNT(*) FILTER (WHERE hpi_yoy_pct IS NOT NULL AND rate_val IS NOT NULL) AS n_overlap,
    CORR(hpi_yoy_pct, rate_val) AS corr_val
  FROM long_lags
  GROUP BY 1,2,3,4,5,6,7
),
ranked AS (
  SELECT
    *,
    ABS(corr_val) AS abs_corr,
    ROW_NUMBER() OVER (
      PARTITION BY year, area_code, rate_code
      ORDER BY ABS(corr_val) DESC NULLS LAST, n_overlap DESC, lag_m ASC
    ) AS rn
  FROM corrs
)
SELECT
  year,
  area_code,
  region_name,
  nuts1,
  rate_code,
  rate_name,
  lag_m,
  n_overlap,
  corr_val,
  abs_corr,
  (rn = 1) AS is_best_lag,
  FIRST_VALUE(lag_m)    OVER (PARTITION BY year, area_code, rate_code ORDER BY rn) AS best_lag_m,
  FIRST_VALUE(corr_val) OVER (PARTITION BY year, area_code, rate_code ORDER BY rn) AS best_corr_val
FROM ranked
ORDER BY year, area_code, rate_code, lag_m;

--checkup
SELECT * FROM mart.mart_lag_corr_year WHERE region_name = 'City of London' 

SELECT
  c.year,
  c.area_code,
  c.rate_code,
  c.lag_m,
  c.corr_val,
  d.is_brexit_vote,
  d.is_covid
FROM mart.mart_lag_corr_year c
JOIN dim.dim_date d
  ON d.year = c.year
WHERE c.area_code = 'E09000001' -- City of London  and c.year = 2020
ORDER BY c.year;




---PBIX ready marts
--1. structural
CREATE OR REPLACE VIEW mart.mart_best_lag_structural AS
SELECT
  area_code,
  region_name,
  nuts1,
  rate_code,
  rate_name,
  best_lag_m,
  ROUND(best_corr_val::numeric, 3) AS best_corr_val,
  n_overlap AS n_overlap_best
FROM mart.mart_lag_corr
WHERE is_best_lag = true
ORDER BY area_code, rate_code;

--checkup
SELECT region_name, nuts1, rate_name, best_lag_m, best_corr_val FROM mart.mart_best_lag_structural
ORDER BY rate_name, ABS(best_corr_val) DESC;


-- 2. for the linear graph

CREATE OR REPLACE VIEW mart.mart_rate AS
WITH base AS (
  SELECT
    d.ym,
    r.rate_code,
    r.rate_name,
    r.rate::numeric AS rate
  FROM dim.dim_date d
  LEFT JOIN stg.rate_core r
    ON r.ym = d.ym
)
SELECT
  ym,
  rate_code,
  rate_name,
  rate,
  LAG(rate, 6) OVER (PARTITION BY rate_code ORDER BY ym) AS rate_lead_6m
FROM base;


--checkup
SELECT *
FROM mart.mart_rate
ORDER BY rate_name, ym
LIMIT 50;


