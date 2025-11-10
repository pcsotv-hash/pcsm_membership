# OCR & Image Verification Plan

Objective: verify uploaded member card images against stored DB metadata (issue/expiry) and reduce fee evasion.

## Components
- OCR: Tesseract (English + Urdu datasets as needed).
- Image similarity: perceptual hash (pHash) to detect if the uploaded card matches the issued card photo.
- Metadata checks: parse text for `issue date` and `expiry date`, compare to DB; flag mismatches.

## Flow
1. User uploads card photo via `POST /api/members/{id}/upload-card`.
2. Backend:
   - Store the image in `documents` (type=`member_card_upload`).
   - Run OCR to extract text blocks.
   - Compute pHash and compare with stored `member_card_photo` (or last verified upload).
   - Extract dates via regex; normalize formats.
   - Compare issue/expiry to DB; flag if out-of-date or mismatched.
3. Record results in `audit_logs` and `documents.meta` with `ocr_text`, `phash`, `verified` boolean.
4. Admin dashboard lists flagged uploads for review.

## OCR Notes
- Preprocess images: grayscale, deskew, resize, binarize to improve OCR accuracy.
- Use language-specific models for Urdu; consider RTL text handling.

## pHash Notes
- Compute fixed-size pHash (e.g., 64-bit) for both stored and uploaded images.
- Threshold tuning: acceptable Hamming distance ≤ N (e.g., 10–15) determined empirically.

## Security & Privacy
- Encrypt sensitive image blobs at rest (column-level or filesystem-level encryption).
- Restrict access to documents via role-based API.

