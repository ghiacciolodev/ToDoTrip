# TodoTrip

Shared trips: calendar, tasks, checklists and split expenses for a group of
friends. FastAPI + PostgreSQL backend (`backend/`), Flutter app (`mobile/`).

## Development

```bash
docker compose up -d db          # PostgreSQL 17
cd backend
python -m venv .venv && .venv/Scripts/pip install -r requirements.txt
alembic upgrade head
uvicorn app.main:app --reload
```

Tests expect a `todotrip_test` database next to the development one:
`docker exec todotrip-db createdb -U todotrip todotrip_test`, then `pytest`.

The app lives in `mobile/`: `flutter pub get`, `flutter run`. The Android
emulator reaches the host API through `10.0.2.2` automatically.

## Realtime: single worker only

Live updates (`WS /api/v1/trips/{id}/events`) are fanned out by an **in-memory**
connection manager in `app/core/events.py`. This only works while the API runs
as **one process**: with several uvicorn workers, an event raised on worker 1
never reaches sockets held by worker 3, and realtime degrades intermittently —
which looks like a client bug and is not.

Run production with one worker (`uvicorn app.main:app`, no `--workers`). If the
API ever needs to scale horizontally, replace the in-process fan-out inside
`emit()` with Redis pub/sub; the routers calling `emit()` do not change.

Clients treat the socket as a latency optimisation, never a requirement: every
screen still refetches on tab switch and on app resume, so with the socket down
the app behaves exactly as it did before realtime existed.
