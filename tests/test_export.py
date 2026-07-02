import pandas as pd

from src.export_excel import export_to_excel


class TestExport:
    def test_export_to_excel_returns_bytes(self):
        top = pd.DataFrame(
            {"product": ["A"], "category": ["X"], "units_sold": [10], "revenue": [500]}
        )
        result = export_to_excel(1000, 5, 200, 3, top)
        assert isinstance(result, bytes)
        assert len(result) > 0
