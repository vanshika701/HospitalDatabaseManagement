-- Create the database
CREATE DATABASE IF NOT EXISTS hospital_management;
USE hospital_management;

-- First, remove the foreign key constraint
SET FOREIGN_KEY_CHECKS = 0;

-- Drop tables in correct order
DROP TABLE IF EXISTS prescriptions;
DROP TABLE IF EXISTS bills;
DROP TABLE IF EXISTS admissions;
DROP TABLE IF EXISTS appointments;
DROP TABLE IF EXISTS rooms;
DROP TABLE IF EXISTS staff;
DROP TABLE IF EXISTS doctors;
DROP TABLE IF EXISTS departments;
DROP TABLE IF EXISTS patients;

-- Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;

-- Create Patients table
CREATE TABLE IF NOT EXISTS patients (
    patient_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender VARCHAR(10) NOT NULL,
    address TEXT,
    phone_number VARCHAR(20),
    email VARCHAR(100),
    blood_group VARCHAR(5),
    emergency_contact VARCHAR(20),
    room_number VARCHAR(10),
    is_admitted TINYINT(1) DEFAULT 0,
    registration_date DATE
);

-- Create Departments table
CREATE TABLE IF NOT EXISTS departments (
    department_id INT AUTO_INCREMENT PRIMARY KEY,
    department_name VARCHAR(50) NOT NULL,
    head_doctor_id INT,
    location VARCHAR(100) NOT NULL,
    phone_number VARCHAR(15) NOT NULL
);

-- Create Doctors table
CREATE TABLE IF NOT EXISTS doctors (
    doctor_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    license_number VARCHAR(50) NOT NULL UNIQUE,
    staff_id VARCHAR(20) NOT NULL UNIQUE,
    department_id INT NOT NULL,
    specialization VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20),
    email VARCHAR(100),
    qualification VARCHAR(100),
    experience_years INT,
    joining_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
);

-- Add foreign key for head_doctor_id after doctors table is created
ALTER TABLE departments
ADD CONSTRAINT fk_head_doctor
FOREIGN KEY (head_doctor_id) REFERENCES doctors(doctor_id);

-- Create Rooms table
CREATE TABLE IF NOT EXISTS rooms (
    room_id INT AUTO_INCREMENT PRIMARY KEY,
    room_number VARCHAR(10) NOT NULL UNIQUE,
    room_type ENUM('Lab', 'Patient Room', 'Waiting Room', 'Consultation Room', 'Other') NOT NULL,
    status VARCHAR(20) DEFAULT 'Available',
    
    -- Common fields
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Lab specific fields
    lab_id VARCHAR(20),
    lab_name VARCHAR(100),
    lab_contact VARCHAR(20),
    
    -- Patient Room specific fields
    bed_count INT,
    current_patients INT DEFAULT 0,
    max_patients INT,
    
    -- Waiting Room specific fields
    seating_capacity INT,
    has_tv BOOLEAN DEFAULT FALSE,
    has_vending_machine BOOLEAN DEFAULT FALSE,
    
    -- Consultation Room specific fields
    equipment TEXT,
    assigned_doctor_id INT,
    FOREIGN KEY (assigned_doctor_id) REFERENCES doctors(doctor_id),
    
    -- Other Room specific fields
    other_room_type VARCHAR(50)
);

-- Create Appointments table
CREATE TABLE IF NOT EXISTS appointments (
    appointment_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    appointment_date DATE NOT NULL,
    appointment_time TIME NOT NULL,
    status VARCHAR(20) DEFAULT 'Scheduled',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
);

-- Create Admissions table
CREATE TABLE IF NOT EXISTS admissions (
    admission_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    room_id INT NOT NULL,
    admission_date DATE NOT NULL,
    discharge_date DATE,
    reason VARCHAR(255) NOT NULL,
    status VARCHAR(20) DEFAULT 'Admitted',
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (room_id) REFERENCES rooms(room_id)
);

-- Create Bills table
CREATE TABLE IF NOT EXISTS bills (
    bill_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    bill_date DATE NOT NULL,
    consultation_fee DECIMAL(10,2),
    medication_fee DECIMAL(10,2),
    test_fee DECIMAL(10,2),
    room_charge DECIMAL(10,2),
    other_charges DECIMAL(10,2),
    total_amount DECIMAL(10,2) GENERATED ALWAYS AS 
        (COALESCE(consultation_fee, 0) + 
         COALESCE(medication_fee, 0) + 
         COALESCE(test_fee, 0) + 
         COALESCE(room_charge, 0) + 
         COALESCE(other_charges, 0)) STORED,
    payment_status VARCHAR(20) DEFAULT 'Pending',
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
);

