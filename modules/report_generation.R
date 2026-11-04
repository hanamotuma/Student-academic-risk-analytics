# report_generation.R
library(writexl)

export_student_report <- function(df, path = "reports/student_report.xlsx") {
  write_xlsx(df, path)
}

export_risk_report <- function(df, path = "reports/risk_report.xlsx") {
  write_xlsx(high_risk_students(df), path)
}

export_subject_summary <- function(df, path = "reports/subject_summary.xlsx") {
  write_xlsx(get_subject_summary(df), path)
}