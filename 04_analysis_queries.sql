/* 
MediDemo_DB Analysis Queries
Author: Maria Bass
Purpose: Portfolio project demonstrating SQL data analysis
Scope: Appointment, patient, and diagnosis analytics for synthetic clinical dataset
Database: MediDemo_DB (SQL Server)
Date: October 2025
*/

-- ************ PATIENT & APPOINTMENT VOLUME ********************

-- ==== 1. MONTHLY APPOINTMENT VOLUME OVERALL ==== 

/* - Keeps clinics with zero completed appointments (LEFT JOINs)
   - Counts ONLY 'Completed' rows via SUM(CASE ...)
*/

  SELECT 
	AC.clinic_id,
	AC.clinic_name,
	SUM(CASE WHEN S.status_name = 'Completed' THEN 1 ELSE 0 END) AS total_completed_appointments
  FROM Alaska_Clinics AC
  LEFT JOIN MedicalStaff MS ON AC.clinic_id = MS.clinic_id
  LEFT JOIN Appointments A ON MS.staff_id = A.doctor_id
  LEFT JOIN AppointmentStatus S ON A.status_id = S.status_id 
  GROUP BY AC.clinic_id, AC.clinic_name
  ORDER BY AC.clinic_name

  -- ==== 2. MONTHLY APPOINTMENT VOLUME BY CLINIC ==== 
  -- Excludes 'Canceled' and 'No-Show' appointments.
  -- Uses a specified time frame.

    -- Add a computed column month_start to facilitate monthly grouping.
ALTER TABLE Appointments
ADD month_start AS CAST((DATEADD(month, DATEDIFF(month, 0, appointment_date), 0)) AS Date) PERSISTED;


DECLARE @start_date date = '2025-01-01';
DECLARE @end_date date = '2025-12-31';

SELECT
  AC.clinic_name,
  A.month_start,
 SUM(CASE WHEN AST.status_name IS NOT NULL THEN 1 ELSE 0 END) AS appointments_count
FROM Alaska_Clinics AC
LEFT JOIN MedicalStaff MS 
	ON AC.clinic_id = MS.clinic_id
LEFT JOIN Appointments A 
	ON A.doctor_id = MS.staff_id
	 AND A.appointment_date BETWEEN @start_date AND @end_date     -- apply filters in ON to preserve LEFT JOIN
LEFT JOIN AppointmentStatus AST 
	ON AST.status_id = A.status_id
	AND AST.status_name NOT IN ('Canceled','No-Show')
GROUP BY
  AC.clinic_name,
  A.month_start
ORDER BY
  AC.clinic_name, A.month_start;

-- ==== 3. APPOINTMENTS OUTCOME COUNTS BY CLINIC (TO DATE) ==== 
-- Counts appointments per clinic by outcome: Completed, Canceled, No-Show, Pending (Checked In / Confirmed / Scheduled / Rescheduled)

DECLARE @today date = CAST(GETDATE() AS date);

WITH status_totals AS (
    SELECT 
        AC.clinic_name,
        COUNT(*) AS total_appointments,
        SUM(CASE WHEN S.status_name = 'Canceled'  THEN 1 ELSE 0 END) AS canceled_count,
        SUM(CASE WHEN S.status_name = 'No-Show'   THEN 1 ELSE 0 END) AS no_show_count,
        SUM(CASE WHEN S.status_name = 'Completed' THEN 1 ELSE 0 END) AS completed_count,
        SUM(CASE WHEN S.status_name IN ('Checked In','Confirmed','Scheduled','Rescheduled') THEN 1 ELSE 0 END) AS pending_count
    FROM dbo.Appointments      AS A
    JOIN dbo.AppointmentStatus AS S  ON S.status_id  = A.status_id
    JOIN dbo.MedicalStaff      AS MS ON MS.staff_id  = A.doctor_id
    JOIN dbo.Alaska_Clinics    AS AC ON AC.clinic_id = MS.clinic_id
    WHERE A.appointment_date <= @today
    GROUP BY AC.clinic_name
)
SELECT
    clinic_name,
    total_appointments,
    canceled_count,
    no_show_count,
    completed_count,
    pending_count
FROM status_totals
ORDER BY clinic_name;

