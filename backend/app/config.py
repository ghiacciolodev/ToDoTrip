from functools import lru_cache

from pydantic import model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

# Values that ship in documentation and get left behind. A secret from this list
# is public knowledge, and anyone holding it can mint tokens for any account.
_PLACEHOLDER_SECRETS = frozenset(
    {"change-me", "changeme", "change_me", "secret", "todotrip", "test", "dev"}
)

# 32 bytes is the output size of the SHA-256 that HS256 is built on: a shorter
# key adds no strength and usually means someone typed a word.
_MIN_SECRET_LENGTH = 32


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str
    jwt_secret: str
    jwt_algorithm: str = "HS256"
    access_token_minutes: int = 15
    refresh_token_days: int = 30
    environment: str = "development"

    # Which header carries the real client address, when something sits in front.
    #
    # Empty by default and that is the safe default: trusting a forwarded header
    # unconditionally lets anybody set their own identity and walk straight past
    # every limit. Behind a proxy the opposite failure applies — every request
    # arrives from the proxy, so one shared bucket throttles all users at once.
    # Set it to what the platform actually guarantees: "Fly-Client-IP" on
    # Fly.io, "X-Forwarded-For" behind most others.
    trusted_proxy_header: str = ""

    @model_validator(mode="after")
    def check_jwt_secret(self):
        """Refuse to start outside development with a guessable signing key.

        Checked here rather than left to a deployment checklist: the failure it
        prevents is silent — every token stays valid and forgery leaves no trace,
        so nothing would ever reveal that the key was still the example one.
        Development is exempt so a fresh clone runs with the sample .env.
        """
        if self.environment == "development":
            return self
        if (
            self.jwt_secret.strip().lower() in _PLACEHOLDER_SECRETS
            or len(self.jwt_secret) < _MIN_SECRET_LENGTH
        ):
            raise ValueError(
                "JWT_SECRET must be a random value of at least "
                f"{_MIN_SECRET_LENGTH} characters outside development "
                '(generate one with: python -c "import secrets; '
                'print(secrets.token_urlsafe(48))")'
            )
        return self


@lru_cache
def get_settings() -> Settings:
    return Settings()
