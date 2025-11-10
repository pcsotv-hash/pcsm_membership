from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
import base64, hmac, hashlib, json, os
from uuid import UUID

from ..db import get_db
from ..models import Member, Payment
from ..schemas import QRVerifyOut

router = APIRouter(prefix="/api/qr", tags=["qr"])


@router.get("/verify", response_model=QRVerifyOut)
def verify(token: str, db: Session = Depends(get_db)):
    # Token format: base64url(payload).hex(signature) separated by '.'
    try:
        payload_b64, signature_hex = token.split(".")
        payload_str = base64.urlsafe_b64decode(payload_b64 + "==").decode()
    except Exception:
        return QRVerifyOut(valid=False)

    secret = os.getenv("API_SECRET", "change_me_secret")
    expected_sig = hmac.new(secret.encode(), payload_str.encode(), hashlib.sha256).hexdigest()
    if not hmac.compare_digest(signature_hex, expected_sig):
        return QRVerifyOut(valid=False)

    try:
        payload = json.loads(payload_str)
        member_id = UUID(payload.get("member_id"))
    except Exception:
        return QRVerifyOut(valid=False)

    m = db.get(Member, member_id)
    if not m:
        return QRVerifyOut(valid=False)

    # Determine status
    status = "active"
    import datetime
    if m.is_blocked:
        status = "blocked"
    elif m.expiry_date and m.expiry_date < datetime.date.today():
        status = "expired"

    # Find last successful payment, using metadata timestamp if present
    last = None
    try:
        pays = db.query(Payment).filter(Payment.member_id == m.id, Payment.status == "succeeded").all()
        def parse_ts(p):
            try:
                ts = p.metadata and p.metadata.get("timestamp")
                if not ts:
                    return None
                # Accept ISO date or datetime
                if len(ts) == 10:
                    return ts
                import datetime as dt
                return dt.datetime.fromisoformat(ts).date().isoformat()
            except Exception:
                return None
        candidates = [parse_ts(p) for p in pays]
        last = max([c for c in candidates if c], default=None)
    except Exception:
        pass

    return QRVerifyOut(valid=True, member_id=m.id, designation=m.designation, status=status, last_payment_date=last)
