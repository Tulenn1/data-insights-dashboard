from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from config import settings
from src.logger import get_logger

logger = get_logger(__name__)

engine = create_engine(
    settings.db_url,
    pool_size=settings.db_pool_size,
    pool_pre_ping=True,
)

logger.info("Database engine created: %s", settings.db_url)


def get_session() -> Session:
    return Session(engine)
