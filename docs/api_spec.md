# API Specification (REST)

Base URL: `/api`
Auth: bearer tokens for admin; device/app registrations use signed requests.

## Common
- Headers: `Content-Type: application/json`
- Error: `{ error: string, code: string }`

## Health
- GET `/api/health` → `{ status: "ok" }`

## Devices
- POST `/api/devices/register`
  - Body: `{ device_identifier: string, app_id?: string }`
  - Response: `{ id: uuid, device_identifier: string, app_id?: uuid }`
- GET `/api/devices` → list devices
- POST `/api/devices/block`
  - Body: `{ device_identifier: string, reason?: string }`
  - Response: `{ success: true }`
- POST `/api/devices/unblock`
  - Body: `{ device_identifier: string }`
  - Response: `{ success: true }`

## Members
- POST `/api/register` (new member registration; includes device_uuid)
  - Body: `{ device_uuid: string, member: MemberCreate }`
  - Response: `{ member_id: uuid, device_id: uuid }`
- POST `/api/members`
  - Body: `{ app_id: uuid, name: string, father_husband_name?: string, designation?: string, nationality: 'Pakistani'|'Other', cnic?: string, passport_id?: string, phone?: string, email?: string, state?: string, district?: string, tehsil?: string, address?: string, issue_date?: string(YYYY-MM-DD), expiry_date?: string(YYYY-MM-DD) }`
  - Response: `{ id: uuid, app_id: uuid }`
- GET `/api/members/{id}` → member profile
- GET `/api/members`
  - Query: `state?, district?, tehsil?, blocked?, expired?`
  - Response: `[{ id, name, designation, state, expiry_date, is_blocked, is_expired }]`
- POST `/api/members/{id}/block`
  - Body: `{ reason?: string }` → `{ success: true }`
- POST `/api/members/{id}/unblock` → `{ success: true }`
- POST `/api/members/{id}/qr`
  - Body: `{ timestamp?: number }`
  - Response: `{ payload: string, signature: string }` (HMAC-SHA256 over payload)
- POST `/api/members/{id}/card-upload`
  - Body: `multipart/form-data` with `image` (card photo)
  - Response: `{ uploaded: true, verified: boolean }`
- POST `/api/members/{id}/upload-card` (alias; supports OCR verification)
  - Body: `multipart/form-data` with `image`
  - Response: `{ uploaded: true, ocr_text?: string, verified: boolean }`

## Payments
- POST `/api/payments/webhook`
  - Body: `{ gateway: 'jazzcash'|'easypaisa', payload: object }`
  - Response: `{ received: true }`
- POST `/api/payments/jazzcash/initiate`
  - Body: `{ member_id: uuid, amount: number }`
  - Response: JazzCash init fields for client-side checkout
- POST `/api/payments/jazzcash/confirm`
  - Body: `{ member_id: uuid, txn_id: string, status: 'succeeded'|'failed' }`
  - Response: `{ success: boolean }`
- POST `/api/payments/easypaisa/initiate` (similar to JazzCash)
- POST `/api/payments/easypaisa/confirm`
- POST `/api/payments/manual/submit`
  - Body: `{ member_id: uuid, reference: string, amount: number }`
  - Response: `{ status: 'pending' }`

## Website Sync
- GET `/api/public/members`
  - Query: `state?`
  - Response: active (non-blocked, non-expired) members only
- GET `/api/public/members/{id}` → limited profile

## Admin
- GET `/api/admin/members`
  - Filters: `state, blocked, expired`
- GET `/api/admin/devices` → device list with block flags
- POST `/api/admin/devices/block`
- POST `/api/admin/devices/unblock`
- GET `/api/admin/payments`
- GET `/api/admin/documents`

## Security
- Device ID captured on register/login
- Block list enforced at request middleware: blocked device or member returns `403`
- Card upload verification compares extracted issue/expiry with stored DB
- QR signature: `HMAC(secret, JSON.stringify({ member_id, designation, expiry_date, timestamp }))`
  - Verification endpoint: `GET /api/qr/verify?token=...`
    - Token format: `base64url(payload).hex(signature)` separated by `.`
    - Response: `{ valid: boolean, member_id?: uuid, designation?: string, status?: 'active'|'expired'|'blocked' }`

## Status Codes
- 200 OK, 201 Created
- 400 Bad Request (validation)
- 401 Unauthorized (admin)
- 403 Forbidden (blocked)
- 404 Not Found
- 409 Conflict (duplicate)
- 500 Server Error
