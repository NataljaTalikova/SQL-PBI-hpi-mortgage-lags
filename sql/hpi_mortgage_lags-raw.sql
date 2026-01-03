-- RAW: full UK HPI file (mirror header; all text so import never fails)
DROP TABLE IF EXISTS raw.uk_hpi_full;
CREATE TABLE raw.uk_hpi_full (
  "Date" text,
  "RegionName" text,
  "AreaCode" text,
  "AveragePrice" text,
  "Index" text,
  "IndexSA" text,
  "1m%Change" text,
  "12m%Change" text,
  "AveragePriceSA" text,
  "SalesVolume" text,
  "DetachedPrice" text,
  "DetachedIndex" text,
  "Detached1m%Change" text,
  "Detached12m%Change" text,
  "SemiDetachedPrice" text,
  "SemiDetachedIndex" text,
  "SemiDetached1m%Change" text,
  "SemiDetached12m%Change" text,
  "TerracedPrice" text,
  "TerracedIndex" text,
  "Terraced1m%Change" text,
  "Terraced12m%Change" text,
  "FlatPrice" text,
  "FlatIndex" text,
  "Flat1m%Change" text,
  "Flat12m%Change" text,
  "CashPrice" text,
  "CashIndex" text,
  "Cash1m%Change" text,
  "Cash12m%Change" text,
  "CashSalesVolume" text,
  "MortgagePrice" text,
  "MortgageIndex" text,
  "Mortgage1m%Change" text,
  "Mortgage12m%Change" text,
  "MortgageSalesVolume" text,
  "FTBPrice" text,
  "FTBIndex" text,
  "FTB1m%Change" text,
  "FTB12m%Change" text,
  "FOOPrice" text,
  "FOOIndex" text,
  "FOO1m%Change" text,
  "FOO12m%Change" text,
  "NewPrice" text,
  "NewIndex" text,
  "New1m%Change" text,
  "New12m%Change" text,
  "NewSalesVolume" text,
  "OldPrice" text,
  "OldIndex" text,
  "Old1m%Change" text,
  "Old12m%Change" text,
  "OldSalesVolume" text
);

DROP TABLE IF EXISTS raw.boe_effective_mortgage_rates_wide;

CREATE TABLE raw.boe_effective_mortgage_rates_wide (
  date_raw text,
  cfmz6jm  text,
  cfmz6jo  text,
  cfmz6jx  text,
  cfmz6k3  text
);


DELETE
FROM raw.boe_effective_mortgage_rates_wide
WHERE date_raw = 'Date';


SELECT COUNT(*) FROM raw.boe_effective_mortgage_rates_wide;
SELECT * 
FROM raw.boe_effective_mortgage_rates_wide
ORDER BY date_raw DESC
LIMIT 5;

DROP TABLE IF EXISTS raw.uk_hpi_full;

CREATE TABLE raw.uk_hpi_full (
  "Date" text,
  "RegionName" text,
  "AreaCode" text,
  "AveragePrice" text,
  "Index" text,
  "IndexSA" text,
  "1m%Change" text,
  "12m%Change" text,
  "AveragePriceSA" text,
  "SalesVolume" text,
  "DetachedPrice" text,
  "DetachedIndex" text,
  "Detached1m%Change" text,
  "Detached12m%Change" text,
  "SemiDetachedPrice" text,
  "SemiDetachedIndex" text,
  "SemiDetached1m%Change" text,
  "SemiDetached12m%Change" text,
  "TerracedPrice" text,
  "TerracedIndex" text,
  "Terraced1m%Change" text,
  "Terraced12m%Change" text,
  "FlatPrice" text,
  "FlatIndex" text,
  "Flat1m%Change" text,
  "Flat12m%Change" text,
  "CashPrice" text,
  "CashIndex" text,
  "Cash1m%Change" text,
  "Cash12m%Change" text,
  "CashSalesVolume" text,
  "MortgagePrice" text,
  "MortgageIndex" text,
  "Mortgage1m%Change" text,
  "Mortgage12m%Change" text,
  "MortgageSalesVolume" text,
  "FTBPrice" text,
  "FTBIndex" text,
  "FTB1m%Change" text,
  "FTB12m%Change" text,
  "FOOPrice" text,
  "FOOIndex" text,
  "FOO1m%Change" text,
  "FOO12m%Change" text,
  "NewPrice" text,
  "NewIndex" text,
  "New1m%Change" text,
  "New12m%Change" text,
  "NewSalesVolume" text,
  "OldPrice" text,
  "OldIndex" text,
  "Old1m%Change" text,
  "Old12m%Change" text,
  "OldSalesVolume" text
);

DELETE
FROM raw.uk_hpi_full
WHERE "Date" = 'Date';

SELECT COUNT(*) FROM raw.uk_hpi_full;


--checkups
SELECT *
FROM raw.uk_hpi_full
ORDER BY "Date"
LIMIT 3;

SELECT "Date", "AreaCode", "RegionName"
FROM raw.uk_hpi_full
ORDER BY "Date"
LIMIT 3;