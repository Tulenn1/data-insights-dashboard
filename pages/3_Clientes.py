from datetime import date

import streamlit as st
from src.charts import new_customers_line, revenue_by_region_bar
from src.services import (
    cached_customer_count,
    cached_new_customers_by_month,
    cached_revenue_by_region,
    cached_top_customers,
)

st.set_page_config(layout="wide", page_title="Panel de Clientes")
st.title("👥 Panel de Clientes")

today = date.today()

regions = ["Todas", "Norte", "Sur", "Centro"]

with st.sidebar:
    st.header("Filtros")
    selected_region = st.selectbox("Región", options=regions)
    start_date = st.date_input("Desde", value=date(2024, 1, 1))
    end_date = st.date_input("Hasta", value=today)

    if start_date > end_date:
        st.warning("La fecha 'Desde' debe ser anterior a 'Hasta'")
        st.stop()

start_date = date(start_date.year, start_date.month, start_date.day)
end_date = date(end_date.year, end_date.month, end_date.day)

customer_count_df = cached_customer_count()
total_customers = int(customer_count_df["total"].iloc[0]) if not customer_count_df.empty else 0

top_customers_df = cached_top_customers(start_date, end_date)
top_customer = top_customers_df.iloc[0] if not top_customers_df.empty else None

filtered = top_customers_df
if selected_region != "Todas":
    filtered = filtered[filtered["region"] == selected_region]

total_revenue = filtered["total_spent"].sum() if not filtered.empty else 0
total_orders = int(filtered["orders"].sum()) if not filtered.empty else 0

kpi_cols = st.columns(4)
with kpi_cols[0]:
    st.metric("👥 Total Clientes", f"{total_customers}")
with kpi_cols[1]:
    st.metric("💰 Revenue Total", f"${total_revenue:,.2f}")
with kpi_cols[2]:
    st.metric("📦 Órdenes Totales", f"{total_orders}")
with kpi_cols[3]:
    name = top_customer["customer"] if top_customer is not None else "N/A"
    spent = top_customer["total_spent"] if top_customer is not None else 0
    st.metric("🏆 Cliente Top", name, f"${spent:,.2f}")

rev_region_df = cached_revenue_by_region(start_date, end_date)
fig1 = revenue_by_region_bar(rev_region_df)
st.plotly_chart(fig1, use_container_width=True)

new_cust_df = cached_new_customers_by_month()
fig2 = new_customers_line(new_cust_df)
st.plotly_chart(fig2, use_container_width=True)

st.subheader("📋 Top Clientes")

if not filtered.empty:
    display = filtered[["customer", "email", "region", "orders", "total_spent"]].copy()
    display["total_spent"] = display["total_spent"].apply(lambda x: f"${x:,.2f}")
    display.columns = ["Cliente", "Email", "Región", "Órdenes", "Total Gastado"]
    st.dataframe(display, use_container_width=True, hide_index=True)
else:
    st.info("⚠️ No hay datos para el período seleccionado", icon="ℹ️")
