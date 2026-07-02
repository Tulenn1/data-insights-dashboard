---
name: python-patterns
description: Python general conventions (type hints, testing, linting, clean architecture). Framework-agnostic base skill.
license: MIT
compatibility: both
metadata:
  audience: implementers
  type: skill
---

## What I Do

Provide general Python coding conventions for the implementer subagent.
Framework-specific skills (e.g., `fastapi-patterns`) layer on top of this
and take precedence when available.

---

## Clean Architecture Patterns

Directory structure convention for Python:

```
  src/ (or app/)
    domain/          # Entities, value objects, domain exceptions
    application/     # Use cases, ports (interfaces, protocols)
    infrastructure/  # Adapters (DB, HTTP, messaging implementations)
    presentation/    # Routers, schemas, controllers (if applicable)
  tests/
    unit/
    integration/
    e2e/
```

Key rules:
- Domain layer has ZERO external dependencies (no frameworks, no DB, no HTTP)
- Application layer defines protocols (ABCs or typing.Protocol) that infrastructure implements
- Infrastructure depends on domain interfaces, not the other way around

## Code Conventions

- **Naming**: `snake_case` for functions, methods, variables, modules, and files
              `PascalCase` for classes and exceptions
              `UPPER_CASE` for module-level constants
- **File naming**: `snake_case.py` (e.g., `user_repository.py`)
- **Type hints**: REQUIRED on all public functions, methods, and class attributes
                   Use `from __future__ import annotations` for forward references
- **Import order**: standard library → third-party → local imports (ruff I001 rule)
- **Max function length**: 20 lines
- **Max file length**: 300 lines
- **Docstrings**: Google-style docstrings for all public modules, classes, and functions
- **No wildcard imports**: `from module import *` is forbidden
- **Trailing commas**: Use trailing commas in multi-line collections

## Tooling

- **Linting/formatting**: `ruff check` and `ruff format`
- **Type checking**: `mypy --strict` (or `pyright` if configured)
- **Install command**: `pip install -r requirements.txt` or `poetry install`
- **Run lint**: `ruff check . && ruff format --check .`
- **Run type check**: `mypy src/`

## Testing

- **Test framework**: `pytest`
- **Plugins**: `pytest-cov` for coverage, `pytest-xdist` for parallel runs
- **Test file convention**: `test_<module>.py` in `tests/` directory
- **Fixture location**: `tests/conftest.py` for shared fixtures
- **Run command**: `pytest tests/ -v`
- **Run with coverage**: `pytest tests/ -v --cov=src --cov-report=term`
- **Mocking library**: `unittest.mock` (stdlib) or `pytest-mock` plugin
- **Testing async code**: `pytest-asyncio` with `@pytest.mark.asyncio` decorator
- **Test naming**: `test_<method>_<scenario>_<expected_result>` pattern
                   e.g., `test_create_user_with_valid_email_returns_user`

## Common Patterns

### Dependency Injection

Use constructor injection — pass dependencies through `__init__`:

```python
class CreateUserUseCase:
    def __init__(self, user_repo: UserRepository, email_service: EmailService) -> None:
        self._user_repo = user_repo
        self._email_service = email_service

    async def execute(self, command: CreateUserCommand) -> User:
        ...
```

### Error Handling

- Raise specific domain exceptions (not generic `Exception`)
- Catch exceptions at infrastructure boundaries, wrap them if needed
- Avoid bare `except:` — always specify exception types
- Use `try/finally` for cleanup, not `except` for control flow

### Logging

- Use `logging.getLogger(__name__)` at module level
- Log at appropriate levels: DEBUG for dev detail, INFO for key events,
  WARNING for recoverable issues, ERROR for failures
- Always log exceptions with `exc_info=True`

### Configuration

- Use environment variables for secrets (never hardcode)
- Use `.env` files for local development only (never commit)
- Define config as a dataclass or Pydantic model, loaded at startup

### Database Access

- Use the Repository pattern to abstract data access
- Repository interfaces live in `domain/` or `application/`
- Repository implementations live in `infrastructure/`
- Never leak ORM session objects outside the infrastructure layer

## Anti-patterns to Avoid

- Mixing domain logic with framework code (e.g., business rules in HTTP handlers)
- Using `print()` for logging — use the `logging` module
- Mutating global state or using singletons for DI
- Using `**kwargs` as a substitute for explicit parameters
- Catching `Exception` broadly and silencing it
- Returning `None` to indicate errors — raise exceptions instead
- Using mutable default arguments (`def foo(items=[])`)
- Over-engineering: don't add abstractions without a concrete need
- Committing `.env` files or secrets to version control
