USE hospital_emr;
DELIMITER $$

CREATE TRIGGER before_doctor_insert
BEFORE INSERT ON doctor
FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT 1 FROM department WHERE id=NEW.department_id AND is_active=TRUE) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Doctor must belong to an active department';
    END IF;
END$$

CREATE TRIGGER before_doctor_update
BEFORE UPDATE ON doctor
FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT 1 FROM department WHERE id=NEW.department_id AND is_active=TRUE) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Doctor must belong to an active department';
    END IF;
END$$

CREATE TRIGGER before_appointment_insert
BEFORE INSERT ON appointment
FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT 1 FROM doctor WHERE id=NEW.doctor_id AND is_active=TRUE) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Appointment requires an active doctor';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM time_slot WHERE id=NEW.slot_id AND is_active=TRUE) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Invalid or inactive time slot';
    END IF;
END$$

CREATE TRIGGER before_appointment_update
BEFORE UPDATE ON appointment
FOR EACH ROW
BEGIN
    IF NEW.status IN ('Scheduled','Completed') AND NOT EXISTS
       (SELECT 1 FROM doctor WHERE id=NEW.doctor_id AND is_active=TRUE) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Appointment requires an active doctor';
    END IF;
END$$

CREATE TRIGGER before_visit_insert
BEFORE INSERT ON visit
FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT 1 FROM appointment WHERE id=NEW.appointment_id
                   AND patient_id=NEW.patient_id AND doctor_id=NEW.doctor_id
                   AND status='Completed') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Visit must match a completed appointment';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM clinical_user cu WHERE cu.user_id=NEW.created_by_user_id
                   AND cu.doctor_id=NEW.doctor_id AND cu.can_edit_records=TRUE
                   AND EXISTS (SELECT 1 FROM app_user au WHERE au.id=cu.user_id AND au.is_active=TRUE)) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Only an authorized clinical user can create a visit';
    END IF;
END$$

CREATE TRIGGER before_diagnosis_insert
BEFORE INSERT ON diagnosis
FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT 1 FROM clinical_user cu JOIN visit v ON v.doctor_id=cu.doctor_id
                   WHERE cu.user_id=NEW.created_by_user_id AND cu.can_edit_records=TRUE AND v.id=NEW.visit_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Only an authorized clinical user can record a diagnosis';
    END IF;
END$$

CREATE TRIGGER before_prescription_insert
BEFORE INSERT ON prescription
FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT 1 FROM clinical_user cu JOIN visit v ON v.doctor_id=cu.doctor_id
                   WHERE cu.user_id=NEW.created_by_user_id AND cu.can_edit_records=TRUE AND v.id=NEW.visit_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Only an authorized clinical user can record a prescription';
    END IF;
END$$

CREATE TRIGGER after_appointment_insert
AFTER INSERT ON appointment
FOR EACH ROW
BEGIN
    INSERT INTO appointment_log(appointment_id,action_type,new_status)
    VALUES(NEW.id,'INSERT',NEW.status);
END$$

CREATE TRIGGER after_appointment_update
AFTER UPDATE ON appointment
FOR EACH ROW
BEGIN
    INSERT INTO appointment_log(appointment_id,action_type,old_status,new_status)
    VALUES(NEW.id,'UPDATE',OLD.status,NEW.status);
END$$

CREATE TRIGGER after_bill_item_insert
AFTER INSERT ON bill_item
FOR EACH ROW
BEGIN
    UPDATE bill SET total_amount=(SELECT COALESCE(SUM(amount),0) FROM bill_item WHERE bill_id=NEW.bill_id)
    WHERE id=NEW.bill_id;
END$$

CREATE TRIGGER after_bill_item_update
AFTER UPDATE ON bill_item
FOR EACH ROW
BEGIN
    UPDATE bill SET total_amount=(SELECT COALESCE(SUM(amount),0) FROM bill_item WHERE bill_id=NEW.bill_id)
    WHERE id=NEW.bill_id;
END$$

CREATE TRIGGER after_bill_item_delete
AFTER DELETE ON bill_item
FOR EACH ROW
BEGIN
    UPDATE bill SET total_amount=(SELECT COALESCE(SUM(amount),0) FROM bill_item WHERE bill_id=OLD.bill_id)
    WHERE id=OLD.bill_id;
END$$

CREATE TRIGGER before_diagnosis_update
BEFORE UPDATE ON diagnosis
FOR EACH ROW
BEGIN
    INSERT INTO audit_log(entity_name,entity_id,action_type,old_value,new_value)
    VALUES('diagnosis',OLD.id,'UPDATE',JSON_OBJECT('diagnosis_name',OLD.diagnosis_name,'remarks',OLD.remarks),JSON_OBJECT('diagnosis_name',NEW.diagnosis_name,'remarks',NEW.remarks));
END$$

CREATE TRIGGER before_prescription_update
BEFORE UPDATE ON prescription
FOR EACH ROW
BEGIN
    INSERT INTO audit_log(entity_name,entity_id,action_type,old_value,new_value)
    VALUES('prescription',OLD.id,'UPDATE',JSON_OBJECT('medicine_name',OLD.medicine_name,'dosage',OLD.dosage,'frequency',OLD.frequency,'duration',OLD.duration),JSON_OBJECT('medicine_name',NEW.medicine_name,'dosage',NEW.dosage,'frequency',NEW.frequency,'duration',NEW.duration));
END$$


CREATE TRIGGER before_diagnosis_delete
BEFORE DELETE ON diagnosis
FOR EACH ROW
BEGIN
    INSERT INTO audit_log(entity_name,entity_id,action_type,old_value)
    VALUES('diagnosis',OLD.id,'DELETE',JSON_OBJECT('diagnosis_name',OLD.diagnosis_name,'remarks',OLD.remarks));
END$$

CREATE TRIGGER before_prescription_delete
BEFORE DELETE ON prescription
FOR EACH ROW
BEGIN
    INSERT INTO audit_log(entity_name,entity_id,action_type,old_value)
    VALUES('prescription',OLD.id,'DELETE',JSON_OBJECT('medicine_name',OLD.medicine_name,'dosage',OLD.dosage,'frequency',OLD.frequency,'duration',OLD.duration));
END$$

DELIMITER ;
