-- ============================================================================
-- Tạo 2 SQL Views phục vụ phân tích trong Python (Bước 4) và Power BI (Bước 5)
--   1. v_order_fact: Bảng sự kiện ở cấp ĐƠN HÀNG (1 dòng = 1 order_id).
--   2. v_item_fact:  Bảng sự kiện ở cấp DÒNG SẢN PHẨM (1 dòng = 1 món hàng).
-- ============================================================================

-- View 1: Cấp đơn hàng (đã gộp tiền hàng/ship và khử trùng review mới nhất)
CREATE OR REPLACE VIEW v_order_fact AS --tạo bảng ảo, nếu bảng ảo đã tồn tại thì ghi đè lên cập nhật logic mới
WITH order_rev AS ( --bảng tạm gom tổng tiền hàng và phí ship của từng đơn theo order_id
    SELECT 
        order_id, 
        SUM(price) AS revenue, 
        SUM(freight_value) AS freight
    FROM olist_order_items 
    GROUP BY order_id
),
latest_review AS ( --bảng tạm lấy review mới nhất của từng đơn hàng
    SELECT 
        order_id, 
        review_score,
        ROW_NUMBER() OVER (
            PARTITION BY order_id 
            ORDER BY review_answer_timestamp DESC
        ) AS rn
    FROM olist_order_reviews
)
SELECT 
    o.order_id, -- mẫ đơn
    c.customer_unique_id, -- mã định danh người thật
    c.customer_state, -- bang của khách
    o.order_status, --trạng thái đơn 
    o.order_purchase_timestamp::date AS purchase_date,  -- cắt bỏ giờ phút giây chỉ giữ Y-M -D
    r.revenue,
    r.freight, --phí ship
    CASE 
        WHEN o.order_status = 'delivered' 
         AND o.order_delivered_customer_date IS NOT NULL
        THEN EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)) / 86400.0 -- đổi thời gian ra giây trừ đi nhau rồi quy ngược trở lại về ngày (dạng thập phân)
    END AS delivery_days, --tính số ngày giao hàng thực tế
    CASE 
        WHEN o.order_status = 'delivered' 
         AND o.order_delivered_customer_date IS NOT NULL
        THEN CASE 
                 WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 
                 ELSE 0 
             END 
    END AS is_late, -- gắn cờ giao trễ 
    lr.review_score
FROM olist_orders o -- lấy bảng này làm gốc
JOIN olist_customers c USING (customer_id) -- lấy thông tin bang và mã khách hàng thật
LEFT JOIN order_rev r USING (order_id) -- ghép doanh thu vào đơn giữ lại cả rỗng
LEFT JOIN latest_review lr ON lr.order_id = o.order_id AND lr.rn = 1; --chỉ ghép dòng review mới nhất và giữ lại cả đơn chưa đánh giá

-- View 2: Cấp dòng sản phẩm (đã chuẩn hóa tên danh mục tiếng Anh)
CREATE OR REPLACE VIEW v_item_fact AS
SELECT 
    i.order_id,
    i.price,
    COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category, -- chuẩn hoá tên tiếng anh,nếu không có lấy tiếng BĐN, nếu không có cả 2 thì gán unkown
    c.customer_state,
    o.order_status,
    o.order_purchase_timestamp::date AS purchase_date
FROM olist_order_items i --lấy bảng chi tiết từng món hàng làm gốc
JOIN olist_orders o USING (order_id)
JOIN olist_customers c USING (customer_id)
LEFT JOIN olist_products p USING (product_id)
LEFT JOIN product_category_name_translation t
       ON t.product_category_name = p.product_category_name;