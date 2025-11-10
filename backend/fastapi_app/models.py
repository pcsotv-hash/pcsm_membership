from sqlalchemy import Column, String, Date, Boolean, JSON, Numeric, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid

from .db import Base


class Member(Base):
    __tablename__ = "members"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    app_id = Column(UUID(as_uuid=True), unique=True, nullable=False)
    name = Column(String(120), nullable=False)
    father_husband_name = Column(String(120))
    designation = Column(String(80))
    nationality = Column(String(40), nullable=False)
    cnic = Column(String(20))
    passport_id = Column(String(30))
    phone = Column(String(30))
    email = Column(String(120))
    state = Column(String(80))
    district = Column(String(80))
    tehsil = Column(String(80))
    address = Column(String)
    issue_date = Column(Date)
    expiry_date = Column(Date)
    is_blocked = Column(Boolean, nullable=False, default=False)

    devices = relationship("Device", back_populates="member")
    payments = relationship("Payment", back_populates="member")
    documents = relationship("Document", back_populates="member")


class Device(Base):
    __tablename__ = "devices"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    device_identifier = Column(String(128), unique=True, nullable=False)
    member_id = Column(UUID(as_uuid=True), ForeignKey("members.id"))
    is_blocked = Column(Boolean, nullable=False, default=False)

    member = relationship("Member", back_populates="devices")


class Payment(Base):
    __tablename__ = "payments"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    member_id = Column(UUID(as_uuid=True), ForeignKey("members.id"))
    amount = Column(Numeric(12, 2), nullable=False)
    currency = Column(String(8), nullable=False, default="PKR")
    method = Column(String(20), nullable=False)
    status = Column(String(20), nullable=False)
    txn_id = Column(String(80))
    metadata = Column(JSON)

    member = relationship("Member", back_populates="payments")


class Document(Base):
    __tablename__ = "documents"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    member_id = Column(UUID(as_uuid=True), ForeignKey("members.id"))
    doc_type = Column(String(30), nullable=False)
    storage_path = Column(String, nullable=False)
    checksum = Column(String(64))
    verified = Column(Boolean, nullable=False, default=False)

    member = relationship("Member", back_populates="documents")


class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    actor_type = Column(String(20), nullable=False)
    actor_id = Column(UUID(as_uuid=True))
    action = Column(String(50), nullable=False)
    target_type = Column(String(30))
    target_id = Column(UUID(as_uuid=True))
    metadata = Column(JSON)
