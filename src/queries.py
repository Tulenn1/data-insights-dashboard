from datetime import date

import pandas as pd
from sqlalchemy import text
from sqlalchemy.orm import Session


def get_revenue(session: Session, start_date: date, end_date: date) -> pd.DataFrame:
    query = text("""
        SELECT COALESCE(SUM(total), 0) AS revenue
        FROM orders
        WHERE status = 'completed'
          AND order_date BETWEEN :start_date AND :end_date
    """)
    return pd.read_sql(query, session.connection(), params={"start_date": start_date, "end_date": end_date})


def get_order_count(session: Session, start_date: date, end_date: date) -> pd.DataFrame:
    query = text("""
        SELECT COUNT(*) AS total_orders
        FROM orders
        WHERE status = 'completed'
          AND order_date BETWEEN :start_date AND :end_date
    """)
    return pd.read_sql(query, session.connection(), params={"start_date": start_date, "end_date": end_date})


def get_avg_ticket(session: Session, start_date: date, end_date: date) -> pd.DataFrame:
    query = text("""
        SELECT COALESCE(AVG(total), 0) AS avg_ticket
        FROM orders
        WHERE status = 'completed'
          AND order_date BETWEEN :start_date AND :end_date
    """)
    return pd.read_sql(query, session.connection(), params={"start_date": start_date, "end_date": end_date})


def get_active_customers(session: Session, start_date: date, end_date: date) -> pd.DataFrame:
    query = text("""
        SELECT COUNT(DISTINCT customer_id) AS active_customers
        FROM orders
        WHERE status = 'completed'
          AND order_date BETWEEN :start_date AND :end_date
    """)
    return pd.read_sql(query, session.connection(), params={"start_date": start_date, "end_date": end_date})


def get_monthly_revenue(session: Session, start_date: date, end_date: date) -> pd.DataFrame:
    query = text("""
        SELECT
            DATE_TRUNC('month', order_date)::DATE AS month,
            SUM(total) AS revenue,
            COUNT(*) AS orders
        FROM orders
        WHERE status = 'completed'
          AND order_date BETWEEN :start_date AND :end_date
        GROUP BY month
        ORDER BY month
    """)
    return pd.read_sql(query, session.connection(), params={"start_date": start_date, "end_date": end_date})


def get_top_products(
    session: Session, start_date: date, end_date: date, limit: int = 5
) -> pd.DataFrame:
    query = text("""
        SELECT
            p.name AS product,
            c.name AS category,
            SUM(oi.quantity) AS units_sold,
            SUM(oi.quantity * oi.unit_price) AS revenue
        FROM order_items oi
        JOIN products p ON p.id = oi.product_id
        JOIN categories c ON c.id = p.category_id
        JOIN orders o ON o.id = oi.order_id
        WHERE o.status = 'completed'
          AND o.order_date BETWEEN :start_date AND :end_date
        GROUP BY p.id, p.name, c.name
        ORDER BY revenue DESC
        LIMIT :limit
    """)
    return pd.read_sql(
        query,
        session.connection(),
        params={"start_date": start_date, "end_date": end_date, "limit": limit},
    )


def get_product_profitability(session: Session) -> pd.DataFrame:
    query = text("""
        SELECT
            p.id,
            p.name AS product,
            c.name AS category,
            p.price,
            p.cost,
            (p.price - p.cost) AS margin,
            ROUND(((p.price - p.cost) / NULLIF(p.cost, 0)) * 100, 2) AS margin_pct
        FROM products p
        JOIN categories c ON c.id = p.category_id
        ORDER BY margin DESC
    """)
    return pd.read_sql(query, session.connection())


def get_revenue_by_category(session: Session, start_date: date, end_date: date) -> pd.DataFrame:
    query = text("""
        SELECT
            c.name AS category,
            SUM(oi.quantity * oi.unit_price) AS revenue,
            COUNT(DISTINCT o.id) AS orders
        FROM order_items oi
        JOIN products p ON p.id = oi.product_id
        JOIN categories c ON c.id = p.category_id
        JOIN orders o ON o.id = oi.order_id
        WHERE o.status = 'completed'
          AND o.order_date BETWEEN :start_date AND :end_date
        GROUP BY c.id, c.name
        ORDER BY revenue DESC
    """)
    return pd.read_sql(query, session.connection(), params={"start_date": start_date, "end_date": end_date})


def get_top_margin_products(session: Session, limit: int = 10) -> pd.DataFrame:
    query = text("""
        SELECT
            p.name AS product,
            c.name AS category,
            (p.price - p.cost) AS margin,
            ROUND(((p.price - p.cost) / NULLIF(p.cost, 0)) * 100, 2) AS margin_pct
        FROM products p
        JOIN categories c ON c.id = p.category_id
        WHERE p.cost IS NOT NULL
        ORDER BY margin DESC
        LIMIT :limit
    """)
    return pd.read_sql(query, session.connection(), params={"limit": limit})


def get_product_summary(session: Session) -> pd.DataFrame:
    query = text("""
        SELECT
            COUNT(*) AS total_products,
            ROUND(AVG(price), 2) AS avg_price,
            ROUND(AVG(COALESCE(cost, 0)), 2) AS avg_cost
        FROM products
    """)
    return pd.read_sql(query, session.connection())


def get_most_profitable_product(session: Session) -> pd.DataFrame:
    query = text("""
        SELECT
            p.name AS product,
            c.name AS category,
            (p.price - p.cost) AS margin
        FROM products p
        JOIN categories c ON c.id = p.category_id
        WHERE p.cost IS NOT NULL
        ORDER BY margin DESC
        LIMIT 1
    """)
    return pd.read_sql(query, session.connection())


def get_top_customers(session: Session, start_date: date, end_date: date) -> pd.DataFrame:
    query = text("""
        SELECT
            c.name AS customer,
            c.email,
            c.region,
            COUNT(o.id) AS orders,
            COALESCE(SUM(o.total), 0) AS total_spent
        FROM customers c
        LEFT JOIN orders o ON o.customer_id = c.id
            AND o.status = 'completed'
            AND o.order_date BETWEEN :start_date AND :end_date
        GROUP BY c.id, c.name, c.email, c.region
        ORDER BY total_spent DESC
    """)
    return pd.read_sql(query, session.connection(), params={"start_date": start_date, "end_date": end_date})


def get_revenue_by_region(session: Session, start_date: date, end_date: date) -> pd.DataFrame:
    query = text("""
        SELECT
            c.region,
            COUNT(DISTINCT c.id) AS customers,
            COALESCE(SUM(o.total), 0) AS revenue,
            COUNT(o.id) AS orders
        FROM customers c
        LEFT JOIN orders o ON o.customer_id = c.id
            AND o.status = 'completed'
            AND o.order_date BETWEEN :start_date AND :end_date
        GROUP BY c.region
        ORDER BY revenue DESC
    """)
    return pd.read_sql(query, session.connection(), params={"start_date": start_date, "end_date": end_date})


def get_new_customers_by_month(session: Session) -> pd.DataFrame:
    query = text("""
        SELECT
            DATE_TRUNC('month', created_at)::DATE AS month,
            COUNT(*) AS new_customers
        FROM customers
        GROUP BY month
        ORDER BY month
    """)
    return pd.read_sql(query, session.connection())


def get_customer_count(session: Session) -> pd.DataFrame:
    query = text("SELECT COUNT(*) AS total FROM customers")
    return pd.read_sql(query, session.connection())
