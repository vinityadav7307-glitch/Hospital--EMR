USE hospital_emr;

-- Run this file only with an account having permission to create roles/users.
-- These roles are an additional database-level privacy layer.
CREATE ROLE IF NOT EXISTS 'emr_receptionist', 'emr_clinician', 'emr_admin';

GRANT SELECT ON healpoint.doctor TO 'emr_receptionist';
GRANT SELECT ON healpoint.patient TO 'emr_receptionist';
GRANT SELECT, INSERT, UPDATE ON healpoint.appointment TO 'emr_receptionist';
GRANT SELECT ON healpoint.doctor_schedule TO 'emr_receptionist';

GRANT SELECT ON healpoint.patient TO 'emr_clinician';
GRANT SELECT ON healpoint.appointment TO 'emr_clinician';
GRANT SELECT, INSERT, UPDATE ON healpoint.visit TO 'emr_clinician';
GRANT SELECT, INSERT, UPDATE ON healpoint.diagnosis TO 'emr_clinician';
GRANT SELECT, INSERT, UPDATE ON healpoint.prescription TO 'emr_clinician';
GRANT SELECT ON healpoint.patient_history TO 'emr_clinician';
GRANT SELECT ON healpoint.audit_log TO 'emr_clinician';

GRANT ALL PRIVILEGES ON healpoint.* TO 'emr_admin';

-- Example account assignment (create named accounts according to your college lab policy):
-- CREATE USER 'reception_user'@'localhost' IDENTIFIED BY 'ChangeThisStrongPassword!';
-- GRANT 'emr_receptionist' TO 'reception_user'@'localhost';
-- SET DEFAULT ROLE 'emr_receptionist' TO 'reception_user'@'localhost';
