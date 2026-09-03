# Concord

Concord is a Discord-like chat/voice platform made up of three apps that share one backend:

- **`backend/Concord`** — ASP.NET Core 10 Web API (REST + SignalR hubs), backed by PostgreSQL, Redis, Elasticsearch/Kibana, and LiveKit (voice).
- **`frontend/Concord`** — React 19 + Vite web client.
- **`mobile/concord`** — Flutter mobile client.

Full endpoint/hub documentation lives in [`docs/API_REFERENCE.md`](docs/API_REFERENCE.md) (human-readable) and [`docs/openapi.json`](docs/openapi.json) (machine-readable spec).

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) + Docker Compose v2 (the `docker compose` subcommand) — for the backend and its infrastructure.
- [Node.js](https://nodejs.org/) 22+ and npm — for the frontend.
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart ^3.12) — for the mobile app.

---

## 1. Backend (Docker)

All backend commands below are run from `backend/Concord/`.

```bash
cd backend/Concord
```

### 1.1 Configure the environment

`.env`, `.env.Local`, and `.env.Production` carry real secrets (JWT signing key, DB password,
LiveKit API keys) and are git-ignored — they are never committed. Each has a checked-in
`*.example` counterpart (`.env.example`, `.env.Local.example`, `.env.Production.example`) with
the same keys and placeholder values; copy the one(s) you need and fill in real values:

```bash
cp .env.example .env
cp .env.Local.example .env.Local        # if running the Local profile
cp .env.Production.example .env.Production  # if running the Production profile
```

Compose reads two layers of env files:

- **`.env`** (repo root of this folder) — used by Compose itself to fill in `${...}` placeholders in `compose.yaml` (image tags, container names, port mappings, volume paths). It must have real values, not just be present.
- **`.env.Local`** / **`.env.Production`** — loaded *into the containers* at runtime, selected by `.env`'s `APP_ENV` value (`env_file: .env.${APP_ENV}`). Fill in the `REPLACE_ME` placeholders in your copy of `.env.Local`/`.env.Production` with real values before starting the stack — a random 32+ character string is fine for `AuthenticationSettings__SigningKey`.

`Concord.API/appsettings.Development.json`'s `AuthenticationSettings:SigningKey` and
`ApiSettings:PostgresConnectionString` password are intentionally blank in source control. If
you run the API directly with `dotnet run` (outside Docker, where `.env.Local` doesn't apply),
supply them via .NET user-secrets instead of editing the checked-in file:

```bash
cd Concord.API
dotnet user-secrets set "AuthenticationSettings:SigningKey" "<your-local-signing-key>"
dotnet user-secrets set "ApiSettings:PostgresConnectionString" "Host=localhost:5432;Database=Concord;Username=postgres;Password=<your-local-password>"
```

For local development, edit `.env` and set:

```dotenv
APP_ENV=Local
POSTGRES_DIRECTORY=./.data/postgres
ELASTICSEARCH_DIRECTORY=./.data/elasticsearch
```

(`POSTGRES_DIRECTORY`/`ELASTICSEARCH_DIRECTORY` are host paths for the DB/ES data volumes — any writable local folder works.)

### 1.2 Build the shared base image

`Concord.API`'s Dockerfile builds `FROM shared:${APP_ENV}`, an image that isn't built by Compose itself, so build it once first (rebuild whenever `Concord.Domain`/`Concord.Infrastructure`/`Concord.Application` change):

```bash
docker build -t shared:Local -f Dockerfile .
```

### 1.3 Start the stack

```bash
docker compose --profile db --profile backend up -d --build
```

This starts Postgres, Redis, LiveKit, Elasticsearch, Kibana (`db` profile) and the API (`backend` profile). The API container hardcodes `ASPNETCORE_ENVIRONMENT=Development`, so on startup it automatically:
- applies EF Core migrations, and
- seeds an admin user — **`admin@gmail.com` / `admin`** — if the `Users` table is empty.

Check status / logs:

```bash
docker compose ps
docker compose logs -f api
```

### 1.4 Verify it's up

With the default local ports (`API_HTTP_PORT=6001` etc. in `.env`):

- API base URL: `http://localhost:6001/Api/V1.0`
- Swagger UI: `http://localhost:6001/swagger`
- Kibana: `http://localhost:5601`

### 1.5 Stop / clean up

```bash
docker compose --profile db --profile backend down      # stop and remove containers
docker compose --profile db --profile backend down -v    # also remove volumes (wipes DB/ES data)
```

> `.env.Local` contains real-looking secrets for local use only — don't reuse them anywhere outside your machine.

---

## 2. Frontend (React + Vite)

Run from `frontend/Concord/`. The service layer already reads its API base URL from `VITE_API_URL` (see `src/api/httpClient.js`).

### Option A — Vite dev server (recommended while developing)

```bash
cd frontend/Concord
npm install
echo "VITE_API_URL=http://localhost:6001" > .env.local
npm run dev
```

Open `http://localhost:5173`.

### Option B — Docker (production-style build via the existing `Dockerfile`)

```bash
cd frontend/Concord
docker build --build-arg VITE_API_URL=http://localhost:6001 -t concord-frontend .
docker run --rm -p 5173:80 concord-frontend
```

Open `http://localhost:5173`.

---

## 3. Mobile (Flutter)

Run from `mobile/concord/`. There's no Docker image for this app — Flutter targets a device/emulator/simulator, not a container. The API base URL is read via `--dart-define=API_BASE_URL=...` (see `lib/api/api_config.dart`), defaulting to `http://localhost:6001` if omitted.

```bash
cd mobile/concord
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:6001
```

> **Android emulator:** `localhost` refers to the emulator itself, not your host machine — use `--dart-define=API_BASE_URL=http://10.0.2.2:6001` instead.

---

## Running everything together 1

1. Start the backend (section 1) — wait until `docker compose ps` shows `api` healthy/running.
2. Start the frontend (section 2, Option A) and/or the mobile app (section 3), pointed at the backend's URL.
3. Log in with the seeded admin account (`admin@gmail.com` / `admin`) or register a new user via `POST /Api/V1.0/Register`.

## Running everything together 2

cd backend/Concord
docker build -t shared:Local -f Dockerfile .
docker compose --env-file .env.Local --profile db --profile backend --profile frontend up -d --build
docker compose --env-file .env.Local --profile db --profile backend --profile frontend up -d --up