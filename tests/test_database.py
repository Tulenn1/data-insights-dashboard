from sqlalchemy.orm import Session

from src.database import engine, get_session


def test_engine_is_sqlalchemy_engine():
    assert hasattr(engine, "connect")


def test_get_session_returns_session():
    session = get_session()
    assert isinstance(session, Session)
    session.close()


def test_engine_url_from_config():
    assert engine.url is not None


def test_engine_pool_pre_ping_enabled():
    assert engine.pool._pre_ping is True
