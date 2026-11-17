-- ============================================================================
-- Q1: Doanh thu, số đơn hàng, AOV và tăng trưởng MoM theo tháng
-- Định nghĩa chỉ số:
--   - Doanh thu (Revenue) = SUM(price) tính bằng BRL (không bao gồm phí ship).
--   - AOV (Average Order Value) = Tổng doanh thu / Tổng số đơn hàng hợp lệ.
--   - MoM Growth (%) = ((Doanh thu tháng này - Doanh thu tháng trước) / Doanh thu tháng trước) * 100.
-- Giả định áp dụng:
--   - Loại bỏ các đơn ở trạng thái 'canceled' và 'unavailable'.
--   - Gộp doanh thu về mức order_id trước khi JOIN với bảng olist_orders để tránh nhân đôi.
--   - Phân tích xu hướng tập trung vào cửa sổ 20 tháng đầy đủ (2017-01 đến 2018-08).
-- ============================================================================

WITH order_rev AS (
    SELECT 
        order_id, 
        SUM(price) AS revenue, 
        SUM(freight_value) AS freight
    FROM olist_order_items
    GROUP BY order_id
),
monthly AS (
    SELECT 
        date_trunc('month', o.order_purchase_timestamp)::date AS month,
        COUNT(*) AS orders,
        ROUND(SUM(r.revenue)::numeric, 2) AS revenue,
        ROUND((SUM(r.revenue) / COUNT(*))::numeric, 2) AS aov
    FROM olist_orders o
    JOIN order_rev r USING (order_id)
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY 1
)
SELECT 
    month, 
    orders, 
    revenue, 
    aov,
    ROUND(
        100.0 * (revenue - LAG(revenue) OVER (ORDER BY month)) 
        / NULLIF(LAG(revenue) OVER (ORDER BY month), 0), 
        1
    ) AS mom_growth_pct
FROM monthly
ORDER BY month;