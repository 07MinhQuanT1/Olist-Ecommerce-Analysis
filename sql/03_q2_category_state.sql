-- ============================================================================
-- Q2: Danh mục sản phẩm (kèm Pareto 80/20) và Bang đóng góp doanh thu
-- Định nghĩa chỉ số:
--   - Doanh thu (Revenue) = SUM(price) tính bằng BRL (không gồm phí ship).
--   - Tỉ trọng (%) = (Doanh thu nhóm / Tổng doanh thu toàn sàn) * 100.
--   - Tỉ trọng cộng dồn (%) = Tổng tỉ trọng từ hạng 1 đến hạng hiện tại (Pareto 80/20).
-- Giả định áp dụng:
--   - Loại bỏ đơn hàng ở trạng thái 'canceled' và 'unavailable'.
--   - Q2a tính ở cấp dòng sản phẩm (order_items) vì một đơn có thể gồm nhiều danh mục;
--     dùng LEFT JOIN với bảng dịch tiếng Anh và gán 'unknown' nếu thiếu danh mục/bản dịch.
--   - Q2b tính ở cấp đơn hàng (gộp revenue về order_id trước) để đếm chính xác số đơn theo bang.
-- ============================================================================

-- Q2a: Xếp hạng danh mục sản phẩm theo doanh thu & Phân tích Pareto 80/20
WITH item_cat AS (
    SELECT 
        i.price,
        COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category
    FROM olist_order_items i
    JOIN olist_orders o USING (order_id)
    LEFT JOIN olist_products p USING (product_id)
    LEFT JOIN product_category_name_translation t
           ON t.product_category_name = p.product_category_name
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
),
cat AS (
    SELECT 
        category, 
        COUNT(*) AS items,
        ROUND(SUM(price)::numeric, 2) AS revenue
    FROM item_cat 
    GROUP BY category
)
SELECT 
    RANK() OVER (ORDER BY revenue DESC) AS rnk,
    category, 
    items, 
    revenue,
    ROUND(100.0 * revenue / SUM(revenue) OVER (), 2) AS share_pct,
    ROUND(100.0 * SUM(revenue) OVER (ORDER BY revenue DESC) / SUM(revenue) OVER (), 2) AS cum_share_pct
FROM cat
ORDER BY revenue DESC;

-- Q2b: Xếp hạng các bang (customer_state) đóng góp doanh thu và số đơn
WITH order_rev AS (
    SELECT 
        order_id, 
        SUM(price) AS revenue
    FROM olist_order_items
    GROUP BY order_id
),
state_rev AS (
    SELECT 
        c.customer_state AS state,
        COUNT(*) AS orders,
        ROUND(SUM(r.revenue)::numeric, 2) AS revenue,
        ROUND((SUM(r.revenue) / COUNT(*))::numeric, 2) AS aov
    FROM olist_orders o
    JOIN order_rev r USING (order_id)
    JOIN olist_customers c USING (customer_id)
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY c.customer_state
)
SELECT 
    RANK() OVER (ORDER BY revenue DESC) AS rnk,
    state,
    orders,
    revenue,
    aov,
    ROUND(100.0 * revenue / SUM(revenue) OVER (), 2) AS share_pct,
    ROUND(100.0 * SUM(revenue) OVER (ORDER BY revenue DESC) / SUM(revenue) OVER (), 2) AS cum_share_pct
FROM state_rev
ORDER BY revenue DESC;