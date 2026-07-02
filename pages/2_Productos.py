from datetime import date

import pandas as pd
import streamlit as st

from src.charts import revenue_by_category_bar, top_margin_barh
from src.services import (
    cached_most_profitable_product,
    cached_product_profitability,
    cached_product_summary,
    cached_revenue_by_category,
    cached_top_margin_products,
)

st.set_page_config(layout="wide", page_title="Panel de Productos")
st.title("📦 Panel de Productos")

today = date.today()

categories = ["Todas", "Electrónica", "Ropa", "Hogar", "Deportes"]

with st.sidebar:
    st.header("Filtros")
    selected_category = st.selectbox("Categoría", options=categories)
    start_date = st.date_input("Desde", value=date(2024, 1, 1))
    end_date = st.date_input("Hasta", value=today)

    if start_date > end_date:
        st.warning("La fecha 'Desde' debe ser anterior a 'Hasta'")
        st.stop()

start_date = date(start_date.year, start_date.month, start_date.day)
end_date = date(end_date.year, end_date.month, end_date.day)

summary_df = cached_product_summary()
profit_df = cached_product_profitability()
top_margin_df = cached_top_margin_products()
most_profitable = cached_most_profitable_product()

total_products = (
    int(summary_df["total_products"].iloc[0]) if not summary_df.empty else 0
)
avg_price = summary_df["avg_price"].iloc[0] if not summary_df.empty else 0
top_product_name = (
    most_profitable["product"].iloc[0] if not most_profitable.empty else "N/A"
)
top_margin_val = most_profitable["margin"].iloc[0] if not most_profitable.empty else 0

if selected_category != "Todas":
    profit_df = profit_df[profit_df["category"] == selected_category]

kpi_cols = st.columns(4)
with kpi_cols[0]:
    st.metric("📦 Total Productos", f"{total_products}")
with kpi_cols[1]:
    st.metric("💰 Precio Promedio", f"${avg_price:,.2f}")
with kpi_cols[2]:
    avg_margin = profit_df["margin"].mean() if not profit_df.empty else 0
    st.metric("📈 Margen Promedio", f"${avg_margin:,.2f}")
with kpi_cols[3]:
    st.metric("🏆 Más Rentable", top_product_name, f"${top_margin_val:,.2f}")

rev_cat_df = cached_revenue_by_category(start_date, end_date)
fig1 = revenue_by_category_bar(rev_cat_df)
st.plotly_chart(fig1, use_container_width=True)

fig2 = top_margin_barh(top_margin_df)
st.plotly_chart(fig2, use_container_width=True)

st.subheader("📋 Rentabilidad por Producto")

if not profit_df.empty:
    display = profit_df[
        ["product", "category", "price", "cost", "margin", "margin_pct"]
    ].copy()
    display["price"] = display["price"].apply(lambda x: f"${x:,.2f}")
    display["cost"] = display["cost"].apply(
        lambda x: f"${x:,.2f}" if pd.notna(x) else "N/A"
    )
    display["margin"] = display["margin"].apply(lambda x: f"${x:,.2f}")
    display["margin_pct"] = display["margin_pct"].apply(lambda x: f"{x}%")
    display.columns = [
        "Producto",
        "Categoría",
        "Precio",
        "Costo",
        "Margen ($)",
        "Margen (%)",
    ]
    st.dataframe(display, use_container_width=True, hide_index=True)
else:
    st.info("⚠️ No hay datos de productos disponibles", icon="ℹ️")
