"""Settings validation. Guards the one misconfiguration that fails silently."""

import pytest
from pydantic import ValidationError

from app.config import Settings

DB = "postgresql+asyncpg://user:password@localhost:5432/todotrip"
STRONG = "yq0Zt7Xn2LmR8vKpA4dWbF6sJ1cH3gQeTuYiOoPlZxCv"


def _settings(**overrides) -> Settings:
    # _env_file=None so a developer's own .env cannot decide the outcome.
    return Settings(database_url=DB, _env_file=None, **overrides)


class TestJwtSecret:
    def test_placeholder_is_rejected_in_production(self):
        with pytest.raises(ValidationError):
            _settings(jwt_secret="change-me", environment="production")

    def test_short_secret_is_rejected_in_production(self):
        with pytest.raises(ValidationError):
            _settings(jwt_secret="yq0Zt7Xn2LmR8vKp", environment="production")

    def test_strong_secret_is_accepted(self):
        assert _settings(jwt_secret=STRONG, environment="production").jwt_secret == STRONG

    def test_any_non_development_environment_is_checked(self):
        """Staging holds real accounts too, so it is not exempt."""
        with pytest.raises(ValidationError):
            _settings(jwt_secret="change-me", environment="staging")

    def test_development_still_runs_with_the_sample_secret(self):
        """A fresh clone must start from .env.example without ceremony."""
        assert _settings(jwt_secret="change-me").environment == "development"
