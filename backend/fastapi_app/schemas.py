from pydantic import BaseModel, Field
from typing import Optional
from uuid import UUID
from datetime import date


class DeviceRegisterIn(BaseModel):
    device_identifier: str
    app_id: Optional[UUID] = None


class DeviceOut(BaseModel):
    id: UUID
    device_identifier: str
    app_id: Optional[UUID] = None


class MemberCreateIn(BaseModel):
    app_id: UUID
    name: str
    father_husband_name: Optional[str] = None
    designation: Optional[str] = None
    nationality: str
    cnic: Optional[str] = None
    passport_id: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    state: Optional[str] = None
    district: Optional[str] = None
    tehsil: Optional[str] = None
    address: Optional[str] = None
    issue_date: Optional[date] = None
    expiry_date: Optional[date] = None


class MemberOut(BaseModel):
    id: UUID
    app_id: UUID
    name: str
    designation: Optional[str] = None
    state: Optional[str] = None
    expiry_date: Optional[date] = None
    is_blocked: bool


class MemberQRPayloadOut(BaseModel):
    payload: str
    signature: str


class MemberRegisterIn(BaseModel):
    name: str
    father_husband_name: Optional[str] = None
    designation: Optional[str] = None
    nationality: str
    cnic: Optional[str] = None
    passport_id: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    state: Optional[str] = None
    district: Optional[str] = None
    tehsil: Optional[str] = None
    address: Optional[str] = None
    issue_date: Optional[date] = None
    expiry_date: Optional[date] = None


class RegisterIn(BaseModel):
    device_uuid: str
    member: MemberRegisterIn


class QRVerifyOut(BaseModel):
    valid: bool
    member_id: Optional[UUID] = None
    designation: Optional[str] = None
    status: Optional[str] = None
    last_payment_date: Optional[str] = None
