# Olist E-Commerce Performance & Customer Analytics

**SQL · Python · Power BI**

> **Executive summary:** End-to-end analysis of **99,441 Brazilian e-commerce orders** (Olist, 2016–2018) using **PostgreSQL**, **Python (pandas, SciPy)** and **Power BI**. The project examines revenue growth, revenue concentration (Pareto), delivery performance and its relationship with customer reviews, repeat-purchase behavior, and installment payment patterns, and turns each finding into an actionable recommendation.

---

## Table of Contents

1. [Business Context](#1-business-context)
2. [Dataset & Architecture](#2-dataset--architecture)
3. [Metric Definitions & Analytical Guardrails](#3-metric-definitions--analytical-guardrails)
4. [Key Findings & Recommendations](#4-key-findings--recommendations)
5. [Methods & Technical Implementation](#5-methods--technical-implementation)
6. [Repository Structure & How to Reproduce](#6-repository-structure--how-to-reproduce)
7. [Limitations & Next Steps](#7-limitations--next-steps)
8. [Tech Stack & Author](#8-tech-stack--author)

---

## 1. Business Context

Acting as a **Data Analyst Intern** for Olist, a Brazilian e-commerce marketplace that connects small businesses to major retail channels, this project answers five strategic questions for leadership:

| # | Theme | Question |
|---|---|---|
| **Q1** | Growth & basket size | How do monthly revenue, order volume and Average Order Value (AOV) evolve month over month (MoM)? |
| **Q2** | Revenue concentration | Which product categories and customer states drive most of the revenue, and how closely does performance follow the Pareto 80/20 rule? |
| **Q3** | Logistics & customer experience | How fast are deliveries, what is the late-delivery rate, and how strongly is delivery speed associated with review scores? |
| **Q4** | Customer retention | What share of unique customers place repeat orders (≥ 2 purchases), and how do they differ from one-time buyers? |
| **Q5** | Payment & installments | Which payment methods and credit-card installment plans do shoppers prefer, and how does order value vary across them? |

---

## 2. Dataset & Architecture

- **Source:** [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle)
- **License:** CC BY-NC-SA 4.0 (non-commercial, attribution required)
- **Period covered:** September 2016 – October 2018

### Verified scale

Row counts were verified in PostgreSQL with `COUNT(*)` across 9 relational tables:

| Table | Rows |
|---|---:|
| Orders | 99,441 |
| Order items | 112,650 |
| Payment records | 103,886 |
| Customer reviews | 99,224 |
| Unique customers (`customer_unique_id`) | 96,096 |
| Products | 32,951 |
| Sellers | 3,095 |
| Geolocation entries | 1,000,163 |
| Category translations | 71 |

### Relational schema

```text
olist_customers ──(customer_id)── olist_orders ──(order_id)── olist_order_items ──(product_id)── olist_products ──(category)── category_translation
                                      │                              │
                                      │                              └──(seller_id)── olist_sellers
                                      ├──(order_id)── olist_order_payments
                                      └──(order_id)── olist_order_reviews
```

### Data quality audit (`sql/01_data_quality.sql`)

| Area | Finding | Treatment |
|---|---|---|
| **Sparse boundary months** | Raw data spans 2016-09 to 2018-10, but 2016-09 to 2016-12 (329 orders in total) and 2018-09 to 2018-10 (20 orders in total) are severely truncated. | Trend analyses use the **20 complete months (2017-01 to 2018-08)**. |
| **Order status & empty orders** | Of 99,441 orders, 96,478 (97.0%) are delivered, 625 are canceled and 609 are unavailable. 775 orders have no line items (primarily canceled/unavailable). | Canceled and unavailable orders are excluded from revenue metrics. |
| **One-to-many join traps** | 2,961 orders contain multiple payment rows (e.g., credit card + voucher) and 547 orders contain multiple reviews. | Every table is aggregated or deduplicated to the `order_id` grain before joining, preventing double-counting of GMV. |
| **Customer identifier granularity** | 99,441 order-level `customer_id` values map to 96,096 distinct individuals (`customer_unique_id`), i.e. 3,345 repeat-order instances. | Customers are counted via `customer_unique_id` only. |
| **Missing values & untranslated categories** | 2,965 orders lack `order_delivered_customer_date` (including 8 orders marked delivered). 610 products have no category name, and 2 Portuguese categories (`pc_gamer`, `portateis_cozinha_e_preparadores_de_alimentos`) have no English translation. | Orders without a delivery date are excluded from transit-time calculations. Missing categories are labeled `unknown`. |
| **Financial cross-check** | Comparing `SUM(price + freight_value)` with `SUM(payment_value)` across 98,665 orders gives 99.75% reconciliation; only 249 orders differ by more than 1 BRL (vouchers and minor adjustments). | Item-level values are treated as reliable for revenue analysis. |

---

## 3. Metric Definitions & Analytical Guardrails

| Item | Definition |
|---|---|
| **Merchandise revenue (GMV)** | `SUM(price)` in Brazilian Real (BRL). Shipping (`freight_value`) is excluded and tracked separately. |
| **Valid orders: revenue, AOV, retention, payments (Q1, Q2, Q4, Q5)** | 98,207 orders: all orders with line items, excluding `canceled` and `unavailable`. |
| **Valid orders: delivery & reviews (Q3)** | 96,470 delivered orders with a non-null `order_delivered_customer_date`. |
| **Unique customers** | Counted strictly via `customer_unique_id` (94,990 unique buyers with valid orders). |
| **Review deduplication** | For multi-review orders, only the latest response is kept: `ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY review_answer_timestamp DESC) = 1`. |
| **Split payments** | Orders paid with several methods are classified by the primary method, i.e. the one with the highest `payment_value`. |
| **Currency** | All monetary values are in BRL and are not converted. |

---

## 4. Key Findings & Recommendations

> The full strategic analysis and action roadmap are in [`reports/insights.md`](reports/insights.md).

### At a glance

| Metric | Value |
|---|---|
| Peak monthly GMV | 1,003,862.14 BRL (2017-11, 7,421 orders, +52.1% MoM) |
| Average order value | ≈ 137.41 BRL (monthly range 124.76 – 152.60) |
| Revenue concentration | 18 of 74 categories generate 81.26% of GMV; 7 of 27 states generate 81.47% |
| Late-delivery rate | 8.11% of delivered orders |
| Review score: on-time vs. late | 4.29 vs. 2.57 (out of 5) |
| Repeat-customer rate | 3.04% (2,888 of 94,990 unique buyers) |
| Orders paid by credit card | 75.47% |

### Q1 — Volume-driven growth with a flat AOV

Monthly GMV grew roughly 8.4× from **120,098.27 BRL** (787 orders, 2017-01) to a peak of **1,003,862.14 BRL** (7,421 orders, 2017-11, +52.1% MoM), then plateaued between about 838k and 994k BRL per month in 2018. AOV stayed flat at around **137.41 BRL** (range 124.76–152.60 BRL), so growth came from order volume rather than larger baskets.

**Recommendation:** Test a **160 BRL free-shipping threshold** and checkout cross-sell bundles to lift basket size.

### Q2 — Strong 80/20 concentration across categories and states

**18 of 74 categories (24.3%)** generate **81.26%** of GMV, led by `health_beauty` (1.26M BRL), `watches_gifts` (1.20M BRL) and `bed_bath_table` (1.04M BRL). Geographically, **7 of 27 states** drive **81.47%** of GMV; São Paulo (SP) alone accounts for **38.27%** (5.16M BRL) at the lowest AOV nationwide (125.57 BRL).

**Recommendation:** Protect inventory depth in the top 18 categories and recruit regional sellers outside SP to reduce interstate freight barriers.

### Q3 — Late deliveries are strongly associated with lower reviews

| Group | Share of orders | Median transit | Avg. review | 1–2 star rate |
|---|---:|---:|---:|---:|
| On time | 91.89% | 9.73 days | 4.29 / 5 | 9.22% |
| Late | 8.11% | 29.15 days | 2.57 / 5 | 54.07% |

The gap is **1.72 review points**. Ratings drop sharply once transit exceeds 20 days (from 4.13 to 3.23). A Mann–Whitney U test (p < 0.001, CLES = 0.770) and a Spearman correlation (ρ = −0.33, p < 0.001) confirm a statistically significant association. These tests show association, not causation.

**Recommendation:** Trigger automated **15-day transit SLA alerts** for proactive carrier escalation before orders reach the 20-day mark.

### Q3 (regional) — Rio de Janeiro is the largest logistics bottleneck by volume

Among major markets (≥ 500 delivered orders), **RJ** records 12,350 deliveries with a **13.47% late rate** (about 1,664 late orders), roughly 2.3× the 5.89% rate in SP.

**Recommendation:** Audit SP → RJ carrier lanes and recalibrate estimated delivery buffers to manage customer expectations.

### Q4 — Very low repeat rate leaves growth dependent on new acquisition

Only **3.04%** (2,888 of 94,990 unique buyers) placed two or more orders, contributing 6.22% of total orders. Repeat buyers show slightly higher satisfaction (4.18 vs. 4.11) but smaller baskets (122.95 vs. 138.38 BRL), a pattern consistent with replenishment-type purchases (a hypothesis to validate).

**Recommendation:** Pilot an automated **Day-14 post-delivery voucher** for 4–5 star first-time buyers in replenishable categories (`health_beauty`, `bed_bath_table`).

### Q5 — Credit-card installments accompany higher-ticket orders

Credit cards (75.47%) and boleto (19.90%) account for **95.37%** of orders. Among credit-card orders, **67.99%** use two or more installments, and average order value rises more than 4× from **100.78 BRL** (1 installment) to **309.00 BRL** (8) and **414.76 BRL** (10).

**Recommendation:** Display 6–10× monthly installment pricing prominently on product cards for items above 200 BRL.

---

## 5. Methods & Technical Implementation

**SQL (PostgreSQL 17)**
Multi-table joins, CTEs, window functions (`LAG`, `ROW_NUMBER`, `SUM() OVER`, `RANK`), conditional aggregation (`FILTER`), and reusable analytical views (`v_order_fact`, `v_item_fact`).

**Python (pandas, SQLAlchemy, SciPy, matplotlib, seaborn)**
Automated ETL ingestion (`scripts/load_data.py`), SQL-vs-pandas reconciliation (0.00 BRL revenue discrepancy), visualizations, and non-parametric hypothesis testing (`notebooks/01_eda_and_validation.ipynb`).

**Power BI Desktop**
Star-schema data model (date table + fact views), custom DAX measures (Total Revenue, Total Orders, AOV, Late Delivery %, Avg Review Score, Repeat Customer %), and an interactive executive dashboard (`dashboard/olist_dashboard.pbix`).

---

## 6. Repository Structure & How to Reproduce

### Structure

```text
Olist-Ecommerce-Analysis/
├── README.md
├── data/
│   ├── raw/                        # Place the 9 Kaggle CSVs here (ignored by Git)
│   └── processed/
├── sql/
│   ├── 00_load_notes.md            # ETL & indexing log
│   ├── 01_data_quality.sql         # Data auditing & financial cross-checks
│   ├── 02_q1_monthly_revenue.sql   # Monthly revenue, orders, AOV & MoM growth
│   ├── 03_q2_category_state.sql    # Category Pareto 80/20 & state breakdown
│   ├── 04_q3_delivery_reviews.sql  # Delivery speed, late rate & review impact
│   ├── 05_q4_repeat_customers.sql  # Customer retention & cohort comparison
│   ├── 06_q5_payments.sql          # Payment methods & installment analysis
│   └── 07_views_for_powerbi.sql    # Clean fact views for BI & Python
├── scripts/
│   └── load_data.py                # Automated CSV-to-PostgreSQL loader
├── notebooks/
│   └── 01_eda_and_validation.ipynb # Reconciliation, charts & statistical tests
├── dashboard/
│   ├── olist_dashboard.pbix        # Interactive Power BI report
│   └── screenshots/
│       └── dashboard_main.png
├── reports/
│   └── insights.md                 # Full business insights & action roadmap
├── .env.example
├── .gitignore
└── requirements.txt
```

### Step-by-step reproduction

**1. Clone the repository and install dependencies**

```bash
git clone https://github.com/07MinhQuanT1/Olist-Ecommerce-Analysis.git
cd Olist-Ecommerce-Analysis

python -m venv .venv
# Windows:
.venv\Scripts\activate
# macOS / Linux:
# source .venv/bin/activate

pip install -r requirements.txt
```

**2. Configure data and environment**

- Download the [Olist dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) from Kaggle and extract the 9 CSV files into `data/raw/`.
- Create a PostgreSQL database named `olist`, copy `.env.example` to `.env`, and set your `DATABASE_URL`.

**3. Run the ETL and SQL pipeline**

```bash
python scripts/load_data.py
```

Then execute `sql/01_data_quality.sql` through `sql/07_views_for_powerbi.sql` in order (for example with `psql -d olist -f <file>`).

**4. Explore the notebook and dashboard**

- Open `notebooks/01_eda_and_validation.ipynb` and run all cells to reproduce the reconciliation checks, charts, and Mann–Whitney / Spearman tests.
- Open `dashboard/olist_dashboard.pbix` in Power BI Desktop to interact with the dashboard.

---

## 7. Limitations & Next Steps

**Limitations**

- **Observational scope:** Findings reflect marketplace activity in Brazil during 2016–2018. The statistical tests confirm strong associations, not causal proof.
- **Right-censoring:** Customers acquired near the end of the observation window have had less time to place repeat orders, which may understate the repeat rate.
- **Missing cost data:** Seller COGS and margins are unavailable, so profitability cannot be assessed.
- **Modeling assumptions:** The "latest review per order" and "primary payment method" rules are analytical choices that may affect results for the small share of orders they touch.

**Next steps**

- Build a monthly **cohort retention heatmap**.
- Analyze **seller-level fulfillment SLAs**.
- Develop a **churn / repeat-purchase propensity model**.

---

## 8. Tech Stack & Author

**Tools:** PostgreSQL 17 · Python 3.13 (pandas, SQLAlchemy, SciPy, matplotlib, seaborn) · Power BI Desktop (DAX, Power Query) · Git / GitHub

**Author:** Le Minh Quan — [GitHub](https://github.com/07MinhQuanT1) · [LinkedIn](https://www.linkedin.com/in/mquan007) 

**Acknowledgements:** Data provided by Olist via Kaggle, used under CC BY-NC-SA 4.0.