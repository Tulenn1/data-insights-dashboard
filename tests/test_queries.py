from datetime import date

import pytest
from sqlalchemy import create_engine, event, text
from sqlalchemy.orm import Session

from src.queries import (
    get_active_customers,
    get_avg_ticket,
    get_monthly_revenue,
    get_order_count,
    get_revenue,
    get_top_products,
)


@pytest.fixture
def session():
    engine = create_engine("sqlite://", echo=False)

    @event.listens_for(engine, "connect")
    def _set_sqlite_pragma(dbapi_connection, connection_record):
        cursor = dbapi_connection.cursor()
        cursor.execute("PRAGMA foreign_keys=ON")
        cursor.close()

    conn = engine.connect()
    for stmt in [
        "CREATE TABLE categories (id INTEGER PRIMARY KEY, name TEXT)",
        "CREATE TABLE products (id INTEGER PRIMARY KEY, name TEXT, category_id INTEGER, price REAL, cost REAL)",
        "CREATE TABLE customers (id INTEGER PRIMARY KEY, name TEXT, email TEXT, region TEXT)",
        "CREATE TABLE orders (id INTEGER PRIMARY KEY, customer_id INTEGER, order_date TEXT, total REAL, status TEXT)",
        "CREATE TABLE order_items (id INTEGER PRIMARY KEY, order_id INTEGER, product_id INTEGER, quantity INTEGER, unit_price REAL)",
    ]:
        conn.execute(text(stmt))

    for stmt in [
        "INSERT INTO categories VALUES (1, 'Electrónica'), (2, 'Ropa')",
        "INSERT INTO products VALUES (1, 'Laptop', 1, 1500, 1100), (2, 'Mouse', 1, 45, 25), (3, 'Camiseta', 2, 35, 15)",
        "INSERT INTO customers VALUES (1, 'Juan', 'juan@e.com', 'Norte'), (2, 'Ana', 'ana@e.com', 'Sur')",
        "INSERT INTO orders VALUES (1, 1, '2024-01-15', 1500, 'completed'), (2, 1, '2024-02-10', 45, 'completed'), (3, 2, '2024-03-05', 35, 'completed')",
        "INSERT INTO order_items VALUES (1, 1, 1, 1, 1500), (2, 2, 2, 1, 45), (3, 3, 3, 1, 35)",
    ]:
        conn.execute(text(stmt))

    conn.commit()
    yield Session(bind=conn)
    conn.close()


SD = date(2024, 1, 1)
ED = date(2024, 12, 31)


class TestQueries:
    def test_get_revenue(self, session):
        df = get_revenue(session, SD, ED)
        assert df["revenue"].iloc[0] == 1580.0

    def test_get_revenue_empty_range(self, session):
        df = get_revenue(session, date(2025, 1, 1), date(2025, 12, 31))
        assert df["revenue"].iloc[0] == 0

    def test_get_order_count(self, session):
        df = get_order_count(session, SD, ED)
        assert df["total_orders"].iloc[0] == 3

    def test_get_avg_ticket(self, session):
        df = get_avg_ticket(session, SD, ED)
        assert round(df["avg_ticket"].iloc[0], 2) == 526.67

    def test_get_active_customers(self, session):
        df = get_active_customers(session, SD, ED)
        assert df["active_customers"].iloc[0] == 2

    def test_get_monthly_revenue(self, session):
        df = get_monthly_revenue(session, SD, ED)
        assert len(df) == 3
        assert df["revenue"].sum() == 1580.0

    def test_get_top_products(self, session):
        df = get_top_products(session, SD, ED, limit=2)
        assert len(df) == 2
        assert df["product"].iloc[0] == "Laptop"
