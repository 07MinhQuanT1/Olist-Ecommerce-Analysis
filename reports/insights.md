# Business Insights & Strategic Recommendations Report — Olist E-Commerce (2017–2018)

**Prepared by:** Data Analyst Intern  
**Observation Window:** January 2017 – August 2018 (20 complete operating months; full dataset spans September 2016 – October 2018)  
**Scope:** 98,207 valid orders | 13,494,400.74 BRL Gross Merchandise Value (GMV) | 94,990 unique customers  
**Tech Stack:** PostgreSQL · Python (pandas, SciPy) · Power BI  

---

## 1. Executive Summary

An end-to-end analysis of **98,207 valid orders** (generating **13.49 million BRL** in product revenue, excluding shipping freight) reveals that Olist achieved rapid top-line expansion throughout 2017—scaling monthly revenue nearly **8x**—before stabilizing at a high operational plateau of **838k–994k BRL/month** in 2018.

However, decomposing this growth exposes two structural vulnerabilities:
1. **Acquisition-Heavy Growth Model:** Revenue expansion is driven almost entirely by new customer acquisition rather than customer retention. Only **3.04%** of unique buyers place a repeat order, and Average Order Value (**AOV**) has remained flat around **137.41 BRL**.
2. **Logistics-Driven Satisfaction Erosion:** While **91.89%** of delivered orders arrive on or before the estimated delivery date and achieve a strong **4.29 / 5.0** average review score, the **8.11%** of orders delivered late suffer a severe rating collapse to **2.57 / 5.0** ($p < 0.001$, $\text{CLES} = 0.770$). **Rio de Janeiro (`RJ`)** stands out as the single largest operational bottleneck by volume, generating **~1,664 late orders** (a **13.47%** late rate across 12,350 deliveries).

### Headline KPI Scorecard

| Business Dimension | Core Metric | Verified Value | Analytical Benchmark / Context |
| :--- | :--- | :--- | :--- |
| **Scale & Revenue** | Total Valid Orders | **98,207** | Excludes 625 `canceled` & 609 `unavailable` orders |
| **Scale & Revenue** | Total Merchandise Revenue (GMV) | **13,494,400.74 BRL** | Product `price` only (shipping freight tracked separately) |
| **Order Economics** | Overall Average Order Value (AOV) | **137.41 BRL** | Narrow monthly band of 124.76 – 152.60 BRL |
| **Concentration** | Top Category Share (Pareto) | **81.26%** | Driven by **18 of 74** categories (24.3%) |
| **Concentration** | Top State Share (Pareto) | **81.47%** | Driven by **7 of 27** states; `SP` alone = **38.27%** |
| **Logistics & CX** | Late Delivery Rate | **8.11%** | 7,826 late vs. 88,644 on-time (`delivered` orders) |
| **Logistics & CX** | Review Score Gap (On-Time vs. Late) | **4.29 vs. 2.57** | **-1.72 pts** drop; 1–2 star share jumps 9.22% $\rightarrow$ 54.07% |
| **Retention** | Repeat Customer Rate ($\ge 2$ orders) | **3.04%** | 2,888 of 94,990 unique buyers (6.22% of total orders) |
| **Payments** | Credit Card Adoption & Installments | **75.47%** | **67.99%** of card orders use $\ge 2$ monthly installments |

---

## 2. Analytical Methodology & Data Guardrails

To ensure a Single Source of Truth across SQL, Python, and Power BI, all metrics adhere to strict data-hygiene rules established during data quality auditing:
- **Boundary Month Filtering:** Incomplete boundary months (`2016-09` to `2016-12` with 329 orders; `2018-09` to `2018-10` with 20 orders) are excluded from time-series trend analyses to prevent artificial Month-over-Month (MoM) distortions.
- **Preventing Join Fan-Out:** Because **2,961 orders** contain multiple payment rows and **547 orders** contain multiple review entries, line items and payments are pre-aggregated to the `order_id` grain, and reviews are deduplicated via `ROW_NUMBER()` to retain only the latest customer response (`review_answer_timestamp DESC`).
- **True Customer Granularity:** Buyers are tracked via `customer_unique_id` (96,096 distinct individuals across 99,441 total orders) rather than order-level `customer_id`.
- **100% Revenue Preservation:** Products missing category metadata (610 items) or English translations (`pc_gamer`, `portateis_cozinha_e_preparadores_de_alimentos`) are retained via `LEFT JOIN` and `COALESCE` under `unknown` or their original Portuguese labels.

---

## 3. Detailed Findings & Strategic Recommendations

