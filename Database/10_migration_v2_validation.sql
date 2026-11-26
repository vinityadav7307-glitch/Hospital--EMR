-- =========================================================
-- HealPoint — Migration V2 validation / test script
-- Run AFTER 01_schema.sql (patched) + 02-07 + migration V2,
-- on a staging copy of hospital_emr. Every block is wrapped
-- so it can be run and then rolled back with no side effects.
-- =========================================================

USE hospital_emr;

-- ---------------------------------------------------------
-- TEST 1: staff <-> app_user is strictly 1-to-1
-- ---------------------------------------------------------
START TRANSACTION;
INSERT INTO app_user (username, full_name, email) VALUES ('nurse1','Test Nurse','nurse1@test.local');
SET @uid := LAST_INSERT_ID();
INSERT INTO staff (app_user_id, staff_code, full_name, joining_date)
VALUES (@uid, 'STF-T1', 'Test Nurse', CURRENT_DATE);
-- This second insert MUST fail (duplicate app_user_id):
-- INSERT INTO staff (app_user_id, staff_code, full_name, joining_date)
-- VALUES (@uid, 'STF-T2', 'Test Nurse Duplicate', CURRENT_DATE);
ROLLBACK;

-- ---------------------------------------------------------
-- TEST 2: permission seed has no role_permission row granting
-- VIEW_ALL_MEDICAL_RECORDS to anyone, including ADMIN
-- ---------------------------------------------------------
SELECT COUNT(*) AS should_be_zero
FROM role_permission rp
JOIN permission p ON p.id = rp.permission_id
WHERE p.permission_key = 'VIEW_ALL_MEDICAL_RECORDS';

-- ---------------------------------------------------------
-- TEST 3: custom role starts with zero permissions
-- ---------------------------------------------------------
START TRANSACTION;
INSERT INTO role (role_name, is_system, description) VALUES ('Lab Assistant', FALSE, 'Manual role example');
SET @custom_role_id := LAST_INSERT_ID();
SELECT COUNT(*) AS should_be_zero FROM role_permission WHERE role_id = @custom_role_id;
ROLLBACK;

-- ---------------------------------------------------------
-- TEST 4: payment_attempt allows retries after a failure
-- (one payment row, multiple attempt rows)
-- ---------------------------------------------------------
START TRANSACTION;
-- assumes appointment id 1 exists from 02_seed_data.sql
INSERT INTO payment (appointment_id, amount) VALUES (1, 500.00);
SET @pay_id := LAST_INSERT_ID();
INSERT INTO payment_attempt (payment_id, attempt_no, idempotency_key, status, failure_reason)
VALUES (@pay_id, 1, 'idem-fail-1', 'FAILED', 'card declined (test)');
INSERT INTO payment_attempt (payment_id, attempt_no, idempotency_key, status)
VALUES (@pay_id, 2, 'idem-retry-1', 'PAID');
SELECT status FROM payment WHERE id = @pay_id;   -- expect 'PAID'
ROLLBACK;

-- ---------------------------------------------------------
-- TEST 5: duplicate idempotency_key on payment_attempt is rejected
-- ---------------------------------------------------------
START TRANSACTION;
INSERT INTO payment (appointment_id, amount) VALUES (1, 500.00);
SET @pay_id2 := LAST_INSERT_ID();
INSERT INTO payment_attempt (payment_id, attempt_no, idempotency_key, status)
VALUES (@pay_id2, 1, 'idem-dupe', 'PAID');
-- This MUST fail with a duplicate-key error:
-- INSERT INTO payment_attempt (payment_id, attempt_no, idempotency_key, status)
-- VALUES (@pay_id2, 2, 'idem-dupe', 'PAID');
ROLLBACK;

-- ---------------------------------------------------------
-- TEST 6: refund cannot exceed the original payment amount
-- ---------------------------------------------------------
START TRANSACTION;
INSERT INTO payment (appointment_id, amount, status) VALUES (1, 500.00, 'PAID');
SET @pay_id3 := LAST_INSERT_ID();
INSERT INTO refund (payment_id, attempt_no, original_amount, deduction_amount, refund_amount,
                     idempotency_key, requested_by_user_id)
VALUES (@pay_id3, 1, 500.00, 50.00, 450.00, 'refund-ok-1', 1);
-- This MUST fail (450 + 100 > 500):
-- INSERT INTO refund (payment_id, attempt_no, original_amount, deduction_amount, refund_amount,
--                      idempotency_key, requested_by_user_id)
-- VALUES (@pay_id3, 2, 500.00, 0, 100.00, 'refund-over-1', 1);
ROLLBACK;

-- ---------------------------------------------------------
-- TEST 7: doctor_schedule cannot double-book the same
-- doctor/day/slot combination
-- ---------------------------------------------------------
START TRANSACTION;
INSERT INTO doctor_schedule (doctor_id, day_of_week, slot_id) VALUES (1, 1, 1);
-- This MUST fail (duplicate doctor/day/slot):
-- INSERT INTO doctor_schedule (doctor_id, day_of_week, slot_id) VALUES (1, 1, 1);
ROLLBACK;

-- ---------------------------------------------------------
-- TEST 8: patient_assignment rejects a non-nurse or inactive staff
-- ---------------------------------------------------------
START TRANSACTION;
INSERT INTO app_user (username, full_name) VALUES ('recept_test','Test Receptionist');
SET @ruid := LAST_INSERT_ID();
INSERT INTO staff (app_user_id, staff_code, full_name, joining_date, employment_status)
VALUES (@ruid, 'STF-T3', 'Test Receptionist', CURRENT_DATE, 'ACTIVE');
SET @rstaff_id := LAST_INSERT_ID();
-- @ruid has no NURSE role assigned, so this MUST fail (trigger):
-- INSERT INTO patient_assignment (nurse_staff_id, patient_id, assigned_by_user_id)
-- VALUES (@rstaff_id, 1, 1);
ROLLBACK;

-- ---------------------------------------------------------
-- TEST 9: a second ACTIVE assignment of the same nurse to the
-- same patient is rejected; re-assigning after deactivation is not
-- ---------------------------------------------------------
START TRANSACTION;
INSERT INTO app_user (username, full_name) VALUES ('nurse2','Test Nurse 2');
SET @nuid := LAST_INSERT_ID();
INSERT INTO role (role_name) VALUES ('NURSE_TEST_ONLY');  -- use real 'NURSE' row in practice
INSERT INTO staff (app_user_id, staff_code, full_name, joining_date)
VALUES (@nuid, 'STF-T4', 'Test Nurse 2', CURRENT_DATE);
SET @nstaff_id := LAST_INSERT_ID();
INSERT INTO user_role (user_id, role_id) SELECT @nuid, id FROM role WHERE role_name = 'NURSE_TEST_ONLY';
-- (trigger checks for role_name = 'NURSE' specifically, so this
--  block is illustrative of the uniqueness constraint only —
--  run against the real NURSE-seeded role in staging)
ROLLBACK;

-- ---------------------------------------------------------
-- TEST 10: appointment status widen is backward compatible
-- ---------------------------------------------------------
SELECT status, COUNT(*) FROM appointment GROUP BY status;
-- Expect only the original 4 values present until new workflow
-- code starts writing 'Pending'/'Approved'/'Rejected'.
