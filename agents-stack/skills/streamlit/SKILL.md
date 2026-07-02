---
name: streamlit-patterns
description: Streamlit conventions for data dashboards with SQLAlchemy, pandas, Plotly, and openpyxl. Active when streamlit is detected.
license: MIT
compatibility: both
metadata:
  audience: implementers
  type: skill
---

## What I Do

Provide Streamlit-specific coding conventions for the implementer subagent.
Loads on top of `python-patterns` (you must also follow those conventions).
Active when the implementer detects `streamlit` in project dependencies.

---

## Project Structure

```
  src/
    config.py                # Streamlit secrets / env vars / DB config
    database.py              # SQLAlchemy engine + session factory (sync)
    queries.py               # Raw SQL or SQLAlchemy query functions
    services.py              # Business logic layer (caches, transforms)
    charts.py                # Plotly chart factories
    export_excel.py          # openpyxl export helpers
  app.py                     # Main Streamlit entrypoint
  assets/                    # Static files (images, logos, custom CSS)
  exports/                   # Generated Excel exports
  tests/
    test_queries.py
    test_services.py
    test_charts.py
```

## Streamlit Conventions

### App Structure

- **Single entrypoint** `app.py` at project root with multi-page via `st.navigation` or `st.Page`
- **Pages** in `pages/` directory (one file per view)
- **Session state** managed via `st.session_state` with getter/setter helpers
- **No business logic** in `app.py` — delegate to `src/services.py`

### Code Patterns

```python
# config.py — load settings from Streamlit secrets or .env
import os
from dataclasses import dataclass, field

@dataclass
class Settings:
    db_url: str = field(default_factory=lambda: os.getenv("DATABASE_URL", ""))
    db_pool_size: int = int(os.getenv("DB_POOL_SIZE", "5"))

settings = Settings()
```

```python
# database.py — SQLAlchemy engine (sync)
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from src.config import settings

engine = create_engine(
    settings.db_url,
    pool_size=settings.db_pool_size,
    pool_pre_ping=True,
)

def get_session() -> Session:
    return Session(engine)
```

```python
# queries.py — query functions return DataFrames or typed lists
import pandas as pd
from sqlalchemy import text
from sqlalchemy.orm import Session

def get_sales_summary(session: Session, year: int) -> pd.DataFrame:
    query = text("""
        SELECT
            DATE_TRUNC('month', order_date) AS month,
            SUM(total) AS revenue,
            COUNT(*) AS orders
        FROM orders
        WHERE EXTRACT(YEAR FROM order_date) = :year
        GROUP BY month
        ORDER BY month
    """)
    return pd.read_sql(query, session.connection(), params={"year": year})
```

```python
# services.py — cached business logic
import pandas as pd
from streamlit.runtime.caching import cache_data
from src.database import get_session
from src.queries import get_sales_summary

@cache_data(ttl=300)
def cached_sales_summary(year: int) -> pd.DataFrame:
    with get_session() as session:
        return get_sales_summary(session, year)
```

### State Management

```python
# Session state helpers
def init_state():
    if "filters" not in st.session_state:
        st.session_state.filters = {}
    if "selected_year" not in st.session_state:
        st.session_state.selected_year = 2024

def get_filters():
    return st.session_state.get("filters", {})

def set_filter(key: str, value):
    st.session_state.filters[key] = value
```

### Caching Strategy

| Decorator | Use case | TTL |
|-----------|----------|-----|
| `@st.cache_data` | DataFrames, API responses, query results | 5-60 min |
| `@st.cache_resource` | DB engine, ML models, expensive objects | app lifetime |

### Charts (Plotly)

```python
# charts.py
import plotly.express as px
import plotly.graph_objects as go
import pandas as pd

def revenue_line_chart(df: pd.DataFrame) -> go.Figure:
    fig = px.line(
        df, x="month", y="revenue",
        title="Revenue Over Time",
        markers=True,
    )
    fig.update_layout(
        xaxis_title="Month",
        yaxis_title="Revenue ($)",
        hovermode="x unified",
    )
    return fig
```

### Excel Export (openpyxl)

```python
# export_excel.py
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill
from openpyxl.utils.dataframe import dataframe_to_rows
import pandas as pd
from pathlib import Path

EXPORT_DIR = Path("exports")
EXPORT_DIR.mkdir(exist_ok=True)

def export_to_excel(df: pd.DataFrame, filename: str) -> Path:
    wb = Workbook()
    ws = wb.active

    # Header styling
    header_font = Font(bold=True, color="FFFFFF")
    header_fill = PatternFill(start_color="4472C4", end_color="4472C4", fill_type="solid")

    for r_idx, row in enumerate(dataframe_to_rows(df, index=False, header=True)):
        ws.append(row)
        if r_idx == 0:
            for cell in ws[1]:
                cell.font = header_font
                cell.fill = header_fill

    filepath = EXPORT_DIR / filename
    wb.save(filepath)
    return filepath
```

### Dockerfile

```dockerfile
FROM python:3.13-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8501
HEALTHCHECK CMD curl --fail http://localhost:8501/_stcore/health
CMD ["streamlit", "run", "app.py", "--server.port=8501", "--server.address=0.0.0.0"]
```

### Layout & UX

- Use `st.set_page_config(layout="wide")` for dashboards
- Sidebar for filters with `st.sidebar.*`
- Use `st.columns()` for dashboard grid layout
- Use `st.metric()` for KPI cards
- Use `st.expander()` for collapsible detail sections
- Avoid long page loads — use `@st.cache_data` aggressively
- Add a `st.spinner()` wrapper for long-running queries

```
## Anti-patterns

- Calling external APIs or running heavy computations on every rerun (always cache)
- Storing secrets in `app.py` (use `st.secrets` or `.env`)
- Mixing presentation and business logic in the same function
- Using `st.set_page_config()` in pages (must be first call in `app.py`)
- Loading large datasets without pagination or aggregation
