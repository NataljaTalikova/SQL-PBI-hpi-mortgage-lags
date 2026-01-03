-- creates view for desired areal granularity selected HPI 
-- and converts dates to compatible format
CREATE OR REPLACE VIEW stg.hpi_core AS
SELECT
    (date_trunc('month', to_date("Date", 'DD/MM/YYYY'))
        + interval '1 month - 1 day')::date      AS ym,
    "AreaCode"                                   AS area_code,
    "RegionName"                                 AS region_name,
    NULLIF("Index", '')::numeric                 AS hpi_index,
    NULLIF("AveragePrice", '')::numeric          AS average_price
FROM raw.uk_hpi_full
WHERE "AreaCode" IN (
    'K02000001','E92000001','W92000004','S92000003','N92000001',
    'E12000001','E12000002','E12000003','E12000004','E11000005',
    'E12000006','E12000007','E12000008','E12000009'
)
AND "Index" IS NOT NULL;

SELECT COUNT(*) FROM stg.hpi_core;

SELECT * FROM stg.hpi_core LIMIT 5

--- Converts dates to compatible format
CREATE OR REPLACE VIEW stg.rate_core AS
SELECT
    to_date(date_raw, 'DD Mon YY')::date AS ym,
    rate_code,
    rate_name,
    NULLIF(rate_txt, '')::numeric        AS rate
FROM raw.boe_effective_mortgage_rates_wide
CROSS JOIN LATERAL (
    VALUES
      ('CFMZ6JM', 'New mortgages (all)', cfmz6jm),
      ('CFMZ6JO', 'Floating rate',       cfmz6jo),
      ('CFMZ6JX', 'Fixed ≤2y',            cfmz6jx),
      ('CFMZ6K3', 'Fixed 5y',             cfmz6k3)
) v(rate_code, rate_name, rate_txt)
WHERE date_raw IS NOT NULL
  AND date_raw <> '';


-- checkups
SELECT * FROM stg.rate_core LIMIT 5

SELECT COUNT(*) FROM raw.boe_effective_mortgage_rates_wide;

SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'raw'
ORDER BY table_name;

---stage for London and boroughs
/* 2) London boroughs only (LAD codes E090...) */
CREATE OR REPLACE VIEW stg.hpi_london_boroughs AS
SELECT
    (date_trunc('month', to_date("Date", 'DD/MM/YYYY'))
        + interval '1 month - 1 day')::date      AS ym,
    "AreaCode"                                   AS area_code,
    "RegionName"                                 AS region_name,
    NULLIF("Index", '')::numeric                 AS hpi_index,
    NULLIF("AveragePrice", '')::numeric          AS average_price
FROM raw.uk_hpi_full
WHERE "AreaCode" LIKE 'E090%'
  AND "Index" IS NOT NULL;

--check up
SELECT * FROM stg.hpi_london_boroughs LIMIT 5

/* 3) Unified analysis scope = NUTS1/countries + London boroughs */
CREATE OR REPLACE VIEW stg.hpi_scope AS
SELECT * FROM stg.hpi_core
UNION ALL
SELECT * FROM stg.hpi_london_boroughs;

SELECT * FROM stg.hpi_scope LIMIT 5


