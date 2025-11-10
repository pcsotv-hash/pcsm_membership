from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from ..db import get_db
from ..models import Member, Device
from ..schemas import RegisterIn

router = APIRouter(prefix="/api", tags=["register"])


@router.post("/register")
def register(body: RegisterIn, db: Session = Depends(get_db)):
    # ensure device exists
    device = db.query(Device).filter(Device.device_identifier == body.device_uuid).first()
    if not device:
        device = Device(device_identifier=body.device_uuid)
        db.add(device)
        db.commit()
        db.refresh(device)

    # create member
    m = Member(
        app_id=device.id,
        name=body.member.name,
        father_husband_name=body.member.father_husband_name,
        designation=body.member.designation,
        nationality=body.member.nationality,
        cnic=body.member.cnic,
        passport_id=body.member.passport_id,
        phone=body.member.phone,
        email=body.member.email,
        state=body.member.state,
        district=body.member.district,
        tehsil=body.member.tehsil,
        address=body.member.address,
        issue_date=body.member.issue_date,
        expiry_date=body.member.expiry_date,
    )
    db.add(m)
    db.commit()
    db.refresh(m)
    return {"member_id": str(m.id), "device_id": str(device.id)}

