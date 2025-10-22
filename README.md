## 🏥 MediDemo_DB — SQL Portfolio Project

### 📌 Overview

**MediDemo_DB** is a synthetic healthcare database designed to demonstrate SQL skills relevant to **Data Analyst** and **QA Engineer** roles.  
It simulates a simplified healthcare appointment system, including clinics, medical staff, patients, appointments, and diagnoses.  
All data is **synthetic and AI-generated** — no real personal or medical data is used.

---

## 📂 Project Structure

| File Name | Description |
|------------|-------------|
| **01_create_schema.sql** | Creates the database schema, tables, constraints, and relationships |
| **02_load_data.sql** | Inserts synthetic data into all tables, following correct foreign key dependency order |
| **03_clean_validate.sql** | Performs data validation and cleaning — checks for nulls, invalid dates, weekend or after-hours bookings, and duplicate appointments |
| **04_analysis_queries.sql** | Contains analytical queries showcasing SQL proficiency — includes KPIs and summaries for clinics, doctors, and patients |

---

## 🧩 Database Schema  

### Main Entities

- `Alaska_Clinics` – Clinic locations  
- `MedicalStaff` – Doctors and specialists  
- `Patients` – Synthetic patient demographic data  
- `AppointmentStatus` – Appointment lifecycle states (`Completed`, `Canceled`, `No-Show`, `Pending`)  
- `Appointments` – Links patients, staff, and clinics with date/time and status  
- `Diagnoses_Types` – List of possible diagnoses  
- `Cases` – Connects appointments to diagnoses types  

### Entity Relationships

```text

Clinics → MedicalStaff → Appointments ← Patients  
Appointments → Cases → Diagnoses_Types

Each clinic employs many medical staff.  
Each staff member can conduct many appointments.  
Each patient can have multiple appointments (with different staff or clinics).  
Each appointment may generate one or more cases, each linked to a diagnosis type.
```

---

## 🎯 Key Analytical Queries  

| Category | Description |
|-----------|--------------|
| **Appointments Volume** | Total and monthly appointment counts per clinic |
| **Appointments Outcomes** | Counts of appointment statuses (Completed, Canceled, No-Show, Pending) by clinic as of today |
| **Patient Volume by Clinic** | Total appointments and unique patients served through yesterday (excluding Canceled / No-Show) |
| **Appointments per Day** | Counts daily appointment volume for each clinic |
| **Busiest Doctors** | Top 5 doctors by completed appointments (ties included) |
| **Common Diagnoses** | Most frequent diagnoses overall and by clinic |
| **Patients with Multiple Diagnoses** | Lists patients with more than one distinct conditions |

---

## 🧹 Data Cleaning Highlights

- Checked for null or invalid dates in `Appointments` and `Patients`  
- Detected and removed diagnoses linked to canceled or no-show appointments  
- Fixed appointments scheduled before patient birth dates  
- Shifted weekend appointments to valid weekday slots  
- Detected double-booked doctors and overlapping appointments  
- Ensured no after-hours appointments remained

---

## 🧮 SQL Skills Demonstrated

| Skill | Description |
|--------|-------------|
| **Joins** | Combined data across multiple related tables (clinics, staff, patients, appointments, diagnoses) |
| **Grouping & Aggregation** | Produced summaries by clinic, month, and day to measure appointment and patient volume |
| **Conditional Logic** | Applied `CASE` expressions to filter, classify, and count appointment outcomes |
| **Window Functions** | Used `ROW_NUMBER()` and `DENSE_RANK()` for detecting scheduling conflicts and ranking doctors |
| **CTEs (Common Table Expressions)** | Structured complex queries and safe update operations for clarity and reusability |
| **Date Functions** | Used `DATEADD()`, `DATEDIFF()`, and `DATENAME()` for dynamic date ranges and validation rules |
| **STRING_AGG()** | Combined multiple diagnosis descriptions per patient into a single aggregated field |
| **Data Cleaning & Validation** | Checked for nulls, invalid or inconsistent values, weekend and after-hours bookings |
| **Transactional Updates** | Used `BEGIN TRAN`, `COMMIT`, and `ROLLBACK` to safely correct and audit data changes |
| **Computed Columns** | Created derived columns (`month_start`) to facilitate time-based grouping and analysis |

---

## 🚦 How to Run the Project

Run the SQL scripts in the following order (SQL Server Management Studio or Azure Data Studio):

1️⃣ **Create database and tables**  
   `01_database_and_tables_creation.sql`

2️⃣ **Populate with data**  
   `02_tables_population.sql`

3️⃣ **Verify and clean**  
   `03_data_verif_and_cleaning.sql`

4️⃣ **Run analysis**  
   `04_data_analysis.sql`

---

## 🧾 Notes

- All data is **synthetic** and used for **educational and portfolio purposes only**.  
- The project demonstrates both **data preparation** and **analysis skills** using **T-SQL**.  
- No external data sources or confidential information are used.

---

## ⚖️ License

© 2025 Maria.  
This project is shared under the **MIT License** for educational and portfolio use.  
You are free to fork, use, or adapt the code with proper attribution.

---

## 📬 Contact

**Author:** Maria Bass  
**Location:** Alaska, USA  
💼 [LinkedIn Profile](https://www.linkedin.com/in/maria-bass-4a422052/)  

---
