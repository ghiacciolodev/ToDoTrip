# Deploying

Getting the API onto the internet and the app pointed at it. Roughly twenty
minutes, most of it waiting for things to build.

- [What you need](#what-you-need)
- [1. The database](#1-the-database)
- [2. The API](#2-the-api)
- [3. Check it](#3-check-it)
- [4. Point the app at it](#4-point-the-app-at-it)
- [Updating](#updating)
- [Things that bite](#things-that-bite)

---

## What you need

A [Neon](https://neon.tech) database and somewhere to run one container.

**On "free": check the current terms yourself before committing.** Hosting free
tiers change every few months and anything written here ages badly. What does not
change is the shape of the trade-off:

| | Cost | Catch |
|---|---|---|
| **Fly.io** | a few euros a month for the smallest machine | Pay-as-you-go. The configuration in `fly.toml` keeps one machine awake, which is what websockets need. |
| **Render / Koyeb free tier** | free | The instance sleeps when idle. Waking takes tens of seconds, and every open websocket dies with it. |
| **Oracle Cloud Always Free** | genuinely free, indefinitely | A VM you administer yourself: updates, TLS certificates, restarts. |

The sleeping tiers are the ones to think twice about. This app tolerates a dead
socket by design — every screen refetches on resume — so it will *work*, but the
first person to open it after a quiet hour waits for a cold start, and live
updates stop being live.

Any host that runs a container works the same way. Only the commands in step 2
change; everything else, including the two settings that matter, is identical.

```bash
# macOS / Linux
curl -L https://fly.io/install.sh | sh
# Windows
powershell -Command "iwr https://fly.io/install.ps1 -useb | iex"

fly auth login
```

---

## 1. The database

Create a project on Neon and copy the connection string. It arrives shaped for
psycopg:

```
postgresql://user:pass@ep-xxx.eu-central-1.aws.neon.tech/todotrip?sslmode=require
```

Two edits are needed before it works here:

```
postgresql+asyncpg://user:pass@ep-xxx.eu-central-1.aws.neon.tech/todotrip
```

- `postgresql+asyncpg://` — the driver this project uses. Without it SQLAlchemy
  reaches for psycopg, which is not installed.
- **drop `?sslmode=require`** — that is psycopg's parameter and asyncpg does not
  understand it. It still connects over TLS: asyncpg negotiates it whenever the
  server asks, and Neon always asks.

---

## 2. The API

From the repository root, where `fly.toml` is:

```bash
fly launch --no-deploy        # pick a name; say no to a Fly Postgres
```

Then the two secrets. They are set separately from `fly.toml` because that file
is in the repository and these must never be:

```bash
fly secrets set DATABASE_URL="postgresql+asyncpg://...your Neon string..."
fly secrets set JWT_SECRET="$(python -c 'import secrets; print(secrets.token_urlsafe(48))')"
```

The secret is generated, not invented. `app/config.py` refuses to start outside
development with anything from its list of placeholders or shorter than 32
characters — a signing key somebody typed is a key somebody else can guess, and
forged tokens leave no trace.

```bash
fly deploy
```

Migrations run as the container starts, before it accepts a request.

---

## 3. Check it

```bash
curl https://your-app.fly.dev/health
# {"status":"ok","environment":"production"}
```

That endpoint opens a connection to PostgreSQL, so a 200 means the database is
reachable too — not merely that the process is alive.

Then the part worth checking by hand, because it fails silently:

```bash
curl -X POST https://your-app.fly.dev/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"you@example.com","password":"password123","display_name":"You"}'
```

A `201` means the schema is there and Argon2 is working. A `500` almost always
means the migrations did not run — `fly logs` says so plainly.

---

## 4. Point the app at it

The API address is compiled into the app. A build without it points at
`10.0.2.2`, which on a real phone is nothing:

```bash
cd mobile
flutter build apk --release \
  --dart-define=API_BASE_URL=https://your-app.fly.dev/api/v1 \
  --dart-define=MAP_TILE_URL="https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=YOUR_KEY" \
  --dart-define=MAP_TILE_ATTRIBUTION="MapTiler | OpenStreetMap contributors"
```

The websocket URL is derived from `API_BASE_URL`, so `https` becomes `wss`
without a second setting.

The two map values matter only for a build other people will install. Left
unset, the app asks OpenStreetMap's own servers for tiles — right for one
developer, outside their usage policy for an app handed to an unknown number of
people. Any provider with a free tier works. The attribution is passed alongside
the URL because crediting OpenStreetMap under somebody else's tiles would be
both a licence breach and a false statement about where the map came from.

---

## Updating

```bash
git push          # whatever you normally do
fly deploy
```

New migrations apply themselves on the next start. Roll back with
`fly releases` and `fly deploy --image <previous>`.

---

## Things that bite

**One machine, deliberately.** `fly.toml` pins it, and `auto_stop_machines` is
off. A second instance would hold websockets the first cannot reach, so members
of the same trip would get live updates or not depending on which machine they
landed on. Scaling out means putting Redis behind `emit()` first — the callers
do not change.

**`TRUSTED_PROXY_HEADER` is not optional in production.** It is set to
`Fly-Client-IP` in `fly.toml`. Behind a proxy every request otherwise arrives
from the proxy's own address, so all users share one rate-limit bucket and ten
people signing in lock everybody out for five minutes. On another host set it to
whatever that platform guarantees — usually `X-Forwarded-For`. Never set it to a
header the platform does not itself control: anyone could then send their own
and walk past the limit entirely.

**Neon sleeps.** The free tier suspends an idle database, so the first request
after a quiet spell takes a few seconds while it wakes. The app's timeouts
tolerate it; a health check with a short timeout may not.

**A build with no `MAP_TILE_URL` points at OpenStreetMap.** That is the default
so a fresh clone runs with nothing configured — which means it is also what ships
if you forget. `AppConfig.usesPublicOsmTiles` reports which of the two any given
build is.

**The privacy policy still has placeholders.** `assets/legal/privacy-policy.md`
has three fields in square brackets that only you can fill: the controller's
name, a postal address, and a contact email. A fourth, the hosting location,
follows from the choice above — say where the container and the database
physically run, and if either sits outside the EEA, name the safeguard relied on.

While this is a repository that is a documented gap. The moment real people
register it is an unmet legal obligation, and it is the one thing on this page
that cannot be fixed by writing code.