-- ==== 4. PATIENTS VOLUME BY CLINIC ====  
-- through yesterday, excluding Canceled / No-Show

DECLARE @startDate date = (SELECT MIN(appointment_date) FROM Appointments);
DECLARE @today date = CAST(GETDATE() AS date);
DECLARE @prevDay date = DATEADD(day, -1, @today);

SELECT
  AC.clinic_name,
  COUNT(A.appointment_id) AS total_appointments,
  COUNT(DISTINCT A.patient_id) AS unique_patients
FROM Alaska_Clinics AC
LEFT JOIN MedicalStaff MS
  ON MS.clinic_id = AC.clinic_id
LEFT JOIN Appointments A
  ON A.doctor_id = MS.staff_id
 AND A.appointment_date BETWEEN @startDate AND @prevDay
 AND A.status_id IN (
       SELECT status_id
       FROM AppointmentStatus
       WHERE status_name NOT IN ('Canceled','No-Show')
     )
-- (No WHERE clause: we want to keep clinics with zero activity)
GROUP BY AC.clinic_name
ORDER BY total_appointments DESC;

-- ==== 5. UNIQUE PATIENTS BY CLINIC ==== 
-- aggregated by month for active (non-canceled or no-show) appointments only

DECLARE @today   date = CAST(GETDATE() AS date);
DECLARE @prevDay date = DATEADD(day, -1, @today);

SELECT
  AC.clinic_name,
  CAST(DATEADD(month, DATEDIFF(month, 0, A.appointment_date), 0) AS date) AS month_start,
  COUNT(DISTINCT A.patient_id) AS unique_patients
FROM Appointments A
JOIN AppointmentStatus S ON S.status_id = A.status_id
JOIN MedicalStaff MS ON MS.staff_id = A.doctor_id
JOIN Alaska_Clinics AC ON AC.clinic_id = MS.clinic_id
WHERE A.appointment_date <= @prevDay
  AND S.status_name NOT IN ('Canceled','No-Show')
GROUP BY
  AC.clinic_name,
  DATEADD(month, DATEDIFF(month, 0, A.appointment_date), 0)
ORDER BY
  AC.clinic_name, month_start;

-- ==== 6. NUMBER OF APPOINTMENTS PER DAY PER CLINIC ==== 

DECLARE @start_date date = '2025-01-01';
DECLARE @end_date   date = '2025-12-31';  

SELECT
    AC.clinic_name,
    A.appointment_date,
    COUNT(A.appointment_id) AS total_appointments
FROM
    Appointments A
JOIN
	AppointmentStatus S ON A.status_id = S.status_id
JOIN
    MedicalStaff MS ON A.doctor_id = MS.staff_id
JOIN
    Alaska_Clinics AC ON MS.clinic_id = AC.clinic_id
WHERE (A.appointment_date BETWEEN @start_date AND @end_date) 
	AND (S.status_name NOT IN ('Canceled', 'No-Show'))
GROUP BY
    AC.clinic_name,
    A.appointment_date
ORDER BY
    AC.clinic_name,
    A.appointment_date;

-- ==== 7. TOP 5 BUSIEST DOCTORS ==== 
-- (ties included via DENSE_RANK)

DECLARE @start_date date = '2025-01-01';
DECLARE @end_date   date = '2025-12-31';  

WITH ranked_doctors AS (
  SELECT
      MS.staff_id,
      MS.first_name,
      MS.last_name,
	  MS.specialization,
      COUNT(*) AS appointments_count,
      DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS rank
  FROM Appointments A
  JOIN AppointmentStatus S ON A.status_id = S.status_id
  JOIN MedicalStaff MS ON MS.staff_id = A.doctor_id
  WHERE (S.status_name NOT IN ('Canceled', 'No-Show'))
	AND (A.appointment_date BETWEEN @start_date AND @end_date)
  GROUP BY MS.staff_id, MS.first_name, MS.last_name, MS.specialization
)
SELECT staff_id, first_name, last_name, specialization, appointments_count
FROM ranked_doctors
WHERE rank <= 5
ORDER BY appointments_count DESC, last_name, first_name;

-- ************ DATA ABOUT PATIENTS ********************

-- ==== 1. PATIENTS AGE AS OF TODAY BASED ON DATE OF BIRTH ==== 

