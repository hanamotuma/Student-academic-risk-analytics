# Student Academic Performance & Risk Analytics System

An R-based analytical module designed to process, evaluate, and visualize student academic metrics. The system ingests assessment scores (quizzes, midterms, final exams) alongside attendance records to compute weighted performance metrics and automatically categorize students into actionable academic risk tiers.
🎯 Key Features & System Logic

Weighted Performance Calculation: Evaluates student academic standing using a weighted distribution:
  * Quizzes: **20%**
  * Midterm Exam: **30%**
  * Final Exam: **50%**
Multi-Criteria Risk Classification: Automatically flags risk levels based on academic performance and attendance thresholds:
  * 🔴 **High Risk:** Overall score $< 60\%$ **OR** Attendance $< 70\%$ *(Requires immediate intervention)*
  * 🟡 **Moderate Risk:** Overall score between $60\%$ and $75\%$
  * 🟢 **Low Risk:** Overall score $\ge 75\%$ **AND** Attendance $\ge 70\%$
* **Executive Console Reporting:** Outputs summary metrics including total student counts, class averages, overall attendance, risk level distributions, and filtered lists of high-risk students.
* **Risk Matrix Visualization:** Renders a scatter plot using `ggplot2` to map overall performance against attendance, featuring decision boundary threshold lines.

---

## 🛠️ Project Structure

```text
student-academic-risk-analytics/
├── .gitignore
├── student-academic-risk-analytics.Rproj
└── main_analytics.R
