# Hospital Appointment & EMR Lite — DBMS PBL

## Project scope
The canonical database name is `hospital_emr`. All scripts target this same schema. A MySQL 8.0 database for patients, doctors, appointments, visits, diagnoses, prescriptions, billing, audit history and role-based access.

## Execution order
Run the files in MySQL Workbench or the MySQL client in this order:

1. `01_schema.sql`
2. `03_triggers.sql`
3. `04_procedures.sql`
4. `02_seed_data.sql`
5. `05_views.sql`
6. `06_queries.sql`
7. `07_security_roles.sql` (optional; requires role/GRANT privileges)

> The baseline schema is now non-destructive on reruns; it uses CREATE TABLE IF NOT EXISTS and does not drop tables. Existing table definitions are not upgraded by CREATE IF NOT EXISTS; use reviewed numbered migrations for changes. Back up before applying any migration.

## Business-rule coverage
- Unique patient and doctor identifiers: primary keys.
- Doctor department requirement: `doctor.department_id` is mandatory and references `department`.
- Active doctor requirement: appointment triggers/procedure validate active doctors.
- Valid slots: `time_slot` table plus foreign key and trigger.
- No double booking: generated active keys and unique constraints prevent a doctor or patient from having two active appointments in the same date/slot.
- Visit validity: a visit must match a completed appointment and cannot be duplicated for the same appointment.
- Authorized clinical entry: clinical users are linked to doctors; triggers validate authorized users for visits, diagnoses and prescriptions.
- Prescription completeness: medicine, dosage, frequency and duration are mandatory.
- Positive billing items: quantity and unit price have `CHECK` constraints; bill totals are recalculated by triggers.
- Audit history: diagnosis/prescription updates and appointment changes are logged.
- Privacy: restricted views and optional MySQL roles are included. Production systems should also use application authentication, encryption, backups and formal access reviews.

## Demonstration commands
```sql
CALL AddPatient('Neha Singh','Female','2002-03-10','9955555555','Bhopal, MP');
CALL AddAppointment(5,3,'2026-09-28',1);
SELECT * FROM doctor_schedule;
SELECT * FROM patient_history;
SELECT * FROM audit_log;
```

## Important note
Database triggers enforce core rules, but complete privacy in a real hospital requires secure application login, least-privilege accounts, encryption and operational controls in addition to this database design.
