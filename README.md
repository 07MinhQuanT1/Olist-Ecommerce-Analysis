# Olist E-commerce Analysis (SQL · pandas · Power BI)

> One-line summary: End-to-end analysis of 99,441 Brazilian e-commerce orders (Olist, 2016–2018) using PostgreSQL, Python (pandas, SciPy), and Power BI to evaluate revenue trends, category/state concentration, delivery performance vs. customer reviews, repeat purchase behavior, and payment patterns.

## 1. Business context
Acting as a Data Analyst intern for Olist (a Brazilian e-commerce marketplace), this project answers five core business questions for leadership:
- **Q1:** How do revenue, order volume, and Average Order Value (AOV) change month-over-month (MoM)?
- **Q2:** Which product categories and customer states contribute the most revenue, and how concentrated is revenue (Pareto 80/20)?
- **Q3:** How fast are deliveries, what is the late delivery rate, and how does delivery speed relate to customer review scores?
- **Q4:** What is the repeat customer rate (customers placing ≥ 2 orders)?
- **Q5:** What payment methods and installment plans do customers use, and how does order value differ across them?

## 2. Data
- **Source:** [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle), License: CC BY-NC-SA 4.0.
- **Actual Scale (verified via `COUNT(*)`):** 99,441 orders, 112,650 order items, 103,886 payment records, 99,224 reviews, 96,096 unique customers, 32,951 products, and 3,095 sellers across 9 relational tables.

### Data Quality Notes (Step 2 Findings)
1. **Sparse boundary months:** Data spans `2016-09` to `2018-10`, but `2016-09`–`2016-12` (only 329 orders total) and `2018-09`–`2018-10` (20 orders total) are incomplete/truncated. Trend analyses focus on the 20 complete months from **`2017-01` to `2018-08`**.
2. **Order status & empty orders:** Out of 99,441 orders, 96,478 (97.0%) are `delivered`, while 625 are `canceled` and 609 are `unavailable`. Additionally, 775 orders have no line items in `olist_order_items` (mostly canceled/unavailable orders).
3. **One-to-many join traps:** **2,961 orders** have multiple payment rows (e.g., credit card + voucher) and **547 orders** have multiple review entries. All tables are aggregated or deduplicated to the `order_id` level before joining to prevent double-counting revenue.
4. **Customer identifier granularity:** There are 99,441 `customer_id` values (one per order) corresponding to **96,096 unique individuals** (`customer_unique_id`), confirming 3,345 repeat-order instances.
5. **Missing values & untranslated categories:** 2,965 orders lack `order_delivered_customer_date` (including 8 `delivered` orders, which are excluded from delivery-time calculations). 610 products have `NULL` categories, and 2 Portuguese categories (`pc_gamer`, `portateis_cozinha_e_preparadores_de_alimentos`) lack English translations in the lookup table.
6. **Financial cross-check:** Comparing `SUM(price + freight_value)` vs. `SUM(payment_value)` across 98,665 orders shows 99.75% agreement (only 249 orders differ by > 1 BRL, attributable to vouchers or minor adjustments).

## 3. Definitions & Assumptions
- **Revenue:** Defined as `SUM(price)` (Gross Merchandise Value excluding shipping freight), reported in Brazilian Real (**BRL**). Freight is tracked separately.
- **Valid Order Status:**
  - *Revenue, AOV, and Customer metrics:* All orders excluding `canceled` and `unavailable`.
  - *Delivery & Review metrics (Q3):* Only `delivered` orders with non-null `order_delivered_customer_date`.
- **Trend Analysis Window:** **`2017-01` to `2018-08`** (20 full months) to avoid distortion from sparse boundary months.
- **Unique Customers:** Counted using `customer_unique_id`.
- **Deduplication Rules:** For orders with multiple reviews, only the latest review (`review_answer_timestamp DESC`) is retained. For orders with multiple payment methods, the method with the highest `payment_value` is assigned as the primary payment type.