from fastapi import APIRouter
from fastapi import Depends
from sqlalchemy.orm import Session
from ..db import get_db
from ..models import Payment, Member

router = APIRouter(prefix="/api/payments", tags=["payments"])


@router.post("/jazzcash/initiate")
def jazzcash_initiate(member_id: str, amount: float):
    # Placeholder: return fields needed for client checkout to redirect to JazzCash
    return {"member_id": member_id, "amount": amount, "gateway": "jazzcash", "status": "init"}


@router.post("/jazzcash/confirm")
def jazzcash_confirm(member_id: str, txn_id: str, status: str):
    # Placeholder confirmation
    return {"success": status == "succeeded"}


@router.post("/easypaisa/initiate")
def easypaisa_initiate(member_id: str, amount: float):
    return {"member_id": member_id, "amount": amount, "gateway": "easypaisa", "status": "init"}


@router.post("/easypaisa/confirm")
def easypaisa_confirm(member_id: str, txn_id: str, status: str):
    return {"success": status == "succeeded"}


@router.post("/manual/submit")
def manual_submit(member_id: str, reference: str, amount: float):
    return {"status": "pending", "member_id": member_id, "reference": reference}


@router.post("/webhook")
def payments_webhook(gateway: str, payload: dict, db: Session = Depends(get_db)):
    # Minimal webhook receiver: store payload, mark as pending for later verification
    # Attach a timestamp into metadata for later reporting
    if "timestamp" not in payload:
        import datetime as dt
        payload["timestamp"] = dt.datetime.utcnow().isoformat()

    member_id = payload.get("member_id")
    status = payload.get("status", "pending")
    amount = float(payload.get("amount", 0))
    p = Payment(method=gateway or "wallet", status=status, amount=amount, metadata=payload)
    if member_id:
        try:
            from uuid import UUID
            p.member_id = UUID(member_id)
        except Exception:
            pass
    db.add(p)
    db.commit()
    # If success, extend membership expiry by 1 year as a simple rule
    if member_id and status == "succeeded":
        try:
            from uuid import UUID
            mid = UUID(member_id)
            m = db.get(Member, mid)
            if m:
                import datetime as dt
                today = dt.date.today()
                m.expiry_date = (m.expiry_date or today) + dt.timedelta(days=365)
                db.commit()
        except Exception:
            pass
    return {"received": True}
