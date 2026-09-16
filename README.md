# Concord

Concord is a Discord-like chat/voice platform made up of three apps that share one backend:

- **`backend/Concord`** - ASP.NET Core 10 Web API (REST + SignalR hubs), backed by PostgreSQL, Redis, Elasticsearch/Kibana, and LiveKit (voice).
- **`frontend/Concord`** - React 19 + Vite web client.
- **`mobile/concord`** - Flutter mobile client.

Full endpoint/hub documentation lives in [`docs/API_REFERENCE.md`](docs/API_REFERENCE.md) (human-readable) and [`docs/openapi.json`](docs/openapi.json) (machine-readable spec).

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) + Docker Compose v2 (the `docker compose` subcommand) - for the backend and its infrastructure.
- [Node.js](https://nodejs.org/) 22+ and npm - for the frontend.
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart ^3.12) - for the mobile app.

---

## 1. Backend (Docker)

All backend commands below are run from `backend/Concord/`.

```bash
cd backend/Concord
```

### 1.1 Configure the environment

There are no `.env.example` files in this repo - `.env` and `.env.Local` are the real files,
and both are checked in directly:

- **`.env`** is committed as a mostly-blank template (only ports and secrets are empty). Fill in
  `APP_ENV` and the two data directories before starting anything:

  ```dotenv
  APP_ENV=Local
  POSTGRES_DIRECTORY=./.data/postgres
  ELASTICSEARCH_DIRECTORY=./.data/elasticsearch
  ```

  (`POSTGRES_DIRECTORY`/`ELASTICSEARCH_DIRECTORY` are host paths for the DB/ES data volumes - any writable local folder works.)

- **`.env.Local`** is committed with working values already filled in (including a random
  32+ character `AuthenticationSettings__SigningKey` and dummy LiveKit keys) - use it as-is for
  local development, or edit it if you need different values.
- **`.env.Production`** is git-ignored (it carries real production secrets: JWT signing key, DB
  password, LiveKit API keys) and won't exist on a fresh clone. Create it yourself before
  deploying - use `.env.Local`'s keys as a template and fill in real production values.

Compose reads two layers of env files:

- **`.env`** (this folder) - used by Compose itself to fill in `${...}` placeholders in `compose.yaml` (image tags, container names, port mappings, volume paths). It must have real values, not just be present.
- **`.env.Local`** / **`.env.Production`** - loaded *into the containers* at runtime, selected by `.env`'s `APP_ENV` value (`env_file: .env.${APP_ENV}`).

