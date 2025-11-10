# Membership App + Website Wireframes (Textual)

## Top Member Card (Header)
- Member photo (left), name, designation
- Issued date and expiry date (clearly visible)
- Dynamic QR (logo-embedded; scannable) with small settings/QR button to view details
- Language toggle: `Urdu | English | Pashto` (prominent)
- Theme toggle: `Light | Dark`
- No balance shown anywhere (explicitly removed)

Layout (desktop/tablet):
- Row: [Photo] [Name/Designation + Issue/Expiry] [QR]
- Below row: Notice if expired: "Membership expired — limited access"

## Main Area (Two Columns)

### Left: New Member Form
- Large rounded button with icon `user-plus` (or form icon) + text "New Member"
- Nationality selector: `Pakistani | Other`
- If Pakistani: CNIC field; else: Passport/ID field
- Personal details: Name, Father/Husband Name, Designation, State/Province, District, Tehsil, Address, Phone, Email
- Issue date, expiry date (auto or admin-provided)
- Payment options: JazzCash, EasyPaisa, Fallback manual transfer
- Uploads: CNIC front/back (Pakistani), Passport/ID image (Other)
- Submit button
- Downloadable docs section below form: Manshoor, Candidate list, Terms

### Right: Existing Member Actions
- Large rounded button with icon `id-card` or `user-check` + text "Existing Member"
- Search/lookup: Member ID or CNIC/Passport
- Upload card image: Issue/expiry screenshot/photo
- Show current membership status (active/expired/blocked)
- Actions: Renew, Update details, Contact support
- Contact us block (below right column): Social links, helpline phone, office location

## Mobile Wireframe (Portrait)
- Header: Photo, name/designation, issue & expiry, QR, settings/QR details button
- Language chooser visible; RTL layout when Urdu is selected
- Primary action buttons: stacked, large rounded with icons
- Tabs/sections: `New Member` | `Existing Member` | `Downloads` | `Contact`
- New Member: stacked sections with nationality logic and uploads
- Existing Member: search, status, upload card image (OCR/verification)
- Downloads: static file links
- Contact: social links, phone, map location

## Admin Dashboard (Brief)
- Members list with filters (state-wise); actions: block/unblock
- Devices list: show device ID, linked accounts; actions: block/unblock
- Payments: status, method, reference/txnId
- Documents: download (CNIC/Passport, card images)

## Notes
- Multi-language labels derived from localization files
- Expiry enforcement: expired → restricted actions, show banner
- QR content is dynamic via signed payload; regenerate on detail change
