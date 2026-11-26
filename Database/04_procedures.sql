USE hospital_emr;
DELIMITER $$

CREATE PROCEDURE AddPatient(
    IN p_name VARCHAR(100), IN p_gender VARCHAR(10), IN p_dob DATE,
    IN p_phone VARCHAR(15), IN p_address VARCHAR(200)
)
BEGIN
    IF p_gender NOT IN ('Male','Female','Other') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Invalid gender';
    END IF;
    INSERT INTO patient(patient_name,gender,date_of_birth,phone,address)
    VALUES(p_name,p_gender,p_dob,p_phone,p_address);
END$$

CREATE PROCEDURE AddAppointment(
    IN p_patient_id INT, IN p_doctor_id INT, IN p_date DATE, IN p_slot_id INT
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM patient WHERE id=p_patient_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Patient does not exist';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM doctor WHERE id=p_doctor_id AND is_active=TRUE) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Doctor is missing or inactive';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM time_slot WHERE id=p_slot_id AND is_active=TRUE) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Invalid time slot';
    END IF;
    INSERT INTO appointment(patient_id,doctor_id,appointment_date,slot_id)
    VALUES(p_patient_id,p_doctor_id,p_date,p_slot_id);
END$$

CREATE PROCEDURE RecordVisit(
    IN p_appointment_id INT, IN p_notes VARCHAR(1000), IN p_user_id INT
)
BEGIN
    DECLARE v_patient_id INT;
    DECLARE v_doctor_id INT;
    DECLARE v_date DATE;
    SELECT patient_id,doctor_id,appointment_date INTO v_patient_id,v_doctor_id,v_date
    FROM appointment WHERE id=p_appointment_id AND status='Completed';
    IF v_patient_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Appointment must be completed before visit recording';
    END IF;
    INSERT INTO visit(appointment_id,patient_id,doctor_id,visit_date,notes,created_by_user_id)
    VALUES(p_appointment_id,v_patient_id,v_doctor_id,v_date,p_notes,p_user_id);
END$$

DELIMITER ;
