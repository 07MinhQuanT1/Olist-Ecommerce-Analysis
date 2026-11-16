-- ============================================================================
-- BƯỚC 2: KIỂM TRA CHẤT LƯỢNG DỮ LIỆU (DATA QUALITY CHECKS)
-- ============================================================================

-- 1. Số dòng từng bảng cốt lõi
SELECT 'orders' AS table_name, COUNT(*) AS row_count FROM olist_orders
UNION ALL SELECT 'order_items', COUNT(*) FROM olist_order_items
UNION ALL SELECT 'payments',    COUNT(*) FROM olist_order_payments
UNION ALL SELECT 'reviews',     COUNT(*) FROM olist_order_reviews
UNION ALL SELECT 'customers',   COUNT(*) FROM olist_customers
UNION ALL SELECT 'products',    COUNT(*) FROM olist_products;

-- 2. Phân bố đơn theo tháng (để chọn khoảng thời gian ổn định cho xu hướng)
SELECT date_trunc('month', order_purchase_timestamp)::date AS month, 
       COUNT(*) AS orders
FROM olist_orders 
GROUP BY 1 
ORDER BY 1;

-- 3. Phân bố trạng thái đơn hàng
SELECT order_status, COUNT(*) AS orders
FROM olist_orders 
GROUP BY 1 
ORDER BY 2 DESC;

-- 4. Kiểm tra đơn hàng không có dòng sản phẩm nào (Orders without items)
SELECT COUNT(*) AS orders_without_items
FROM olist_orders o
LEFT JOIN olist_order_items i USING (order_id)
WHERE i.order_id IS NULL;

-- 5. Kiểm tra đơn có nhiều dòng thanh toán / nhiều review (Bẫy JOIN nhân đôi)
SELECT COUNT(*) AS orders_multi_payment
FROM (SELECT order_id FROM olist_order_payments GROUP BY 1 HAVING COUNT(*) > 1) x;

SELECT COUNT(*) AS orders_multi_review
FROM (SELECT order_id FROM olist_order_reviews GROUP BY 1 HAVING COUNT(*) > 1) x;

-- 6. Phân biệt customer_id (theo đơn) vs customer_unique_id (khách hàng thật)
SELECT COUNT(DISTINCT customer_id)        AS customer_ids,
       COUNT(DISTINCT customer_unique_id) AS real_customers
FROM olist_customers;

-- 7. Giá trị thiếu (NULL) ở cột ngày giao hàng thực tế
SELECT COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL) AS no_delivery_date,
       COUNT(*) FILTER (WHERE order_status = 'delivered'
                          AND order_delivered_customer_date IS NULL) AS delivered_but_no_date
FROM olist_orders;

-- 8. Sản phẩm thiếu danh mục gốc hoặc thiếu bản dịch tiếng Anh
SELECT COUNT(*) AS products_no_category
FROM olist_products 
WHERE product_category_name IS NULL;

SELECT DISTINCT p.product_category_name
FROM olist_products p
LEFT JOIN product_category_name_translation t USING (product_category_name)
WHERE p.product_category_name IS NOT NULL
  AND t.product_category_name_english IS NULL;

-- 9. Đối chiếu chéo: Tổng (price + freight_value) vs Tổng payment_value ở mức đơn
WITH i AS (
    SELECT order_id, SUM(price + freight_value) AS items_total
    FROM olist_order_items 
    GROUP BY 1
),
p AS (
    SELECT order_id, SUM(payment_value) AS paid_total
    FROM olist_order_payments 
    GROUP BY 1
)
SELECT COUNT(*) AS orders_compared,
       COUNT(*) FILTER (WHERE ABS(i.items_total - p.paid_total) > 1) AS mismatch_over_1_brl
FROM i JOIN p USING (order_id);