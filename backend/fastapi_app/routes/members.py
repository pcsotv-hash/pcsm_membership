from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session
from uuid import UUID
import hmac, hashlib, json, os

from ..db import get_db
from ..models import Member
from ..schemas import MemberCreateIn, MemberOut, MemberQRPayloadOut


router = APIRouter(prefix="/api/members", tags=["members"])


@router.post("", response_model=MemberOut, status_code=201)
def create_member(body: MemberCreateIn, db: Session = Depends(get_db)):
    # nationality check enforced at DB level in production; do basic check here
    if body.nationality == "Pakistani":
        if not body.cnic:
            raise HTTPException(status_code=400, detail="CNIC required for Pakistani members")
        body.passport_id = None
    else:
        if not body.passport_id:
            raise HTTPException(status_code=400, detail="Passport/ID required for non-Pakistani members")
        body.cnic = None

    m = Member(
        app_id=body.app_id,
        name=body.name,
        father_husband_name=body.father_husband_name,
        designation=body.designation,
        nationality=body.nationality,
        cnic=body.cnic,
        passport_id=body.passport_id,
        phone=body.phone,
        email=body.email,
        state=body.state,
        district=body.district,
        tehsil=body.tehsil,
        address=body.address,
        issue_date=body.issue_date,
        expiry_date=body.expiry_date,
    )
    db.add(m)
    db.commit()
    db.refresh(m)
    return MemberOut(
        id=m.id,
        app_id=m.app_id,
        name=m.name,
        designation=m.designation,
        state=m.state,
        expiry_date=m.expiry_date,
        is_blocked=m.is_blocked,
    )


@router.get("/{member_id}", response_model=MemberOut)
def get_member(member_id: UUID, db: Session = Depends(get_db)):
    m = db.get(Member, member_id)
    if not m:
        raise HTTPException(status_code=404, detail="Member not found")
    return MemberOut(
        id=m.id,
        app_id=m.app_id,
        name=m.name,
        designation=m.designation,
        state=m.state,
        expiry_date=m.expiry_date,
        is_blocked=m.is_blocked,
    )


@router.get("", response_model=list[MemberOut])
def list_members(state: str | None = None, blocked: bool | None = None, expired: bool | None = None, db: Session = Depends(get_db)):
    q = db.query(Member)
    if state:
        q = q.filter(Member.state == state)
    if blocked is not None:
        q = q.filter(Member.is_blocked == blocked)
    # expired is computed in DB in production; here emulate simple filter
    if expired is not None:
        from sqlalchemy import func
        if expired:
            q = q.filter(Member.expiry_date != None).filter(Member.expiry_date < func.current_date())
        else:
            q = q.filter((Member.expiry_date == None) | (Member.expiry_date >= func.current_date()))
    res = []
    for m in q.all():
        res.append(MemberOut(
            id=m.id,
            app_id=m.app_id,
            name=m.name,
            designation=m.designation,
            state=m.state,
            expiry_date=m.expiry_date,
            is_blocked=m.is_blocked,
        ))
    return res


@router.post("/{member_id}/qr", response_model=MemberQRPayloadOut)
def create_member_qr(member_id: UUID, db: Session = Depends(get_db)):
    m = db.get(Member, member_id)
    if not m:
        raise HTTPException(status_code=404, detail="Member not found")
    secret = os.getenv("API_SECRET", "change_me_secret")
    payload = {
        "member_id": str(m.id),
        "designation": m.designation,
        "expiry_date": m.expiry_date.isoformat() if m.expiry_date else None,
        "timestamp": __import__("time").time(),
    }
    payload_str = json.dumps(payload, separators=(",", ":"))
    signature = hmac.new(secret.encode(), payload_str.encode(), hashlib.sha256).hexdigest()
    return MemberQRPayloadOut(payload=payload_str, signature=signature)


@router.post("/{member_id}/upload-card")
def upload_card(member_id: UUID, image: UploadFile = File(...), db: Session = Depends(get_db)):
    # Placeholder: accept image and record a document entry for review
    m = db.get(Member, member_id)
    if not m:
        raise HTTPException(status_code=404, detail="Member not found")
    # In a real implementation, save file and compute OCR + pHash
    # Here we just stub a response
    return {"uploaded": True, "ocr_text": None, "verified": False}
