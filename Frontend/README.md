# Meridian Health — Hospital Appointment & EMR Lite (Frontend)

A frontend-only hospital management UI for a DBMS college PBL project.
Built with plain HTML5, CSS3, JavaScript (ES6+), Bootstrap 5 and Bootstrap Icons —
no build tools, no framework required.

**This project does not create, modify, or connect to any database.**
It is designed to be connected to your existing MySQL database through a backend
API you build separately.

## 1. Folder structure

```
frontend/
  index.html              Landing page
  login.html               Login (role select: Admin / Doctor / Patient)
  register.html             Patient registration
  forgot-password.html      Password reset UI
  admin-dashboard.html      Admin: stats, charts, recent activity
  doctors.html               Admin: doctor management (CRUD UI)
  patients.html               Admin: patient management (CRUD UI)
  departments.html             Admin: department management
  appointments.html             Admin: appointment list, filters, cancel
  book-appointment.html          Patient: appointment booking flow
  doctor-dashboard.html           Doctor: today's & upcoming appointments
  visits.html                      Doctor: visit records (incl. diagnosis)
  prescriptions.html                Doctor: prescription management
  billing.html                       Admin: billing dashboard
  audit-logs.html                     Admin: system activity log
  patient-dashboard.html               Patient: portal (appointments, visits,
                                        prescriptions, bills)
  settings.html                         Profile / password (shared)
  css/
    style.css        All design tokens + shared component styles
  js/
    mockData.js       Mock data (doctors, patients, appointments, etc.)
    api.js             API service layer — this is where you connect your backend
    main.js             Shared UI behavior (sidebar, toasts, validation, filters)
  assets/              (empty — put logos/images here)
```

## 2. How to run in VS Code

1. Open the `frontend/` folder in VS Code.
2. Install the **Live Server** extension (by Ritwick Dey) if you don't have it.
3. Right-click `index.html` → **Open with Live Server**.
4. The site opens at `http://127.0.0.1:5500/index.html` (or similar).

No `npm install` or build step is required — it's plain HTML/CSS/JS.

## 3. Pages at a glance

| Page | Purpose |
|---|---|
| `index.html` | Marketing/landing page with hero, services, departments, CTA |
| `login.html` / `register.html` / `forgot-password.html` | Mock authentication UI only — see Section 5 |
| `admin-dashboard.html` | Stat cards, a Chart.js bar chart, recent appointments & activity |
| `doctors.html`, `patients.html`, `departments.html` | Admin CRUD screens using mock data, with add/edit modals, search, and (for doctors) delete confirmation |
| `appointments.html` | Full appointment list with status filter, search, details modal, cancel |
| `book-appointment.html` | 4-step patient booking flow: department → doctor → date/time → confirm |
| `doctor-dashboard.html` | Doctor's today/upcoming appointments, mark no-show, start visit |
| `visits.html` | Add/edit/view visit records, including diagnosis and treatment notes |
| `prescriptions.html` | Add and list prescriptions per patient |
| `billing.html` | Billing dashboard with totals, bill list, add bill, print UI |
| `audit-logs.html` | Read-only system activity log with filters |
| `patient-dashboard.html` | Patient's own appointments, visit history, prescriptions, bills |
| `settings.html` | Profile and password forms (shared by all roles) |

## 4. Mock data → real API

All dummy data lives in **`js/mockData.js`**, in a single `MOCK` object, completely
separate from the HTML/UI code. Every page reads from `MOCK.*` on load, e.g.:

```js
let doctors = [...MOCK.doctors];
```

**`js/api.js`** is the only file you should need to touch to connect a real
backend. It defines a generic `apiGet/apiPost/apiPut/apiDelete` helper (fetch
wrapped, currently mocked) and domain services (`DoctorService`,
`PatientService`, `AppointmentService`, `VisitService`, `PrescriptionService`,
`BillingService`, `AuditService`, `AuthService`).

To connect a real endpoint, uncomment the `apiGet(...)` line inside the
relevant service function and delete the `return MOCK....` line, e.g. in
`DoctorService.list()`:

```js
async list() {
  return apiGet("/doctors");   // <-- uncomment this
  // return MOCK.doctors;      // <-- remove this
}
```

Then update `API_BASE_URL` at the top of `js/api.js` to point at your real
backend (e.g. `http://localhost:8000/api`).

Every HTML page already calls these service functions (not raw fetch calls),
so swapping the implementation in `api.js` updates every page automatically.

## 5. What still needs a real backend

This frontend intentionally does **not** implement:

- Real authentication or password hashing (`login.html`/`register.html` use
  `AuthService.login()`, a mock that always "succeeds")
- Role-based authorization — the sidebar links are UI-only; a user could type
  any URL directly. **Enforce real access control on the backend.**
- Appointment slot availability / double-booking prevention — must be
  validated server-side in `AppointmentService.book()`
- Real audit logging — `audit-logs.html` only displays log rows; actual
  tamper-resistant logging belongs in your database/backend
- Payment processing — `billing.html` has no payment gateway integration
- Input sanitization against SQL injection — always use parameterized
  queries / an ORM on the backend, never trust frontend validation alone

## 6. Design notes

Palette: deep pine green (`--pine-900`/`--pine-800`) for navigation and
headings, a medical teal accent, and a clinical blue for interactive/info
elements — chosen to read as a healthcare product rather than a generic SaaS
dashboard. Headings use "Fraunces" (serif) for a calmer, more clinical feel;
body and UI text use "Inter" for legibility in dense tables. All colors,
spacing and component styles are centralized in `css/style.css` as CSS custom
properties, so re-theming the whole app means editing one file.
