from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..db import get_db
from ..models import Member, Device, Payment, Document

router = APIRouter(prefix="/api/admin", tags=["admin"])


@router.get("/members")
def list_members(state: str | None = None, blocked: bool | None = None, expired: bool | None = None, db: Session = Depends(get_db)):
    q = db.query(Member)
    if state:
        q = q.filter(Member.state == state)
    if blocked is not None:
        q = q.filter(Member.is_blocked == blocked)
    return [{"id": str(m.id), "name": m.name, "state": m.state, "blocked": m.is_blocked} for m in q.all()]


@router.get("/devices")
def list_devices(db: Session = Depends(get_db)):
    q = db.query(Device)
    return [{"id": str(d.id), "device_identifier": d.device_identifier, "blocked": d.is_blocked} for d in q.all()]


@router.get("/payments")
def list_payments(db: Session = Depends(get_db)):
    q = db.query(Payment)
    return [{"id": str(p.id), "member_id": str(p.member_id), "amount": float(p.amount), "status": p.status, "method": p.method} for p in q.all()]


@router.get("/documents")
def list_documents(db: Session = Depends(get_db)):
    q = db.query(Document)
    return [{"id": str(d.id), "member_id": str(d.member_id), "doc_type": d.doc_type, "verified": d.verified} for d in q.all()]

