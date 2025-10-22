# 🧾 MediDemo_Changelog

This file documents notable updates and fixes made to the **MediDemo_DB** SQL portfolio project.

---

## **Version 1.0.0 (2025-10-12)**

### 🐞 Fixes

- **Table `Cases`** – 75 rows removed.  
  These records were mistakenly created for appointments with status **'Canceled'** and **'No-Show'**.

- **Table `Appointments`** – Updated the appointment time for **appointment_id 10162**.  
  _Reason:_ the doctor was double-booked.

- **Table `Appointments`** – Updated appointment dates for **appointment_id 10018**, **10056**, and **10161**.  
  _Reason:_ the original dates occurred before the patients’ dates of birth.

---

### ⚙️ Changes

- **Table `Appointments`** – Adjusted 143 rows: weekend appointments (Saturday / Sunday) were shifted to Monday / Tuesday.  
  _Reason:_ to align with valid working-day scheduling rules.

---

### 🆕 New

- **Table `Appointments`** – Added computed column **`month_start`** to support monthly-level aggregation and reporting.

---