SELECT
    patient_id,
    first_name,
    last_name,
    date_of_birth,
    DATEDIFF(year, date_of_birth, GETDATE()) - 
        CASE
            -- Check if the current date is before the patient's birthday in the current year
            WHEN MONTH(GETDATE()) < MONTH(date_of_birth) OR 
                 (MONTH(GETDATE()) = MONTH(date_of_birth) AND DAY(GETDATE()) < DAY(date_of_birth))
            THEN 1
            ELSE 0
        END AS age
FROM
    Patients
ORDER BY age DESC;

-- ==== 2. PATIENTS AGE DISTRIBUTION BUCKETS ==== 

DECLARE @today date = CAST(GETDATE() AS date);

WITH PatientAges AS (
    SELECT
        patient_id,
        DATEDIFF(year, date_of_birth, @today) -
        CASE
            -- Corrects the age if the patient's birthday has not yet occurred this year
            WHEN MONTH(@today) < MONTH(date_of_birth) OR
                 (MONTH(@today) = MONTH(date_of_birth) AND DAY(@today) < DAY(date_of_birth))
            THEN 1
            ELSE 0
        END AS age
    FROM
        Patients
)   
SELECT
    SUM(CASE WHEN age BETWEEN 0 AND 17 THEN 1 ELSE 0 END) AS patients_0_to_17,
    SUM(CASE WHEN age BETWEEN 18 AND 24 THEN 1 ELSE 0 END) AS patients_18_to_24,
    SUM(CASE WHEN age BETWEEN 25 AND 34 THEN 1 ELSE 0 END) AS patients_25_to_34,
	SUM(CASE WHEN age BETWEEN 35 AND 44 THEN 1 ELSE 0 END) AS patients_35_to_44,
    SUM(CASE WHEN age BETWEEN 45 AND 54 THEN 1 ELSE 0 END) AS patients_45_to_54,
    SUM(CASE WHEN age BETWEEN 55 AND 64 THEN 1 ELSE 0 END) AS patients_55_to_64,
	SUM(CASE WHEN age BETWEEN 65 AND 74 THEN 1 ELSE 0 END) AS patients_65_to_74,
	SUM(CASE WHEN age BETWEEN 75 AND 84 THEN 1 ELSE 0 END) AS patients_75_to_84,
    SUM(CASE WHEN age > 84 THEN 1 ELSE 0 END) AS patients_over_85
FROM
    PatientAges;

-- ==== 3. PATIENTS SEX DISTRIBUTION ==== 

SELECT
	SUM (CASE WHEN gender = 'Male' THEN 1 ELSE 0 END) AS male_count,
	SUM (CASE WHEN gender = 'Female' THEN 1 ELSE 0 END) AS female_count,
	SUM(CASE WHEN gender = 'Other' THEN 1 ELSE 0 END) AS other_count
FROM Patients;

-- ==== 4. MOST COMMON DIAGNOSES OVERALL ====
-- Calculates each diagnosis's share (%) of all diagnoses within the selected time frame

DECLARE @start_date date = '2025-01-01';
DECLARE @end_date   date = '2025-12-31';

SELECT
  DT.diagnosis_code,
  DT.diagnosis_description,
  COUNT(*) AS diagnosis_count,
  CAST(
	ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 3) 
	AS decimal(10,3)
  ) AS pct_of_all_diagnoses
FROM Cases C
JOIN Appointments A ON A.appointment_id = C.appointment_id
JOIN AppointmentStatus S ON S.status_id = A.status_id
JOIN Diagnoses_types DT  ON DT.diagnosis_code = C.diagnosis_code
WHERE A.appointment_date BETWEEN @start_date AND @end_date
  AND S.status_name NOT IN ('Canceled','No-Show')
GROUP BY DT.diagnosis_code, DT.diagnosis_description
ORDER BY diagnosis_count DESC, DT.diagnosis_code

 -- ==== 5. MOST COMMON DIAGNOSES BY CLINIC ====
 -- Calculates each diagnosis's share (%) within its clinic over the selected time frame
 -- Excludes 'Canceled' and 'No-Show' appointments

DECLARE @start_date DATE = '2025-01-01';
DECLARE @end_date   DATE = '2025-12-31';

