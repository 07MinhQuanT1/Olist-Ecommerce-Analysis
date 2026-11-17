-- ============================================================================
-- Q5: Hình thức thanh toán, số kỳ trả góp và giá trị đơn hàng
-- Định nghĩa chỉ số:
--   - Hình thức thanh toán chủ đạo (main_type): Với đơn dùng nhiều hình thức thanh toán
--     (2,961 đơn ở Bước 2), chọn hình thức có payment_value lớn nhất làm đại diện.
--   - Tổng tiền thanh toán đơn (total_paid) = SUM(payment_value) theo order_id.
--   - Giá trị đơn trung bình (aov_paid) = AVG(total_paid) (gồm cả tiền hàng + phí ship).
-- Giả định áp dụng:
--   - Chỉ xét các đơn hàng hợp lệ (loại bỏ 'canceled' và 'unavailable').
--   - Gộp dữ liệu bảng olist_order_payments về mức order_id trước khi JOIN với olist_orders
--     để tránh bẫy nhân đôi số đơn hàng.
--   - Với Q5b (trả góp), chỉ xét các đơn có hình thức chủ đạo là 'credit_card' và
--     payment_installments >= 1 (loại bỏ giá trị 0 kỳ nếu có).
-- ============================================================================

-- Q5a: Cơ cấu các hình thức thanh toán chủ đạo và giá trị đơn hàng trung bình
WITH pay_order AS ( -- bảng tạm thu gọn thanh toán về mức order_id)
    SELECT 
        order_id,
        SUM(payment_value) AS total_paid, -- cộng tổng số tiền khách trả cho đơn hàng
        COUNT(DISTINCT payment_type) AS n_types, -- đếm đơn hàng có bao nhiêu kiểu thanh toán 
        (ARRAY_AGG(payment_type ORDER BY payment_value DESC))[1] AS main_type, --sắp xếp theo số tiền trả của từng hình thức (DESC) và lấy ra phần tử đầu tiên - hình thức thanh toán chủ đạo
        MAX(payment_installments) AS max_installments -- số kỳ trả góp lớn nhất của đơn hàng đó
    FROM olist_order_payments
    GROUP BY order_id -- gom tất cả lần quẹt thẻ về một dòng duy nhất theo order_id
)
SELECT 
    p.main_type,
    COUNT(*) AS orders, --đếm tổng số đơn hàng của hình thức chủ đạo
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS share_pct, --tỉ trọng của của từng hình thức chủ đạo
    ROUND(AVG(p.total_paid)::numeric, 2) AS aov_paid,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY p.total_paid)::numeric, 2) AS median_paid
FROM pay_order p
JOIN olist_orders o USING (order_id) -- nối sang bảng đơn hàng lọc các đơn hợp lệ
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY p.main_type
ORDER BY orders DESC;

-- Q5b: Phân tích hành vi trả góp (Installments) trên nhóm thanh toán bằng thẻ tín dụng
WITH pay_order AS ( 
    SELECT 
        order_id,
        SUM(payment_value) AS total_paid,
        (ARRAY_AGG(payment_type ORDER BY payment_value DESC))[1] AS main_type,
        MAX(payment_installments) AS installments
    FROM olist_order_payments
    GROUP BY order_id
)
SELECT 
    p.installments,
    COUNT(*) AS orders,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS share_pct,
    ROUND(AVG(p.total_paid)::numeric, 2) AS aov_paid,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY p.total_paid)::numeric, 2) AS median_paid
FROM pay_order p
JOIN olist_orders o USING (order_id)
WHERE o.order_status NOT IN ('canceled', 'unavailable')
  AND p.main_type = 'credit_card' --chỉ xét các đơn dùng thẻ tín dụng
  AND p.installments >= 1 --loại bỏ các đơn lỗi ghi 0 kỳ trả góp
GROUP BY p.installments --gom nhóm theo từng mốc kỳ trả góp
ORDER BY p.installments; --sắp xếp theo số kỳ trả góp tăng dần 