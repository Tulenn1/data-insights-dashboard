from datetime import date

import pandas as pd
from sqlalchemy.exc import OperationalError
from streamlit.runtime.caching import cache_data

from src.database import get_session
from src.logger import get_logger

logger = get_logger(__name__)
from src.queries import (
    get_active_customers,
    get_avg_ticket,
    get_customer_count,
    get_monthly_revenue,
    get_new_customers_by_month,
    get_order_count,
    get_product_profitability,
    get_product_summary,
    get_most_profitable_product,
    get_revenue,
    get_revenue_by_category,
    get_revenue_by_region,
    get_top_customers,
    get_top_margin_products,
    get_top_products,
)


def _safe_query(query_fn, *args, **kwargs) -> pd.DataFrame:
    try:
        with get_session() as session:
            return query_fn(session, *args, **kwargs)
    except OperationalError as e:
        logger.error("Database query failed: %s", e)
        return pd.DataFrame()


@cache_data(ttl=300)
def cached_revenue(start_date: date, end_date: date) -> pd.DataFrame:
    return _safe_query(get_revenue, start_date, end_date)


@cache_data(ttl=300)
def cached_order_count(start_date: date, end_date: date) -> pd.DataFrame:
    return _safe_query(get_order_count, start_date, end_date)


@cache_data(ttl=300)
def cached_avg_ticket(start_date: date, end_date: date) -> pd.DataFrame:
    return _safe_query(get_avg_ticket, start_date, end_date)


@cache_data(ttl=300)
def cached_active_customers(start_date: date, end_date: date) -> pd.DataFrame:
    return _safe_query(get_active_customers, start_date, end_date)


@cache_data(ttl=300)
def cached_monthly_revenue(start_date: date, end_date: date) -> pd.DataFrame:
    return _safe_query(get_monthly_revenue, start_date, end_date)


@cache_data(ttl=300)
def cached_top_products(start_date: date, end_date: date) -> pd.DataFrame:
    return _safe_query(get_top_products, start_date, end_date, limit=5)


@cache_data(ttl=300)
def cached_product_profitability() -> pd.DataFrame:
    return _safe_query(get_product_profitability)


@cache_data(ttl=300)
def cached_revenue_by_category(start_date: date, end_date: date) -> pd.DataFrame:
    return _safe_query(get_revenue_by_category, start_date, end_date)


@cache_data(ttl=300)
def cached_top_margin_products() -> pd.DataFrame:
    return _safe_query(get_top_margin_products, limit=10)


@cache_data(ttl=300)
def cached_product_summary() -> pd.DataFrame:
    return _safe_query(get_product_summary)


@cache_data(ttl=300)
def cached_most_profitable_product() -> pd.DataFrame:
    return _safe_query(get_most_profitable_product)


@cache_data(ttl=300)
def cached_top_customers(start_date: date, end_date: date) -> pd.DataFrame:
    return _safe_query(get_top_customers, start_date, end_date)


@cache_data(ttl=300)
def cached_revenue_by_region(start_date: date, end_date: date) -> pd.DataFrame:
    return _safe_query(get_revenue_by_region, start_date, end_date)


@cache_data(ttl=300)
def cached_new_customers_by_month() -> pd.DataFrame:
    return _safe_query(get_new_customers_by_month)


@cache_data(ttl=300)
def cached_customer_count() -> pd.DataFrame:
    return _safe_query(get_customer_count)
