# PCSM Membership Backend (FastAPI)

## Overview
- FastAPI backend for membership app + website
- PostgreSQL database via Docker Compose
- Endpoints for members, devices, payments (placeholder), admin

## Prerequisites
- Docker Desktop installed
- Ports available: `5432` (Postgres), `8000` (API)

## Quick Start

```bash
# from project root
docker compose up --build
```

- API docs: http://localhost:8000/docs
- Health check: http://localhost:8000/api/health

## Configuration
- Set environment vars in `docker-compose.yml` for DB and `API_SECRET`
- Backend defaults:
  - `DB_HOST=db`, `DB_PORT=5432`, `DB_NAME=pcsm`, `DB_USER=pcsm`, `DB_PASSWORD=pcsm`
  - `API_SECRET` for QR signing (change for production)

## Database
- Schema documented in `docs/db_schema.md`
- Dev-time auto table creation runs on backend startup; for production use migrations (Alembic)

## Endpoints
- See `docs/api_spec.md` and interactive Swagger at `/docs`

## Testing Plan (Initial)
- Unit: schemas validation, QR signature generation
- Integration: create member → list → get → QR
- Device flows: register, block/unblock
- Admin: list members/devices/payments/documents

## Deployment Notes
- Self-hosted via Docker Compose on a VM or on-prem
- Use reverse proxy (Nginx) and TLS for production
- Configure backups for `db_data` volume

## Security & Privacy
- Device ID recorded and can be blocked server-side
- Members can be blocked; expired memberships restricted
- QR payloads signed with `API_SECRET`; verify on scan
- Sensitive data stored in Postgres; secure access and backups

