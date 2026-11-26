USE hospital_emr;

-- Test 1: this should fail because doctor 1 already has the same active slot/date.
-- CALL AddAppointment(2,1,'2026-09-25',3);

-- Test 2: this should fail because the doctor is inactive/non-existent.
-- CALL AddAppointment(2,99,'2026-09-28',1);

-- Test 3: this should fail because a visit requires a completed appointment.
-- CALL RecordVisit(2,'Attempted invalid visit',2);

-- Test 4: this should fail because bill item values must be positive.
-- INSERT INTO bill_item(bill_id,item_description,quantity,unit_price)
-- VALUES(1,'Invalid item',0,100);

-- Test 5: audit records
SELECT * FROM appointment_log;
SELECT * FROM audit_log;
