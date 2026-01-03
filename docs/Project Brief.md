
## UK House Price Index (HPI) and Mortgage Rates — Lag Analysis

### Objective
To explore and quantify the temporal relationship between UK mortgage rates and house price growth (HPI), with a focus on identifying typical response lags and regional heterogeneity. The project is exploratory and analytical in nature, designed to surface structural patterns rather than establish causal inference.

---
### Why it matters (business framing)
- **Pricing & planning:** anticipate regional housing market slowdowns/speedups after rate moves.
- **Risk lens:** gauge sensitivity of collateral valuations to monetary policy.
- **Stakeholder clarity:** one map (lag by region) + simple time-series overlays.

- --
## Scope & Constraints
- Geographic level: **UK countries + English NUTS1 regions** **+ London boroughs**(map-friendly).
- Frequency: **Monthly**.
- Period: **2016-01 → latest** overlap (given CFMZ6JM availability).
- Method focus: YoY growth and **lag L ∈ [0..24]** months, not causal inference.
---
## Data
- **House Prices:** _UK HPI full file_ (HM Land Registry via GOV.UK) — index and average price, Not Seasonably Adjusted(NSA).
  - Source: https://www.gov.uk/government/collections/uk-house-price-index-reports
  - Use fields: `date (YYYY-MM)`, `area_code/name`, `index`, `average_price` (optional for tooltip)
- **Mortgage Rates (BoE Effective Interest Rates):**
  - **Headline:** `CFMZ6JM` — new mortgages (individuals).
  - **Detailed:** `CFMZ6JX` (fixed ≤2y), `CFMZ6K3` (fixed 5y), `CFMZ6JO` (floating).
  - Portal: https://www.bankofengland.co.uk/boeapps/database/fromshowcolumns.asp?Travel=NIxSUx&FromSeries=1&ToSeries=50&DAT=RNG&FD=1&FM=Jan&FY=1995&TD=24&TM=Dec&TY=2025&FNY=&CSVF=TT&html.x=96&html.y=43&C=TZ6&C=QYL&C=TZ7&C=QWQ&Filter=N (search by code; download CSV)

---

### Methodology

1. **Preprocessing & Feature Engineering**
   - Monthly HPI levels were transformed into **month-on-month (MoM) percentage changes**.
   - MoM changes were aggregated into **rolling year-on-year (YoY) growth rates** to mitigate seasonality inherent in housing market transactions.
   - Mortgage rates were used at their observed monthly level (no YoY transformation), reflecting their role as policy-driven signals rather than seasonal series.

2. **Exploratory Analysis**
   - Initial analysis examined national-level time series of HPI YoY growth and mortgage rates to identify broad directional relationships.
   - Visual inspection suggested an inverse and lagged association between rising rates and subsequent house price growth.

3. **Lag Simulation & Correlation Analysis**
   - Lagged versions of mortgage rates were generated (0–24 months).
   - For each region and rate type, correlations were computed between HPI YoY growth and lagged mortgage rates.
   - The **“best lag”** was defined as the lag maximizing the absolute correlation, subject to sufficient data overlap.
   - No formal hypothesis testing or statistical significance testing was applied, consistent with the exploratory scope of the project.

4. **Geographic & Structural Analysis**
   - Results were analyzed across UK regions to identify spatial heterogeneity.
   - Period-based segmentation (Brexit uncertainty, Covid, post-Covid, Ukraine war) was introduced to contextualize structural breaks and shocks.

---

### Key Analytical Assumptions & Limitations
- Correlation is used as a descriptive measure of co-movement; **no causal claims are made**.
- Lag selection is based on historical fit and may vary outside the sample period.
- No formal statistical testing (e.g., AB testing, bootstrapping, Granger causality) was conducted due to project scope.

---
### Key Metrics / KPIs
- **Best lag (months):** Time delay at which mortgage rates and HPI growth are most strongly correlated for each region.
- **Max |correlation|:** Absolute correlation value at best lag (typically negative).
- **Hit-rate:** Proportion of periods where the sign of Δrate predicts the opposite sign of ΔHPI at the best lag.
- **Semi-elasticity proxy:** Median ΔHPI at best lag, split by lower/upper quantiles of rate changes (exploratory).

---
### Deliverables
- **Live PostgreSQL implementation:** All feature engineering and marts created as database tables/views (SQL scripts included).
- Power BI dashboard visualizing:
  - National and regional time series
  - Geographic patterns of HPI growth
  - Best lag structures and correlation summaries
- CSV snapshots of analytical marts for reproducibility.

---
### Recommended Next Steps
- Formal statistical validation of lag structures using resampling or hypothesis testing (e.g., in R or Python).
- Extension to causal frameworks (e.g., VAR, Granger causality, regime-switching models).
- Sensitivity analysis under alternative transformations or sub-period definitions.

---

*This brief documents the analytical approach and design decisions underpinning the project. For results, visualizations, and reproducibility instructions, see `README.md`.*


