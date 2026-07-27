# Slim, not alpine: asyncpg and argon2-cffi ship manylinux wheels that alpine's
# musl cannot use, so alpine would build both from source on every image build.
FROM python:3.13-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

# Requirements first, as their own layer: application code changes on every
# commit, dependencies almost never, and this keeps the install cached.
COPY requirements.txt .
RUN pip install --upgrade pip && pip install -r requirements.txt

COPY . .

# Not root. A container that never needs to write to its own filesystem should
# not be able to.
RUN useradd --create-home --uid 1000 app && chown -R app:app /app
USER app

EXPOSE 8000

# Migrations run here rather than in a separate service: they must happen after
# the database is reachable and before the first request, which is exactly the
# window this command owns. One worker — the realtime fan-out is in-process (see
# README).
CMD ["sh", "-c", "alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port 8000"]
