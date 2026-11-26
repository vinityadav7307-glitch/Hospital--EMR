/* =========================================================
   MOCK DATA
   This file stands in for your MySQL database until the
   backend API (see js/api.js) is connected.
   TODO: Delete this file's usages once real API responses
   are wired up on each page.
   ========================================================= */

const MOCK = {

  departments: [
    { id: "D-01", name: "Cardiology", doctors: 4, description: "Heart & vascular care" },
    { id: "D-02", name: "Orthopedics", doctors: 3, description: "Bones, joints & muscles" },
    { id: "D-03", name: "Pediatrics", doctors: 5, description: "Child & adolescent care" },
    { id: "D-04", name: "Dermatology", doctors: 2, description: "Skin, hair & nails" },
    { id: "D-05", name: "Neurology", doctors: 3, description: "Brain & nervous system" },
    { id: "D-06", name: "General Medicine", doctors: 6, description: "Primary & preventive care" },
  ],

  doctors: [
    { id: "DOC-101", name: "Dr. Ananya Rao", department: "Cardiology", specialization: "Interventional Cardiology", email: "ananya.rao@meridian.health", phone: "+91 98450 11221", status: "Active" },
    { id: "DOC-102", name: "Dr. Vikram Sethi", department: "Orthopedics", specialization: "Joint Replacement", email: "vikram.sethi@meridian.health", phone: "+91 98450 11332", status: "Active" },
    { id: "DOC-103", name: "Dr. Meera Iyer", department: "Pediatrics", specialization: "Neonatal Care", email: "meera.iyer@meridian.health", phone: "+91 98450 11443", status: "Active" },
    { id: "DOC-104", name: "Dr. Farhan Sheikh", department: "Dermatology", specialization: "Cosmetic Dermatology", email: "farhan.sheikh@meridian.health", phone: "+91 98450 11554", status: "On Leave" },
    { id: "DOC-105", name: "Dr. Kavita Nair", department: "Neurology", specialization: "Stroke & Epilepsy", email: "kavita.nair@meridian.health", phone: "+91 98450 11665", status: "Active" },
    { id: "DOC-106", name: "Dr. Rohit Malhotra", department: "General Medicine", specialization: "Internal Medicine", email: "rohit.malhotra@meridian.health", phone: "+91 98450 11776", status: "Active" },
  ],

  patients: [
    { id: "PAT-2001", name: "Sanjay Kulkarni", dob: "1988-04-12", gender: "Male", phone: "+91 90210 55321", email: "sanjay.k@example.com", address: "MG Road, Pune" },
    { id: "PAT-2002", name: "Priya Deshmukh", dob: "1995-11-02", gender: "Female", phone: "+91 90210 55432", email: "priya.d@example.com", address: "Baner, Pune" },
    { id: "PAT-2003", name: "Arjun Menon", dob: "1979-07-23", gender: "Male", phone: "+91 90210 55543", email: "arjun.m@example.com", address: "Kothrud, Pune" },
    { id: "PAT-2004", name: "Neha Kapoor", dob: "2001-01-30", gender: "Female", phone: "+91 90210 55654", email: "neha.k@example.com", address: "Viman Nagar, Pune" },
    { id: "PAT-2005", name: "Imran Qureshi", dob: "1966-09-15", gender: "Male", phone: "+91 90210 55765", email: "imran.q@example.com", address: "Hadapsar, Pune" },
  ],

  appointments: [
    { id: "APT-3001", patient: "Sanjay Kulkarni", doctor: "Dr. Ananya Rao", department: "Cardiology", date: "2026-09-22", time: "10:00 AM", reason: "Chest discomfort follow-up", status: "Confirmed" },
    { id: "APT-3002", patient: "Priya Deshmukh", doctor: "Dr. Meera Iyer", department: "Pediatrics", date: "2026-09-22", time: "11:30 AM", reason: "Vaccination", status: "Scheduled" },
    { id: "APT-3003", patient: "Arjun Menon", doctor: "Dr. Vikram Sethi", department: "Orthopedics", date: "2026-09-21", time: "09:15 AM", reason: "Knee pain", status: "Completed" },
    { id: "APT-3004", patient: "Neha Kapoor", doctor: "Dr. Kavita Nair", department: "Neurology", date: "2026-09-23", time: "02:00 PM", reason: "Migraine evaluation", status: "Scheduled" },
    { id: "APT-3005", patient: "Imran Qureshi", doctor: "Dr. Rohit Malhotra", department: "General Medicine", date: "2026-09-20", time: "04:30 PM", reason: "Annual check-up", status: "No-show" },
    { id: "APT-3006", patient: "Sanjay Kulkarni", doctor: "Dr. Rohit Malhotra", department: "General Medicine", date: "2026-09-19", time: "03:00 PM", reason: "Fever", status: "Cancelled" },
  ],

  visits: [
    { id: "VIS-4001", appointmentId: "APT-3003", patient: "Arjun Menon", doctor: "Dr. Vikram Sethi", date: "2026-09-21", chiefComplaint: "Right knee pain on stairs", diagnosis: "Early-stage osteoarthritis", notes: "Advised physiotherapy, review in 3 weeks.", followUp: "2026-10-12" },
    { id: "VIS-4002", appointmentId: "APT-3005", patient: "Imran Qureshi", doctor: "Dr. Rohit Malhotra", date: "2026-09-20", chiefComplaint: "Routine annual check-up", diagnosis: "Mild hypertension", notes: "Lifestyle modification advised, recheck BP in 1 month.", followUp: "2026-10-20" },
  ],

  prescriptions: [
    { id: "RX-5001", visitId: "VIS-4001", patient: "Arjun Menon", medicine: "Naproxen", dosage: "500mg", frequency: "Twice daily", duration: "10 days", instructions: "Take after food", date: "2026-09-21" },
    { id: "RX-5002", visitId: "VIS-4002", patient: "Imran Qureshi", medicine: "Amlodipine", dosage: "5mg", frequency: "Once daily", duration: "30 days", instructions: "Take in the morning", date: "2026-09-20" },
  ],

  bills: [
    { id: "BILL-6001", visitId: "VIS-4001", patient: "Arjun Menon", amount: 1800, status: "Paid", date: "2026-09-21" },
    { id: "BILL-6002", visitId: "VIS-4002", patient: "Imran Qureshi", amount: 950, status: "Pending", date: "2026-09-20" },
    { id: "BILL-6003", visitId: "VIS-4001", patient: "Arjun Menon", amount: 500, status: "Cancelled", date: "2026-09-18" },
  ],

  auditLogs: [
    { id: "LOG-7001", userId: "ADM-01", action: "CREATE", entityType: "Appointment", entityId: "APT-3004", timestamp: "2026-09-19 09:12" },
    { id: "LOG-7002", userId: "DOC-102", action: "UPDATE", entityType: "Visit", entityId: "VIS-4001", timestamp: "2026-09-21 10:45" },
    { id: "LOG-7003", userId: "ADM-01", action: "DELETE", entityType: "Appointment", entityId: "APT-3006", timestamp: "2026-09-19 16:02" },
    { id: "LOG-7004", userId: "DOC-106", action: "CREATE", entityType: "Prescription", entityId: "RX-5002", timestamp: "2026-09-20 15:40" },
  ],

  timeSlots: ["09:00 AM","09:30 AM","10:00 AM","10:30 AM","11:00 AM","11:30 AM","02:00 PM","02:30 PM","03:00 PM","03:30 PM","04:00 PM"],
};
