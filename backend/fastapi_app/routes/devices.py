from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..db import get_db
from ..models import Device
from ..schemas import DeviceRegisterIn, DeviceOut


router = APIRouter(prefix="/api/devices", tags=["devices"])


@router.post("/register", response_model=DeviceOut, status_code=201)
def register_device(body: DeviceRegisterIn, db: Session = Depends(get_db)):
    existing = db.query(Device).filter(Device.device_identifier == body.device_identifier).first()
    if existing:
        return DeviceOut(id=existing.id, device_identifier=existing.device_identifier, app_id=existing.member_id)
    d = Device(device_identifier=body.device_identifier)
    db.add(d)
    db.commit()
    db.refresh(d)
    return DeviceOut(id=d.id, device_identifier=d.device_identifier, app_id=d.member_id)


@router.get("/", response_model=list[DeviceOut])
def list_devices(db: Session = Depends(get_db)):
    devices = db.query(Device).all()
    return [DeviceOut(id=d.id, device_identifier=d.device_identifier, app_id=d.member_id) for d in devices]


@router.post("/block")
def block_device(device_identifier: str, db: Session = Depends(get_db)):
    d = db.query(Device).filter(Device.device_identifier == device_identifier).first()
    if not d:
        raise HTTPException(status_code=404, detail="Device not found")
    d.is_blocked = True
    db.commit()
    return {"success": True}


@router.post("/unblock")
def unblock_device(device_identifier: str, db: Session = Depends(get_db)):
    d = db.query(Device).filter(Device.device_identifier == device_identifier).first()
    if not d:
        raise HTTPException(status_code=404, detail="Device not found")
    d.is_blocked = False
    db.commit()
    return {"success": True}
