import os
from dataclasses import dataclass, field


@dataclass
class Settings:
    db_url: str = field(
        default_factory=lambda: os.getenv(
            "DATABASE_URL", "postgresql://user:pass@localhost:5432/insights"
        )
    )
    db_pool_size: int = int(os.getenv("DB_POOL_SIZE", "5"))
    debug: bool = os.getenv("DEBUG", "false").lower() == "true"


settings = Settings()
