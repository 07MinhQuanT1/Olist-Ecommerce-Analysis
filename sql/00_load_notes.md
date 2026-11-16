# Nhật ký nạp dữ liệu (Bước 1)

## 1. Phương thức nạp
- **Công cụ:** Script Python `scripts/load_data.py` sử dụng `pandas.read_csv()` và `SQLAlchemy` (`to_sql` với `if_exists="replace"`, `index=False`).
- **Bảo mật kết nối:** Chuỗi kết nối PostgreSQL (`DATABASE_URL`) được nạp qua biến môi trường từ file `.env` (không lưu trong mã nguồn).

## 2. Chuẩn hóa kiểu dữ liệu & Tối ưu truy vấn
- **Ép kiểu ngày giờ (`parse_dates` -> `timestamp without time zone`):**
  - `olist_orders`: `order_purchase_timestamp`, `order_approved_at`, `order_delivered_carrier_date`, `order_delivered_customer_date`, `order_estimated_delivery_date`
  - `olist_order_items`: `shipping_limit_date`
  - `olist_order_reviews`: `review_creation_date`, `review_answer_timestamp`
- **Chỉ mục (Index) đã tạo để tối ưu JOIN:**
  - `idx_items_order` trên `olist_order_items(order_id)`
  - `idx_pay_order` trên `olist_order_payments(order_id)`
  - `idx_rev_order` trên `olist_order_reviews(order_id)`
  - `idx_orders_cust` trên `olist_orders(customer_id)`

## 3. Quy mô dữ liệu thực tế sau khi nạp
| File CSV gốc | Tên bảng PostgreSQL | Số dòng thực tế |
| :--- | :--- | ---: |
| `olist_customers_dataset.csv` | `olist_customers` | 99,441 |
| `olist_geolocation_dataset.csv` | `olist_geolocation` | 1,000,163 |
| `olist_order_items_dataset.csv` | `olist_order_items` | 112,650 |
| `olist_order_payments_dataset.csv` | `olist_order_payments` | 103,886 |
| `olist_order_reviews_dataset.csv` | `olist_order_reviews` | 99,224 |
| `olist_orders_dataset.csv` | `olist_orders` | 99,441 |
| `olist_products_dataset.csv` | `olist_products` | 32,951 |
| `olist_sellers_dataset.csv` | `olist_sellers` | 3,095 |
| `product_category_name_translation.csv` | `product_category_name_translation` | 71 |