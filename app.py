from datetime import date

import streamlit as st

from src.charts import revenue_line_chart
from src.export_excel import export_to_excel
from src.services import (
    cached_active_customers,
    cached_avg_ticket,
    cached_monthly_revenue,
    cached_order_count,
    cached_revenue,
    cached_top_products,
)

st.set_page_config(layout="wide", page_title="Dashboard de Ventas")
st.title("🏠 Dashboard de Ventas")

today = date.today()
default_start = date(2024, 1, 1)

with st.sidebar:
    st.header("Filtros")
    selected_year = st.selectbox("Año", options=[2024, 2025, 2026], index=0)
    start_date = st.date_input("Desde", value=default_start)
    end_date = st.date_input("Hasta", value=today)

    if start_date > end_date:
        st.warning("La fecha 'Desde' debe ser anterior a 'Hasta'")
        st.stop()

start_date = date(start_date.year, start_date.month, start_date.day)
end_date = date(end_date.year, end_date.month, end_date.day)

revenue_df = cached_revenue(start_date, end_date)
orders_df = cached_order_count(start_date, end_date)
ticket_df = cached_avg_ticket(start_date, end_date)
customers_df = cached_active_customers(start_date, end_date)

revenue_val = revenue_df["revenue"].iloc[0] if not revenue_df.empty else 0
orders_val = int(orders_df["total_orders"].iloc[0]) if not orders_df.empty else 0
ticket_val = ticket_df["avg_ticket"].iloc[0] if not ticket_df.empty else 0
customers_val = (
    int(customers_df["active_customers"].iloc[0]) if not customers_df.empty else 0
)

kpi_cols = st.columns(4)
with kpi_cols[0]:
    st.metric("💰 Revenue Total", f"${revenue_val:,.2f}")
with kpi_cols[1]:
    st.metric("📦 Órdenes", f"{orders_val:,}")
with kpi_cols[2]:
    st.metric("🎫 Ticket Promedio", f"${ticket_val:,.2f}")
with kpi_cols[3]:
    st.metric("👥 Clientes Activos", f"{customers_val:,}")

monthly_df = cached_monthly_revenue(start_date, end_date)
fig = revenue_line_chart(monthly_df)
st.plotly_chart(fig, use_container_width=True)

top_df = cached_top_products(start_date, end_date)
if not top_df.empty:
    st.subheader("🏆 Top 5 Productos")
    top_df["revenue"] = top_df["revenue"].apply(lambda x: f"${x:,.2f}")
    st.dataframe(top_df, use_container_width=True, hide_index=True)
else:
    st.info("⚠️ No hay datos para el período seleccionado", icon="ℹ️")

excel_bytes = export_to_excel(
    revenue_val,
    orders_val,
    ticket_val,
    customers_val,
    top_df if not top_df.empty else None,
)
st.download_button(
    label="📥 Exportar a Excel",
    data=excel_bytes,
    file_name=f"ventas_{selected_year}_{today.isoformat()}.xlsx",
    mime="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
)
