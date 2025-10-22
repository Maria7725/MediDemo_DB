/* MediDemo_DB – Database & Table Creation
   Purpose: Portfolio project (SQL Server) – synthetic medical dataset
   Contents: DB creation, core tables, constraints, simple verification
   Note: All data is synthetic 
*/

-- Step 1: Create the database
CREATE database MediDemo_DB;

-- STEP 2: Switch to the newly created database
USE MediDemo_DB;

--Step 3: Create all the tables
CREATE TABLE Alaska_Clinics (
    clinic_id INT IDENTITY(1, 1) PRIMARY KEY,
    clinic_name NVARCHAR(100) NOT NULL,
    street_address NVARCHAR(255) NOT NULL, 
    city NVARCHAR(50) NOT NULL,
    zip_code VARCHAR(10) NOT NULL,
    phone_number VARCHAR(20) NOT NULL UNIQUE
);
GO

CREATE TABLE MedicalStaff (
    staff_id INT IDENTITY (100, 1) PRIMARY KEY, 
    first_name NVARCHAR(50) NOT NULL,
    last_name NVARCHAR(50) NOT NULL,
    specialization VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    clinic_id INT NOT NULL,
    FOREIGN KEY (clinic_id) REFERENCES Alaska_Clinics(clinic_id)
);
GO

CREATE TABLE Patients (
	patient_id INT IDENTITY(1000, 1) PRIMARY KEY,
    first_name NVARCHAR(100) NOT NULL,
	last_name NVARCHAR(100) NOT NULL,
	date_of_birth DATE NOT NULL,
	gender VARCHAR(10) NOT NULL CHECK (gender IN ('Male', 'Female', 'Other')),
	contact_number VARCHAR(20) NOT NULL,
	email VARCHAR(255) NOT NULL UNIQUE 
);
GO

CREATE TABLE AppointmentStatus (
    status_id INT IDENTITY(1,1) PRIMARY KEY,
    status_name VARCHAR(50) NOT NULL UNIQUE
);
GO

CREATE TABLE Appointments (
    appointment_id INT IDENTITY (10000, 1) PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL, 
    appointment_date DATE NOT NULL,
    appointment_time TIME NOT NULL,
    status_id INT NOT NULL,
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id),
    FOREIGN KEY (doctor_id) REFERENCES MedicalStaff(staff_id),
    FOREIGN KEY (status_id) REFERENCES AppointmentStatus(status_id)
);
GO

CREATE TABLE Diagnoses_types (
	diagnosis_code VARCHAR(25) PRIMARY KEY,
	diagnosis_description NVARCHAR(2000) NOT NULL
);
GO

CREATE TABLE Cases (
    case_id INT IDENTITY (1,1) PRIMARY KEY,
    diagnosis_code VARCHAR(25) NOT NULL,
    appointment_id INT NOT NULL,
    FOREIGN KEY (diagnosis_code) REFERENCES Diagnoses_types(diagnosis_code),
    FOREIGN KEY (appointment_id) REFERENCES Appointments(appointment_id)
);
GO

-- STEP 4. Verifying tables creation
SELECT name
FROM sys.tables
WHERE is_ms_shipped = 0;

-- STEP 5 (Optional). Creating, then removing 'Prescriptions' table to show FK inspection and safe drop steps
CREATE TABLE Prescriptions (
	prescription_id INT IDENTITY(100, 1) PRIMARY KEY,
	appointment_id INT NOT NULL,
	issue_date DATE NOT NULL,
	expiration_date DATE NOT NULL,
	medication_name NVARCHAR(500) NOT NULL,
	medication_dosage VARCHAR(300) NOT NULL,  -- amount and frequency
	FOREIGN KEY (appointment_id) REFERENCES Appointments(appointment_id),
	CONSTRAINT chk_dates CHECK (expiration_date >= issue_date)
);

-- verify the name of FK constraint
SELECT
    fk.name AS foreign_key_name
FROM
    sys.foreign_keys AS fk
INNER JOIN
    sys.tables AS t ON fk.parent_object_id = t.object_id
WHERE
    t.name = 'Prescriptions' AND fk.referenced_object_id = OBJECT_ID('Appointments');

-- Removing the constraint from the table and dropping the table
ALTER TABLE Prescriptions DROP CONSTRAINT FK__Prescript__appoi__619B8048;
DROP TABLE Prescriptions;

-- Verify the table was deleted
SELECT name
FROM sys.tables
WHERE is_ms_shipped = 0;


