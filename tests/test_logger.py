from src.logger import get_logger


class TestLogger:
    def test_get_logger_returns_logger(self):
        logger = get_logger("test")
        assert logger.name == "test"
        assert len(logger.handlers) > 0

    def test_get_logger_reuses_instance(self):
        a = get_logger("same")
        b = get_logger("same")
        assert a is b