### Finding 1 (Q1): Volume-Driven Hypergrowth in 2017 Followed by a 2018 Plateau, with Stagnant AOV
- **Quantitative Evidence:** Across the 20 complete operating months (`2017-01` to `2018-08`), monthly GMV expanded nearly **8x**, rising from **120,098.27 BRL** (787 orders in `2017-01`) to an all-time peak of **1,003,862.14 BRL** (7,421 orders in `2017-11`, a **+52.1% MoM** surge over October's 660,179.62 BRL), before normalizing to **742,183.79 BRL** (-26.1% MoM) in `2017-12`. Throughout `2018-01` to `2018-08`, monthly revenue stabilized within a consistent **838k–994k BRL** band (peaking in April 2018 at **993,592.98 BRL** and May 2018 at **992,871.75 BRL**, averaging 6,145–7,187 orders/month). Throughout this entire 20-month period, AOV remained flat between **124.76 BRL** and **152.60 BRL** (trending slightly downward from ~140–152 BRL in early 2017 to ~132–145 BRL in 2018).
- **Why It Matters:** Olist successfully scaled marketplace liquidity and order volume, but top-line growth relied entirely on transaction count rather than basket-size expansion. Once monthly order volume plateaued in 2018, stagnant AOV capped overall revenue growth.
- **Actionable Recommendations:**
  1. Introduce a **tiered free-shipping threshold** set ~15–20% above the current median/average basket (e.g., free shipping on orders $\ge$ **160 BRL**) to incentivize multi-item checkouts.
  2. Deploy automated **"Frequently Bought Together" cross-sell bundles** at checkout for high-velocity categories (`health_beauty`, `bed_bath_table`).
- **Confidence & Limitations:** **High confidence.** Complete 20-month longitudinal coverage. *Limitation:* Because the dataset ends in August 2018, Q4 2018 is unobserved, preventing multi-year seasonality verification of the November Black Friday spike (which is inferred rather than explicitly tagged in the schema).

---

### Finding 2 (Q2a): Product Revenue Follows a Strict Pareto 80/20 Concentration Across Two Distinct Merchandising Models
- **Quantitative Evidence:** Out of **74 product categories**, just **18 categories (24.3%)** generate **81.26%** of total GMV, while the Top 5 alone account for **39.82%**: `health_beauty` (**1.26M BRL**), `watches_gifts` (**1.20M BRL**), `bed_bath_table` (**1.04M BRL**), `sports_leisure`, and `computers_accessories`. The data highlights two distinct revenue engines:
  - *High-Volume Everyday Goods:* `bed_bath_table` leads unit volume with **11,097 items sold** at an average item price of **~93.4 BRL**.
  - *High-Ticket Discretionary Goods:* `watches_gifts` ranks #2 in revenue with **5,970 items** (**~200.7 BRL/item**), while `computers` reaches rank #17 with only **203 items sold** (**~1,098 BRL/item**).
  - Uncategorized items (`unknown`) rank #21 with **178,572.55 BRL** (1.32% of GMV).
- **Why It Matters:** Nearly four-fifths of marketplace revenue depends on fewer than a quarter of categories. Supply disruptions, seller churn, or stockouts in these 18 core categories would disproportionately impact platform GMV.
- **Actionable Recommendations:**
  1. Prioritize seller onboarding, inventory forecasting, and seasonal promotional campaigns around the **Top 18 Pareto categories** ahead of Q4 peak demand.
  2. Enforce mandatory category taxonomy validation during seller listing creation to eliminate the **1.32% (`unknown`)** catalog blind spot and improve search discoverability.
- **Confidence & Limitations:** **High confidence.** 100% of line-item revenue reconciled cleanly (`13,494,400.74 BRL`). *Limitation:* Cost of Goods Sold (COGS) and seller commission take-rates are absent, so concentration is measured on gross GMV rather than net margin.

---

### Finding 3 (Q2b): Geographic Revenue Concentrates in the Southeast While Remote States Exhibit Higher AOV
- **Quantitative Evidence:** **7 out of 27 Brazilian states (25.9%)** generate **81.47%** of total GMV, and the Top 3 Southeast states—**São Paulo (`SP`)**, **Rio de Janeiro (`RJ`)**, and **Minas Gerais (`MG`)**—account for **63.35%**. `SP` alone contributes **38.27%** (**5.16M BRL** across **41,125 orders**) but records the lowest AOV nationwide at **125.57 BRL**. Conversely, remote Northern and Northeastern states exhibit **55–72% higher AOV**, such as Paraíba (`PB`: **216.34 BRL**), Amapá (`AP`: **198.15 BRL**), and Acre (`AC`: **197.32 BRL**).
- **Why It Matters:** Heavy dependence on `SP` exposes Olist to regional macroeconomic fluctuations. Meanwhile, the inverse relationship between proximity and AOV indicates that customers in remote regions consolidate purchases into higher-value baskets to amortize high interstate shipping fees and longer transit times.
- **Actionable Recommendations:**
  1. Recruit regional sellers and establish fulfillment hubs outside `SP` (particularly in the South and Northeast) to lower interstate freight costs and unlock high-frequency, everyday purchasing in underpenetrated states.
  2. Tailor digital marketing in remote high-AOV states toward higher-ticket durable goods where shipping fees represent a smaller fraction of total order value.
- **Confidence & Limitations:** **High confidence.** *Limitation:* Analysis reflects customer state (`customer_state`); cross-border seller-to-customer lane distances were not modeled at the zip-code level due to duplicate coordinate entries in `olist_geolocation`.

---

### Finding 4 (Q3a): Late Deliveries Trigger a Severe Review Collapse, with a Sharp Inflection Point Beyond 20 Days
- **Quantitative Evidence:** Among **96,470 delivered orders** with valid timestamps:
  - **On-Time Deliveries (91.89%, 88,644 orders):** Median transit time is **9.73 days**, yielding a **4.29 / 5.0** average review score and a **9.22%** rate of poor ratings (1–2 stars).
  - **Late Deliveries (8.11%, 7,826 orders):** Median transit time triples to **29.15 days**, causing the average review score to plummet by **1.72 points** to **2.57 / 5.0**, while the 1–2 star rating rate surges nearly sixfold to **54.07%**.
  - **Statistical Validation:** A two-sided **Mann–Whitney U test** confirms the difference is highly significant ($p < 0.001$), with a Common Language Effect Size (**$\text{CLES} = 0.770$**)—meaning a randomly selected on-time order has a **77.0% probability** of receiving a higher review score than a late order. **Spearman rank correlation ($\rho = -0.33, p < 0.001$)** confirms a moderate negative monotonic relationship between transit duration and satisfaction.
  - **20-Day Cliff Effect:** Customer ratings erode gradually across transit buckets up to 20 days (`<= 5 days`: **4.45** $\rightarrow$ `6–10 days`: **4.36** $\rightarrow$ `11–15 days`: **4.27** $\rightarrow$ `16–20 days`: **4.13**), but suffer a sharp **-0.90 point drop** to **3.23** once delivery exceeds **20 days** (which affects **14.63%** of all delivered orders).
- **Why It Matters:** Delivery reliability is the single strongest operational driver of customer sentiment. Beyond the 20-day threshold, customer patience breaks down regardless of promised delivery dates, generating severe brand damage and deterring repeat purchases.
- **Actionable Recommendations:**
  1. Implement an automated **15-day transit SLA alert** to flag in-transit orders approaching the 20-day cliff for proactive carrier escalation and customer notification.
  2. Penalize chronic late-dispatch sellers in search ranking algorithms and incentivize fast carrier handoffs (within 24–48 hours of order approval).
- **Confidence & Limitations:** **High statistical confidence; correlational interpretation.** *Limitation:* Because this is an observational study, results establish a strong statistical association rather than strict causality—unobserved confounders such as product fragility, seller packaging quality, and regional expectations may also influence review scores.

---

### Finding 5 (Q3b): Rio de Janeiro (`RJ`) Represents the Single Largest Operational Bottleneck by Volume
- **Quantitative Evidence:** Among states with substantial volume ($\ge 500$ delivered orders), remote Northeastern states exhibit the highest relative delay percentages—led by Maranhão (`MA`: **19.65%**), Ceará (`CE`: **15.36%**), and Bahia (`BA`: **14.04%**). However, **Rio de Janeiro (`RJ`)** ranks #4 in late percentage at **13.47%** across **12,350 delivered orders**—making it Olist's second-largest market overall (~3.8x the volume of `BA` and ~17x `MA`) and generating **~1,664 late orders** (more than **2.3x** `SP`'s **5.89%** late rate).
- **Why It Matters:** While Northeastern states look worst on a percentage basis, optimizing logistics into `RJ` addresses the largest absolute concentration of dissatisfied customers on the platform.
- **Actionable Recommendations:**
  1. Audit third-party carrier performance specifically on **`SP` $\rightarrow$ `RJ` interstate corridors** and reallocate volume away from underperforming logistics partners.
  2. Recalibrate `order_estimated_delivery_date` buffers for `RJ` and Northeast routes so promised delivery windows reflect realistic transit times, preventing expectation misses.
- **Confidence & Limitations:** **High confidence** (large sample size of 12,350 orders in `RJ`). *Limitation:* The public dataset does not expose carrier IDs (`carrier_id`), preventing direct attribution of delays to specific courier companies.

---

### Finding 6 (Q4): Ultra-Low Repeat Purchase Rate (3.04%) Leaves Growth Dependent on Costly Customer Acquisition
- **Quantitative Evidence:** Out of **94,990 unique customers** with valid orders, **96.96%** (92,102 buyers) purchased only once. Only **3.04%** (2,888 buyers: 2,652 with 2 orders [2.79%] and 236 with $\ge 3$ orders [0.25%]) returned for a second purchase, contributing **6.22%** of total valid orders. Comparing cohorts reveals that repeat buyers leave slightly higher review scores (**4.18 vs. 4.11**) but exhibit a lower AOV (**122.95 BRL vs. 138.38 BRL**), indicating that initial purchases skew toward larger durable goods while repeat orders skew toward smaller, replenishable items (yielding ~1.8x higher cumulative LTV).
- **Why It Matters:** Relying on 97% one-time buyers makes Olist vulnerable to rising Customer Acquisition Costs (CAC). Even a modest lift in retention (e.g., doubling repeat rate from 3% to 6%) would generate thousands of incremental orders with minimal marketing spend.
- **Actionable Recommendations:**
  1. Launch an automated **post-delivery retention workflow (Day 14–30)** targeting satisfied first-time buyers (4–5 star reviewers) in replenishable categories (`health_beauty`, `bed_bath_table`, `pet_shop`) with a time-bound voucher for their second order.
  2. Build platform-level brand recognition (loyalty points or cross-seller free shipping) so buyers associate positive experiences with Olist rather than individual third-party merchants.
- **Confidence & Limitations:** **Moderate-to-High confidence.** *Limitation:* Because the observation window spans 20 months, customers acquired in mid-to-late 2018 suffer from **right-censoring** (insufficient elapsed time to observe a second purchase), meaning long-term retention is slightly understated.

---

### Finding 7 (Q5): Credit Card Installment Plans Act as the Primary Conversion Engine for High-Ticket Orders
- **Quantitative Evidence:** Across **98,206 valid orders** with payment records (classified by primary payment method with highest `payment_value`), **credit cards (`credit_card`)** dominate at **75.47%** (74,116 orders) and generate the highest average transaction value (**166.64 BRL**, median **109.51 BRL**), followed by cash payment slips (**`boleto`**) at **19.90%** (19,539 orders, avg **144.67 BRL**). Together, `credit_card` and `boleto` account for **95.37%** of all orders (`voucher`: 3.09%; `debit_card`: 1.54%). Within credit card transactions, **67.99%** utilize multi-month installments ($\ge 2$ periods), with average order value scaling over **4x** alongside installment duration:
  - **1 installment (32.01% of card orders):** Avg **100.78 BRL** (median **71.63 BRL**)
  - **8 installments:** Avg **309.00 BRL** (median **212.91 BRL**)
  - **10 installments:** Avg **414.76 BRL** (median **240.22 BRL**)
- **Why It Matters:** Interest-free installment financing is culturally ingrained in Brazilian e-commerce and serves as the critical affordability lever enabling shoppers to purchase high-ticket items (`watches_gifts`, `computers_accessories`, `furniture_decor`).
- **Actionable Recommendations:**
  1. Prominently display **monthly installment pricing** (e.g., *"10x of 41.48 BRL interest-free"*) directly on product search cards and checkout pages for items priced above **200 BRL**.
  2. Co-fund promotional 6–10x installment campaigns with top sellers in high-ticket categories while monitoring financing fee structures to protect net unit economics.
- **Confidence & Limitations:** **High confidence.** *Limitation:* For the 2,961 split-payment orders (e.g., credit card + voucher), classifying by the largest `payment_value` slightly underrepresents secondary voucher usage; additionally, merchant discount rates (MDR) and installment financing costs are not recorded in the dataset.

---

## 4. Prioritized Action Roadmap

| Priority | Strategic Initiative | Target Segment | Expected Business Impact | Implementation Effort |
| :--- | :--- | :--- | :--- | :--- |
| **P1 (Immediate)** | **15-Day Transit SLA Alerts & `SP` $\rightarrow$ `RJ` Carrier Reallocation** | Orders >15 days in transit; `RJ` interstate lanes (12,350 orders) | Reduces >20-day cliff delays; lifts `RJ` & platform review scores | **Medium** (Ops & carrier SLA routing) |
| **P2 (Short-Term)** | **Second-Order Retention Voucher Campaign** | 4–5 star first-time buyers in `health_beauty`, `bed_bath_table`, `pet_shop` | Lifts repeat customer rate above 3.04% at near-zero CAC | **Low** (CRM email automation) |
| **P3 (Short-Term)** | **160 BRL Free-Shipping Threshold & Checkout Cross-Sell Bundles** | High-volume, low-AOV markets (`SP` at 125.57 BRL) | Breaks AOV stagnation (137.41 BRL $\rightarrow$ 150+ BRL) | **Low–Medium** (Cart UI & promo rules) |
| **P4 (Medium-Term)** | **Prominent 6–10x Installment Merchandising & Regional Seller Expansion** | High-ticket categories (>200 BRL); non-`SP` states | Increases high-ticket conversion & lowers interstate freight | **Medium–High** (Seller acquisition) |