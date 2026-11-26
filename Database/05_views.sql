USE hospital_emr;

CREATE OR REPLACE VIEW doctor_schedule AS
SELECT a.id AS appointment_id, d.doctor_name, p.patient_name,
       a.appointment_date, ts.slot_label, a.status
FROM appointment a
JOIN doctor d ON d.id=a.doctor_id
JOIN patient p ON p.id=a.patient_id
JOIN time_slot ts ON ts.id=a.slot_id;

CREATE OR REPLACE VIEW patient_history AS
SELECT p.id AS patient_id, p.patient_name, v.id AS visit_id, v.visit_date,
       d.doctor_name, dg.diagnosis_name, pr.medicine_name, pr.dosage,
       pr.frequency, pr.duration
FROM patient p
JOIN visit v ON v.patient_id=p.id
JOIN doctor d ON d.id=v.doctor_id
LEFT JOIN diagnosis dg ON dg.visit_id=v.id
LEFT JOIN prescription pr ON pr.visit_id=v.id;

CREATE OR REPLACE VIEW billing_summary AS
SELECT b.id AS bill_id, p.patient_name, d.doctor_name,
       b.total_amount, b.payment_status
FROM bill b
JOIN visit v ON v.id=b.visit_id
JOIN patient p ON p.id=v.patient_id
JOIN doctor d ON d.id=v.doctor_id;

-- Restricted medical view: expose only minimum necessary fields.
CREATE OR REPLACE VIEW authorized_medical_summary AS
SELECT v.id AS visit_id, v.patient_id, v.visit_date, v.doctor_id,
       d.doctor_name, v.notes
FROM visit v JOIN doctor d ON d.id=v.doctor_id;