-- Create Prescriptions table
CREATE TABLE IF NOT EXISTS prescriptions (
    prescription_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    prescription_date DATE NOT NULL,
    medication VARCHAR(100) NOT NULL,
    dosage VARCHAR(50) NOT NULL,
    instructions TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
);

-- Create Staff table
CREATE TABLE IF NOT EXISTS staff (
    staff_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    role VARCHAR(50) NOT NULL,
    department_id INT,
    hire_date DATE NOT NULL,
    phone_number VARCHAR(20),
    email VARCHAR(100),
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
);

-- Insert sample departments
INSERT INTO departments (department_name, location, phone_number) VALUES
('Cardiology', 'Building A, Floor 2', '555-0101'),
('Neurology', 'Building B, Floor 1', '555-0102'),
('Pediatrics', 'Building A, Floor 3', '555-0103'),
('Orthopedics', 'Building B, Floor 2', '555-0104'),
('Emergency', 'Building A, Ground Floor', '555-0105'),
('Internal Medicine', 'Building C, Floor 1', '555-0106');

-- Insert sample doctors (total 15)
INSERT INTO doctors (first_name, last_name, license_number, staff_id, department_id, specialization, phone_number, email, qualification, experience_years, joining_date) VALUES
('John', 'Smith', 'LIC001', 'DOC001', 1, 'Cardiologist', '555-1001', 'john.smith@hospital.com', 'MD, Cardiology', 15, '2020-01-01'),
('Sarah', 'Johnson', 'LIC002', 'DOC002', 2, 'Neurologist', '555-1002', 'sarah.johnson@hospital.com', 'MD, Neurology', 12, '2020-02-01'),
('Michael', 'Brown', 'LIC003', 'DOC003', 3, 'Pediatrician', '555-1003', 'michael.brown@hospital.com', 'MD, Pediatrics', 10, '2020-03-01'),
('Emily', 'Davis', 'LIC004', 'DOC004', 4, 'Orthopedic Surgeon', '555-1004', 'emily.davis@hospital.com', 'MD, Orthopedics', 8, '2020-04-01'),
('David', 'Wilson', 'LIC005', 'DOC005', 5, 'Emergency Medicine', '555-1005', 'david.wilson@hospital.com', 'MD, Emergency Medicine', 6, '2020-05-01'),
('Lisa', 'Anderson', 'LIC006', 'DOC006', 6, 'Internal Medicine', '555-1006', 'lisa.anderson@hospital.com', 'MD, Internal Medicine', 9, '2020-06-01'),
('Robert', 'Taylor', 'LIC016', 'DOC016', 1, 'Cardiologist', '555-1007', 'robert.taylor@hospital.com', 'MD, Cardiology', 11, '2020-07-01'),
('Jennifer', 'Martinez', 'LIC017', 'DOC017', 2, 'Neurologist', '555-1008', 'jennifer.martinez@hospital.com', 'MD, Neurology', 7, '2020-08-01'),
('William', 'Garcia', 'LIC018', 'DOC018', 3, 'Pediatrician', '555-1009', 'william.garcia@hospital.com', 'MD, Pediatrics', 5, '2020-09-01'),
('Patricia', 'Rodriguez', 'LIC019', 'DOC019', 4, 'Orthopedic Surgeon', '555-1010', 'patricia.rodriguez@hospital.com', 'MD, Orthopedics', 13, '2020-10-01'),
('James', 'Lee', 'LIC020', 'DOC020', 5, 'Emergency Medicine', '555-1011', 'james.lee@hospital.com', 'MD, Emergency Medicine', 4, '2020-11-01'),
('Mary', 'White', 'LIC021', 'DOC021', 6, 'Internal Medicine', '555-1012', 'mary.white@hospital.com', 'MD, Internal Medicine', 8, '2020-12-01'),
('Thomas', 'Harris', 'LIC022', 'DOC022', 1, 'Cardiologist', '555-1013', 'thomas.harris@hospital.com', 'MD, Cardiology', 10, '2021-01-01'),
('Elizabeth', 'Clark', 'LIC023', 'DOC023', 2, 'Neurologist', '555-1014', 'elizabeth.clark@hospital.com', 'MD, Neurology', 6, '2021-02-01'),
('Charles', 'Lewis', 'LIC024', 'DOC024', 3, 'Pediatrician', '555-1015', 'charles.lewis@hospital.com', 'MD, Pediatrics', 9, '2021-03-01');

