import pandas as pd
import plotly.express as px
import plotly.graph_objects as go


def revenue_line_chart(df: pd.DataFrame) -> go.Figure:
    if df.empty:
        fig = go.Figure()
        fig.add_annotation(
            text="No hay datos para el período seleccionado", showarrow=False
        )
        return fig

    fig = px.line(
        df,
        x="month",
        y="revenue",
        title="Revenue por Mes",
        markers=True,
        labels={"month": "Mes", "revenue": "Revenue ($)"},
    )
    fig.update_layout(
        hovermode="x unified",
        xaxis_title="Mes",
        yaxis_title="Revenue ($)",
    )
    return fig


def revenue_by_category_bar(df: pd.DataFrame) -> go.Figure:
    if df.empty:
        fig = go.Figure()
        fig.add_annotation(
            text="No hay datos para el período seleccionado", showarrow=False
        )
        return fig

    fig = px.bar(
        df,
        x="category",
        y="revenue",
        title="Revenue por Categoría",
        labels={"category": "Categoría", "revenue": "Revenue ($)"},
        color="category",
        text_auto="$.2s",
    )
    fig.update_layout(showlegend=False, hovermode="x unified")
    return fig


def top_margin_barh(df: pd.DataFrame) -> go.Figure:
    if df.empty:
        fig = go.Figure()
        fig.add_annotation(text="No hay datos disponibles", showarrow=False)
        return fig

    fig = px.bar(
        df,
        x="margin",
        y="product",
        title="Top 10 Productos por Margen",
        labels={"margin": "Margen ($)", "product": ""},
        color="margin",
        color_continuous_scale="blues",
        orientation="h",
        text_auto="$.2f",
    )
    fig.update_layout(yaxis={"categoryorder": "total ascending"})
    return fig


def revenue_by_region_bar(df: pd.DataFrame) -> go.Figure:
    if df.empty:
        fig = go.Figure()
        fig.add_annotation(
            text="No hay datos para el período seleccionado", showarrow=False
        )
        return fig

    fig = px.bar(
        df,
        x="region",
        y="revenue",
        title="Revenue por Región",
        labels={"region": "Región", "revenue": "Revenue ($)"},
        color="region",
        text_auto="$.2s",
    )
    fig.update_layout(showlegend=False, hovermode="x unified")
    return fig


def new_customers_line(df: pd.DataFrame) -> go.Figure:
    if df.empty:
        fig = go.Figure()
        fig.add_annotation(text="No hay datos disponibles", showarrow=False)
        return fig

    fig = px.line(
        df,
        x="month",
        y="new_customers",
        title="Clientes Nuevos por Mes",
        markers=True,
        labels={"month": "Mes", "new_customers": "Nuevos Clientes"},
    )
    fig.update_layout(hovermode="x unified")
    return fig
