/* 
MediDemo_DB Cleaning and Verification Queries
Author: Maria Bass
Purpose: Portfolio project demonstrating SQL data cleaning and analysis
Database: MediDemo_DB (SQL Server)
Date: October 2025
*/

-- ==== 1. NULL OR INVALID DATES ==== 
SELECT * FROM Appointments 
WHERE appointment_date IS NULL;

SELECT * FROM Patients 
WHERE date_of_birth IS NULL 
	  OR date_of_birth > GETDATE();

-- ==== 2. DIAGNOSES CONNECTED TO CANCELED AND NO-SHOW APPOINTMENTS ==== 
SELECT A.appointment_id, S.status_name, C.diagnosis_code
FROM Appointments A
JOIN AppointmentStatus S ON A.status_id = S.status_id AND
	 S.status_name IN ('Canceled', 'No-Show')
LEFT JOIN Cases C ON A.appointment_id = C.appointment_id
WHERE C.diagnosis_code IS NOT NULL;

/* The result shows that the Cases table contains diagnoses 
   Next, count how many such rows exist (for reporting), then remove those records from the Cases table.
*/
-- Step 1. Count affected rows
SELECT COUNT(*) AS bad_dx
FROM Cases C
JOIN Appointments A ON A.appointment_id = C.appointment_id
JOIN AppointmentStatus S ON S.status_id = A.status_id
WHERE S.status_name IN ('Canceled','No-Show');

-- Step 2. Delete those rows inside a transaction
BEGIN TRAN;
    DELETE C
    FROM Cases C
    JOIN Appointments A    ON A.appointment_id = C.appointment_id
    JOIN AppointmentStatus S ON S.status_id     = A.status_id
    WHERE S.status_name IN ('Canceled','No-Show');

-- Audit the number of deleted rows
SELECT @@ROWCOUNT AS deleted_rows;  
COMMIT;  -- or ROLLBACK;  -- use ROLLBACK instead of COMMIT if verification fails

-- Verify the result 
SELECT A.appointment_id, S.status_name, C.diagnosis_code
FROM Appointments A
JOIN AppointmentStatus S ON A.status_id = S.status_id AND
	 S.status_name IN ('Canceled', 'No-Show')
LEFT JOIN Cases C ON A.appointment_id = C.appointment_id
WHERE C.diagnosis_code IS NOT NULL;

-- ==== 3. DOCTORS DOUBLE-BOOKED SAME DAY/TIME ==== 
 WITH DoubleBookings AS (
    SELECT 
        doctor_id, 
        appointment_date, 
        appointment_time
    FROM Appointments
    GROUP BY doctor_id, appointment_date, appointment_time
    HAVING COUNT(*) > 1
)
SELECT A.*
FROM Appointments A
JOIN DoubleBookings D
  ON A.doctor_id = D.doctor_id
 AND A.appointment_date = D.appointment_date
 AND A.appointment_time = D.appointment_time
ORDER BY A.doctor_id, A.appointment_date, A.appointment_time;

-- Found one case of double-booking
-- Checking available time slots for the double-booked doctor on the same date
SELECT *
FROM Appointments
WHERE doctor_id = 140 AND appointment_date = '2025-04-22'; -- result shows only 2 appointments at the same time

-- Changing the time of one of the appointments
UPDATE Appointments
SET appointment_time = '11:45:00'
WHERE doctor_id = 140 AND patient_id = 1163;

-- To verify the result, run the query that checks doctor double-booking the same day/time again

-- ==== 4. PATIENTS WITH MORE THAN ONE APPOINTMENT AT THE SAME DATE/TIME ==== 4) 
SELECT 
  A.patient_id,
  A.appointment_date,
  A.appointment_time,
  COUNT(*) AS duplicate_count
FROM Appointments A
GROUP BY A.patient_id, A.appointment_date, A.appointment_time
HAVING COUNT(*) > 1
ORDER BY A.patient_id, A.appointment_date, A.appointment_time;

-- ==== 5. COMPLETED APPOINTMENTS WITH NO DIAGNOSIS RECORDED ==== 
SELECT 
  A.appointment_id,
  A.patient_id,
  A.doctor_id,
  A.appointment_date,
  A.appointment_time
FROM Appointments A
JOIN AppointmentStatus S ON S.status_id = A.status_id
LEFT JOIN Cases C         ON C.appointment_id = A.appointment_id
WHERE S.status_name = 'Completed'
  AND C.appointment_id IS NULL
ORDER BY A.appointment_date, A.appointment_time;

-- ==== 6. APPOINTMENTS BEFORE A PATIENT WAS BORN ==== 
SELECT A.appointment_id, A.patient_id, P.date_of_birth, A.appointment_date
FROM Appointments A
JOIN Patients P ON P.patient_id = A.patient_id
WHERE A.appointment_date < P.date_of_birth
ORDER BY A.appointment_date;

