-- Sample seed data for PCSM membership backend
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Minimal tables if not already created (dev convenience; production uses migrations)
CREATE TABLE IF NOT EXISTS members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  app_id UUID UNIQUE NOT NULL,
  name VARCHAR(120) NOT NULL,
  designation VARCHAR(80),
  nationality VARCHAR(40) NOT NULL,
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
  is_blocked BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS devices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  device_identifier VARCHAR(128) NOT NULL UNIQUE,
  member_id UUID,
  is_blocked BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  member_id UUID,
  amount NUMERIC(12,2) NOT NULL DEFAULT 0,
  currency VARCHAR(8) NOT NULL DEFAULT 'PKR',
  method VARCHAR(20) NOT NULL,
  status VARCHAR(20) NOT NULL,
  txn_id VARCHAR(80),
  metadata JSON
);

CREATE TABLE IF NOT EXISTS documents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  member_id UUID,
  doc_type VARCHAR(30) NOT NULL,
  storage_path TEXT NOT NULL,
  checksum VARCHAR(64),
  verified BOOLEAN NOT NULL DEFAULT FALSE
);

-- Sample device
INSERT INTO devices (id, device_identifier, is_blocked)
VALUES (uuid_generate_v4(), 'sample-device-001', FALSE)
ON CONFLICT (device_identifier) DO NOTHING;

-- Sample member linked to sample device app_id
INSERT INTO members (id, app_id, name, designation, nationality, cnic, phone, state, issue_date, expiry_date, is_blocked)
SELECT uuid_generate_v4(), d.id, 'Sample Member', 'Member', 'Pakistani', '35202-1234567-8', '+92-300-0000000', 'Punjab', CURRENT_DATE, CURRENT_DATE + INTERVAL '365 days', FALSE
FROM devices d WHERE d.device_identifier = 'sample-device-001'
ON CONFLICT (app_id) DO NOTHING;

