-- =========================================================
-- HealPoint — Migration V2 (revised per Mishra's corrections)
-- Adds: RBAC normalization, staff management, custom roles,
--       attendance, doctor schedule/leave, payments (with
--       retryable attempts), refunds, notifications,
--       appointment approval history, nurse-patient assignment.
--
-- SAFETY:
--   - No DROP TABLE, no DELETE, no data loss. All existing
--     tables, triggers, procedures and views are untouched.
--   - MySQL 8.0.29+ (uses IF NOT EXISTS on CREATE/ALTER). On
--     older 8.0.x builds, drop "IF NOT EXISTS" from the ALTER
--     TABLE lines and run each block once manually.
--   - Assumes 01_schema.sql is run AFTER the one-line
--     trailing-comma fix in `patient` (noted at the bottom).
--   - NOT EXECUTED. Review in staging first.
-- =========================================================

USE hospital_emr;

-- =========================================================
-- SECTION 1 — Authentication: credential storage on app_user
-- =========================================================
ALTER TABLE app_user
    ADD COLUMN IF NOT EXISTS email VARCHAR(120) NULL,
    ADD COLUMN IF NOT EXISTS phone VARCHAR(15) NULL,
    ADD COLUMN IF NOT EXISTS password_hash VARCHAR(255) NULL,
    ADD COLUMN IF NOT EXISTS password_algo VARCHAR(30) NOT NULL DEFAULT 'bcrypt',
    ADD COLUMN IF NOT EXISTS password_updated_at TIMESTAMP NULL,
    ADD COLUMN IF NOT EXISTS failed_login_attempts INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS locked_until TIMESTAMP NULL,
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE app_user
    ADD UNIQUE INDEX IF NOT EXISTS uq_app_user_email (email);

-- =========================================================
-- SECTION 2 — Normalized RBAC
-- =========================================================
ALTER TABLE role
    ADD COLUMN IF NOT EXISTS is_system BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS description VARCHAR(255) NULL,
    ADD COLUMN IF NOT EXISTS created_by_user_id INT NULL,
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ADD CONSTRAINT fk_role_created_by FOREIGN KEY IF NOT EXISTS (created_by_user_id)
        REFERENCES app_user(id);

-- A custom/manual role is a `role` row with is_system = FALSE.
-- It starts with ZERO rows in role_permission. Only an admin
-- action (enforced in the Phase 4 service layer, never implicit)
-- may insert role_permission rows for it. No role inherits
-- permissions from another role — every grant is an explicit row.

CREATE TABLE IF NOT EXISTS permission (
    id INT AUTO_INCREMENT PRIMARY KEY,
    permission_key VARCHAR(80) NOT NULL UNIQUE,
    description VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS role_permission (
    role_id INT NOT NULL,
    permission_id INT NOT NULL,
    granted_by_user_id INT NULL,
    granted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (role_id, permission_id),
    FOREIGN KEY (role_id) REFERENCES role(id),
    FOREIGN KEY (permission_id) REFERENCES permission(id),
    FOREIGN KEY (granted_by_user_id) REFERENCES app_user(id)
);

-- Permission catalogue. VIEW_ALL_MEDICAL_RECORDS is seeded here
-- but intentionally never appears in any role_permission seed row
-- below — no role, including ADMIN, gets it by default, and no
-- future authorization code should special-case ADMIN around it.
INSERT IGNORE INTO permission (permission_key, description) VALUES
('VIEW_ALL_STAFF','View all staff records'),
('MANAGE_STAFF','Add, edit, deactivate staff'),
('MANAGE_DOCTORS','Add, edit, deactivate doctors'),
('MANAGE_DEPARTMENTS','Manage departments'),
('MARK_ATTENDANCE','Mark staff/doctor attendance'),
('VIEW_ATTENDANCE','View attendance records'),
('VIEW_DOCTOR_SCHEDULE','View doctor schedules/availability'),
('MANAGE_OWN_SCHEDULE','Doctor manages own schedule/leave'),
('APPROVE_APPOINTMENTS','Approve or reject appointments'),
('BOOK_APPOINTMENT','Patient books an appointment'),
('VIEW_OWN_APPOINTMENTS','View only own appointments'),
('VIEW_ALL_APPOINTMENTS','View all appointments'),
('CREATE_VISIT','Create a visit record'),
('VIEW_OWN_PATIENT_RECORDS','Doctor views records for own authorized patients (via clinical_user)'),
('VIEW_ASSIGNED_PATIENTS','Nurse views the list of patients currently assigned to them'),
('VIEW_ASSIGNED_PATIENT_RECORDS','Nurse views clinical records for currently-assigned patients only'),
('VIEW_OWN_MEDICAL_RECORDS','Patient views own records only'),
('VIEW_ALL_MEDICAL_RECORDS','Unrestricted clinical record access — granted to nobody by default'),
('CREATE_DIAGNOSIS','Add diagnosis'),
('CREATE_PRESCRIPTION','Add prescription'),
('MANAGE_BILLING','Create/update bills'),
('VIEW_BILLING','View billing records'),
('PROCESS_PAYMENT','Record/initiate a payment attempt'),
('PROCESS_REFUND','Approve/process a refund'),
('VIEW_AUDIT_LOGS','View audit logs'),
('MANAGE_SYSTEM_SETTINGS','Manage system settings'),
('ASSIGN_PATIENT_TO_NURSE','Assign or unassign a patient to/from a nurse'),
('MANAGE_PRESCRIPTION_FULFILLMENT','Pharmacist manages fulfillment of existing prescriptions');

-- =========================================================
-- SECTION 3 — Staff management (1-to-1 with app_user)
-- =========================================================
CREATE TABLE IF NOT EXISTS staff (
    id INT AUTO_INCREMENT PRIMARY KEY,
    app_user_id INT NOT NULL UNIQUE,   -- UNIQUE enforces strict 1-to-1 with app_user
    staff_code VARCHAR(20) NOT NULL UNIQUE,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(120) NULL,
    phone VARCHAR(15) NULL,
    department_id INT NULL,
    joining_date DATE NOT NULL,
    employment_status ENUM('ACTIVE','ON_LEAVE','INACTIVE','TERMINATED') NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (app_user_id) REFERENCES app_user(id),
    FOREIGN KEY (department_id) REFERENCES department(id)
);

ALTER TABLE doctor
    ADD COLUMN IF NOT EXISTS staff_id INT NULL,
    ADD COLUMN IF NOT EXISTS consultation_fee DECIMAL(10,2) NOT NULL DEFAULT 500.00,
    ADD CONSTRAINT fk_doctor_staff FOREIGN KEY IF NOT EXISTS (staff_id) REFERENCES staff(id);
-- staff_id stays NULL for most doctors; only used if a doctor also
-- needs HR/attendance tracked through the staff table.

-- =========================================================
-- SECTION 4 — Attendance
-- =========================================================
CREATE TABLE IF NOT EXISTS attendance (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    app_user_id INT NOT NULL,
    attendance_date DATE NOT NULL,
    status ENUM('PRESENT','ABSENT','LEAVE','HALF_DAY') NOT NULL,
    check_in_time TIME NULL,
    check_out_time TIME NULL,
    marked_by_user_id INT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (app_user_id) REFERENCES app_user(id),
    FOREIGN KEY (marked_by_user_id) REFERENCES app_user(id),
    UNIQUE KEY uq_attendance_user_date (app_user_id, attendance_date)
);

-- =========================================================
-- SECTION 5 — Doctor schedule & leave
-- VERIFIED against existing 01_schema.sql: time_slot(id,
-- slot_label, start_time, end_time, is_active) is a single
-- global catalog of time bands, not per-doctor. doctor_schedule
-- below correctly maps doctor + day_of_week onto that existing
-- catalog via slot_id -> time_slot(id); no change to time_slot
-- itself is needed or made.
-- =========================================================
CREATE TABLE IF NOT EXISTS doctor_schedule (
    id INT AUTO_INCREMENT PRIMARY KEY,
    doctor_id INT NOT NULL,
    day_of_week TINYINT NOT NULL,            -- 0=Sunday ... 6=Saturday
    slot_id INT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (doctor_id) REFERENCES doctor(id),
    FOREIGN KEY (slot_id) REFERENCES time_slot(id),
    CONSTRAINT chk_day_of_week CHECK (day_of_week BETWEEN 0 AND 6),
    UNIQUE KEY uq_doctor_day_slot (doctor_id, day_of_week, slot_id)
);

CREATE TABLE IF NOT EXISTS doctor_leave (
    id INT AUTO_INCREMENT PRIMARY KEY,
    doctor_id INT NOT NULL,
    leave_date DATE NOT NULL,
    leave_type ENUM('LEAVE','ABSENT','UNAVAILABLE') NOT NULL DEFAULT 'LEAVE',
    reason VARCHAR(255) NULL,
    requested_by_user_id INT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (doctor_id) REFERENCES doctor(id),
    FOREIGN KEY (requested_by_user_id) REFERENCES app_user(id),
    UNIQUE KEY uq_doctor_leave_date (doctor_id, leave_date)
);

-- =========================================================
-- SECTION 6 — Appointment workflow
-- =========================================================
ALTER TABLE appointment
    MODIFY COLUMN status ENUM('Pending','Approved','Rejected','Completed','Cancelled','No-Show')
        NOT NULL DEFAULT 'Pending';

-- fee_amount is a historical snapshot of the doctor's consultation
-- fee AT BOOKING TIME. It must never be recalculated from
-- doctor.consultation_fee after the fact, even if the doctor's
-- rate changes later — that would corrupt past invoices/refunds.
ALTER TABLE appointment
    ADD COLUMN IF NOT EXISTS fee_amount DECIMAL(10,2) NOT NULL DEFAULT 500.00;

CREATE TABLE IF NOT EXISTS appointment_approval (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT NOT NULL,
    action ENUM('APPROVED','REJECTED','CANCELLED') NOT NULL,
    performed_by_user_id INT NOT NULL,
    reason VARCHAR(255) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (appointment_id) REFERENCES appointment(id),
    FOREIGN KEY (performed_by_user_id) REFERENCES app_user(id)
);

-- =========================================================
-- SECTION 7 — Payments (with retryable attempts) & refunds
--
-- REVISED DESIGN: `payment` is the single logical charge tied to
-- one appointment (UNIQUE appointment_id stays — an appointment
-- has exactly one fee to collect). Every individual gateway call
-- — success, failure, or retry — is its own row in
-- `payment_attempt`, so a failed attempt never blocks a retry and
-- never requires deleting/overwriting a prior row. `payment.status`
-- reflects the net outcome and is kept in sync by trigger from the
-- latest attempt. `refund` references `payment`, never
-- `payment_attempt` — refunds and payment attempts are fully
-- separate concerns.
-- =========================================================
CREATE TABLE IF NOT EXISTS payment (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT NOT NULL UNIQUE,
    amount DECIMAL(10,2) NOT NULL,
    currency CHAR(3) NOT NULL DEFAULT 'INR',
    status ENUM('PENDING','INITIATED','PAID','FAILED','REFUND_PENDING','PARTIALLY_REFUNDED','REFUNDED')
        NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_payment_amount CHECK (amount > 0),
    FOREIGN KEY (appointment_id) REFERENCES appointment(id)
);

CREATE TABLE IF NOT EXISTS payment_attempt (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    payment_id BIGINT NOT NULL,
    attempt_no INT NOT NULL,
    gateway VARCHAR(50) NOT NULL DEFAULT 'SANDBOX',
    gateway_reference VARCHAR(100) NULL UNIQUE,
    idempotency_key VARCHAR(100) NOT NULL UNIQUE,
    status ENUM('INITIATED','PAID','FAILED') NOT NULL DEFAULT 'INITIATED',
    failure_reason VARCHAR(255) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (payment_id) REFERENCES payment(id),
    UNIQUE KEY uq_payment_attempt_no (payment_id, attempt_no)
);

DELIMITER $$

-- Keep payment.status synced with its latest attempt outcome.
DROP TRIGGER IF EXISTS after_payment_attempt_change$$
CREATE TRIGGER after_payment_attempt_change
AFTER INSERT ON payment_attempt
FOR EACH ROW
BEGIN
    UPDATE payment
    SET status = CASE NEW.status
            WHEN 'PAID' THEN 'PAID'
            WHEN 'FAILED' THEN 'FAILED'
            ELSE 'INITIATED'
        END
    WHERE id = NEW.payment_id;
END$$

DROP TRIGGER IF EXISTS after_payment_attempt_update$$
CREATE TRIGGER after_payment_attempt_update
AFTER UPDATE ON payment_attempt
FOR EACH ROW
BEGIN
    UPDATE payment
    SET status = CASE NEW.status
            WHEN 'PAID' THEN 'PAID'
            WHEN 'FAILED' THEN 'FAILED'
            ELSE 'INITIATED'
        END
    WHERE id = NEW.payment_id;
END$$

DELIMITER ;

CREATE TABLE IF NOT EXISTS refund (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    payment_id BIGINT NOT NULL,
    attempt_no INT NOT NULL DEFAULT 1,
    original_amount DECIMAL(10,2) NOT NULL,
    deduction_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    refund_amount DECIMAL(10,2) NOT NULL,
    reason VARCHAR(255) NULL,
    status ENUM('PENDING','PROCESSING','COMPLETED','FAILED') NOT NULL DEFAULT 'PENDING',
    gateway_reference VARCHAR(100) NULL UNIQUE,
    idempotency_key VARCHAR(100) NOT NULL UNIQUE,
    requested_by_user_id INT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_refund_amount CHECK (refund_amount >= 0 AND refund_amount <= original_amount),
    FOREIGN KEY (payment_id) REFERENCES payment(id),
    FOREIGN KEY (requested_by_user_id) REFERENCES app_user(id),
    UNIQUE KEY uq_refund_payment_attempt (payment_id, attempt_no)
);
-- refund_amount is ALWAYS computed server-side (Phase 8 service
-- layer) from refund_policy + payment.amount. No controller may
-- accept a client-supplied refund_amount and store it verbatim.

-- Configurable cancellation-window policy. unit now explicitly
-- supports day-based or hour-based windows per Mishra's correction.
CREATE TABLE IF NOT EXISTS refund_policy (
    id INT AUTO_INCREMENT PRIMARY KEY,
    window_value INT NOT NULL,                 -- e.g. 1, 2, 24, 48
    unit ENUM('CALENDAR_DAYS','HOURS') NOT NULL DEFAULT 'CALENDAR_DAYS',
    deduction_percent DECIMAL(5,2) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE KEY uq_refund_policy_window (window_value, unit)
);
INSERT IGNORE INTO refund_policy (window_value, unit, deduction_percent) VALUES
(1, 'CALENDAR_DAYS', 10.00),
(2, 'CALENDAR_DAYS', 5.00);

-- System-wide config, starting with the hospital's timezone.
-- All "N days/hours before appointment" math in the Java service
-- layer must be done using this zone (Asia/Kolkata by default),
-- not the server JVM's default zone or the DB session zone.
CREATE TABLE IF NOT EXISTS system_setting (
    setting_key VARCHAR(80) NOT NULL PRIMARY KEY,
    setting_value VARCHAR(255) NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
INSERT IGNORE INTO system_setting (setting_key, setting_value) VALUES
('HOSPITAL_TIMEZONE', 'Asia/Kolkata');

DELIMITER $$

-- Prevent over-refunding regardless of what the caller requests.
DROP TRIGGER IF EXISTS before_refund_insert$$
CREATE TRIGGER before_refund_insert
BEFORE INSERT ON refund
FOR EACH ROW
BEGIN
    DECLARE v_already_refunded DECIMAL(10,2);
    SELECT COALESCE(SUM(refund_amount), 0) INTO v_already_refunded
    FROM refund
    WHERE payment_id = NEW.payment_id AND status IN ('COMPLETED','PROCESSING');

    IF (v_already_refunded + NEW.refund_amount) > NEW.original_amount THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Refund would exceed the original payment amount';
    END IF;
END$$

DELIMITER ;

-- =========================================================
-- SECTION 8 — Notifications
-- =========================================================
CREATE TABLE IF NOT EXISTS notification (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    app_user_id INT NOT NULL,
    type VARCHAR(50) NOT NULL,
    title VARCHAR(150) NOT NULL,
    message VARCHAR(500) NOT NULL,
    related_entity VARCHAR(50) NULL,
    related_entity_id INT NULL,
    channel ENUM('IN_APP','EMAIL','SMS') NOT NULL DEFAULT 'IN_APP',
    delivery_status ENUM('PENDING','SENT','FAILED','NOT_APPLICABLE') NOT NULL DEFAULT 'PENDING',
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (app_user_id) REFERENCES app_user(id)
);

-- =========================================================
-- SECTION 9 — Nurse-patient assignment
-- NOTE: nurse_staff_id alone is NOT sufficient authorization.
-- The Phase 4+ service layer (and, defense-in-depth, the trigger
-- below) must also confirm: staff.employment_status = 'ACTIVE',
-- the staff's app_user currently holds the NURSE role in
-- user_role, and the assignment row itself is_active = TRUE,
-- before any VIEW_ASSIGNED_PATIENT_RECORDS access is granted.
-- =========================================================
CREATE TABLE IF NOT EXISTS patient_assignment (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nurse_staff_id INT NOT NULL,
    patient_id INT NOT NULL,
    assigned_by_user_id INT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    active_patient_for_nurse INT GENERATED ALWAYS AS
        (CASE WHEN is_active THEN patient_id ELSE NULL END) STORED,
    assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    unassigned_at TIMESTAMP NULL,
    FOREIGN KEY (nurse_staff_id) REFERENCES staff(id),
    FOREIGN KEY (patient_id) REFERENCES patient(id),
    FOREIGN KEY (assigned_by_user_id) REFERENCES app_user(id),
    UNIQUE KEY uq_nurse_active_patient (nurse_staff_id, active_patient_for_nurse)
);

DELIMITER $$

-- Defense-in-depth: reject the assignment at the DB layer if the
-- staff row is not an active, currently-NURSE-roled account. This
-- does NOT replace the service-layer checks Mishra specified —
-- it's a second, independent guard against a bug upstream.
DROP TRIGGER IF EXISTS before_patient_assignment_insert$$
CREATE TRIGGER before_patient_assignment_insert
BEFORE INSERT ON patient_assignment
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM staff s
        JOIN user_role ur ON ur.user_id = s.app_user_id
        JOIN role r ON r.id = ur.role_id
        WHERE s.id = NEW.nurse_staff_id
          AND s.employment_status = 'ACTIVE'
          AND r.role_name = 'NURSE'
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Assignment requires an active staff account currently holding the NURSE role';
    END IF;
END$$

DELIMITER ;

-- =========================================================
-- END OF MIGRATION V2
-- =========================================================

-- ---------------------------------------------------------
-- REQUIRED ONE-LINE FIX (apply before running 01_schema.sql,
-- not part of this file, listed here for traceability):
--
--   In 01_schema.sql, table `patient`, remove the trailing
--   comma after:
--     created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
--   so the line reads:
--     created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
--   immediately before the closing ")".
--   01_schema.sql has never executed successfully (this bug
--   blocks it), so this is a direct correction to that file,
--   not a migration against live data.
-- ---------------------------------------------------------