-- Update department heads
UPDATE departments SET head_doctor_id = 1 WHERE department_id = 1;
UPDATE departments SET head_doctor_id = 2 WHERE department_id = 2;
UPDATE departments SET head_doctor_id = 3 WHERE department_id = 3;
UPDATE departments SET head_doctor_id = 4 WHERE department_id = 4;
UPDATE departments SET head_doctor_id = 5 WHERE department_id = 5;
UPDATE departments SET head_doctor_id = 6 WHERE department_id = 6;

-- Insert sample patients
INSERT INTO patients (first_name, last_name, date_of_birth, gender, address, phone_number, email, blood_group, emergency_contact, registration_date) VALUES
('Alice', 'Johnson', '1988-05-15', 'Female', '123 Main St, New York', '555-2001', 'alice.j@email.com', 'A+', '555-3001', '2023-01-01'),
('Bob', 'Williams', '1975-08-22', 'Male', '456 Oak Ave, Chicago', '555-2002', 'bob.w@email.com', 'B-', '555-3002', '2023-01-02'),
('Carol', 'Davis', '1992-03-10', 'Female', '789 Pine Rd, Los Angeles', '555-2003', 'carol.d@email.com', 'O+', '555-3003', '2023-01-03'),
('Daniel', 'Miller', '1980-11-28', 'Male', '321 Elm St, Houston', '555-2004', 'daniel.m@email.com', 'AB+', '555-3004', '2023-01-04'),
('Eva', 'Brown', '1995-07-04', 'Female', '654 Maple Dr, Miami', '555-2005', 'eva.b@email.com', 'A-', '555-3005', '2023-01-05'),
('Frank', 'Wilson', '1972-09-18', 'Male', '987 Cedar Ln, Boston', '555-2006', 'frank.w@email.com', 'B+', '555-3006', '2023-01-06'),
('Grace', 'Moore', '1985-12-30', 'Female', '741 Birch St, Seattle', '555-2007', 'grace.m@email.com', 'O-', '555-3007', '2023-01-07'),
('Henry', 'Taylor', '1990-04-22', 'Male', '852 Spruce Ave, Denver', '555-2008', 'henry.t@email.com', 'AB-', '555-3008', '2023-01-08'),
('Isabella', 'Anderson', '1983-07-15', 'Female', '963 Oak Dr, Phoenix', '555-2009', 'isabella.a@email.com', 'A+', '555-3009', '2023-01-09'),
('Jack', 'Thomas', '1978-02-28', 'Male', '159 Pine Ln, Atlanta', '555-2010', 'jack.t@email.com', 'B-', '555-3010', '2023-01-10'),
('Katherine', 'Jackson', '1993-11-05', 'Female', '357 Maple St, Dallas', '555-2011', 'katherine.j@email.com', 'O+', '555-3011', '2023-01-11'),
('Liam', 'White', '1987-06-12', 'Male', '486 Cedar Ave, San Francisco', '555-2012', 'liam.w@email.com', 'AB+', '555-3012', '2023-01-12'),
('Mia', 'Harris', '1974-03-25', 'Female', '753 Birch Rd, Philadelphia', '555-2013', 'mia.h@email.com', 'A-', '555-3013', '2023-01-13'),
('Noah', 'Martin', '1991-08-08', 'Male', '951 Spruce Dr, San Diego', '555-2014', 'noah.m@email.com', 'B+', '555-3014', '2023-01-14'),
('Olivia', 'Thompson', '1982-01-17', 'Female', '258 Oak St, Austin', '555-2015', 'olivia.t@email.com', 'O-', '555-3015', '2023-01-15');

