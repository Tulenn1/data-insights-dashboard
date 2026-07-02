# data-insights-dashboard

Dashboard de análisis de negocio con PostgreSQL, Streamlit, y visualizaciones interactivas.

## Stack

- **Python 3.13** + **Streamlit** — UI web interactiva
- **PostgreSQL 16** — Base de datos relacional
- **SQLAlchemy 2.0** + **psycopg2** — Acceso a datos
- **pandas** — Transformaciones y análisis
- **Plotly** — Gráficos interactivos
- **openpyxl** — Exportación a Excel
- **Docker** — Contenedores

## Estructura

```
data-insights-dashboard/
├── app.py                  # Dashboard de Ventas
├── pages/
│   ├── 2_Productos.py      # Panel de Productos
│   └── 3_Clientes.py       # Panel de Clientes
├── src/
│   ├── database.py         # Engine + sesión SQLAlchemy
│   ├── queries.py          # Consultas SQL parametrizadas
│   ├── services.py         # Lógica de negocio con cache
│   ├── charts.py           # Fábricas de gráficos Plotly
│   ├── export_excel.py     # Exportación openpyxl
│   └── logger.py           # Logger estructurado
├── database/
│   ├── schema.sql          # DDL inicial
│   └── seed.sql            # Datos de ejemplo
├── alembic/                # Migraciones
├── tests/                  # Tests unitarios (pytest)
├── agents-stack/           # Pipeline de subagentes
└── docker-compose.yml      # PostgreSQL + app
```

## Inicio rápido

```bash
git clone https://github.com/tu-usuario/data-insights-dashboard.git
cd data-insights-dashboard

# Opción 1: Docker Compose
docker compose up -d
# Abrir http://localhost:8501

# Opción 2: Local
cp .env.example .env
pip install -r requirements.txt
docker compose up -d db
streamlit run app.py
```

## Comandos

| Comando | Descripción |
|---------|-------------|
| `streamlit run app.py` | Iniciar dashboard |
| `pytest tests/ -v` | Ejecutar tests |
| `ruff check . && ruff format --check .` | Lint + formato |
| `python scripts/run_checks.py` | Lint + tests automáticos |

## Pipeline de subagentes

El proyecto incluye un pipeline de desarrollo asistido por IA con 12 subagentes:

```bash
opencode run "/context"                              # Documentar proyecto
opencode run "/planner Nueva funcionalidad"           # Planificar
opencode run "/spec" && opencode run "/tasks"         # Features + tareas
opencode run "/implement-all"                        # Implementar
opencode run "/pr-ready"                             # Commit + PR
```