SELECT
    AC.clinic_name,
    DT.diagnosis_code,
    DT.diagnosis_description,
    COUNT(*) AS diagnosis_count,
    CAST(
        ROUND(
            COUNT(*) * 100.0
            / SUM(COUNT(*)) OVER (PARTITION BY AC.clinic_name)
        , 3) AS DECIMAL(10,3)
    ) AS pct_within_clinic
FROM Cases C
JOIN Appointments      A  ON A.appointment_id = C.appointment_id
JOIN AppointmentStatus S  ON S.status_id       = A.status_id
JOIN MedicalStaff      MS ON MS.staff_id       = A.doctor_id
JOIN Alaska_Clinics    AC ON AC.clinic_id      = MS.clinic_id
JOIN Diagnoses_Types   DT ON DT.diagnosis_code = C.diagnosis_code
WHERE A.appointment_date BETWEEN @start_date AND @end_date
  AND S.status_name NOT IN ('Canceled', 'No-Show')
GROUP BY
    AC.clinic_name,
    DT.diagnosis_code,
    DT.diagnosis_description
ORDER BY
    AC.clinic_name,
    diagnosis_count DESC,
    DT.diagnosis_code;

-- ==== 6. PATIENTS WITH MORE THAN ONE DISTINCT CONDITION ====
-- Lists patients with >1 distinct diagnosis
-- Includes an ordered, readable diagnoses list

DECLARE @start_date date = '2025-01-01';
DECLARE @end_date   date = '2025-12-31';

WITH dx AS (
  SELECT DISTINCT
         P.patient_id,
         C.diagnosis_code
  FROM Patients P
  JOIN Appointments A ON A.patient_id = P.patient_id
  JOIN AppointmentStatus S ON S.status_id = A.status_id
  JOIN Cases C ON C.appointment_id = A.appointment_id
  WHERE A.appointment_date BETWEEN @start_date AND @end_date
    AND S.status_name NOT IN ('Canceled','No-Show')
)
SELECT
  P.patient_id,
  P.first_name,
  P.last_name,
  COUNT(*) AS diagnosis_count,
  STRING_AGG(CONCAT(dx.diagnosis_code, ' - ', DT.diagnosis_description), '; ')
    WITHIN GROUP (ORDER BY dx.diagnosis_code) AS diagnoses_list
FROM Patients P
JOIN dx ON dx.patient_id = P.patient_id
JOIN Diagnoses_Types DT ON DT.diagnosis_code = dx.diagnosis_code
GROUP BY P.patient_id, P.first_name, P.last_name
HAVING COUNT(*) > 1
ORDER BY diagnosis_count DESC, P.last_name, P.first_name;

-- ==== 7. PATIENTS WITH MORE THAN ONE DISTINCT CONDITION (INCLUDES AGE) ====
-- Returns patients who have >1 distinct diagnosis within the selected date range, including date of birth and age (as of @end_date).

DECLARE @start_date date = '2025-01-01';
DECLARE @end_date   date = '2025-12-31';

WITH PatientAges AS (
    SELECT
        patient_id,
        first_name,
        last_name,
        DATEDIFF(year, date_of_birth, @end_date) -
            CASE
                WHEN MONTH(@end_date) < MONTH(date_of_birth) 
				OR (MONTH(@end_date) = MONTH(date_of_birth) 
					AND DAY(@end_date) < DAY(date_of_birth))
                THEN 1
                ELSE 0
            END AS patient_age
    FROM Patients
)
SELECT
    P.patient_id,
    P.first_name,
    P.last_name,
	P.date_of_birth,
	PA.patient_age,
    COUNT(DISTINCT C.diagnosis_code) AS diagnoses_count
FROM Patients P
JOIN PatientAges PA ON P.patient_id = PA.patient_id
JOIN Appointments A ON P.patient_id = A.patient_id
JOIN AppointmentStatus S ON S.status_id = A.status_id
JOIN Cases C ON A.appointment_id = C.appointment_id
WHERE A.appointment_date BETWEEN @start_date AND @end_date
	  AND S.status_name NOT IN ('Canceled', 'No-Show')
GROUP BY
    P.patient_id,
    P.first_name,
    P.last_name,
	P.date_of_birth,
    PA.patient_age
HAVING COUNT(DISTINCT C.diagnosis_code) > 1
ORDER BY
    diagnoses_count DESC,
    patient_age DESC;