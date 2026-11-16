import os, glob
import pandas as pd
from sqlalchemy import create_engine
from dotenv import load_dotenv

load_dotenv()
engine = create_engine(os.environ["DATABASE_URL"])

date_cols = {
    "olist_orders": [
        "order_purchase_timestamp", "order_approved_at",
        "order_delivered_carrier_date", "order_delivered_customer_date",
        "order_estimated_delivery_date",
    ],
    "olist_order_items": ["shipping_limit_date"],
    "olist_order_reviews": ["review_creation_date", "review_answer_timestamp"],
}

for path in sorted(glob.glob("data/raw/*.csv")):
    name = os.path.basename(path).replace("_dataset.csv", "").replace(".csv", "")
    df = pd.read_csv(path, parse_dates=date_cols.get(name, []))
    df.to_sql(name, engine, if_exists="replace", index=False)
    print(f"{name}: {len(df):,} rows")