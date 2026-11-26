USE hospital_emr;

INSERT INTO department (department_name) VALUES
('Cardiology'), ('Orthopedics'), ('General Medicine'), ('Pediatrics');

INSERT INTO doctor (department_id, doctor_name, specialisation, phone) VALUES
(1, 'Dr. A. Sharma', 'Cardiologist', '9800000001'),
(2, 'Dr. R. Verma', 'Orthopedic Surgeon', '9800000002'),
(3, 'Dr. S. Iyer', 'General Physician', '9800000003'),
(4, 'Dr. P. Nair', 'Pediatrician', '9800000004');

INSERT INTO patient (patient_name, gender, date_of_birth, phone, address) VALUES
('Vinit Yadav','Male','2004-05-12','9911111111','Gwalior, MP'),
('Rishu Gupta','Male','2003-11-02','9922222222','Gwalior, MP'),
('Sudhanshu Kumar','Male','2004-01-20','9933333333','Gwalior, MP'),
('Anita Rao','Female','1998-07-15','9944444444','Indore, MP');

INSERT INTO time_slot (slot_label, start_time, end_time) VALUES
('09:00-09:30','09:00:00','09:30:00'),
('09:30-10:00','09:30:00','10:00:00'),
('10:00-10:30','10:00:00','10:30:00'),
('10:30-11:00','10:30:00','11:00:00'),
('11:00-11:30','11:00:00','11:30:00'),
('12:00-12:30','12:00:00','12:30:00');

INSERT INTO role (role_name) VALUES ('ADMIN'), ('DOCTOR'), ('RECEPTIONIST');
-- Required by patient self-registration; appended to preserve existing role IDs.
INSERT IGNORE INTO role (role_name) VALUES ('PATIENT');
INSERT INTO app_user (username, full_name) VALUES
('admin1','Hospital Administrator'), ('doctor1','Dr. A. Sharma'),
('doctor2','Dr. R. Verma'), ('reception1','Front Desk User');
INSERT INTO user_role (user_id, role_id) VALUES (1,1),(2,2),(3,2),(4,3);
INSERT INTO clinical_user (user_id, doctor_id) VALUES (2,1),(3,2);

INSERT INTO appointment (patient_id, doctor_id, appointment_date, slot_id, status) VALUES
(1,1,'2026-09-25',3,'Scheduled'),
(2,2,'2026-09-25',5,'Scheduled'),
(3,3,'2026-09-26',2,'Scheduled'),
(4,4,'2026-09-26',6,'Cancelled');

-- Marking appointment 1 completed allows a visit to be recorded.
UPDATE appointment SET status = 'Completed' WHERE id = 1;

INSERT INTO visit (appointment_id, patient_id, doctor_id, visit_date, notes, created_by_user_id)
VALUES (1,1,1,'2026-09-25','Routine cardiac checkup, BP normal.',2);

INSERT INTO diagnosis (visit_id, diagnosis_name, remarks, created_by_user_id)
VALUES (1,'Hypertension - Mild','Monitor BP weekly',2);

INSERT INTO prescription (visit_id, medicine_name, dosage, frequency, duration, instructions, created_by_user_id)
VALUES (1,'Amlodipine','5mg','Once daily','30 days','Take after breakfast',2);

INSERT INTO bill (visit_id, total_amount, payment_status) VALUES (1,0.00,'Pending');
INSERT INTO bill_item (bill_id, item_description, quantity, unit_price) VALUES
(1,'Consultation',1,500.00), (1,'Diagnostic service',1,300.00);
UPDATE bill b SET total_amount = (SELECT COALESCE(SUM(amount),0) FROM bill_item bi WHERE bi.bill_id=b.id) WHERE b.id=1;
UPDATE bill SET payment_status='Paid' WHERE id=1;
