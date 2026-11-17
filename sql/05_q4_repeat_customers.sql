-- ============================================================================
-- Q4: Tỉ lệ khách hàng quay lại (Repeat Customer Rate) & So sánh hành vi mua
-- Định nghĩa chỉ số:
--   - Khách hàng duy nhất (Unique Customer) đếm bằng customer_unique_id (KHÔNG dùng customer_id).
--   - Khách quay lại (Repeat Customer) = Khách có tổng số đơn hợp lệ >= 2.
--   - Repeat Customer Rate (%) = (Số khách có >= 2 đơn / Tổng số khách duy nhất) * 100.
-- Giả định áp dụng:
--   - Chỉ tính các đơn hàng hợp lệ (loại bỏ 'canceled' và 'unavailable').
--   - Cửa sổ quan sát của dữ liệu là ~2 năm (2016–2018), nên khách mới mua cuối kỳ
--     có thể chưa kịp phát sinh đơn tiếp theo.
-- ============================================================================

-- Q4a: Phân bố số đơn trên mỗi khách hàng & Tỉ lệ khách quay lại
WITH cust_orders AS ( --đếm số đơn hợp lệ của từng khách hàng thật 
    SELECT 
        c.customer_unique_id, --lấy mã định danh duy nhất
        COUNT(DISTINCT o.order_id) AS order_count --đếm số đơn hợp lệ của từng khách và đặt tên cột
    FROM olist_orders o
    JOIN olist_customers c USING (customer_id)
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY c.customer_unique_id
),
bucketed AS ( --khai báo bảng tạm thứ 2
    SELECT 
        customer_unique_id,
        order_count,
        CASE 
            WHEN order_count = 1 THEN '1. 1 đơn (One-time)'
            WHEN order_count = 2 THEN '2. 2 đơn'
            ELSE '3. 3+ đơn'
        END AS order_bucket -- chia thành 3 nhóm dựa vào cột order_count
    FROM cust_orders
)
SELECT 
    order_bucket, -- hiển thị tên nhóm tần suất mua
    COUNT(*) AS customers, --đếm có bao nhiêu khách trong nhóm đó
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS customer_share_pct,
    SUM(order_count) AS total_orders, -- cộng tổng số đơn của nhóm đó
    ROUND(100.0 * SUM(order_count) / SUM(SUM(order_count)) OVER (), 2) AS order_share_pct
FROM bucketed
GROUP BY order_bucket
ORDER BY order_bucket; -- gom nhóm theo tần suất và sắp xếp thứ tự 1 2 3

-- Q4b: So sánh giá trị đơn trung bình (AOV) & điểm review giữa khách mua 1 lần vs khách quay lại
WITH order_rev AS ( -- gom tổng tiền hàng của từng đơn về đúng một dòng
    SELECT order_id, SUM(price) AS revenue
    FROM olist_order_items
    GROUP BY order_id
),
latest_review AS (
    SELECT 
        order_id, 
        review_score,
        ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY review_answer_timestamp DESC) AS rn --đánh số thự tự các dòng review của từng đơn, latest thì đánh rn = 1
    FROM olist_order_reviews
),
cust_orders AS ( --tính tổng số đơn hợp lệ của từng khách hàng thật
    SELECT 
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM olist_orders o
    JOIN olist_customers c USING (customer_id)
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY c.customer_unique_id
)
SELECT 
    CASE WHEN co.order_count >= 2 THEN 'Repeat (>= 2 đơn)' ELSE 'One-time (1 đơn)' END AS customer_type, --chia khách thành 2 tệp đối lập nhau
    COUNT(DISTINCT co.customer_unique_id) AS customers, --đếm số lượng con người thật không trùng trong mỗi tệp
    COUNT(o.order_id) AS orders, -- đếm tổng số đơn của mỗi tệp
    ROUND(AVG(r.revenue)::numeric, 2) AS avg_order_value,
    ROUND(AVG(lr.review_score)::numeric, 2) AS avg_review_score
FROM cust_orders co -- từ bảng khách hàng đã biết tổng số đơn
JOIN olist_customers c ON c.customer_unique_id = co.customer_unique_id --nối để lấy lại mã customer_id
JOIN olist_orders o ON o.customer_id = c.customer_id --lấy danh sách từng đơn hàng cụ thể
JOIN order_rev r ON r.order_id = o.order_id -- lấy tiền hàng của từng đơn
LEFT JOIN latest_review lr ON lr.order_id = o.order_id AND lr.rn = 1 --lấy điểm review mới nhất
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY 1 -- gom nhóm theo cột thứ 1(customer_type)
ORDER BY 1; --sắp xếp theo bảng chữ cái (One-time trước Repeat)