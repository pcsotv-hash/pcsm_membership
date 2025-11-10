# Database Schema (PostgreSQL)

## Entities
- `members`: core profile and membership status
- `devices`: device identifiers linked to accounts (optional link)
- `payments`: records for JazzCash, EasyPaisa, manual transfers
- `documents`: stored files like CNIC, Passport, uploaded card images
- `audit_logs`: security/audit trail of actions

## Table Definitions (DDL)

```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  app_id UUID NOT NULL UNIQUE, -- unique app install/account id
  name VARCHAR(120) NOT NULL,
  father_husband_name VARCHAR(120),
  designation VARCHAR(80),
  nationality VARCHAR(40) NOT NULL, -- Pakistani / Other
  cnic VARCHAR(20),
  passport_id VARCHAR(30),
  phone VARCHAR(30),
  email VARCHAR(120),
  state VARCHAR(80),
  district VARCHAR(80),
  tehsil VARCHAR(80),
  address TEXT,
  issue_date DATE,
  expiry_date DATE,
  is_blocked BOOLEAN NOT NULL DEFAULT FALSE,
  is_expired BOOLEAN GENERATED ALWAYS AS (
    CASE WHEN expiry_date IS NULL THEN FALSE ELSE (expiry_date < CURRENT_DATE) END
  ) STORED,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Ensure either CNIC or Passport is present depending on nationality
CREATE OR REPLACE FUNCTION members_identity_check() RETURNS trigger AS $$
BEGIN
  IF NEW.nationality = 'Pakistani' THEN
    IF NEW.cnic IS NULL OR NEW.cnic = '' THEN
      RAISE EXCEPTION 'Pakistani members must provide CNIC';
    END IF;
    NEW.passport_id := NULL;
  ELSE
    IF NEW.passport_id IS NULL OR NEW.passport_id = '' THEN
      RAISE EXCEPTION 'Non-Pakistani members must provide Passport/ID';
    END IF;
    NEW.cnic := NULL;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_members_identity_check ON members;
CREATE TRIGGER trg_members_identity_check
BEFORE INSERT OR UPDATE ON members
FOR EACH ROW EXECUTE FUNCTION members_identity_check();

CREATE TABLE IF NOT EXISTS devices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  device_identifier VARCHAR(128) NOT NULL UNIQUE,
  member_id UUID REFERENCES members(id) ON DELETE SET NULL,
  is_blocked BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  member_id UUID REFERENCES members(id) ON DELETE CASCADE,
  amount NUMERIC(12,2) NOT NULL,
  currency VARCHAR(8) NOT NULL DEFAULT 'PKR',
  method VARCHAR(20) NOT NULL, -- JazzCash, EasyPaisa, Manual
  status VARCHAR(20) NOT NULL, -- pending, succeeded, failed, refunded
  txn_id VARCHAR(80),
  metadata JSONB,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payments_member ON payments(member_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);

CREATE TABLE IF NOT EXISTS documents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  member_id UUID REFERENCES members(id) ON DELETE CASCADE,
  doc_type VARCHAR(30) NOT NULL, -- cnic_front, cnic_back, passport, card_image
  storage_path TEXT NOT NULL,
  checksum VARCHAR(64),
  verified BOOLEAN NOT NULL DEFAULT FALSE,
  uploaded_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_documents_member ON documents(member_id);
CREATE INDEX IF NOT EXISTS idx_documents_type ON documents(doc_type);

CREATE TABLE IF NOT EXISTS audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  actor_type VARCHAR(20) NOT NULL, -- admin, system, member
  actor_id UUID,
  action VARCHAR(50) NOT NULL, -- block_account, unblock_device, upload_doc, payment_update
  target_type VARCHAR(30), -- member, device, payment, document
  target_id UUID,
  metadata JSONB,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Public listing (state-wise) of active members
CREATE INDEX IF NOT EXISTS idx_members_public_list ON members(state, is_blocked, is_expired);
```

## Relationships
- One member can have multiple devices.
- Member has many payments and documents.
- Audit logs reference any entity by `target_type` + `target_id`.

## QR Payload (Signed)
- Fields: `member_id`, `designation`, `expiry_date`, `timestamp`
- Signature: HMAC-SHA256(secret, payloadJSON)
- Scan flow: backend validates signature and current status before allowing actions.