-- Insert sample rooms
INSERT INTO rooms (room_number, room_type, status, description, bed_count, max_patients, lab_id, lab_name, lab_contact, seating_capacity, has_tv, has_vending_machine, equipment, assigned_doctor_id, other_room_type) VALUES
-- Patient Rooms
('101', 'Patient Room', 'Available', 'Standard patient room with two beds', 2, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('102', 'Patient Room', 'Occupied', 'Private patient room', 1, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('103', 'Patient Room', 'Available', 'Standard patient room with two beds', 2, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('104', 'Patient Room', 'Available', 'Private patient room', 1, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('105', 'Patient Room', 'Occupied', 'Standard patient room with two beds', 2, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('106', 'Patient Room', 'Available', 'Private patient room', 1, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('107', 'Patient Room', 'Available', 'Standard patient room with two beds', 2, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('108', 'Patient Room', 'Occupied', 'Private patient room', 1, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),

-- Consultation Rooms
('201', 'Consultation Room', 'Available', 'General consultation room', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Basic medical equipment', 1, NULL),
('202', 'Consultation Room', 'Available', 'Specialist consultation room', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Advanced medical equipment', 2, NULL),
('203', 'Consultation Room', 'Available', 'General consultation room', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Basic medical equipment', 3, NULL),
('204', 'Consultation Room', 'Available', 'Specialist consultation room', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Advanced medical equipment', 4, NULL),

-- Labs
('301', 'Lab', 'Available', 'General laboratory', NULL, NULL, 'LAB001', 'General Lab', '555-4001', NULL, NULL, NULL, NULL, NULL, NULL),
('302', 'Lab', 'Available', 'Specialized testing laboratory', NULL, NULL, 'LAB002', 'Specialized Lab', '555-4002', NULL, NULL, NULL, NULL, NULL, NULL),
('303', 'Lab', 'Available', 'Pathology laboratory', NULL, NULL, 'LAB003', 'Pathology Lab', '555-4003', NULL, NULL, NULL, NULL, NULL, NULL),
('304', 'Lab', 'Available', 'Radiology laboratory', NULL, NULL, 'LAB004', 'Radiology Lab', '555-4004', NULL, NULL, NULL, NULL, NULL, NULL),

-- Waiting Rooms
('401', 'Waiting Room', 'Available', 'Main waiting area', NULL, NULL, NULL, NULL, NULL, 50, TRUE, TRUE, NULL, NULL, NULL),
('402', 'Waiting Room', 'Available', 'Emergency waiting area', NULL, NULL, NULL, NULL, NULL, 30, TRUE, TRUE, NULL, NULL, NULL),

-- Other Rooms
('501', 'Other', 'Available', 'Storage room', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Storage'),
('502', 'Other', 'Available', 'Administrative office', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Office');

-- Insert sample staff
INSERT INTO staff (first_name, last_name, role, department_id, hire_date, phone_number, email) VALUES
-- Nurses
('Mary', 'Wilson', 'Nurse', 1, '2020-01-15', '555-4001', 'mary.w@hospital.com'),
('James', 'Taylor', 'Nurse', 2, '2020-02-15', '555-4002', 'james.t@hospital.com'),
('Patricia', 'Anderson', 'Nurse', 3, '2020-03-15', '555-4003', 'patricia.a@hospital.com'),
('Robert', 'Thomas', 'Nurse', 4, '2020-04-15', '555-4004', 'robert.t@hospital.com'),
('Jennifer', 'Martinez', 'Nurse', 5, '2020-05-15', '555-4005', 'jennifer.m@hospital.com'),
('Michael', 'Garcia', 'Nurse', 6, '2020-06-15', '555-4006', 'michael.g@hospital.com'),
('Linda', 'Rodriguez', 'Nurse', 1, '2020-07-15', '555-4007', 'linda.r@hospital.com'),
('William', 'Lee', 'Nurse', 2, '2020-08-15', '555-4008', 'william.l@hospital.com'),

-- Receptionists
('Elizabeth', 'White', 'Receptionist', NULL, '2020-09-15', '555-4009', 'elizabeth.w@hospital.com'),
('David', 'Harris', 'Receptionist', NULL, '2020-10-15', '555-4010', 'david.h@hospital.com'),

-- Lab Technicians
('Barbara', 'Clark', 'Lab Technician', NULL, '2020-11-15', '555-4011', 'barbara.c@hospital.com'),
('Richard', 'Lewis', 'Lab Technician', NULL, '2020-12-15', '555-4012', 'richard.l@hospital.com'),
('Susan', 'Walker', 'Lab Technician', NULL, '2021-01-15', '555-4013', 'susan.w@hospital.com'),

-- Administrative Staff
('Joseph', 'Hall', 'Administrative Staff', NULL, '2021-02-15', '555-4014', 'joseph.h@hospital.com'),
('Sarah', 'Allen', 'Administrative Staff', NULL, '2021-03-15', '555-4015', 'sarah.a@hospital.com'),

-- Other Staff
('Thomas', 'Young', 'Maintenance', NULL, '2021-04-15', '555-4016', 'thomas.y@hospital.com'),
('Karen', 'King', 'Security', NULL, '2021-05-15', '555-4017', 'karen.k@hospital.com'),
('Charles', 'Wright', 'IT Support', NULL, '2021-06-15', '555-4018', 'charles.w@hospital.com'),
('Nancy', 'Scott', 'Housekeeping', NULL, '2021-07-15', '555-4019', 'nancy.s@hospital.com'),
('Daniel', 'Green', 'Pharmacy Technician', NULL, '2021-08-15', '555-4020', 'daniel.g@hospital.com');

-- Insert sample appointments
INSERT INTO appointments (patient_id, doctor_id, appointment_date, appointment_time, status) VALUES
(1, 1, CURDATE(), '09:00:00', 'Scheduled'),
(2, 2, CURDATE(), '10:00:00', 'Scheduled'),
(3, 3, CURDATE(), '11:00:00', 'Scheduled'),
(4, 4, DATE_ADD(CURDATE(), INTERVAL 1 DAY), '09:00:00', 'Scheduled'),
(5, 5, DATE_ADD(CURDATE(), INTERVAL 1 DAY), '10:00:00', 'Scheduled');

-- Insert sample bills for patients
INSERT INTO bills (patient_id, bill_date, consultation_fee, medication_fee, test_fee, room_charge, other_charges, payment_status) VALUES
-- Alice Johnson (patient_id: 1)
(1, '2023-01-15', 500.00, 250.00, 300.00, 1000.00, 150.00, 'Paid'),
(1, '2023-02-20', 500.00, 150.00, 200.00, 0.00, 50.00, 'Paid'),
(1, '2023-03-10', 500.00, 300.00, 400.00, 0.00, 100.00, 'Pending'),

-- Bob Williams (patient_id: 2)
(2, '2023-01-20', 600.00, 350.00, 400.00, 1500.00, 200.00, 'Paid'),
(2, '2023-02-25', 600.00, 200.00, 250.00, 0.00, 75.00, 'Paid'),
(2, '2023-03-15', 600.00, 400.00, 500.00, 0.00, 150.00, 'Pending'),

-- Carol Davis (patient_id: 3)
(3, '2023-01-25', 550.00, 300.00, 350.00, 1200.00, 175.00, 'Paid'),
(3, '2023-02-28', 550.00, 175.00, 225.00, 0.00, 60.00, 'Paid'),
(3, '2023-03-20', 550.00, 350.00, 450.00, 0.00, 125.00, 'Pending'),

-- Daniel Miller (patient_id: 4)
(4, '2023-01-30', 650.00, 400.00, 450.00, 1800.00, 250.00, 'Paid'),
(4, '2023-03-05', 650.00, 250.00, 300.00, 0.00, 100.00, 'Paid'),
(4, '2023-03-25', 650.00, 450.00, 550.00, 0.00, 175.00, 'Pending'),

-- Eva Brown (patient_id: 5)
(5, '2023-02-05', 700.00, 450.00, 500.00, 2000.00, 300.00, 'Paid'),
(5, '2023-03-10', 700.00, 300.00, 350.00, 0.00, 125.00, 'Paid'),
(5, '2023-03-30', 700.00, 500.00, 600.00, 0.00, 200.00, 'Pending');

-- Insert sample prescriptions for patients
INSERT INTO prescriptions (patient_id, doctor_id, prescription_date, medication, dosage, instructions) VALUES
-- Alice Johnson (patient_id: 1)
(1, 1, '2023-01-15', 'Lisinopril', '10mg once daily', 'Take in the morning with food'),
(1, 2, '2023-02-20', 'Metformin', '500mg twice daily', 'Take with meals'),
(1, 3, '2023-03-10', 'Amoxicillin', '500mg three times daily', 'Take for 7 days'),

-- Bob Williams (patient_id: 2)
(2, 2, '2023-01-20', 'Atorvastatin', '20mg once daily', 'Take at bedtime'),
(2, 3, '2023-02-25', 'Omeprazole', '20mg once daily', 'Take before breakfast'),
(2, 4, '2023-03-15', 'Ibuprofen', '400mg as needed', 'Take with food'),

-- Carol Davis (patient_id: 3)
(3, 3, '2023-01-25', 'Levothyroxine', '50mcg once daily', 'Take on empty stomach'),
(3, 4, '2023-02-28', 'Albuterol', '2 puffs as needed', 'Use before exercise'),
(3, 5, '2023-03-20', 'Prednisone', '20mg once daily', 'Take with food'),

-- Daniel Miller (patient_id: 4)
(4, 4, '2023-01-30', 'Warfarin', '5mg once daily', 'Take at same time daily'),
(4, 5, '2023-03-05', 'Metoprolol', '25mg twice daily', 'Take with meals'),
(4, 6, '2023-03-25', 'Cephalexin', '500mg four times daily', 'Take for 10 days'),

-- Eva Brown (patient_id: 5)
(5, 5, '2023-02-05', 'Losartan', '50mg once daily', 'Take in the morning'),
(5, 6, '2023-03-10', 'Gabapentin', '300mg three times daily', 'Take with food'),
(5, 1, '2023-03-30', 'Doxycycline', '100mg twice daily', 'Take for 14 days'); 