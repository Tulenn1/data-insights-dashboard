import pandas as pd
import plotly.graph_objects as go

from src.charts import revenue_line_chart, revenue_by_category_bar, top_margin_barh


class TestCharts:
    def test_revenue_line_chart_returns_figure(self):
        df = pd.DataFrame(
            {
                "month": ["2024-01-01", "2024-02-01"],
                "revenue": [100, 200],
                "orders": [1, 2],
            }
        )
        fig = revenue_line_chart(df)
        assert isinstance(fig, go.Figure)
        assert fig.layout.title.text == "Revenue por Mes"

    def test_revenue_line_chart_empty(self):
        fig = revenue_line_chart(pd.DataFrame())
        assert isinstance(fig, go.Figure)

    def test_revenue_by_category_bar(self):
        df = pd.DataFrame(
            {"category": ["A", "B"], "revenue": [100, 200], "orders": [1, 2]}
        )
        fig = revenue_by_category_bar(df)
        assert isinstance(fig, go.Figure)

    def test_revenue_by_category_bar_empty(self):
        fig = revenue_by_category_bar(pd.DataFrame())
        assert isinstance(fig, go.Figure)

    def test_top_margin_barh(self):
        df = pd.DataFrame(
            {"product": ["P1", "P2"], "margin": [50, 30], "margin_pct": [25.0, 15.0]}
        )
        fig = top_margin_barh(df)
        assert isinstance(fig, go.Figure)
