from fastapi import APIRouter
from fastapi import Depends
from sqlalchemy.orm import Session
from ..db import get_db
from ..models import Payment

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
    p = Payment(method="wallet", gateway=gateway, status="pending", amount=0, metadata=payload)
    db.add(p)
    db.commit()
    return {"received": True}
