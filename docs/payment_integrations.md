# Payment Integration Specs (JazzCash & EasyPaisa)

Goal: support transaction confirmation for new/renewal membership payments with either JazzCash, EasyPaisa, or manual transfer fallback.

## Common Flow
- Client initiates payment specifying gateway and amount.
- Gateway redirects/callbacks to our webhook: `POST /api/payments/webhook` with signed payload.
- Backend verifies signature, records transaction with `status` (`pending|success|failed`), updates `members.last_payment_id` and `members.state` if applicable.
- Manual transfer fallback: admin creates `payments` row with `method='manual'` and attaches evidence (receipt photo) in `documents`.

## JazzCash
- Endpoint: uses hosted checkout/mobile SDK (reference official docs).
- Required fields: `pp_Amount`, `pp_TxnRefNo`, `pp_SecureHash`, `pp_TxnDateTime`, `pp_TxnType`, etc.
- Webhook verification:
  - Recompute `pp_SecureHash` using JazzCash secret key and payload fields.
  - Compare amounts and reference numbers, ensure idempotency via `unique_reference` in `payments`.
- Record: `gateway='jazzcash'`, `method='wallet'`, store raw payload in `payments.meta`.

## EasyPaisa
- Endpoint: hosted checkout/API (reference official docs).
- Required fields: `amount`, `orderId`, `signature`, `transactionDate`, etc.
- Webhook verification:
  - Verify `signature` against secret using documented algorithm.
  - Use `orderId` for idempotency and `payments.unique_reference`.
- Record: `gateway='easypaisa'`, `method='wallet'`, store raw payload in `payments.meta`.

## Idempotency & Security
- Use `unique_reference` to dedupe incoming webhooks.
- Persist full webhook payload to `payments.meta` (JSON).
- Associate payment with `member_id` either from metadata or via a lookup key (e.g., `orderId` embeds member code).
- Write an audit log entry: `payment_webhook_received`.

## API Contracts
- `POST /api/payments/webhook` Body: `{ gateway: 'jazzcash'|'easypaisa', payload: object }`
- Response: `{ received: true }` (actual member status updated asynchronously after verification).

## Manual Transfer
- Admin or staff records payment:
  - `POST /api/payments/manual` Body: `{ member_id, amount, reference, notes }`
  - Upload receipt via `POST /api/members/{id}/documents`.
- Verification: mark as `success` once evidence is accepted; update member status.