`Concord.API/appsettings.Development.json`'s `AuthenticationSettings:SigningKey` and
`ApiSettings:PostgresConnectionString` password are intentionally blank in source control. If
you run the API directly with `dotnet run` (outside Docker, where `.env.Local` doesn't apply),
supply them via .NET user-secrets instead of editing the checked-in file:

```bash
cd Concord.API
dotnet user-secrets set "AuthenticationSettings:SigningKey" "<your-local-signing-key>"
dotnet user-secrets set "ApiSettings:PostgresConnectionString" "Host=localhost:5432;Database=Concord;Username=postgres;Password=<your-local-password>"
```

File uploads (avatars, server icons, message attachments) are stored on local disk everywhere
except `ASPNETCORE_ENVIRONMENT=Production`, where `FileStorageConfig.AddFileStorage` (checked via
`builder.Environment.IsProduction()`) switches to Azure Blob Storage instead - a container's
filesystem doesn't survive a redeploy. Only needed in `.env.Production`, fill in real values for:

```dotenv
AzureBlobStorageSettings__ConnectionString=
AzureBlobStorageSettings__ContainerName=
```

(the API throws on startup if either is blank while `ASPNETCORE_ENVIRONMENT=Production`).

### 1.2 Build the shared base image

`Concord.API`'s Dockerfile builds `FROM shared:${APP_ENV}`, an image that isn't built by Compose itself, so build it once first (rebuild whenever `Concord.Domain`/`Concord.Infrastructure`/`Concord.Application` change):

```bash
docker build -t shared:Local -f Dockerfile .
```

### 1.3 Start the stack

```bash
docker compose --profile db --profile backend up -d --build
```

This starts Postgres, Redis, and LiveKit (`db` profile) and the API (`backend` profile).
Elasticsearch/Kibana are their own `logging` profile - split out deliberately, since they're
~2GB+ of RAM and the API runs fine without them (Serilog's Elasticsearch sink is non-blocking,
it just has nowhere to ship logs). Bring them up explicitly when you want them:

```bash
docker compose --profile logging up -d
```

`ASPNETCORE_ENVIRONMENT` is set per profile in the env files (`Development` in `.env.Local`,
`Production` in `.env.Production`), not hardcoded. On startup the API always applies EF Core
migrations; only when `ASPNETCORE_ENVIRONMENT=Development` (i.e. the `Local` profile) does it
also seed an admin user - **`admin@gmail.com` / `admin`** - if the `Users` table is empty, and
expose Swagger UI.

Check status / logs:

```bash
docker compose ps
docker compose logs -f api
```

### 1.4 Verify it's up

With the default local ports (`API_HTTP_PORT=6001` etc. in `.env`):

- API base URL: `http://localhost:6001/Api/V1.0`
- Swagger UI: `http://localhost:6001/swagger` (only exposed when `ASPNETCORE_ENVIRONMENT=Development`, i.e. the `Local` profile)
- Kibana: `http://localhost:5601` (only if you also brought up the `logging` profile)

### 1.5 Stop / clean up

```bash
docker compose --profile db --profile backend --profile logging down      # stop and remove containers
docker compose --profile db --profile backend --profile logging down -v    # also remove volumes (wipes DB/ES data)
```

(drop `--profile logging` if you never brought it up - Compose ignores profiles for services that aren't running.)

> `.env.Local` contains real-looking secrets for local use only - don't reuse them anywhere outside your machine.

---

## 2. Frontend (React + Vite)

Run from `frontend/Concord/`. The service layer already reads its API base URL from `VITE_API_URL` (see `src/api/httpClient.js`).

### Option A - Vite dev server (recommended while developing)

```bash
cd frontend/Concord
npm install
echo "VITE_API_URL=http://localhost:6001" > .env.local
npm run dev
```

Open `http://localhost:5173`.

### Option B - Docker (production-style build via the existing `Dockerfile`)

```bash
cd frontend/Concord
docker build --build-arg VITE_API_URL=http://localhost:6001 -t concord-frontend .
docker run --rm -p 5173:80 concord-frontend
```

Open `http://localhost:5173`.

---

## 3. Mobile (Flutter)

Run from `mobile/concord/`. There's no Docker image for this app - Flutter targets a device/emulator/simulator, not a container. The API base URL is read via `--dart-define=API_BASE_URL=...` (see `lib/api/api_config.dart`), defaulting to `http://localhost:6001` if omitted.

```bash
cd mobile/concord
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:6001
```

> **Android emulator:** `localhost` refers to the emulator itself, not your host machine - use `--dart-define=API_BASE_URL=http://10.0.2.2:6001` instead.

---

## Running everything together

### Option A - backend in Docker, frontend/mobile run natively (recommended while developing)

1. Start the backend (section 1) - wait until `docker compose ps` shows `api` healthy/running.
2. Start the frontend (section 2, Option A) and/or the mobile app (section 3), pointed at the backend's URL.
3. Log in with the seeded admin account (`admin@gmail.com` / `admin`, only seeded on the `Local` profile) or register a new user via `POST /Api/V1.0/Register`.

### Option B - everything in Docker, including the frontend

Compose also has a `frontend` profile (see `compose.yaml`) that builds and serves the React app
alongside the backend, instead of running it with `npm run dev` as in section 2:

```bash
cd backend/Concord
docker build -t shared:Local -f Dockerfile .
docker compose --env-file .env.Local --profile db --profile backend --profile frontend up -d --build
```

Start vercel automation command.
