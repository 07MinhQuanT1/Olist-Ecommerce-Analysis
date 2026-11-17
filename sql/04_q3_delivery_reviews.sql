-- ============================================================================
-- Q3: Tốc độ giao hàng, tỉ lệ giao trễ và mối liên hệ với điểm đánh giá (Review)
-- Định nghĩa chỉ số:
--   - Thời gian giao thực tế (delivery_days) = (order_delivered_customer_date - order_purchase_timestamp) tính theo ngày thực.
--   - Giao trễ (is_late) = 1 nếu order_delivered_customer_date > order_estimated_delivery_date, ngược lại = 0.
-- Giả định áp dụng:
--   - Chỉ xét các đơn trạng thái 'delivered' và có đầy đủ order_delivered_customer_date (loại 8 đơn bị NULL).
--   - Với các đơn có nhiều dòng review (547 đơn), chỉ giữ lại review mới nhất (review_answer_timestamp DESC) bằng ROW_NUMBER().
-- ============================================================================

-- Q3a: Tổng quan tốc độ giao hàng, tỉ lệ giao trễ và so sánh điểm review (Đúng hạn vs Trễ hạn)
WITH latest_review AS ( --khai báo bảng tạm
    SELECT 
        order_id, 
        review_score, --lấy ra mã đơn và đánh giá từ bảng olist_order_reviews
        ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY review_answer_timestamp DESC) AS rn --đánh giá mới nhất được đánh rn = 1
    FROM olist_order_reviews
),
delivery_base AS (
    SELECT 
        o.order_id,
        EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)) / 86400.0 AS delivery_days, --thời gian nhận - thời gian đặt 
        CASE 
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 
            ELSE 0 --so sánh ngày giao thực tế và dự diến
        END AS is_late,
        lr.review_score
    FROM olist_orders o --lấy dữ liệu gốc từ bảng đơn hàng đặt tên viết tắt là o
    LEFT JOIN latest_review lr ON lr.order_id = o.order_id AND lr.rn = 1 --ghép bảng đơn hàng với bảng lạm review (chỉ lấy đúng dòng rn =1)
    WHERE o.order_status = 'delivered' --chỉ giữ các đơn giao thành công
      AND o.order_delivered_customer_date IS NOT NULL
)
SELECT 
    CASE WHEN is_late = 1 THEN 'Late (Trễ hạn)' ELSE 'On-time (Đúng hạn)' END AS delivery_status, --đổi số 0 và 1 thành on-time và late
    COUNT(*) AS orders, --đếm tổng số đơn của mỗi nhóm
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS share_pct, --tỉ trọng % của mỗi nhóm so với tổng số đơn
    ROUND(AVG(delivery_days)::numeric, 2) AS avg_delivery_days, --trung bình cộng số ngày giao hàng
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY delivery_days)::numeric, 2) AS median_delivery_days, --tính trung vị số ngày giao
    ROUND(AVG(review_score)::numeric, 2) AS avg_review_score, --tính điểm đánhg giá trung bình của mỗi nhóm
    ROUND(100.0 * COUNT(*) FILTER (WHERE review_score <= 2) / NULLIF(COUNT(review_score), 0), 2) AS low_score_1_2_pct
FROM delivery_base
GROUP BY is_late
ORDER BY is_late;

-- Q3b: Điểm review trung bình theo từng nhóm số ngày giao hàng (Delivery Buckets)
WITH latest_review AS (
    SELECT 
        order_id, 
        review_score,
        ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY review_answer_timestamp DESC) AS rn
    FROM olist_order_reviews
),
delivery_buckets AS (
    SELECT 
        EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)) / 86400.0 AS delivery_days,
        lr.review_score
    FROM olist_orders o
    LEFT JOIN latest_review lr ON lr.order_id = o.order_id AND lr.rn = 1
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND lr.review_score IS NOT NULL --loại bỏ các đơn không có đánh giá 
)
SELECT 
    CASE 
        WHEN delivery_days <= 5  THEN '1. <= 5 days'
        WHEN delivery_days <= 10 THEN '2. 6–10 days'
        WHEN delivery_days <= 15 THEN '3. 11–15 days'
        WHEN delivery_days <= 20 THEN '4. 16–20 days'
        ELSE '5. > 20 days'
    END AS delivery_bucket,
    COUNT(*) AS orders,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS share_pct,
    ROUND(AVG(review_score)::numeric, 2) AS avg_review_score
FROM delivery_buckets
GROUP BY 1
ORDER BY 1;

-- Q3c: Top 10 bang có tỉ lệ giao trễ cao nhất (chỉ xét các bang có >= 500 đơn để tránh nhiễu mẫu nhỏ)
SELECT 
    c.customer_state AS state,
    COUNT(*) AS delivered_orders,
    ROUND(AVG(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)) / 86400.0)::numeric, 2) AS avg_delivery_days,
    ROUND(100.0 * COUNT(*) FILTER (WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date) / COUNT(*), 2) AS late_rate_pct
FROM olist_orders o
JOIN olist_customers c USING (customer_id) --nối bảng đơn hàng (o) với khách hàng (c) theo customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state --gom nhóm tính toán theo từng bang
HAVING COUNT(*) >= 500 --lọc sau khi gom nhóm, chỉ giữ các nhóm có >= 500 đơn
ORDER BY late_rate_pct DESC
LIMIT 10; --sắp xếp trễ nhất lên đầu, lấy 10 bang đứng đầu