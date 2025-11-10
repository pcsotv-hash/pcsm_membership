from fastapi import FastAPI
from .db import engine, Base
from .routes.members import router as members_router
from .routes.devices import router as devices_router
from .routes.payments import router as payments_router
from .routes.admin import router as admin_router
from .routes.register import router as register_router
from .routes.qr import router as qr_router


def create_app() -> FastAPI:
    app = FastAPI(title="PCSM Membership Backend", version="0.1.0")

    @app.get("/api/health")
    def health():
        return {"status": "ok"}

    app.include_router(members_router)
    app.include_router(devices_router)
    app.include_router(payments_router)
    app.include_router(admin_router)
    app.include_router(register_router)
    app.include_router(qr_router)
    return app


app = create_app()

# Create tables if not exist (simple dev-only auto-migrate)
try:
    Base.metadata.create_all(bind=engine)
except Exception as e:
    # In dev, we can log this; production should use migrations
    print(f"[WARN] Failed to auto-create tables: {e}")
