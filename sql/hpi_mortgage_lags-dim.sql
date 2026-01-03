DROP TABLE IF EXISTS dim.dim_date CASCADE;

CREATE TABLE dim.dim_date AS
WITH bounds AS (
  SELECT
    (GREATEST(
        (SELECT MIN(ym) FROM stg.hpi_core),
        (SELECT MIN(ym) FROM stg.rate_core)
     ) - INTERVAL '12 months')::date AS start_ym,
    LEAST(
      (SELECT MAX(ym) FROM stg.hpi_core),
      (SELECT MAX(ym) FROM stg.rate_core)
    )::date AS end_ym
),
months AS (
  SELECT generate_series(start_ym, end_ym, interval '1 month')::date AS d
  FROM bounds
)
SELECT
  (date_trunc('month', d) + INTERVAL '1 month - 1 day')::date AS ym,
  EXTRACT(YEAR  FROM d)::int AS year,
  EXTRACT(MONTH FROM d)::int AS month,

  CASE
    WHEN (date_trunc('month', d) + INTERVAL '1 month - 1 day')::date >= DATE '2022-02-28'
      THEN 'War in Ukraine'
    WHEN (date_trunc('month', d) + INTERVAL '1 month - 1 day')::date BETWEEN DATE '2021-03-31' AND DATE '2022-01-31'
      THEN 'Post-Covid'
    WHEN (date_trunc('month', d) + INTERVAL '1 month - 1 day')::date BETWEEN DATE '2020-03-31' AND DATE '2021-02-28'
      THEN 'Covid'
    WHEN (date_trunc('month', d) + INTERVAL '1 month - 1 day')::date BETWEEN DATE '2015-12-31' AND DATE '2020-02-29'
      THEN 'Brexit uncertainty'
    ELSE NULL
  END AS period,

  CASE
    WHEN (date_trunc('month', d) + INTERVAL '1 month - 1 day')::date >= DATE '2022-02-28' THEN 4
    WHEN (date_trunc('month', d) + INTERVAL '1 month - 1 day')::date BETWEEN DATE '2021-03-31' AND DATE '2022-01-31' THEN 3
    WHEN (date_trunc('month', d) + INTERVAL '1 month - 1 day')::date BETWEEN DATE '2020-03-31' AND DATE '2021-02-28' THEN 2
    WHEN (date_trunc('month', d) + INTERVAL '1 month - 1 day')::date BETWEEN DATE '2015-12-31' AND DATE '2020-02-29' THEN 1
    ELSE NULL
  END AS period_order
FROM months
ORDER BY ym;


--checkups
SELECT MIN(ym), MAX(ym), COUNT(*) FROM dim.dim_date;
SELECT period, period_order, MIN(ym) AS min_ym, MAX(ym) AS max_ym, COUNT(*) AS n_months
FROM dim.dim_date
GROUP BY period, period_order
ORDER BY period_order;



--dim for London boroughs
/* Update dim_region to support hierarchy:
      - Boroughs get nuts1 = 'London'
      - NUTS1 London keeps nuts1 = 'Aggregate'
      - Other English NUTS1: nuts1 = region_name
      - UK/countries: nuts1 = 'Aggregate'
*/
DROP TABLE IF EXISTS dim.dim_region;

CREATE TABLE dim.dim_region AS
SELECT DISTINCT
    area_code,

    /* London NUTS1 renamed to London for visuals */
    CASE
        WHEN area_code = 'E12000007' THEN 'London'
        ELSE region_name
    END AS region_name,

    CASE
        WHEN area_code LIKE 'E090%' THEN 'London'          -- boroughs
        WHEN area_code = 'E12000007' THEN 'Aggregate'      -- London NUTS1 grouped with aggregates
        WHEN area_code LIKE 'E12%' OR area_code = 'E11000005'
            THEN region_name                               -- other English NUTS1
        ELSE 'Aggregate'                                   -- UK + countries
    END AS nuts1

FROM stg.hpi_scope
ORDER BY nuts1, region_name;


-- checkups
SELECT * FROM dim.dim_region LIMIT 3

SELECT
  COUNT(*) FILTER (WHERE region_name = nuts1) AS same_name,
  COUNT(*) FILTER (WHERE nuts1 IS NULL)        AS null_nuts1,
  COUNT(*)                                    AS total
FROM dim.dim_region;


--update for better readability
UPDATE dim.dim_region
SET nuts1 = 'London (all boroughs)'
WHERE nuts1 = 'London';

--checkup
SELECT * FROM dim.dim_region WHERE nuts1 = 'London (all boroughs)' LIMIT 10


UPDATE dim.dim_region
SET nuts1 = 'England (by parts)'
WHERE
    nuts1 <> 'Aggregate'
    AND nuts1 <> 'London (all boroughs)';
	
SELECT * FROM dim.dim_region WHERE nuts1 = 'England (by parts)' LIMIT 10


UPDATE dim.dim_region
SET nuts1 = CASE
    WHEN region_name = 'United Kingdom' THEN 'UK'
    WHEN region_name = 'London' THEN 'London'
    ELSE nuts1
END;
SELECT * FROM dim.dim_region

UPDATE dim.dim_region
SET nuts1 = 'UK (by parts)'
WHERE area_code IN ('E92000001','N92000001','S92000003','W92000004');


--add the label for Westminster to use in Map Shape json
ALTER TABLE dim.dim_region
ADD COLUMN IF NOT EXISTS region_label text;

UPDATE dim.dim_region
SET region_label = CASE
  WHEN region_name = 'City of Westminster' THEN 'Westminster'
  ELSE region_name
END;

--primary keys setup
SELECT ym, COUNT(*)
FROM dim.dim_date
GROUP BY ym
HAVING COUNT(*) > 1;

ALTER TABLE dim.dim_date
  ADD CONSTRAINT dim_date_pk PRIMARY KEY (ym);

SELECT area_code, COUNT(*)
FROM dim.dim_region
GROUP BY area_code
HAVING COUNT(*) > 1;  

ALTER TABLE dim.dim_region
  ADD CONSTRAINT dim_region_pk PRIMARY KEY (area_code);
