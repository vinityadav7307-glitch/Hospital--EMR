USE hospital_emr;

-- 1. All patients
SELECT * FROM patient;

-- 2. Active doctors with departments
SELECT d.id, d.doctor_name, dp.department_name, d.specialisation
FROM doctor d JOIN department dp ON dp.id=d.department_id
WHERE d.is_active=TRUE;

-- 3. Appointments with readable slot labels
SELECT a.id, p.patient_name, d.doctor_name, a.appointment_date,
       ts.slot_label, a.status
FROM appointment a
JOIN patient p ON p.id=a.patient_id
JOIN doctor d ON d.id=a.doctor_id
JOIN time_slot ts ON ts.id=a.slot_id
ORDER BY a.appointment_date, ts.start_time;

-- 4. Pending bills
SELECT * FROM billing_summary WHERE payment_status <> 'Paid';

-- 5. Revenue collected
SELECT COALESCE(SUM(total_amount),0) AS total_revenue
FROM bill WHERE payment_status='Paid';

-- 6. Department-wise active doctor count
SELECT dp.department_name, COUNT(d.id) AS active_doctors
FROM department dp LEFT JOIN doctor d
ON d.department_id=dp.id AND d.is_active=TRUE
GROUP BY dp.id, dp.department_name;

-- 7. Patients with more than one visit
SELECT p.patient_name, COUNT(v.id) AS visit_count
FROM patient p JOIN visit v ON v.patient_id=p.id
GROUP BY p.id, p.patient_name HAVING COUNT(v.id)>1;

-- 8. Full medical history (use only for authorized users)
SELECT * FROM patient_history;

-- 9. Audit history of changed medical records
SELECT * FROM audit_log ORDER BY changed_at DESC;

-- 10. Appointment audit history
SELECT * FROM appointment_log ORDER BY changed_at DESC;