-- Found 3 appointments with invalid dates (before patient’s birth)
-- Review the bad rows (dry run)
SELECT A.appointment_id, A.patient_id, P.date_of_birth, A.appointment_date, A.appointment_time
FROM Appointments A
JOIN Patients P ON P.patient_id = A.patient_id
WHERE A.patient_id = 1090
  AND A.appointment_id IN (10018, 10161, 10056)
  AND A.appointment_date < P.date_of_birth
ORDER BY A.appointment_date;

-- Plan the new dates (preview only)
WITH to_fix AS (
  SELECT
    A.appointment_id,
    P.date_of_birth,
    ROW_NUMBER() OVER (ORDER BY A.appointment_date, A.appointment_id) AS rn
  FROM Appointments A
  JOIN Patients P ON P.patient_id = A.patient_id
  WHERE A.patient_id = 1090
    AND A.appointment_id IN (10018, 10161, 10056)
    AND A.appointment_date < P.date_of_birth
)
SELECT
  appointment_id,
  date_of_birth,
  rn,
  DATEADD(day, 30 + 14*(rn-1), date_of_birth) AS new_appointment_date
FROM to_fix
ORDER BY rn;

-- Update (wrapped for safety)
BEGIN TRAN;

WITH to_fix AS (
  SELECT
    A.appointment_id,
    P.date_of_birth,
    ROW_NUMBER() OVER (ORDER BY A.appointment_date, A.appointment_id) AS rn
  FROM Appointments A
  JOIN Patients P ON P.patient_id = A.patient_id
  WHERE A.patient_id = 1090
    AND A.appointment_id IN (10018, 10161, 10056)
    AND A.appointment_date < P.date_of_birth
)
UPDATE A
SET A.appointment_date = DATEADD(day, 30 + 14*(F.rn-1), F.date_of_birth)
FROM Appointments A
JOIN to_fix F ON F.appointment_id = A.appointment_id;

-- Audit how many were changed
SELECT @@ROWCOUNT AS rows_updated;

COMMIT; -- if correct
-- ROLLBACK  -- if wrong

-- Verify the result
SELECT A.appointment_id, A.patient_id, P.date_of_birth, A.appointment_date, A.appointment_time
FROM Appointments A
JOIN Patients P ON P.patient_id = A.patient_id
WHERE A.patient_id = 1090
  AND A.appointment_id IN (10018, 10161, 10056)
ORDER BY A.appointment_date;

-- ==== 7. AFTER-HOURS APPOINTMENTS (BEFORE 08:00 OR AFTER 17:00) ==== 
SELECT *
FROM Appointments
WHERE appointment_time < '08:00' OR appointment_time > '17:00';

-- ==== 8. WEEKEND APPOINTMENTS ==== 
SELECT *
FROM Appointments
WHERE DATENAME(weekday, appointment_date) IN ('Saturday','Sunday');  

/* 143 appointments were found.  
   Their dates will be shifted to valid working days (2 days forward),  
   keeping the same time slot unless this causes overlaps.  
*/

-- Checking for conflicts (double-booking of doctors or patients)
WITH to_fix AS (
    SELECT
        A.appointment_id,
        A.doctor_id,
        A.patient_id,
        A.appointment_date,
		A.appointment_time,
        DATEADD(day, 2, A.appointment_date) AS target_date	-- next Monday or Tuesday     
    FROM Appointments A
    WHERE DATENAME(weekday, A.appointment_date) IN ('Saturday','Sunday')
),
correct_appointments AS (  -- all non-weekend appts (your reference set)
    SELECT
        A.doctor_id,
        A.patient_id,
        A.appointment_date,
        A.appointment_time
    FROM Appointments AS A
    WHERE DATENAME(weekday, A.appointment_date) NOT IN ('Saturday','Sunday')
),
conflicts AS (             -- any clash at the target slot
    SELECT DISTINCT F.appointment_id
    FROM to_fix AS F
    JOIN correct_appointments C
      ON (
            -- doctor busy at same date+time
            (C.doctor_id  = F.doctor_id)
        OR  -- OR patient busy at same date+time
            (C.patient_id = F.patient_id)
         )
     AND  C.appointment_date = F.target_date
     AND  C.appointment_time = F.appointment_time
)
SELECT *
FROM conflicts;

--	No conflicts found, updating the Appointments table
BEGIN TRAN;

WITH to_fix AS (
  SELECT
      A.appointment_id,
      DATEADD(day, 2, A.appointment_date) AS target_date  -- always +2 days
  FROM Appointments AS A
  WHERE DATENAME(weekday, A.appointment_date) IN ('Saturday','Sunday')
)
UPDATE A
SET A.appointment_date = F.target_date
FROM Appointments A
JOIN to_fix F ON F.appointment_id = A.appointment_id;

SELECT @@ROWCOUNT AS rows_moved;  -- audit how many weekend rows were shifted
COMMIT;

-- Verify the result
SELECT *
FROM Appointments
WHERE DATENAME(weekday, appointment_date) IN ('Saturday','Sunday');  

